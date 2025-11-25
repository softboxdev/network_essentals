
## 1. Базовая структура bash скрипта

```bash
#!/bin/bash
#
# Скрипт: network_anomaly_detector.sh
# Назначение: Мониторинг сети для обнаружения аномальной активности
# Автор: Kali Security Team
# Версия: 1.0

# ==========================================
# КОНФИГУРАЦИЯ И НАСТРОЙКИ
# ==========================================

# Целевая сеть для мониторинга
TARGET_NETWORK="192.168.1.0/24"

# Интерфейс для мониторинга
MONITOR_INTERFACE="eth0"

# Пороги для обнаружения аномалий
MAX_CONNECTIONS_PER_HOST=100
MAX_PACKETS_PER_SECOND=1000
MAX_PORT_SCAN_ATTEMPTS=10

# Директории для логов
LOG_DIR="/var/log/network_monitor"
ALERT_LOG="$LOG_DIR/alerts.log"
TRAFFIC_LOG="$LOG_DIR/traffic.log"

# ==========================================
# ФУНКЦИИ СКРИПТА
# ==========================================
```

## 2. Полный скрипт мониторинга с комментариями

```bash
#!/bin/bash

# ==========================================
# ЗАГОЛОВОК И КОНФИГУРАЦИЯ
# ==========================================

# Shebang - указывает интерпретатор
#!/bin/bash

# Комментарий с описанием скрипта
#
# Network Anomaly Detection System for Kali Linux
# Обнаруживает: порт-сканнинг, DDoS, подозрительные соединения
# Использует: tcpdump, netstat, ss, iptables
#

# Глобальные переменные конфигурации - замените на свой целевой адрес сети хоста через команду ip addr show eth0 
TARGET_NETWORK="192.168.1.0/24"
MONITOR_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
LOG_DIR="/var/log/network_monitor"
ALERT_LOG="$LOG_DIR/alerts.log"
TRAFFIC_LOG="$LOG_DIR/traffic.csv"
PCAP_DIR="$LOG_DIR/pcaps"

# Пороги для обнаружения аномалий
MAX_CONNECTIONS_PER_HOST=50
MAX_PACKETS_PER_SECOND=500
MAX_PORT_SCAN_ATTEMPTS=5
SCAN_TIME_WINDOW=60

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ==========================================
# ФУНКЦИИ ИНИЦИАЛИЗАЦИИ
# ==========================================

# Функция инициализации среды мониторинга
init_environment() {
    echo -e "${GREEN}[+] Инициализация системы мониторинга...${NC}"
    
    # Создание директорий для логов
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" "$PCAP_DIR"
        echo -e "${YELLOW}[!] Созданы директории логов: $LOG_DIR${NC}"
    fi
    
    # Проверка прав root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] Ошибка: Скрипт требует прав root для работы${NC}"
        exit 1
    fi
    
    # Проверка необходимых утилит
    check_dependencies
}

# Проверка зависимостей
check_dependencies() {
    local deps=("tcpdump" "netstat" "ss" "iptables" "awk" "grep" "sort" "uniq")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}[!] Ошибка: $dep не установлен${NC}"
            echo -e "${YELLOW}[!] Установите: sudo apt install $dep${NC}"
            exit 1
        fi
    done
    echo -e "${GREEN}[+] Все зависимости удовлетворены${NC}"
}

# ==========================================
# ФУНКЦИИ МОНИТОРИНГА
# ==========================================

# Мониторинг подозрительных соединений
monitor_suspicious_connections() {
    echo -e "${GREEN}[+] Мониторинг подозрительных соединений...${NC}"
    
    # Поиск хостов с большим количеством соединений
    local high_conn_hosts=$(netstat -tun 2>/dev/null | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10)
    
    echo "$high_conn_hosts" | while read count host; do
        if [ "$count" -gt "$MAX_CONNECTIONS_PER_HOST" ] && [ -n "$host" ]; then
            log_alert "HIGH_CONNECTIONS" "Хост $host имеет $count соединений" "$host"
        fi
    done
}

# Обнаружение сканирования портов
detect_port_scanning() {
    echo -e "${GREEN}[+] Проверка сканирования портов...${NC}"
    
    # Анализ недавних соединений
    local recent_conns=$(ss -tun state established | awk '{print $5}' | cut -d: -f1 | sort | uniq -c)
    
    echo "$recent_conns" | while read count host; do
        if [ "$count" -gt "$MAX_PORT_SCAN_ATTEMPTS" ] && [ -n "$host" ]; then
            log_alert "PORT_SCAN" "Возможное сканирование портов с $host ($count попыток)" "$host"
        fi
    done
}

# Мониторинг сетевой статистики
monitor_network_stats() {
    local stats=$(cat /proc/net/dev | grep "$MONITOR_INTERFACE" | awk '{
        print "interface="$1, "rx_bytes="$2, "tx_bytes="$3, "rx_packets="$4, "tx_packets="$5
    }')
    
    # Логирование статистики в CSV формате
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$stats" >> "$TRAFFIC_LOG"
}

# Захват пакетов для анализа
start_packet_capture() {
    local pcap_file="$PCAP_DIR/capture_$(date +%Y%m%d_%H%M%S).pcap"
    
    # Захват только подозрительного трафика в фоне
    tcpdump -i "$MONITOR_INTERFACE" -w "$pcap_file" \
        "tcp and (tcp[tcpflags] & (tcp-syn|tcp-fin) != 0) or icmp or port 445 or port 22" \
        2>/dev/null &
    
    echo $! > /tmp/tcpdump_pid
    echo -e "${YELLOW}[!] Захват пакетов запущен: $pcap_file${NC}"
}

# ==========================================
# ФУНКЦИИ АНАЛИЗА И ОПОВЕЩЕНИЙ
# ==========================================

# Логирование оповещений
log_alert() {
    local alert_type="$1"
    local message="$2"
    local source="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local log_entry="[$timestamp] [$alert_type] $message (Источник: $source)"
    
    # Запись в лог
    echo "$log_entry" >> "$ALERT_LOG"
    
    # Вывод в консоль с цветом
    case $alert_type in
        "PORT_SCAN")
            echo -e "${RED}[!] ВНИМАНИЕ: $message${NC}"
            ;;
        "HIGH_CONNECTIONS")
            echo -e "${YELLOW}[!] ПРЕДУПРЕЖДЕНИЕ: $message${NC}"
            ;;
        *)
            echo -e "${RED}[!] АНОМАЛИЯ: $message${NC}"
            ;;
    esac
    
    # Дополнительные действия при критических событиях
    if [ "$alert_type" = "PORT_SCAN" ]; then
        block_suspicious_host "$source"
    fi
}

# Блокировка подозрительных хостов
block_suspicious_host() {
    local host="$1"
    
    # Проверяем, не заблокирован ли уже хост
    if ! iptables -L INPUT -n | grep -q "$host"; then
        iptables -I INPUT -s "$host" -j DROP
        echo -e "${RED}[!] Хост $host заблокирован в iptables${NC}"
        
        # Логирование блокировки
        echo "$(date '+%Y-%m-%d %H:%M:%S') - BLOCKED: $host" >> "$LOG_DIR/blocked_hosts.log"
    fi
}

# Анализ логов в реальном времени
analyze_realtime_traffic() {
    echo -e "${GREEN}[+] Запуск анализа трафика в реальном времени...${NC}"
    
    # Мониторинг SYN флуда
    tcpdump -i "$MONITOR_INTERFACE" -n "tcp[tcpflags] & tcp-syn != 0" 2>/dev/null | \
    awk -v max_syn=$MAX_PACKETS_PER_SECOND '
    {
        source = $3
        syn_count[source]++
        
        if (syn_count[source] > max_syn) {
            print "SYN_FLOOD от " source " - " syn_count[source] " пакетов"
            system("echo \"[$(date +%Y-%m-%d_%H:%M:%S)] SYN_FLOOD обнаружен от " source "\" >> '"$ALERT_LOG"'")
            syn_count[source] = 0  # Сброс счетчика
        }
    }' &
}

# ==========================================
# ФУНКЦИИ ОТЧЕТНОСТИ
# ==========================================

# Генерация отчета
generate_report() {
    local report_file="$LOG_DIR/report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo -e "${GREEN}[+] Генерация отчета...${NC}"
    
    cat > "$report_file" << EOF
Отчет системы мониторинга сети
Сгенерирован: $(date)
Целевая сеть: $TARGET_NETWORK
Интерфейс: $MONITOR_INTERFACE

СТАТИСТИКА АНОМАЛИЙ:
====================
$(wc -l < "$ALERT_LOG") всего оповещений

ПОСЛЕДНИЕ ОПОВЕЩЕНИЯ:
====================
$(tail -20 "$ALERT_LOG" 2>/dev/null || echo "Нет данных")

ЗАБЛОКИРОВАННЫЕ ХОСТЫ:
=====================
$(cat "$LOG_DIR/blocked_hosts.log" 2>/dev/null | tail -10 || echo "Нет заблокированных хостов")

СЕТЕВАЯ СТАТИСТИКА:
==================
$(ss -s | grep -A 10 "Total:")

EOF

    echo -e "${GREEN}[+] Отчет сохранен: $report_file${NC}"
}

# ==========================================
# ОСНОВНАЯ ЛОГИКА СКРИПТА
# ==========================================

# Функция очистки при завершении
cleanup() {
    echo -e "${YELLOW}[!] Завершение работы...${NC}"
    
    # Остановка захвата пакетов
    if [ -f /tmp/tcpdump_pid ]; then
        kill $(cat /tmp/tcpdump_pid) 2>/dev/null
        rm -f /tmp/tcpdump_pid
    fi
    
    # Завершение фоновых процессов
    pkill -P $$ 2>/dev/null
    
    generate_report
    echo -e "${GREEN}[+] Система мониторинга остановлена${NC}"
    exit 0
}

# Обработка сигналов завершения
trap cleanup SIGINT SIGTERM

# Главная функция
main() {
    echo -e "${GREEN}"
    cat << "EOF"
  _   _ _______ ______ _____  _   _ _____ _   _ _____ 
 | \ | |__   __|  ____|  __ \| \ | |_   _| \ | |  __ \
 |  \| |  | |  | |__  | |__) |  \| | | | |  \| | |  | |
 | . ` |  | |  |  __| |  _  /| . ` | | | | . ` | |  | |
 | |\  |  | |  | |____| | \ \| |\  |_| |_| |\  | |__| |
 |_| \_|  |_|  |______|_|  \_\_| \_|_____|_| \_|_____/
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}Система обнаружения аномальной активности${NC}"
    echo -e "${YELLOW}=========================================${NC}"
    
    # Инициализация
    init_environment
    
    # Запуск мониторинга
    start_packet_capture
    analyze_realtime_traffic
    
    echo -e "${GREEN}[+] Система мониторинга запущена${NC}"
    echo -e "${YELLOW}[!] Для остановки нажмите Ctrl+C${NC}"
    
    # Основной цикл мониторинга
    while true; do
        echo -e "\n${GREEN}[+] Цикл мониторинга $(date)${NC}"
        
        monitor_suspicious_connections
        detect_port_scanning  
        monitor_network_stats
        
        # Пауза между проверками
        sleep 30
    done
}

# Запуск скрипта
main
```

### Установка и запуск:
```bash
# 1. Сделать скрипт исполняемым
chmod +x network_anomaly_detector.sh

# 2. Запуск с правами root
sudo ./network_anomaly_detector.sh

# 3. Для фонового запуска
sudo nohup ./network_anomaly_detector.sh > /dev/null 2>&1 &
```

### Проверка работы:
```bash
# Просмотр логов в реальном времени - нужно найти вашу папку с логами в ОС
tail -f /var/log/network_monitor/alerts.log

# Проверка статистики
./analyze_logs.sh

# Проверка заблокированных хостов
iptables -L INPUT -n
```
