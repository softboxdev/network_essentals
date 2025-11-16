
---

## **Практическая работа: Установка и настройка Cisco оборудования на Ubuntu 24.04**


Постарайтесь установить самостоятельно, в случае вопросов поискать ответ в поисковике. 

### **Часть 1: Подготовка системы**

#### **1.1. Обновление системы**
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential libssl-dev libffi-dev python3-pip python3-venv git curl wget
```

#### **1.2. Установка зависимостей**
```bash
# Основные зависимости для эмуляторов
sudo apt install -y \
    dynamips \
    ubridge \
    wireshark \
    wireshark-qt \
    qt5-default \
    libpcap-dev \
    cmake \
    genisoimage \
    virt-viewer \
    libvirt-daemon-system

# Разрешаем захват пакетов без root прав
sudo dpkg-reconfigure wireshark-common
sudo usermod -a -G wireshark $USER
```

---

### **Часть 2: Установка GNS3**

#### **2.1. Установка GNS3 сервера и GUI**
```bash
# Добавляем репозиторий GNS3
sudo add-apt-repository ppa:gns3/ppa
sudo apt update

# Устанавливаем GNS3
sudo apt install -y gns3-gui gns3-server

# Добавляем пользователя в необходимые группы
sudo usermod -a -G libvirt $USER
sudo usermod -a -G kvm $USER
sudo usermod -a -G wireshark $USER
```

#### **2.2. Настройка GNS3**
```bash
# Запускаем GNS3 для первоначальной настройки
gns3 &

# Вручную создаем конфигурационные директории
mkdir -p ~/GNS3/{projects,images,IOS}
```

---

### **Часть 3: Установка Dynamips**

#### **3.1. Установка Dynamips вручную (если нужно последняя версия)**
```bash
# Клонируем репозиторий
git clone https://github.com/GNS3/dynamips.git
cd dynamips

# Собираем из исходников
mkdir build && cd build
cmake ..
make
sudo make install

# Проверяем установку
dynamips -h
```

---

### **Часть 4: Настройка архитектуры эмуляторов**

#### **4.1. Создание структуры каталогов**
```bash
# Создаем директории для образов IOS
mkdir -p ~/GNS3/images/IOS
mkdir -p ~/GNS3/configs
mkdir -p ~/GNS3/topologies

# Создаем директорию для лабораторных работ
mkdir -p ~/cisco_labs/{basic_networking,advanced_routing,switching}
```

#### **4.2. Настройка прав доступа**
```bash
# Даем права на использование эмуляторов
sudo chmod +x /usr/bin/dynamips
sudo setcap cap_net_admin,cap_net_raw=ep /usr/bin/dynamips

# Перезагружаем службы
sudo systemctl restart libvirtd
```

---

### **Часть 5: Установка дополнительных инструментов**

#### **5.1. Установка Telnet/SSH клиентов**
```bash
sudo apt install -y telnet openssh-client net-tools

# Установка расширенного терминала
sudo apt install -y terminator tilix
```

#### **5.2. Установка инструментов для работы с конфигурациями**
```bash
# Текстовые редакторы
sudo apt install -y vim nano vsftpd tftp

# Утилиты для сетевого анализа
sudo apt install -y tcpdump nmap iperf3
```

---

### **Часть 6: Настройка первой лабораторной сети**

#### **6.1. Схема стенда предприятия**
Создаем базовую схему сети:
```
[PC1] --- [Switch1] --- [Router1] --- [Router2] --- [Switch2] --- [PC2]
    VLAN 10                  |              |              VLAN 20
                      [Server]        [Internet]
```

#### **6.2. Создание конфигурационных файлов**
```bash
# Создаем директорию для конфигураций
mkdir -p ~/cisco_labs/lab1/configs

# Базовый конфиг для роутера
cat > ~/cisco_labs/lab1/configs/router_base_config.txt << 'EOF'
enable secret cisco
username admin privilege 15 secret cisco
line con 0
 password cisco
 login
line vty 0 4
 password cisco
 login
 transport input telnet ssh
service password-encryption
ip domain-name lab.local
crypto key generate rsa modulus 1024
EOF
```

---

### **Часть 7: Интерфейсы управления оборудованием Cisco**

#### **7.1. Настройка подключения к оборудованию**
Создаем скрипты для быстрого подключения:

**Скрипт для Telnet подключения:**
```bash
cat > ~/connect_telnet.sh << 'EOF'
#!/bin/bash
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Использование: $0 <IP> <PORT>"
    exit 1
fi
telnet $1 $2
EOF
chmod +x ~/connect_telnet.sh
```

**Скрипт для SSH подключения:**
```bash
cat > ~/connect_ssh.sh << 'EOF'
#!/bin/bash
if [ -z "$1" ]; then
    echo "Использование: $0 <IP>"
    exit 1
fi
ssh admin@$1
EOF
chmod +x ~/connect_ssh.sh
```

#### **7.2. Настройка серийной консоли**
```bash
# Установка утилит для работы с последовательным портом
sudo apt install -y picocom minicom

# Настройка minicom
sudo usermod -a -G dialout $USER
```

---

### **Часть 8: Знакомство с командным интерфейсом Cisco**

#### **8.1. Основные режимы CLI Cisco**
Создаем шпаргалку по режимам:

```bash
cat > ~/cisco_cli_cheatsheet.txt << 'EOF'
=== РЕЖИМЫ КОМАНДНОГО ИНТЕРФЕЙСА CISCO ===

