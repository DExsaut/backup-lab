#!/bin/bash
LOG_DIR=$1
X=${2:-70}
LIMIT_MB=${3:-1024}
BACKUP_DIR=${4:-./backup}
if [ ! -d "$LOG_DIR" ]; then
    echo "Ошибка: '$LOG_DIR' не папка."
    exit 1
fi
LIMIT_KB=$((LIMIT_MB * 1024))
SIZE_KB=$(du -ck "$LOG_DIR"/* | tail -1 | cut -f1)
PERCENT=$((SIZE_KB * 100 / LIMIT_KB))
echo "Папка $LOG_DIR занята на $PERCENT%, порог $X%."
if [ $PERCENT -le $X ]; then
    echo "Архивация не требуется."
    exit 0
fi
NEED_KB=$((SIZE_KB - LIMIT_KB * X / 100))
FILES=""
FREED_KB=0
for f in $(ls -tr "$LOG_DIR"); do
    if [ $FREED_KB -ge $NEED_KB ]; then
        break
    fi
    FILES="$FILES $f"
    FILE_KB=$(du -k "$LOG_DIR/$f" | cut -f1)
    FREED_KB=$((FREED_KB + FILE_KB))
done
mkdir -p "$BACKUP_DIR"
if [ "$LAB1_MAX_COMPRESSION" = "1" ]; then
    TAR_KEY="--lzma"
    EXT="tar.lzma"
else
    TAR_KEY="-z"
    EXT="tar.gz"
fi
ARCHIVE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).$EXT"
echo "Архивация в $ARCHIVE..."
tar -c $TAR_KEY -f "$ARCHIVE" -C "$LOG_DIR" $FILES
if [ $? -eq 0 ]; then
    for f in $FILES; do
        rm "$LOG_DIR/$f"
    done
    echo "В архив перенесено файлов: $(echo $FILES | wc -w)"
else
    echo "Ошибка при архивации, файлы не удалены"
    exit 1
fi
