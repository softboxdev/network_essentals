#!/bin/bash
# load_test.sh — простой нагрузочный тест
URL="${1:-http://localhost}"
N="${2:-20}"
LOG="$HOME/qa_test/logs/load_test.log"

echo "=== Нагрузочный тест: $N запросов к $URL ===" | tee -a "$LOG"
START=$(date +%s%N)
OK=0; ERR=0

for i in $(seq 1 "$N"); do
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$URL")
    [ "$code" = "200" ] && ((OK++)) || ((ERR++))
done

END=$(date +%s%N)
DUR=$(( (END - START) / 1000000 ))
echo "Успешных: $OK, Ошибок: $ERR" | tee -a "$LOG"
echo "Общее время: ${DUR} мс, Среднее: $((DUR/N)) мс" | tee -a "$LOG"
