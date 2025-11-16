
---

## **Архитектура сетевых эмуляторов и оборудование Cisco**

### **1. Сеть предприятия и схема стенда**

#### **Типовая архитектура сети предприятия:**
```
[Доступ] → [Распределение] → [Ядро] → [Интернет]
    |            |             |          |
 [Пользователи] [Серверы]   [Маршрутизаторы] [Firewall]
```

**Компоненты сетевого стенда:**
- **Маршрутизаторы (Routers)** - соединяют разные сети, выполняют маршрутизацию
- **Коммутаторы (Switches)** - объединяют устройства в одной сети, работают на канальном уровне
- **Терминалы (PC)** - конечные устройства пользователей
- **Серверы** - предоставляют услуги (DHCP, DNS, HTTP)

**Пример лабораторного стенда:**
```
[PC1]---[SW1]---[R1]---[R2]---[SW2]---[PC2]
         |                 |
      [Server]         [Internet]
```

---

### **2. Архитектура эмуляторов Dynamips/GNS3**

#### **Dynamips - эмулятор оборудования Cisco:**
```
+--------------------------------+
| Dynamips (Эмулятор)           |
|  +--------------------------+ |
|  | Виртуальная Cisco IOS    | | ← Образ прошивки
|  | - Обработка команд       | |
|  | - Таблицы маршрутизации  | |
|  | - Протоколы (OSPF, EIGRP)| |
|  +--------------------------+ |
|  | Гипервизор              | | ← Эмуляция CPU/Memory
|  +--------------------------+ |
+--------------------------------+
```

**Как работает Dynamips:**
- **Эмулирует hardware** маршрутизаторов Cisco (72xx, 37xx серии)
- **Загружает реальные IOS образы** - те же, что и на физическом оборудовании
- **Создает виртуальные интерфейсы** для соединения устройств
- **Требует легальные IOS файлы** от Cisco

#### **GNS3 - графическая оболочка:**
```
+---------------------------------------+
| GNS3 GUI                             | ← Графический интерфейс
+---------------------------------------+
| GNS3 Server                          | ← Управление эмуляторами
+---------------------------------------+
| Dynamips    | VirtualBox | Docker    | ← Разные типы эмуляторов
+-------------------+-------------------+
| Linux Network Stack                 | ← Виртуальные сетевые интерфейсы
+---------------------------------------+
```

**Компоненты GNS3:**
1. **GNS3 GUI** - графический интерфейс для построения топологий
2. **GNS3 Server** - управляет виртуальными устройствами
3. **Dynamips** - эмулятор Cisco оборудования
4. **VirtualBox** - для эмуляции конечных устройств
5. **Docker** - для запуска сетевых сервисов

**Процесс работы:**
```python
# Псевдокод работы GNS3
class GNS3Workflow:
    def create_topology(self):
        # 1. Пользователь создает схему в GUI
        topology = GUI.design_topology()
        
        # 2. GNS3 Server запускает эмуляторы
        for device in topology.devices:
            if device.type == "Cisco Router":
                dynamips.start(device.ios_image)
            elif device.type == "PC":
                virtualbox.start(device.vm_image)
        
        # 3. Создаются виртуальные соединения
        network.create_virtual_links()
        
        # 4. Пользователь подключается к консоли
        telnet.connect_to_device_console()
```

---

### **3. Интерфейсы управления оборудованием Cisco**

#### **Способы подключения к оборудованию:**

**1. Консольный порт (Console):**
```
[PC] -- Console Cable -- [Router Console Port]
        (RJ45 to USB)
```
- **Скорость:** 9600 baud
- **Протокол:** Serial
- **Использование:** Первоначальная настройка, восстановление

**2. Telnet/SSH:**
```
[PC] -- Network -- [Router Management Interface]
        (Ethernet)
```
- **Порты:** Telnet (23), SSH (22)
- **Требует:** Настроенный IP-адрес на устройстве

