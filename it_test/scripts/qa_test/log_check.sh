#!/bin/bash
# log_check.sh — анализ ошибок в системных журналах
LOG="$HOME/qa_test/logs/log_check.log"

echo "=== Анализ журналов ===" | tee -a "$LOG"

# Последние ошибки journalctl
echo "--- Последние 10 ошибок (journalctl) ---" | tee -a "$LOG"
journalctl -p err -n 10 --no-pager 2>/dev/null | tee -a "$LOG"

# Подсчёт неудачных попыток входа
echo "--- Неудачные логины ---" | tee -a "$LOG"
grep -i "failed password" /var/log/secure 2>/dev/null | wc -l | tee -a "$LOG"

# Проверка роста логов
echo "--- Размеры /var/log ---" | tee -a "$LOG"
du -sh /var/log/* 2>/dev/null | sort -rh | head -5 | tee -a "$LOG"
