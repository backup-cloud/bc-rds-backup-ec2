#!/bin/sh

echo "Backup script started"

TMPDIR=/mnt/nv

set -e

if [ "${MYSQLDUMP}" = "**None**" ]; then
  echo "You need to set the MYSQLDUMP environment variable."
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

# env vars needed for aws tools - only if an IAM role is not used
if [ "${S3_ACCESS_KEY_ID}" != "" ] &&  [ "${S3_ACCESS_KEY_ID}" != "**None**" ]; then
  export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
fi
if [ "${S3_SECRET_ACCESS_KEY}" != "" ] &&  [ "${S3_SECRET_ACCESS_KEY}" != "**None**" ]; then
  export AWS_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
fi
if [ "${S3_REGION}" != "" ] &&  [ "${S3_REGION}" != "**None**" ]; then
  export AWS_DEFAULT_REGION=$S3_REGION
fi

# python3 -m venv backup_cloud_venv
# source  backup_cloud_venv/bin/activate
# hardwired since right now there's no way to link to "latest stable" 
pip3 install https://github.com/backup-cloud/backup-base/archive/20190821112958-b50c3da.tar.gz

( echo "Starting at: $(date)" ) >&2
# shellcheck disable=SC2086
echo running $MYSQLDUMP --host "$MYSQL_HOST" --port "$MYSQL_PORT" --user "$MYSQL_USER" --password="$MYSQL_PASSWORD" $MYSQLDUMP_OPTIONS >&2
    # shellcheck disable=SC2086
time $MYSQLDUMP --host "$MYSQL_HOST" --port "$MYSQL_PORT" --user "$MYSQL_USER" --password="$MYSQL_PASSWORD" $MYSQLDUMP_OPTIONS 

( echo "Database Dump finished at:  $(date)" ) >&2

backup-cloud-upload "$SSM_BASE_PATH" export* coredb-backup
