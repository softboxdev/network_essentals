#!/bin/bash
# port_check.sh — проверка портов типовой ИС
LOG="$HOME/qa_test/logs/port_check.log"
HOST="127.0.0.1"
declare -A PORTS=(
    [22]="SSH"
    [80]="HTTP"
    [443]="HTTPS"
    [3306]="MySQL"
    [5432]="PostgreSQL"
)

echo "=== Проверка портов на $HOST ===" | tee -a "$LOG"
for port in "${!PORTS[@]}"; do
    if timeout 2 bash -c "echo >/dev/tcp/$HOST/$port" 2>/dev/null; then
        echo "[OPEN] ${PORTS[$port]} (:$port)" | tee -a "$LOG"
    else
        echo "[CLOSED] ${PORTS[$port]} (:$port)" | tee -a "$LOG"
    fi
done
