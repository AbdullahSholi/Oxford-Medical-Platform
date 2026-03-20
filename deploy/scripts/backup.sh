#!/bin/sh
# ═══════════════════════════════════════════════════════════
# MedOrder — Database Backup Script
# Runs daily via cron inside the backup container
# Keeps 7 daily + 4 weekly backups
# ═══════════════════════════════════════════════════════════

BACKUP_DIR="/backups"
DATE=$(date +%Y%m%d_%H%M%S)
DAY_OF_WEEK=$(date +%u)
FILENAME="medorder_${DATE}.sql.gz"

echo "[$(date)] Starting backup..."

# Create backup
pg_dump -h "$PGHOST" -U "$PGUSER" "$PGDATABASE" | gzip > "${BACKUP_DIR}/${FILENAME}"

if [ $? -eq 0 ]; then
    echo "[$(date)] Backup created: ${FILENAME} ($(du -h ${BACKUP_DIR}/${FILENAME} | cut -f1))"

    # Keep weekly backup on Sundays
    if [ "$DAY_OF_WEEK" = "7" ]; then
        cp "${BACKUP_DIR}/${FILENAME}" "${BACKUP_DIR}/weekly_${FILENAME}"
    fi

    # Delete daily backups older than 7 days
    find "$BACKUP_DIR" -name "medorder_*.sql.gz" -mtime +7 ! -name "weekly_*" -delete

    # Delete weekly backups older than 28 days
    find "$BACKUP_DIR" -name "weekly_*.sql.gz" -mtime +28 -delete

    echo "[$(date)] Cleanup done. Backups:"
    ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null
else
    echo "[$(date)] ERROR: Backup failed!"
    exit 1
fi
