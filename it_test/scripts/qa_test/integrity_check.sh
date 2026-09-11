#!/bin/bash
# integrity_check.sh — проверка прав и контрольных сумм
LOG="$HOME/qa_test/logs/integrity.log"
CONF_DIR="/etc"

echo "=== Проверка конфигураций ===" | tee -a "$LOG"

# Файлы, доступные на запись всем — потенциальная уязвимость
echo "--- Файлы с правами 777 или world-writable в $CONF_DIR ---" | tee -a "$LOG"
find "$CONF_DIR" -maxdepth 2 -type f -perm -o+w 2>/dev/null | tee -a "$LOG"

# Контрольные суммы ключевых конфигов
echo "--- Хэши конфигураций ---" | tee -a "$LOG"
for f in /etc/passwd /etc/group /etc/hosts /etc/fstab; do
    [ -f "$f" ] && sha256sum "$f" | tee -a "$LOG"
done

# Владельцы sudoers
echo "--- Права /etc/sudoers ---" | tee -a "$LOG"
ls -l /etc/sudoers 2>/dev/null | tee -a "$LOG"