**3. Web-интерфейс:**
- HTTP/HTTPS доступ к веб-конфигуратору
- Доступен не на всех устройствах

#### **Процесс управления:**
```bash
# Подключение через консоль
picocom /dev/ttyUSB0 -b 9600

# Подключение через Telnet
telnet 192.168.1.1

# Подключение через SSH
ssh admin@192.168.1.1
```

---

### **4. Командный интерфейс Cisco (CLI)**

#### **Иерархия режимов CLI:**

```
User EXEC Mode (Уровень 1)
     ↓ enable
Privileged EXEC Mode (Уровень 15)
     ↓ configure terminal
Global Configuration Mode
     ↓ interface fastethernet0/0
Interface Configuration Mode
     ↓ router ospf 1
Router Configuration Mode
```

#### **Детальное описание режимов:**

**1. Пользовательский режим (User EXEC):**
```
Router>
```
- **Доступ:** Только просмотр
- **Команды:** `show`, `ping`, `traceroute`
- **Ограничения:** Нельзя изменять конфигурацию

**2. Привилегированный режим (Privileged EXEC):**
```
Router> enable
Router#
```
- **Доступ:** Полный мониторинг, отладка
- **Команды:** `show running-config`, `debug`, `reload`
- **Переход:** Команда `enable`

**3. Режим глобальной конфигурации (Global Configuration):**
```
Router# configure terminal
Router(config)#
```
- **Доступ:** Изменение системных параметров
- **Команды:** `hostname`, `ip route`, `username`
- **Переход:** Команда `configure terminal`

**4. Режимы конкретной конфигурации:**
```bash
# Режим интерфейса
Router(config)# interface fastethernet0/0
Router(config-if)# 
# Команды: ip address, no shutdown

# Режим маршрутизации
Router(config)# router ospf 1
Router(config-router)# 
# Команды: network, area

# Режим линии
Router(config)# line console 0
Router(config-line)# 
# Команды: password, login
```

#### **Жизненный цикл конфигурации:**
```bash
# 1. Вход в режим конфигурации
Router# configure terminal

# 2. Настройка параметров
Router(config)# hostname R1
R1(config)# interface fastethernet0/0
R1(config-if)# ip address 192.168.1.1 255.255.255.0
R1(config-if)# no shutdown

# 3. Выход и сохранение
R1(config-if)# end
R1# copy running-config startup-config
```

#### **Система помощи и автодополнения:**
```bash
# Контекстная помощь
Router# ?
Router# show ?
Router# show ip ?

# Автодополнение команд
Router# conf[TAB] → Router# configure
Router# int[TAB] → Router# interface

# История команд
Router# show history
Router# [CTRL+P] - предыдущая команда
```

#### **Режимы отображения информации:**
```bash
# Краткая информация об интерфейсах
Router# show ip interface brief

# Детальная информация
Router# show interfaces fastethernet0/0

# Таблица маршрутизации
Router# show ip route

# Таблица MAC-адресов (на коммутаторе)
Switch# show mac address-table

# Текущая конфигурация
Router# show running-config
```

---

### **Практический пример работы**

**Сценарий:** Настройка базового подключения между двумя маршрутизаторами

```bash
# На R1
R1> enable
R1# configure terminal
R1(config)# interface fastethernet0/0
R1(config-if)# ip address 192.168.1.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# end
R1# copy running-config startup-config

# На R2  
R2> enable
R2# configure terminal
R2(config)# interface fastethernet0/0
R2(config-if)# ip address 192.168.1.2 255.255.255.0
R2(config-if)# no shutdown
R2(config-if)# end
R2# copy running-config startup-config

# Проверка связи
R1# ping 192.168.1.2
```

---

### **Ключевые принципы работы:**

1. **Иерархичность** - строгая структура режимов и привилегий
2. **Контекстность** - команды доступны только в соответствующих режимах  
3. **Инкрементальность** - изменения применяются сразу, но не сохраняются автоматически
4. **Валидация** - система проверяет синтаксис команд перед выполнением
5. **Логирование** - ведется журнал всех операций и изменений

