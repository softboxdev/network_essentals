# Практическое задание: Тестирование типовых информационных систем и веб-приложений в ОС Linux Rosa

## Цель работы
Получить практические навыки тестирования информационных систем и веб-приложений в среде Linux Rosa с использованием bash-скриптов для автоматизации проверок.

## Теоретическая часть

**Linux Rosa** — российский дистрибутив Linux (форк Mandriva/ROSA), используется в корпоративной среде. Имеет собственные утилиты управления (`urpmi`, `rosa-media-player`, центр управления). Базируется на RPM-пакетах.

**Типовые проверки ИС:**
- доступность сервисов (ping, HTTP-коды);
- целостность конфигураций;
- работоспособность БД;
- журналирование и права доступа;
- нагрузочные/функциональные проверки.

---
# Как создать рабочую папку `qa_test`

Есть несколько способов — выберите удобный.

## Способ 1. Через файловый менеджер (графика)

1. Откройте **Файлы** (Nautilus / Dolphin / PCManFM — зависит от редакции Rosa).
2. Перейдите в свою домашнюю папку (`/home/ваш_логин`).
3. Правой кнопкой → **Создать папку** → введите имя `qa_test`.
4. Внутри создайте две подпапки: `logs` и `reports`.

## Способ 2. Через терминал (одной командой)

Откройте терминал (`Ctrl+Alt+T`) и выполните:

```bash
mkdir -p ~/qa_test
mkdir -p ~/qa_test/logs ~/qa_test/reports
```

Разбор команды:
- `mkdir` — команда создания каталогов;
- `-p` — создаёт все недостающие родительские папки и не выдаёт ошибку, если папка уже существует;
- `~` — сокращение для вашей домашней папки (`/home/ваш_логин`);



## Задание 1. Подготовка окружения

Перейдите в рабочую папку проекта cd ~/qa_test/

Создайте рабочую папку и файл лога:

```bash
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
```

---

## Задание 2. Проверка состояния ОС Rosa

```bash
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
```

---

## Задание 3. Тестирование веб-приложения

```bash
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
```

---

## Задание 4. Проверка доступности портов и сервисов

```bash
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
```

---

## Задание 5. Проверка прав доступа и целостности конфигураций

```bash
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
```

---

## Задание 6. Проверка журналов (logs)

```bash
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
```

---

## Задание 7. Нагрузочный мини-тест

```bash
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
```

---

## Задание 8. Итоговый сводный отчёт

```bash
#!/bin/bash
# run_all.sh — запуск всех тестов и сводка
DIR="$HOME/qa_test"
REPORT="$DIR/reports/summary_$(date +%F_%H%M).txt"

{
echo "======================================"
echo " СВОДНЫЙ ОТЧЁТ ТЕСТИРОВАНИЯ"
echo " Дата: $(date '+%F %T')"
echo " Хост: $(hostname)"
echo "======================================"
} > "$REPORT"

bash "$DIR/os_check.sh"        >> "$REPORT" 2>&1
bash "$DIR/port_check.sh"      >> "$REPORT" 2>&1
bash "$DIR/web_test.sh"        >> "$REPORT" 2>&1
bash "$DIR/integrity_check.sh" >> "$REPORT" 2>&1
bash "$DIR/log_check.sh"       >> "$REPORT" 2>&1

echo "Отчёт сохранён: $REPORT"
```

---

## Контрольные вопросы

1. Чем отличается тестирование ОС от тестирования веб-приложения?
2. Какие метрики используются при нагрузочном тестировании?
3. Как в Linux Rosa проверить целостность пакетов? (`rpm -Va`)
4. Что проверяет утилита `curl -w "%{http_code}"` и почему это важно в QA?
5. Как обнаружить потенциальные уязвимости через права доступа файлов?

## Порядок выполнения

1. Скопировать скрипты в `~/qa_test/`, дать права: `chmod +x ~/qa_test/*.sh`.
2. Запустить `setup.sh`, затем `run_all.sh`.
3. Проанализировать `reports/summary_*.txt`.
4. Оформить отчёт: цель, стенд, перечень проверок, найденные дефекты, выводы.
5. Составить 3 баг-репорта по результатам `[FAIL]`/`[WARN]` (формат: шаги, ожидаемо, фактически, severity).

## Критерии оценки
- Корректность работы скриптов — 40%
- Полнота покрытия проверок — 20%
- Оформление баг-репортов и отчёта — 25%
- Ответы на контрольные вопросы — 15%

---

**Примечание:** для Rosa Fresh может потребоваться установка `curl` (`sudo dnf install curl` или `sudo urpmi curl`), а `/var/log/secure` может называться `/var/log/auth.log` — проверяйте в зависимости от версии дистрибутива.
