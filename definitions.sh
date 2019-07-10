#!/bin/sh

AUTO_TERMINATE=true
MYSQLDUMP=mydumper
# MYSQLDUMP_OPTIONS="--quote-names --quick --add-drop-table --add-locks --allow-keywords --disable-keys --extended-insert --single-transaction --create-options --comments --net_buffer_length=16384 --order-by-primary"
MYSQLDUMP_OPTIONS="--lock-all-tables -t 8 -c"
MYSQLDUMP_DATABASE="--all-databases"
MYSQL_HOST="**None**"
MYSQL_PORT="3306"
MYSQL_USER="**None**"
MYSQL_PASSWORD="**None**"
S3_ACCESS_KEY_ID="**None**"
S3_SECRET_ACCESS_KEY="**None**"
S3_BUCKET="**None**"
S3_REGION="us-west-1"
S3_ENDPOINT="**None**"
S3_S3V4="no"
S3_PREFIX="backup"
S3_FILENAME="**None**"
MULTI_FILES="no"
SCHEDULE="**None**"
PUBLIC_KEY="**None**"
ENCRYPT="true"
GPG_KEY_BASE="**None**"
