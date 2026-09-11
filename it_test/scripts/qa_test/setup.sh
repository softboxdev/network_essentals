#!/bin/bash
# setup.sh — подготовка окружения для тестирования
# qa_test - рабочая папка для тестирования, создаётся автоматически

# 1. Путь к рабочей папке
WORKDIR="$HOME/qa_test"

# 2. ЯВНО создаём саму qa_test
mkdir -p "$WORKDIR"
echo "[CREATE] $WORKDIR"

# 3. Создаём подпапки внутри неё
mkdir -p "$WORKDIR/logs"
mkdir -p "$WORKDIR/reports"

# 4. Создаём файл лога
touch "$WORKDIR/logs/test.log"

# 5. Проверяем, что всё реально создалось
if [ -d "$WORKDIR" ] && [ -d "$WORKDIR/logs" ] && [ -d "$WORKDIR/reports" ]; then
    echo "[OK] Структура создана:"
    ls -la "$WORKDIR"
else
    echo "[FAIL] Не удалось создать структуру в $WORKDIR"
    exit 1
fi

# 6. Запись в лог и на экран
echo "[$(date '+%F %T')] Окружение создано: $WORKDIR" | tee -a "$WORKDIR/logs/test.log"
