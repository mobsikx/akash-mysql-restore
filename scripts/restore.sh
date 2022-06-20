#!/bin/bash

# Check if another instance of script is running
pidof -o %PPID -x $0 >/dev/null && echo "ERROR: Script $0 already running" && exit 1

set -e

echo "Restoring database"

export AWS_ACCESS_KEY_ID=$BACKUP_KEY
export AWS_SECRET_ACCESS_KEY=$BACKUP_SECRET

s3_uri_base="s3://${BACKUP_PATH}"
aws_args="--endpoint-url ${BACKUP_HOST}"

if [ -z "$BACKUP_PASSPHRASE" ]; then
  file_type=".dump"
else
  file_type=".dump.gpg"
fi

if [ $# -eq 1 ]; then
  timestamp="$1"
  key_suffix="${MYSQL_DATABASE}_${timestamp}${file_type}"
else
  echo "Finding latest backup..."
  key_suffix=$(
    aws $aws_args s3 ls "${s3_uri_base}/${MYSQL_DATABASE}" \
      | sort \
      | tail -n 1 \
      | awk '{ print $4 }'
  )
fi

if [ -z "$key_suffix" ]; then
  echo "No backup found"
else
  echo "Fetching backup from S3..."
  aws $aws_args s3 cp "${s3_uri_base}/${key_suffix}" "db${file_type}"

  if [ -n "${BACKUP_PASSPHRASE}" ]; then
    echo "Decrypting backup..."
    gpg --decrypt --batch --passphrase "${BACKUP_PASSPHRASE}" db.dump.gpg > db.dump
    rm db.dump.gpg
  fi

  conn_opts=""

  echo "Restoring from backup..."
  mysql --user=${MYSQL_USER} \
        --host=${MYSQL_HOST} \
        --password=${MYSQL_PASSWORD} \
        ${MYSQL_DATABASE} < db.dump
  rm db.dump

  echo "Restore complete."
fi