Эта архитектура обеспечивает безопасное и контролируемое управление сетевым оборудованием, что критически важно для стабильной работы корпоративных сетей.

---

## **Теоретическое обоснование для разбора тестовых заданий**

### **1. Архитектура эмуляторов GNS3/Dynamips**

#### **Принцип работы Dynamips:**
```
+------------------------------------------------+
| Уровень 1: Физическое оборудование            |
| - CPU, RAM, Сетевые интерфейсы                |
+------------------------------------------------+
| Уровень 2: Операционная система (Ubuntu)      |
| - Драйверы, сетевой стек, процессы            |
+------------------------------------------------+
| Уровень 3: Эмулятор Dynamips                  |
| +-------------------------------------------+ |
| | Виртуальный процессор MIPS               | | ← Эмуляция CPU
| | Виртуальная память                       | | ← Эмуляция RAM
| | Виртуальные регистры                     | | |
| +-------------------------------------------+ |
| | Гипервизор                              | | ← Управление эмуляцией
| +-------------------------------------------+ |
+------------------------------------------------+
| Уровень 4: Cisco IOS                          |
| - Командная строка, конфигурации, таблицы     |
+------------------------------------------------+
```

**Ключевые аспекты:**

**1.1 Эмуляция vs Виртуализация:**
- **Эмуляция (Dynamips):** Полное воссоздание аппаратуры (процессор, память, регистры). IOS "думает", что работает на реальном оборудовании.
- **Виртуализация (VirtualBox):** Разделение реальных ресурсов между гостевыми ОС. Гостевая ОС знает, что виртуализирована.

**1.2 Процесс запуска в GNS3:**
```python
# Псевдокод процесса инициализации
class GNS3Workflow:
    def start_topology(self):
        # 1. Парсинг файла топологии (.gns3)
        topology = parse_gns3_file()
        
        # 2. Запуск GNS3 сервера
        server = GNS3Server()
        server.initialize()
        
        # 3. Для каждого Cisco устройства
        for device in topology.cisco_devices:
            # Запуск Dynamips процесса
            dynamips_process = Dynamips(
                ios_image=device.ios_image,
                ram_size=device.ram,
                platform=device.platform
            )
            
            # Создание виртуальных интерфейсов
            for interface in device.interfaces:
                nio = create_network_interface(
                    type=interface.type,
                    parameters=interface.params
                )
                dynamips_process.attach_interface(nio)
            
            # Запуск эмуляции
            dynamips_process.start()
            
            # Подключение консоли
            telnet_port = allocate_telnet_port()
            dynamips_process.connect_console(telnet_port)
```

---

### **2. Иерархия командного интерфейса Cisco CLI**

#### **Детальная структура режимов:**

**2.1 User EXEC Mode (Уровень 1):**
```
Router>
```
- **Цель:** Базовый мониторинг и диагностика
- **Ограничения:** Только read-only команды
- **Примеры команд:**
  ```bash
  show version      # Информация о системе
  show interfaces   # Статус интерфейсов
  ping 192.168.1.1  # Проверка связности
  traceroute 8.8.8.8 # Трассировка маршрута
  ```

**2.2 Privileged EXEC Mode (Уровень 15):**
```
Router> enable
Router#
```
- **Цель:** Расширенная диагностика и управление
- **Доступ:** Все команды мониторинга + управление системой
- **Критические команды:**
  ```bash
  show running-config    # Текущая конфигурация
  debug ip packet        # Отладка сетевых пакетов
  reload                 # Перезагрузка системы
  copy running-config startup-config  # Сохранение конфигурации
  ```

**2.3 Global Configuration Mode:**
```
Router# configure terminal
Router(config)#
```
- **Цель:** Изменение системных параметров
- **Область действия:** Вся система
- **Ключевые команды:**
  ```bash
  hostname R1           # Изменение имени устройства
  ip route 0.0.0.0 0.0.0.0 192.168.1.1  # Статический маршрут
  username admin privilege 15 secret password  # Создание пользователя
  ```

