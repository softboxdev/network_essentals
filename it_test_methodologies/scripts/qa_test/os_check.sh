#!/bin/bash
# os_check.sh — базовая проверка ОС Linux Rosa
LOG="$HOME/qa_test/logs/os_check.log"

{
echo "=== Проверка ОС ==="
echo "Дата: $(date '+%F %T')"

# Версия дистрибутива
if [ -f /etc/rosa-release ]; then
    echo "[OK] ROSA: $(cat /etc/rosa-release)"
else
    echo "[WARN] Файл /etc/rosa-release не найден"
fi

# Ядро
echo "Ядро: $(uname -r)"

# Свободное место на /
FREE=$(df -h / | awk 'NR==2 {print $4}')
echo "Свободно на /: $FREE"

# Загрузка CPU (1 мин)
LOAD=$(awk '{print $1}' /proc/loadavg)
echo "Load average (1m): $LOAD"

# Проверка сервисов
for svc in sshd crond NetworkManager; do
    if systemctl is-active --quiet "$svc"; then
        echo "[OK] Сервис $svc активен"
    else
        echo "[FAIL] Сервис $svc не активен"
    fi
done
} | tee -a "$LOG"
