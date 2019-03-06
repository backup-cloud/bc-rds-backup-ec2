#!/bin/sh

echo "Backup script started"


TMPDIR=/mnt/nv



set -e

if [ "${S3_ACCESS_KEY_ID}" = "**None**" ]; then
  echo "Warning: You did not set the S3_ACCESS_KEY_ID environment variable."
fi

if [ "${S3_SECRET_ACCESS_KEY}" = "**None**" ]; then
  echo "Warning: You did not set the S3_SECRET_ACCESS_KEY environment variable."
fi

if [ "${S3_BUCKET}" = "**None**" ]; then
  echo "You need to set the S3_BUCKET environment variable."
  exit 1
fi

if [ "${MYSQL_HOST}" = "**None**" ]; then
  echo "You need to set the MYSQL_HOST environment variable."
  exit 1
fi

if [ "${MYSQL_USER}" = "**None**" ]; then
  echo "You need to set the MYSQL_USER environment variable."
  exit 1
fi

if [ "${MYSQL_PASSWORD}" = "**None**" ]; then
  echo "You need to set the MYSQL_PASSWORD environment variable or link to a container named MYSQL."
  exit 1
fi

if [ "${S3_IAMROLE}" != "true" ]; then
  # env vars needed for aws tools - only if an IAM role is not used
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
  export AWS_DEFAULT_REGION=$S3_REGION
fi

my_mysql() {
    mysql -h "$MYSQL_HOST" -P "$MYSQL_PORT" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$@"
}

dump_chosen () {
    # ash shell does not support arrays and we need to get the mysql dump
    # options in from the docker file so the least nasty way to do this is, to
    # have an unquoted variable as far as I can see.  Make sure it doesn't come
    # in from an untrusted source, which, in the original application I assume
    # it can't.
    # 
    # shellcheck disable=SC2086
    echo running mysqldump --host "$MYSQL_HOST" --port "$MYSQL_PORT" --user "$MYSQL_USER" --password="$MYSQL_PASSWORD" $MYSQLDUMP_OPTIONS --databases "$@" >&2
    # shellcheck disable=SC2086
    mysqldump --host "$MYSQL_HOST" --port "$MYSQL_PORT" --user "$MYSQL_USER" --password="$MYSQL_PASSWORD" $MYSQLDUMP_OPTIONS --databases "$@"
}

dump_all () {
    # ash shell does not support arrays and we need to get the mysql dump
    # options in from the docker file so the least nasty way to do this is, to
    # have an unquoted variable as far as I can see.  Make sure it doesn't come
    # in from an untrusted source, which, in the original application I assume
    # it can't.
    # 
    # shellcheck disable=SC2086
    echo running mysqldump --host "$MYSQL_HOST" --port "$MYSQL_PORT" --user "$MYSQL_USER" --password="$MYSQL_PASSWORD" $MYSQLDUMP_OPTIONS --all-databases >&2
    # shellcheck disable=SC2086
    mysqldump --host "$MYSQL_HOST" --port "$MYSQL_PORT" --user "$MYSQL_USER" --password="$MYSQL_PASSWORD" $MYSQLDUMP_OPTIONS --all-databases

}


dump_to_s3() {
    ( set -o pipefail
    THE_DB=$1
    THE_DUMP_FILE=$2
    if [ "--all-databases"  = "$THE_DB" ]
    then
	dump_command=dump_all
    else
	dump_command=dump_chosen
    fi
    
    if [ "${ENCRYPT}" = "false" ]
    then
	"$dump_command" "$THE_DB" | pigz | copy_s3 - "${THE_DUMP_FILE}"
    else
	"$dump_command" "$THE_DB" | pigz -9 |
	    gpg --homedir "${GPG_HOME_DIR}" ${RECIPIENTS} --encrypt --trust-model always |
	        copy_s3 - "${THE_DUMP_FILE}"
    fi )

}

if [ "${S3_FILENAME}" = "**None**" ]
then
    S3_FILENAME=$(date +"%Y-%m-%dT%H%M%SZ")
fi

SUFFIX="sql.gz"
if [ "${GPG_KEY_BASE}" = "**None**" ];
then
    ENCRYPT="false"
else
    umask 077
    GPG_HOME_DIR=$(mktemp -d)
    export GPG_HOME_DIR
    ENCRYPT="true"
    SUFFIX="$SUFFIX.gpg"

    # we do want to convert newlines since public keys need them but we
    # don't really want other sequences such as %s since they might
    # appear accidentally;  for now use echo -e

    # Maybe it would be good to use `echo | sed 's/\\n/\n'` but I can't
    # work out a sane way to make that portable between dash/sed on
    # MacOS and alpine.  Using echo on alpine and gecho on MacOS seems
    # closest at this moment
    
    # shellcheck disable=SC2039
    aws s3 cp --recursive "${GPG_KEY_BASE}" public-keys

    # based on
    # https://security.stackexchange.com/questions/86721
    for i in public-keys/*.pub
    do
	gpg --homedir "${GPG_HOME_DIR}" --import $i
    done
    RECIPIENTS=$(gpg --list-keys --with-colons --homedir "${GPG_HOME_DIR}" | grep pub |
		cut -d: -f5 | sed 's/^/--recipient /')
fi


copy_s3 () {
  SRC_FILE=$1
  DEST_FILE=$2

  if [ "${S3_ENDPOINT}" = "**None**" ]; then
    AWS_ARGS=""
  else
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
  fi

  echo "Uploading ${DEST_FILE} to S3..."

  # shellcheck disable=SC2086
  if ! aws ${AWS_ARGS} s3 cp "${SRC_FILE}" "s3://${S3_BUCKET}/${S3_PREFIX}/${DEST_FILE}" 
  then
    >&2 echo "Error uploading ${DEST_FILE} to S3"
  fi

  if [ ! '-' = "${SRC_FILE}" ]
  then
      rm "${SRC_FILE}"
  fi
}

FAILCODE=0
if echo "${MULTI_FILES}" | grep -q -i -E "(yes|true|1)"
then
  # Multi file: yes
  if [ "${MYSQLDUMP_DATABASE}" = "--all-databases" ]; then
    DATABASES=$(my_mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys|innodb)")
  else
    DATABASES="$MYSQLDUMP_DATABASE"
  fi

  for DB in $DATABASES; do
    echo "Creating individual dump of ${DB} from ${MYSQL_HOST}..."

    S3_FILE="${S3_FILENAME}.${DB}.${SUFFIX}"
    DUMP_FILE="$TMPDIR/${DB}.${SUFFIX}"


    if dump_to_s3 "${DB}" "${S3_FILE}"
    then
      echo "SQL backup finished successfully"
    else
      >&2 echo "Error creating dump of ${DB}"
      if [ $? -gt "$FAILCODE" ]
      then
	  FAILCODE=$?
      fi
    fi
  done
  echo "SQL backup finished"
else
  # Multi file: no
  echo "Creating dump for ${MYSQLDUMP_DATABASE} from ${MYSQL_HOST}..."

  S3_FILE="${S3_FILENAME}.${SUFFIX}"
  DUMP_FILE="$TMPDIR/dump.${SUFFIX}"

  if dump_to_s3 "${MYSQLDUMP_DATABASE}" "${S3_FILE}"
  then
    echo "SQL backup finished successfully"
  else
    RET=$?
    if [ "$RET" -gt "$FAILCODE" ]
    then
	FAILCODE="$RET"
    fi
    echo "Error creating dump of all databases" >&2 
  fi
fi

# at this point in docker we should
