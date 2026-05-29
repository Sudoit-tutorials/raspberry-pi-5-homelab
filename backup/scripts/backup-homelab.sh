#!/bin/bash
set -euo pipefail

ENV_FILE="/opt/homelab-backup/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing environment file: $ENV_FILE"
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

RESTIC_REPOSITORY="rclone:gdrive:homelab-backups"
RESTIC_PASSWORD_FILE="/root/.restic-password"
RCLONE_CONFIG="/home/patryk/.config/rclone/rclone.conf"

DOCKER_DATA_PATH="/srv/dev-disk-by-uuid-CHANGE_ME/docker/data"
BACKUP_TMP="/tmp/homelab-backup"
LOG_FILE="/var/log/homelab-restic-backup.log"

export RESTIC_REPOSITORY
export RESTIC_PASSWORD_FILE
export RCLONE_CONFIG

mkdir -p "$BACKUP_TMP"

echo "=== Backup started: $(date) ===" >> "$LOG_FILE"

echo "[1/4] Creating Nextcloud database dump..." >> "$LOG_FILE"

docker exec "$NEXTCLOUD_DB_CONTAINER" mariadb-dump \
  -u "$NEXTCLOUD_DB_USER" \
  -p"$NEXTCLOUD_DB_PASSWORD" \
  "$NEXTCLOUD_DB_NAME" \
  > "$BACKUP_TMP/nextcloud-db.sql"

echo "[2/4] Running Restic backup..." >> "$LOG_FILE"

echo "[INFO] Docker data size:" >> "$LOG_FILE"
du -sh "$DOCKER_DATA_PATH" >> "$LOG_FILE" 2>&1
echo "[INFO] Starting restic backup command..." >> "$LOG_FILE"

restic backup \
"$DOCKER_DATA_PATH" \
"$BACKUP_TMP/nextcloud-db.sql"  
--tag homelab \
--tag nextcloud \
--verbose \
>> "$LOG_FILE" 2>&1

echo "[3/4] Applying retention policy..." >> "$LOG_FILE"

restic forget \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 3 \
  --prune \
  >> "$LOG_FILE" 2>&1

echo "[4/4] Cleaning temporary files..." >> "$LOG_FILE"

rm -f "$BACKUP_TMP/nextcloud-db.sql"

echo "=== Backup finished: $(date) ===" >> "$LOG_FILE"
