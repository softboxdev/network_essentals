# Установка Snort3 из файла дистрибутива `snort3-snort3-3.9.7.0-0-g892f9f3.tar`

## 1. Подготовка системы и распаковка

### Установка основных зависимостей:
```bash
sudo apt update
sudo apt install -y build-essential cmake git flex bison libpcap-dev libpcre3-dev libdumbnet-dev \
zlib1g-dev liblzma-dev openssl libssl-dev libhwloc-dev libcmocka-dev libluajit-5.1-dev \
libunwind-dev libmnl-dev liblz4-dev libsqlite3-dev libmaxminddb-dev libsafec-dev \
libjansson-dev libarchive-dev libnghttp2-dev libfl-dev pkg-config
```

### Распаковка архива:
```bash
# Переходим в директорию с исходными кодами
cd /usr/src

# Распаковываем архив (предполагая, что файл в текущей директории)
tar -xvf snort3-snort3-3.9.7.0-0-g892f9f3.tar

# Переходим в распакованную директорию
cd snort3-snort3-3.9.7.0-0-g892f9f3
```

## 2. Установка дополнительных зависимостей для Snort3

### Установка Python зависимостей (для сборки):
```bash
sudo apt install -y python3-pip
sudo pip3 install gitpython
```

### Установка специфичных зависимостей Snort3:
```bash
sudo apt install -y libdaq-dev libdnet-dev libtcmalloc-minimal4 \
libcurl4-openssl-dev libxml2-dev libpcre++-dev libhyperscan-dev
```

## 3. Конфигурация и сборка

### Создание директории для сборки:
```bash
# Рекомендуется создавать отдельную директорию для build
mkdir build
cd build
```

### Конфигурация CMake:
```bash
# Базовая конфигурация
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_TESTS=OFF

# Или расширенная конфигурация с дополнительными модулями:
cmake .. \
  -DCMAKE_INSTALL_PREFIX=/usr/local \
  -DENABLE_TESTS=OFF \
  -DHAVE_LIBUNWIND=ON \
  -DHAVE_LZMA=ON \
  -DHAVE_LZ4=ON \
  -DHAVE_SAFEC=ON \
  -DHAVE_HYPERSCAN=ON
```

### Компиляция и установка:
```bash
# Компиляция (используйте -j для ускорения, например -j4 для 4 ядер)
make -j$(nproc)

# Установка
sudo make install
```

## 4. Настройка системы

### Обновление ссылок на библиотеки:
```bash
sudo ldconfig
```

### Создание структуры директорий:
```bash
sudo mkdir -p /usr/local/etc/snort
sudo mkdir -p /usr/local/etc/rules
sudo mkdir -p /var/log/snort
sudo mkdir -p /usr/local/lib/snort_dynamicrules
```

### Создание пользователя и групп:
```bash
sudo groupadd snort
sudo useradd -r -s /sbin/nologin -g snort snort
```

### Настройка прав доступа:
```bash
sudo chown -R snort:snort /var/log/snort
sudo chown -R snort:snort /usr/local/etc/snort
sudo chmod -R 5775 /var/log/snort
sudo chmod -R 5775 /usr/local/etc/snort
```

## 5. Базовая конфигурация Snort3

### Копирование конфигурационных файлов:
```bash
# Копируем стандартные конфигурационные файлы
cd /usr/src/snort3-snort3-3.9.7.0-0-g892f9f3
sudo cp -r etc/* /usr/local/etc/snort/
```

### Создание основных конфигурационных файлов:
```bash
sudo nano /usr/local/etc/snort/snort_defaults.lua
```

```lua
-- Snort3 Таргет машина, узнайте с помощью команды ip addr show eth0
HOME_NET = '192.168.1.101/24'
EXTERNAL_NET = 'any'

ports = 
{
    http_ports = { 80, 8080, 8180, 9080 },
    shellcode_ports = { 80, 81, 443, 1433, 1521, 2483, 2484 },
    oracle_ports = { 1521 },
    ssh_ports = { 22 },
    dns_ports = { 53 },
    smtp_ports = { 25, 587, 465 },
    file_data_ports = { 80, 8080, 8180, 9080, 443 },
    ftp_ports = { 21, 2100, 3535 },
    gtp_ports = { 2123, 2152, 3386 }
}

whitelist = 
{
    path = '/usr/local/etc/snort/whitelist'
}

blacklist = 
{
    path = '/usr/local/etc/snort/blacklist'
}

ips = 
{
    mode = tap,
    variables = default_variables,
    rules = [[
        include '/usr/local/etc/snort/snort.lua'
    ]]
}
```

```bash
sudo nano /usr/local/etc/snort/snort.lua
```

```lua
-- Main Snort3 Configuration
include 'snort_defaults.lua'

-- Настройки детекции
detection = 
{
    search_method = 'ac_bnfa',
    enable_safe_search = true
}

-- Настройки вывода
alert_syslog = 
{
    level = 'info',
    facility = 'local4'
}

alert_fast = 
{
    file = true,
    packet = false,
    limit = 128
}

unified2 = 
{
    legacy_events = true
}

-- Локальные правила
include 'local.rules'
```

### Создание файла локальных правил:
```bash
sudo nano /usr/local/etc/snort/local.rules
```