**2.4 Специализированные режимы конфигурации:**
```bash
# Режим интерфейса
Router(config)# interface fastethernet0/0
Router(config-if)# 
# Команды: ip address, duplex, speed, no shutdown

# Режим маршрутизации  
Router(config)# router ospf 1
Router(config-router)# 
# Команды: network, area, passive-interface

# Режим линии
Router(config)# line console 0
Router(config-line)# 
# Команды: password, login, exec-timeout

# Режим VLAN
Switch(config)# vlan 10
Switch(config-vlan)# 
# Команды: name, state
```

---

### **3. Сетевая архитектура предприятия**

#### **Трехуровневая модель:**
```
+----------------+     +-------------------+     +---------------+
|   Access       |     |  Distribution     |     |    Core       |
|   Layer        |-----|   Layer           |-----|   Layer       |
|                |     |                   |     |               |
| - Пользователи |     | - Агрегация трафика|     | - Высокоскоростная|
| - VLANs        |     | - Меж-VLAN routing |     |   маршрутизация |
| - Port security|     | - Policy enforcement|    | - Отказоустойчивость|
+----------------+     +-------------------+     +---------------+
```

**3.1 Access Layer (Уровень доступа):**
- **Оборудование:** Cisco Catalyst 2960, 3560
- **Функции:**
  - Подключение конечных пользователей
  - Реализация VLAN (порт-базированные)
  - Port Security
  - STP для предотвращения петель
- **Конфигурация:**
  ```bash
  interface GigabitEthernet0/1
   switchport mode access
   switchport access vlan 10
   switchport port-security
   switchport port-security maximum 3
  ```

**3.2 Distribution Layer (Уровень распределения):**
- **Оборудование:** Cisco Catalyst 3650, 3850
- **Функции:**
  - Агрегация трафика с Access слоя
  - Меж-VLAN маршрутизация
  - Реализация политик безопасности
  - Поддержка протоколов маршрутизации
- **Конфигурация:**
  ```bash
  interface Vlan10
   ip address 192.168.10.1 255.255.255.0
  interface Vlan20
   ip address 192.168.20.1 255.255.255.0
  ip routing
  router ospf 1
   network 192.168.0.0 0.0.255.255 area 0
  ```

**3.3 Core Layer (Магистральный уровень):**
- **Оборудование:** Cisco Nexus, ASR серии
- **Функции:**
  - Высокоскоростная пересылка пакетов
  - Отказоустойчивость и избыточность
  - Поддержка магистральных протоколов
- **Конфигурация:**
  ```bash
  interface TenGigabitEthernet1/1
   ip address 10.0.0.1 255.255.255.252
   no shutdown
  router bgp 65000
   neighbor 10.0.0.2 remote-as 65001
   network 192.168.0.0
  ```

---

### **4. Принципы работы сетевых протоколов в лабораторной среде**

#### **4.1 VLAN и Trunking:**
**Концепция:**
- **VLAN:** Логическое разделение широковещательных доменов
- **Trunk:** Транспортировка нескольких VLAN через один физический интерфейс

**Конфигурация:**
```bash
# На коммутаторе Access
interface GigabitEthernet0/1
 switchport mode access
 switchport access vlan 10

# На коммутаторе Distribution  
interface GigabitEthernet0/24
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30
```

#### **4.2 OSPF Маршрутизация:**
**Принцип работы:**
1. Установление соседства (Hello пакеты)
2. Обмен LSAs (Link State Advertisements)
3. Построение полной топологии сети
4. Расчет кратчайших путей (алгоритм Дейкстры)

**Конфигурация:**
```bash
router ospf 1
 network 192.168.1.0 0.0.0.255 area 0
 network 192.168.2.0 0.0.0.255 area 1
 passive-interface default
 no passive-interface GigabitEthernet0/0
```

