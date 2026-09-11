#!/bin/bash
# web_test.sh — функциональное тестирование веб-приложения
# Использование: ./web_test.sh https://example.com

URL="${1:-http://localhost}"
LOG="$HOME/qa_test/logs/web_test.log"
PASS=0; FAIL=0

check_url() {
    local url="$1" expected="$2" name="$3"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url")
    if [ "$code" = "$expected" ]; then
        echo "[PASS] $name ($url) → $code" | tee -a "$LOG"
        ((PASS++))
    else
        echo "[FAIL] $name ($url) → $code (ожидалось $expected)" | tee -a "$LOG"
        ((FAIL++))
    fi
}

echo "=== Тест веб-приложения: $URL ===" | tee -a "$LOG"
check_url "$URL"              200 "Главная страница"
check_url "$URL/robots.txt"   200 "robots.txt"
check_url "$URL/nonexist"     404 "Несуществующая страница"

# Проверка времени ответа
TIME=$(curl -s -o /dev/null -w "%{time_total}" --max-time 5 "$URL")
echo "Время отклика: ${TIME}s" | tee -a "$LOG"
awk -v t="$TIME" 'BEGIN{ if (t>2) print "[WARN] Отклик >2 сек"; else print "[OK] Отклик в норме" }'

echo "Итого: PASS=$PASS FAIL=$FAIL" | tee -a "$LOG"