```bash
-- Local Rules for Testing
alert icmp (
    msg:"ICMP Ping Detected";
    icode:0; itype:8;
    sid:1000001;
    rev:1;
)

alert tcp (
    msg:"SSH Connection Attempt";
    flow:to_server,established;
    dport:22;
    sid:1000002;
    rev:1;
)

alert tcp (
    msg:"HTTP Request";
    flow:to_server,established;
    dport:80;
    sid:1000003;
    rev:1;
)

alert tcp (
    msg:"Suspicious Port Activity";
    flow:to_server,established;
    dport:4444;
    sid:1000004;
    rev:1;
)
```

## 6. Создание служебных файлов

### Создание systemd службы:
```bash
sudo nano /etc/systemd/system/snort3.service
```

```ini
[Unit]
Description=Snort3 Network Intrusion Detection System
After=network.target

[Service]
Type=simple
User=snort
Group=snort
ExecStart=/usr/local/bin/snort -c /usr/local/etc/snort/snort.lua -s 65535 -k none -l /var/log/snort -i eth0 -m 0x1b
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### Создание скрипта управления:
```bash
sudo nano /usr/local/bin/snort3-control
```

```bash
#!/bin/bash
# Snort3 Control Script

CONFIG_FILE="/usr/local/etc/snort/snort.lua"
LOG_DIR="/var/log/snort"
INTERFACE="eth0"  # Измените на ваш интерфейс

start_snort() {
    echo "Starting Snort3..."
    sudo -u snort /usr/local/bin/snort -c $CONFIG_FILE -s 65535 -k none -l $LOG_DIR -i $INTERFACE -m 0x1b -D
    if [ $? -eq 0 ]; then
        echo "Snort3 started successfully"
    else
        echo "Failed to start Snort3"
    fi
}

stop_snort() {
    echo "Stopping Snort3..."
    pkill -f "snort -c $CONFIG_FILE"
    sleep 2
    if pgrep -f "snort -c $CONFIG_FILE" > /dev/null; then
        echo "Snort3 stopped successfully"
    else
        echo "Snort3 is not running"
    fi
}

status_snort() {
    if pgrep -f "snort -c $CONFIG_FILE" > /dev/null; then
        echo "Snort3 is running"
    else
        echo "Snort3 is not running"
    fi
}

case "$1" in
    start)
        start_snort
        ;;
    stop)
        stop_snort
        ;;
    restart)
        stop_snort
        sleep 3
        start_snort
        ;;
    status)
        status_snort
        ;;
    reload)
        echo "Reloading configuration..."
        pkill -HUP -f "snort -c $CONFIG_FILE"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|reload}"
        exit 1
        ;;
esac
```

```bash
sudo chmod +x /usr/local/bin/snort3-control
```

## 7. Тестирование установки

### Проверка версии:
```bash
/usr/local/bin/snort -V
```

### Проверка конфигурации:
```bash
sudo /usr/local/bin/snort -c /usr/local/etc/snort/snort.lua --tweaks sanitize -T
```

### Тестовый запуск:
```bash
sudo /usr/local/bin/snort -c /usr/local/etc/snort/snort.lua -i eth0 -A alert_fast -s 65535 -k none
```

## 8. Финальная настройка и запуск

### Определение сетевого интерфейса:
```bash
# Узнайте ваш активный интерфейс
ip route | grep default | awk '{print $5}'
```

### Обновление конфигурации с правильным интерфейсом:
```bash
# Замените eth0 на ваш интерфейс в службе и скрипте
INTERFACE=$(ip route | grep default | awk '{print $5}')
sudo sed -i "s/eth0/$INTERFACE/g" /etc/systemd/system/snort3.service
sudo sed -i "s/eth0/$INTERFACE/g" /usr/local/bin/snort3-control
```

### Запуск как службы:
```bash
sudo systemctl daemon-reload
sudo systemctl enable snort3
sudo systemctl start snort3
sudo systemctl status snort3
```

## 9. Проверка работы

### Просмотр логов:
```bash
sudo tail -f /var/log/snort/alert_fast.txt
```

### Тестирование обнаружения:
```bash
# Отправьте тестовый ICMP пинг
ping -c 3 8.8.8.8

# Проверьте логи на наличие алерта
sudo tail -f /var/log/snort/alert_fast.txt
```

## 10. Дополнительные настройки

### Настройка ротации логов:
```bash
sudo nano /etc/logrotate.d/snort3
```

```bash
/var/log/snort/*.txt {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 snort snort
    postrotate
        /usr/local/bin/snort3-control reload > /dev/null 2>&1 || true
    endscript
}
```

### Оптимизация производительности:
```bash
sudo nano /etc/sysctl.conf
```

Добавьте:
```bash
# Snort3 performance tuning
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 300000
net.core.optmem_max = 67108864
net.core.somaxconn = 1024
```

Примените изменения:
```bash
sudo sysctl -p
```

## 11. Решение возможных проблем

### Если сборка не удалась:
```bash
# Очистите директорию сборки и начните заново
cd /usr/src/snort3-snort3-3.9.7.0-0-g892f9f3
rm -rf build
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DENABLE_TESTS=OFF
make -j$(nproc)
sudo make install
```

### Если не хватает зависимостей:
```bash
# Установите недостающие пакеты
sudo apt install -y libdaq-dev libdnet-dev libhyperscan-dev
```

### Проверка путей установки:
```bash
# Убедитесь что бинарники установлены правильно
ls -la /usr/local/bin/snort
/usr/local/bin/snort --version
```