1. Пользовательский режим (User EXEC)
   Router>
   Доступны базовые команды

2. Привилегированный режим (Privileged EXEC)
   Router> enable
   Router#
   Полный доступ к мониторингу

3. Режим глобальной конфигурации (Global Configuration)
   Router# configure terminal
   Router(config)#
   Изменение глобальных параметров

4. Режим интерфейса (Interface Configuration)
   Router(config)# interface fastethernet0/0
   Router(config-if)#
   Настройка конкретного интерфейса

5. Режим маршрутизации (Routing Configuration)
   Router(config)# router ospf 1
   Router(config-router)#
   Настройка протоколов маршрутизации

=== ОСНОВНЫЕ КОМАНДЫ ===

* Показать конфигурацию: show running-config
* Показать интерфейсы: show ip interface brief
* Показать таблицу маршрутизации: show ip route
* Показать MAC-адреса: show mac address-table
* Сохранить конфигурацию: copy running-config startup-config
* Перезагрузить: reload
* Проверить связность: ping <IP>
* Трассировка: traceroute <IP>
EOF
```

#### **8.2. Создание тренировочных скриптов**
```bash
# Скрипт для тренировки базовых команд
cat > ~/cisco_practice_commands.txt << 'EOF'
=== БАЗОВЫЕ КОМАНДЫ ДЛЯ ТРЕНИРОВКИ ===

1. Навигация:
   enable
   configure terminal
   exit
   end
   disable

2. Просмотр информации:
   show version
   show interfaces
   show ip route
   show running-config
   show startup-config

3. Настройка интерфейсов:
   interface fastethernet0/0
   ip address 192.168.1.1 255.255.255.0
   no shutdown
   description "Connected to LAN"

4. Настройка маршрутизации:
   ip route 0.0.0.0 0.0.0.0 192.168.1.254

5. Безопасность:
   enable secret <password>
   username <name> privilege 15 secret <password>
   service password-encryption
EOF
```

---

### **Часть 9: Запуск и тестирование**

#### **9.1. Запуск GNS3**
```bash
# Запускаем GNS3 сервер в фоне
gns3server &

# Запускаем GUI
gns3 &
```

#### **9.2. Проверка установки**
```bash
# Проверяем установленные компоненты
echo "=== ПРОВЕРКА УСТАНОВКИ ==="
which gns3 && echo "GNS3: OK" || echo "GNS3: FAIL"
which dynamips && echo "Dynamips: OK" || echo "Dynamips: FAIL"
dynamips -h | head -5

# Проверяем группы пользователя
groups $USER
```

---

### **Часть 10: Создание первой лабораторной работы**

#### **10.1. Создание простой топологии**
```bash
mkdir -p ~/cisco_labs/first_lab

cat > ~/cisco_labs/first_lab/README.md << 'EOF'
# Лабораторная работа 1: Базовая настройка Cisco оборудования

## Цели:
1. Освоить подключение к оборудованию
2. Изучить основные режимы CLI
3. Настроить базовые параметры устройства

## Оборудование:
- Маршрутизатор Cisco 3725 x 2
- Коммутатор Cisco 2960 x 1
- PC x 2

## Задачи:
1. Настроить hostname на устройствах
2. Настроить IP-адреса на интерфейсах
3. Проверить связность между устройствами
4. Сохранить конфигурацию

## Команды для выполнения:
- hostname R1
- interface fastethernet0/0
- ip address 192.168.1.1 255.255.255.0
- no shutdown
- ping 192.168.1.2
EOF
```

---

### **Часть 11: Решение возможных проблем**

#### **11.1. Частые проблемы и решения**
```bash
# Если GNS3 не запускается
sudo systemctl restart libvirtd
gns3 --reset-settings

# Проблемы с правами
sudo chmod 666 /dev/net/tun
sudo setcap cap_net_admin,cap_net_raw=ep /usr/bin/dynamips

# Проблемы с образами IOS
echo "Для работы с реальными образами IOS необходимо:"
echo "1. Легально приобрести образы у Cisco"
echo "2. Разместить их в ~/GNS3/images/IOS/"
echo "3. Добавить в GNS3 через интерфейс"
```

#### **11.2. Скрипт диагностики**
```bash
cat > ~/gns3_diagnostic.sh << 'EOF'
#!/bin/bash
echo "=== ДИАГНОСТИКА GNS3 ==="
echo "1. Проверка процессов:"
ps aux | grep gns3

echo "2. Проверка сетевых интерфейсов:"
ip link show | grep tap

echo "3. Проверка образов:"
ls -la ~/GNS3/images/IOS/

echo "4. Проверка версий:"
gns3 --version
dynamips -h 2>/dev/null | head -2

echo "5. Проверка групп пользователя:"
groups $USER
EOF
chmod +x ~/gns3_diagnostic.sh
```

---

### **Итоговая проверка**

После выполнения всех шагов проверьте систему:

```bash
~/gns3_diagnostic.sh
```

**Ожидаемый результат:**
- GNS3 запускается без ошибок
- Dynamips работает корректно
- Пользователь состоит в необходимых группах
- Созданы все рабочие директории
