#!/bin/bash
# run_stlc_tests.sh — выполнение тест-кейсов
WORKDIR="$HOME/stlc_homework"
LOG="$WORKDIR/04_execution/run_tests.log"
URL="${1:-https://www.google.com}"

PASS=0; FAIL=0

run_case() {
    local id="$1" name="$2" url="$3" expected="$4"
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url")
    if [ "$code" = "$expected" ]; then
        echo "[PASS] $id $name → $code" | tee -a "$LOG"
        ((PASS++))
    else
        echo "[FAIL] $id $name → $code (ожидалось $expected)" | tee -a "$LOG"
        ((FAIL++))
    fi
}

echo "=== STLC Test Run: $(date '+%F %T') ===" | tee -a "$LOG"
run_case "TC-01" "Доступность главной" "$URL" "200"
run_case "TC-02" "Обработка 404"        "$URL/not-found-xyz" "404"
run_case "TC-03" "robots.txt"           "$URL/robots.txt" "200"
run_case "TC-04" "favicon"              "$URL/favicon.ico" "200"
run_case "TC-05" "Проверка редиректа"   "$URL/" "200"

echo "Итого: PASS=$PASS FAIL=$FAIL" | tee -a "$LOG"
