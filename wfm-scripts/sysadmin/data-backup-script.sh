#!/bin/bash

BACKUP_DIRS="/home /etc /var/www"
BACKUP_DEST="/backup"  # Change to your backup location
mkdir -p "$BACKUP_DEST"

DAY=$(date +%A)
HOSTNAME=$(hostname -s)
ARCHIVE="$BACKUP_DEST/${HOSTNAME}-${DAY}-backup.tgz"

tar czf "$ARCHIVE" $BACKUP_DIRS
echo "Backup created: $ARCHIVE"