#### **4.3 STP (Spanning Tree Protocol):**
**Цель:** Предотвращение петель в сети Ethernet
**Процесс:**
1. Выбор корневого моста (Root Bridge)
2. Определение корневых портов (Root Ports)
3. Определение назначенных портов (Designated Ports)
4. Блокировка избыточных путей

---

### **5. Управление и мониторинг лабораторного стенда**

#### **5.1 Система управления конфигурациями:**
```python
class ConfigurationManager:
    def __init__(self):
        self.backup_dir = "backups/"
        self.template_dir = "templates/"
    
    def backup_config(self, device):
        """Резервное копирование конфигурации"""
        config = device.get_running_config()
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{device.hostname}_{timestamp}.cfg"
        
        with open(f"{self.backup_dir}/{filename}", 'w') as f:
            f.write(config)
        
        return filename
    
    def validate_config(self, config, template):
        """Валидация конфигурации"""
        errors = []
        for required_line in template.required_lines:
            if required_line not in config:
                errors.append(f"Missing: {required_line}")
        return errors
```

#### **5.2 Мониторинг производительности:**
**Ключевые метрики:**
- **CPU Utilization:** `show processes cpu`
- **Memory Usage:** `show memory statistics`
- **Interface Statistics:** `show interfaces`
- **Network Latency:** `ping` и `traceroute`

**Автоматизация мониторинга:**
```bash
#!/bin/bash
# Скрипт мониторинга
DEVICES="router1 switch1 switch2"

for device in $DEVICES; do
    # Проверка доступности
    ping -c 3 $device > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ALERT: $device is down"
        continue
    fi
    
    # Сбор метрик
    cpu_usage=$(snmpget -v2c -c public $device 1.3.6.1.4.1.9.2.1.58.0)
    memory_usage=$(snmpget -v2c -c public $device 1.3.6.1.4.1.9.9.48.1.1.1.6.1)
    
    echo "$device: CPU=$cpu_usage%, Memory=$memory_usage%"
done
```

---

### **6. Оптимизация производительности эмуляторов**

#### **6.1 Методы оптимизации Dynamips:**
```bash
# Запуск Dynamips с оптимизациями
dynamips \
  -H 7200 \                    # Платформа
  -r 128 \                     # RAM в MB
  -s 0:0:linux_eth:eth0 \      # Сетевой интерфейс
  -s 1:0:udp:10000:127.0.0.1:20000 \  # UDP туннель
  -j \                         # Использование jumboframes
  -c 0x2142 \                  # Конфигурационный регистр
  c7200-adventerprisek9-mz.124-25d.bin
```

#### **6.2 Оптимизация GNS3:**
- **Использование облачных узлов** вместо эмуляции каждого устройства
- **Группировка устройств** на одном сервере
- **Оптимизация сетевых путей** между эмуляторами
- **Кэширование образов IOS** для быстрой загрузки

---

### **7. Решение типичных проблем**

#### **7.1 Проблемы с производительностью:**
**Симптомы:** Высокая загрузка CPU, медленный отклик
**Решение:**
```bash
# 1. Проверка процессов
top -p $(pgrep dynamips)

# 2. Оптимизация параметров
echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 3. Ограничение ресурсов
cpulimit -l 50 -p $(pgrep dynamips)
```

#### **7.2 Проблемы с сетевой связностью:**
**Диагностика:**
```bash
# На маршрутизаторе Cisco
show ip interface brief        # Статус интерфейсов
show ip route                  # Таблица маршрутизации
show vlan brief                # VLAN информация
debug ip packet                # Отладка пакетов

# На хостовой системе
tcpdump -i any host 192.168.1.1  # Перехват трафика
ping 192.168.1.1                 # Проверка связности
traceroute 192.168.1.1           # Трассировка пути
```

Это теоретическое обоснование предоставляет полную основу для понимания принципов работы сетевых эмуляторов, архитектуры Cisco оборудования и методологии построения сложных сетевых инфраструктур в лабораторных условиях.