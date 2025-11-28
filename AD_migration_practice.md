# Лабораторная работа: Миграция с Microsoft AD на домены, поддерживаемые Astra Linux

## Введение в миграцию

### Цели и задачи миграции

**Основные цели:**
- Снижение лицензионных затрат
- Повышение безопасности и контроля
- Упрощение управления гетерогенной средой
- Соответствие требованиям регуляторов

**Задачи лабораторной работы:**
1. Анализ существующей инфраструктуры AD
2. Подготовка целевой среды (FreeIPA/Samba DC/ALD Pro)
3. Миграция пользователей, групп и политик
4. Тестирование и откат при необходимости

## Топология лабораторного стенда

```
                    +-----------------+
                    |     Роутер      |
                    |      gate       |
                    |  192.168.0.1    |
                    +-----------------+
                            |
        +---------------------------------------+
        |                   |                   |
    +---+---+           +---+---+           +---+---+
    |  Net1 |           |  Net2 |           |  Net3 |           |  Net4 |
    +-------+           +-------+           +-------+           +-------+
    
Сети:
- Net1: 192.168.1.0/24 - Windows AD (исходная среда)
  - DC: win-dc01.windows-ad.local (192.168.1.10)
  - Клиент: win-client01 (192.168.1.20)

- Net2: 192.168.2.0/24 - FreeIPA (целевая среда 1)
  - Сервер: ipa01.freeipa.local (192.168.2.10)
  - Клиент: rhel-client01 (192.168.2.20)

- Net3: 192.168.3.0/24 - Samba DC (целевая среда 2)
  - Сервер: samba-dc01.company.local (192.168.3.10)
  - Клиент: astra-client01 (192.168.3.20)

- Net4: 192.168.4.0/24 - ALD Pro (целевая среда 3)
  - Сервер: ald-server.ald.local (192.168.4.10)
  - Клиент: astra-client02 (192.168.4.20)
```

## Этап 1: Анализ и подготовка исходной среды

### Инвентаризация Active Directory

```powershell
# PowerShell скрипт для анализа AD
Get-ADDomain | Select-Object Forest, Domain, DomainMode
Get-ADUser -Filter * | Measure-Object
Get-ADGroup -Filter * | Measure-Object
Get-ADComputer -Filter * | Measure-Object

# Экспорт данных AD в CSV
Get-ADUser -Filter * -Properties * | 
Select-Object Name, SamAccountName, UserPrincipalName, Enabled, 
              Department, Title, EmailAddress |
Export-Csv -Path "C:\AD_Migration\AD_Users.csv" -NoTypeInformation

Get-ADGroup -Filter * -Properties * |
Select-Object Name, GroupCategory, GroupScope, Members |
Export-Csv -Path "C:\AD_Migration\AD_Groups.csv" -NoTypeInformation
```

### Анализ зависимостей

```powershell
# Проверка доверительных отношений
Get-ADTrust -Filter *

# Анализ групповых политик
Get-GPO -All | Select-Object DisplayName, ID, GPOStatus

# Проверка DNS зон
Get-DnsServerZone | Where-Object {$_.ZoneType -eq "Primary"}
```

## Этап 2: Подготовка целевых сред

### Вариант A: Миграция на FreeIPA (RED OS 8)

#### Установка и настройка FreeIPA

```bash
# На сервере ipa01.freeipa.local (192.168.2.10)

# Установка пакетов
sudo dnf install -y freeipa-server freeipa-server-dns freeipa-admintools

# Настройка firewall
sudo firewall-cmd --permanent --add-service={http,https,ldap,ldaps,kerberos,dns,ntp}
sudo firewall-cmd --reload

# Установка сервера
sudo ipa-server-install --domain=freeipa.local --realm=FREEIPA.LOCAL \
  --ds-password=Secret123 --admin-password=Secret123 \
  --hostname=ipa01.freeipa.local --ip-address=192.168.2.10 \
  --setup-dns --forwarder=8.8.8.8 --auto-reverse --no-host-dns \
  --unattended
```

#### Настройка доверительных отношений

```bash
# Создание доверия с Windows AD
sudo ipa trust-add --type=ad windows-ad.local --admin Administrator --password
```

### Вариант B: Миграция на Samba DC (RED OS 8)

#### Установка Samba DC

```bash
# На сервере samba-dc01.company.local (192.168.3.10)

# Установка пакетов
sudo dnf install -y samba samba-dc samba-client samba-winbind

# Создание домена
sudo samba-tool domain provision --realm=COMPANY.LOCAL --domain=COMPANY \
  --adminpass=Secret123 --server-role=dc --use-rfc2307 \
  --dns-backend=SAMBA_INTERNAL --host-name=SAMBA-DC01
```

### Вариант C: Миграция на ALD Pro (Astra Linux)

#### Установка ALD Pro

```bash
# На сервере ald-server.ald.local (192.168.4.10)

# Установка ALD Pro через astra-secure-setup
sudo astra-secure-setup

# Или ручная установка
sudo apt update && sudo apt install ald-server ald-admin-center
```

## Этап 3: Миграция данных

### Миграция пользователей и групп

#### Использование инструментов миграции

**Сценарий миграции в FreeIPA:**

```bash
#!/bin/bash
# migration-freeipa.sh

# Импорт пользователей из CSV
while IFS=, read -r name samaccountname upn enabled department title email
do
    if [ "$name" != "Name" ]; then
        echo "Migrating user: $name"
        ipa user-add "$samaccountname" --first="$name" --last="" \
            --email="$email" --title="$title" --department="$department"
    fi
done < AD_Users.csv

# Импорт групп
while IFS=, read -r name category scope members
do
    if [ "$name" != "Name" ]; then
        echo "Migrating group: $name"
        ipa group-add "$name"
    fi
done < AD_Groups.csv
```

**Сценарий миграции в Samba DC:**

```python
#!/usr/bin/env python3
# migration-samba.py

import csv
import subprocess

def migrate_users_to_samba():
    with open('AD_Users.csv', 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['Enabled'] == 'True':
                cmd = [
                    'samba-tool', 'user', 'create',
                    row['SamAccountName'],
                    'TempPassword123!',
                    '--given-name=' + row['Name'],
                    '--surname=',
                    '--mail=' + row['EmailAddress']
                ]
                subprocess.run(cmd)

if __name__ == "__main__":
    migrate_users_to_samba()
```

### Миграция групповых политик

#### Конвертация GPO в эквиваленты Linux

```bash
# Анализ GPO из Windows AD
# Экспорт политик безопасности
secedit /export /cfg C:\AD_Migration\security_policy.inf

# Конвертация в Linux-эквиваленты
# Для политик паролей в FreeIPA
ipa pwpolicy-mod --maxlife=90 --minlife=1 --history=10 --minlength=8 --minclasses=3

# Для Samba DC - настройка в smb.conf
sudo nano /etc/samba/smb.conf
[global]
    # Политика паролей
    password history length = 10
    minimum password length = 8
    password complexity = yes
```

## Этап 4: Миграция клиентов

### Миграция Windows клиентов

```powershell
# Скрипт миграции Windows клиента с AD на FreeIPA
# На клиенте win-client01 (192.168.1.20)

# Выход из домена AD
Remove-Computer -UnjoinDomaincredential "windows-ad\Administrator" -Restart

# После перезагрузки - присоединение к FreeIPA
# Установка компонентов
Install-WindowsFeature -Name RSAT-AD-PowerShell

# Присоединение к FreeIPA через доверие
Add-Computer -DomainName "freeipa.local" -Credential "FREEIPA\administrator"
```

### Миграция Linux клиентов

```bash
# Миграция клиента с Windows AD на FreeIPA
# На astra-client01 (192.168.3.20)

# Удаление старой конфигурации
sudo systemctl stop winbind
sudo authselect select minimal with-winbind

# Настройка для FreeIPA
sudo authselect select sssd with-mkhomedir --force
sudo ipa-client-install --domain=freeipa.local --server=ipa01.freeipa.local \
  --realm=FREEIPA.LOCAL --principal=admin --password=Secret123 --unattended
```

## Этап 5: Проблемы и решения при миграции

### Распространенные проблемы

#### Проблема 1: Несовместимость атрибутов

**Симптом:** Пользователи не могут аутентифицироваться после миграции
**Решение:**
```bash
# Добавление недостающих атрибутов в FreeIPA
ipa user-mod username --addattr=objectClass=posixAccount
ipa user-mod username --uidNumber=10000 --gidNumber=10000 --login-shell=/bin/bash
```

#### Проблема 2: Различия в политиках паролей

**Симптом:** Ошибки "Password does not meet complexity requirements"
**Решение:**
```bash
# Настройка политик паролей в FreeIPA
ipa pwpolicy-mod --maxfail=5 --failinterval=60 --lockouttime=600
```

#### Проблема 3: Проблемы с DNS

**Симптом:** Клиенты не могут найти контроллер домена
**Решение:**
```bash
# Настройка conditional forwarding
sudo samba-tool dns zonecreate 127.0.0.1 windows-ad.local -U administrator
sudo samba-tool dns add 127.0.0.1 windows-ad.local @ NS samba-dc01.company.local
```

### Скрипт автоматического решения проблем

```bash
#!/bin/bash
# migration-troubleshoot.sh

echo "=== Проверка миграции ==="

# Проверка аутентификации
echo "1. Проверка Kerberos..."
kinit administrator@COMPANY.LOCAL
if [ $? -eq 0 ]; then
    echo "✓ Kerberos аутентификация работает"
    klist
else
    echo "✗ Ошибка Kerberos"
fi

# Проверка DNS
echo "2. Проверка DNS..."
nslookup company.local
nslookup samba-dc01.company.local

# Проверка доступа к ресурсам
echo "3. Проверка SMB..."
smbclient -L //samba-dc01 -U administrator

# Проверка пользователей
echo "4. Проверка пользователей..."
getent passwd | grep company
```

## Этап 6: Тестирование и валидация

### Чеклист тестирования

```bash
#!/bin/bash
# migration-validation.sh

DOMAIN="company.local"
ADMIN_USER="administrator"

echo "=== Валидация миграции ==="

tests_passed=0
tests_failed=0

# Тест 1: Аутентификация
echo "Тест 1: Аутентификация Kerberos"
if kinit $ADMIN_USER@${DOMAIN^^}; then
    echo "✓ Тест 1 пройден"
    ((tests_passed++))
else
    echo "✗ Тест 1 не пройден"
    ((tests_failed++))
fi

# Тест 2: Поиск пользователей
echo "Тест 2: Поиск пользователей LDAP"
if ldapsearch -x -h samba-dc01.$DOMAIN -b "dc=company,dc=local" "(objectClass=user)" | grep -q "dn:"; then
    echo "✓ Тест 2 пройден"
    ((tests_passed++))
else
    echo "✗ Тест 2 не пройден"
    ((tests_failed++))
fi

# Тест 3: Доступ к ресурсам
echo "Тест 3: Доступ к SMB ресурсам"
if smbclient //samba-dc01/netlogon -U $ADMIN_USER%$ADMIN_PASS -c "ls"; then
    echo "✓ Тест 3 пройден"
    ((tests_passed++))
else
    echo "✗ Тест 3 не пройден"
    ((tests_failed++))
fi

echo "Результаты: $tests_passed пройдено, $tests_failed не пройдено"
```

### План отката

```bash
#!/bin/bash
# migration-rollback.sh

echo "=== Начало отката миграции ==="

# Восстановление из резервной копии AD
echo "1. Восстановление Active Directory..."
# Монтирование резервной копии
# Восстановление System State

# Возврат клиентов в домен AD
echo "2. Возврат клиентов в Windows AD..."
# Скрипт повторного присоединения к AD

# Проверка функциональности
echo "3. Проверка восстановленной среды..."
net ads testjoin
net ads info
```

## Заключение и лучшие практики

### Рекомендации по миграции

1. **Поэтапная миграция**: Начинайте с тестовых подразделений
2. **Резервные копии**: Всегда имейте актуальные бэкапы
3. **Документирование**: Фиксируйте все этапы и проблемы
4. **Тестирование**: Тщательное тестирование на каждом этапе
5. **План отката**: Обязательно имейте рабочий план отката

### Метрики успешной миграции

- 100% пользователей могут аутентифицироваться
- Все критичные приложения работают
- Групповые политики применены корректно
- DNS разрешение работает корректно
- Нет потери данных

### Дальнейшие действия

После успешной миграции рекомендуется:
- Мониторинг работы новой среды
- Обучение администраторов
- Оптимизация производительности
- Разработка процедур резервного копирования и восстановления

# Уточнения по сетевым настройкам для лабораторного стенда

## Общая схема сети и маршрутизации

### Топология физической сети

```
                    +-------------------------------------------------+
                    |                 Роутер gate                    |
                    |           (192.168.0.1/24)                    |
                    |   Внешний интерфейс: eth0 (NAT/Internet)      |
                    +-------------------------------------------------+
                                    | eth1 (vlan trunk)
                    +-------------------------------------------------+
                    |                Коммутатор L2                  |
                    |            (VLAN 10,20,30,40)                 |
                    +-------------------------------------------------+
            |               |               |               |
    +-------+-------+ +-----+-------+ +-----+-------+ +-----+-------+
    |     Net1      | |    Net2     | |    Net3     | |    Net4     |
    |  VLAN 10      | |  VLAN 20    | |  VLAN 30    | |  VLAN 40    |
    +---------------+ +-------------+ +-------------+ +-------------+
```

## Детальные сетевые настройки

### 1. Конфигурация маршрутизатора gate

**Назначение:** Центральный маршрутизатор, обеспечивающий:
- Маршрутизацию между подсетями
- NAT для выхода в интернет
- DHCP-сервис (опционально)
- Firewall правила

#### Конфигурация интерфейсов:

```bash
# /etc/network/interfaces на gate
# Внешний интерфейс (интернет)
auto eth0
iface eth0 inet dhcp
    # или static для фиксированного IP
    # address 192.168.100.2
    # netmask 255.255.255.0
    # gateway 192.168.100.1

# Внутренние интерфейсы (VLAN)
auto eth1.10
iface eth1.10 inet static
    address 192.168.1.1
    netmask 255.255.255.0
    vlan-raw-device eth1

auto eth1.20
iface eth1.20 inet static
    address 192.168.2.1
    netmask 255.255.255.0
    vlan-raw-device eth1

auto eth1.30
iface eth1.30 inet static
    address 192.168.3.1
    netmask 255.255.255.0
    vlan-raw-device eth1

auto eth1.40
iface eth1.40 inet static
    address 192.168.4.1
    netmask 255.255.255.0
    vlan-raw-device eth1
```

#### Настройка iptables для маршрутизации и NAT:

```bash
#!/bin/bash
# firewall-setup.sh на gate

# Включение форвардинга
echo 1 > /proc/sys/net/ipv4/ip_forward

# Очистка существующих правил
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -X

# Базовые политики
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Разрешить loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Разрешить established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# NAT для выхода в интернет
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Разрешить маршрутизацию между внутренними сетями
iptables -A FORWARD -i eth1.10 -o eth1.20 -j ACCEPT
iptables -A FORWARD -i eth1.10 -o eth1.30 -j ACCEPT
iptables -A FORWARD -i eth1.10 -o eth1.40 -j ACCEPT
iptables -A FORWARD -i eth1.20 -o eth1.10 -j ACCEPT
iptables -A FORWARD -i eth1.20 -o eth1.30 -j ACCEPT
iptables -A FORWARD -i eth1.20 -o eth1.40 -j ACCEPT
iptables -A FORWARD -i eth1.30 -o eth1.10 -j ACCEPT
iptables -A FORWARD -i eth1.30 -o eth1.20 -j ACCEPT
iptables -A FORWARD -i eth1.30 -o eth1.40 -j ACCEPT
iptables -A FORWARD -i eth1.40 -o eth1.10 -j ACCEPT
iptables -A FORWARD -i eth1.40 -o eth1.20 -j ACCEPT
iptables -A FORWARD -i eth1.40 -o eth1.30 -j ACCEPT

# Разрешить выход в интернет
iptables -A FORWARD -i eth1.10 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth1.20 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth1.30 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth1.40 -o eth0 -j ACCEPT

# Сохраняем правила
iptables-save > /etc/iptables/rules.v4
```

### 2. Детальные настройки для каждой сети

#### Net1: Windows AD (192.168.1.0/24)

**Назначение:** Исходная среда миграции

```bash
# Конфигурация Windows DC (192.168.1.10)
# Интерфейс: eth0 (VLAN 10)
IP: 192.168.1.10
Mask: 255.255.255.0
Gateway: 192.168.1.1
DNS: 192.168.1.10 (сам себя)
DNS Forwarders: 8.8.8.8, 192.168.1.1

# Конфигурация Windows клиента (192.168.1.20)
IP: 192.168.1.20
Mask: 255.255.255.0
Gateway: 192.168.1.1
DNS: 192.168.1.10
```

**Открытые порты на Windows DC:**
- 53 (DNS)
- 88 (Kerberos)
- 135 (RPC)
- 139, 445 (SMB)
- 389, 636 (LDAP/LDAPS)
- 3268, 3269 (Global Catalog)

#### Net2: FreeIPA (192.168.2.0/24)

**Назначение:** Целевая среда миграции 1

```bash
# Конфигурация FreeIPA сервера (192.168.2.10)
# /etc/sysconfig/network-scripts/ifcfg-ens192
DEVICE=ens192
BOOTPROTO=static
IPADDR=192.168.2.10
NETMASK=255.255.255.0
GATEWAY=192.168.2.1
DNS1=192.168.2.10
DNS2=192.168.2.1
DOMAIN=freeipa.local
HOSTNAME=ipa01.freeipa.local

# Конфигурация клиента RHEL (192.168.2.20)
DEVICE=ens192
BOOTPROTO=static
IPADDR=192.168.2.20
NETMASK=255.255.255.0
GATEWAY=192.168.2.1
DNS1=192.168.2.10
DNS2=192.168.2.1
DOMAIN=freeipa.local
```

**Firewall на FreeIPA:**
```bash
sudo firewall-cmd --permanent --add-service={http,https,ldap,ldaps,kerberos,dns,ntp}
sudo firewall-cmd --permanent --add-port={80/tcp,443/tcp,389/tcp,636/tcp,88/tcp,88/udp,464/tcp,464/udp,53/tcp,53/udp,123/udp}
sudo firewall-cmd --reload
```

#### Net3: Samba DC (192.168.3.0/24)

**Назначение:** Целевая среда миграции 2

```bash
# Конфигурация Samba DC (192.168.3.10)
# /etc/sysconfig/network-scripts/ifcfg-ens192
DEVICE=ens192
BOOTPROTO=static
IPADDR=192.168.3.10
NETMASK=255.255.255.0
GATEWAY=192.168.3.1
DNS1=192.168.3.10
DNS2=192.168.3.1
DOMAIN=company.local
HOSTNAME=samba-dc01.company.local

# Конфигурация клиента Astra (192.168.3.20)
# /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.168.3.20
    netmask 255.255.255.0
    gateway 192.168.3.1
    dns-nameservers 192.168.3.10
    dns-search company.local
```

**Firewall на Samba DC:**
```bash
sudo firewall-cmd --permanent --add-service={dns,kerberos,ldap,ldaps,globalcat}
sudo firewall-cmd --permanent --add-port={53/tcp,53/udp,88/tcp,88/udp,135/tcp,139/tcp,389/tcp,445/tcp,464/tcp,464/udp,636/tcp,3268/tcp,3269/tcp}
sudo firewall-cmd --reload
```

#### Net4: ALD Pro (192.168.4.0/24)

**Назначение:** Целевая среда миграции 3

```bash
# Конфигурация ALD Pro сервера (192.168.4.10)
# /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.168.4.10
    netmask 255.255.255.0
    gateway 192.168.4.1
    dns-nameservers 192.168.4.10
    dns-search ald.local

# Конфигурация клиента Astra (192.168.4.20)
auto eth0
iface eth0 inet static
    address 192.168.4.20
    netmask 255.255.255.0
    gateway 192.168.4.1
    dns-nameservers 192.168.4.10
    dns-search ald.local
```

### 3. Настройка DNS и разрешения имен

#### Конфигурация Conditional Forwarding

**На маршрутизаторе gate (DNS forwarder):**

```bash
# /etc/bind/named.conf.local
// Conditional forwarders для каждого домена
zone "windows-ad.local" {
    type forward;
    forwarders { 192.168.1.10; };
};

zone "freeipa.local" {
    type forward;
    forwarders { 192.168.2.10; };
};

zone "company.local" {
    type forward;
    forwarders { 192.168.3.10; };
};

zone "ald.local" {
    type forward;
    forwarders { 192.168.4.10; };
};
```

**В каждом домене настраиваем forwarders на gate:**

```bash
# В FreeIPA
sudo ipa-dnsconfig-mod --forwarder=192.168.2.1 --forward-policy=only

# В Samba DC
sudo samba-tool dns zonelist 127.0.0.1 -U administrator
# Добавляем forwarder для остальных доменов
```

### 4. Настройка времени (NTP)

**Важность:** Для работы Kerberos критически важно синхронизированное время (расхождение не более 5 минут)

```bash
# На маршрутизаторе gate (NTP сервер для внутренней сети)
sudo apt install chrony
# /etc/chrony/chrony.conf
server pool.ntp.org iburst
allow 192.168.0.0/16

# На всех серверах доменов
# /etc/chrony/chrony.conf
server 192.168.1.1 iburst  # gate как основной NTP
server 192.168.1.10        # Windows DC как резервный
```

### 5. Диагностика сетевых проблем

#### Скрипт проверки connectivity

```bash
#!/bin/bash
# network-test.sh
# Запускать на каждом узле

echo "=== Проверка сетевой связности ==="

# Проверка основных маршрутов
echo "1. Проверка маршрутизации:"
ip route show

echo "2. Проверка DNS:"
nslookup google.com
nslookup windows-ad.local
nslookup freeipa.local
nslookup company.local
nslookup ald.local

echo "3. Проверка связи с шлюзом:"
ping -c 3 192.168.1.1

echo "4. Проверка связи между доменами:"
domains=("192.168.1.10" "192.168.2.10" "192.168.3.10" "192.168.4.10")
for domain in "${domains[@]}"; do
    echo "Пинг $domain:"
    ping -c 2 $domain
done

echo "5. Проверка портов:"
ports=("53" "88" "389" "445")
for domain in "${domains[@]}"; do
    echo "Проверка портов на $domain:"
    for port in "${ports[@]}"; do
        nc -zv $domain $port 2>&1 | grep succeeded
    done
done
```

#### Мониторинг трафика

```bash
# На маршрутизаторе для отладки
sudo tcpdump -i any -n host 192.168.1.10 or host 192.168.2.10 or host 192.168.3.10 or host 192.168.4.10

# Проверка маршрутизации
traceroute 192.168.2.10
mtr 192.168.3.10
```

### 6. Особенности для каждого типа ОС

#### Windows Server 2019

```powershell
# Проверка сетевых настроек
Get-NetIPConfiguration
Test-NetConnection 192.168.2.10 -Port 53
Resolve-DnsName freeipa.local

# Настройка firewall для доменных служб
New-NetFirewallRule -DisplayName "AD Domain Services" -Direction Inbound -Protocol TCP -LocalPort 53,88,389,445,464,636 -Action Allow
```

#### RED OS 8 / CentOS

```bash
# Проверка SELinux для доменных служб
sestatus
setsebool -P allow_ypbind=1

# Проверка firewall
firewall-cmd --list-all
```

#### Astra Linux

```bash
# Проверка мандатного контроля
astra-mac-admin status

# Настройка сети через astra-admin
sudo astra-admin --network-setup
```

### 7. Резервное копирование конфигураций сети

```bash
#!/bin/bash
# backup-network-configs.sh

# Резервное копирование конфигураций сети
BACKUP_DIR="/backup/network/$(date +%Y%m%d)"

mkdir -p $BACKUP_DIR

# Копируем важные конфиги
cp /etc/network/interfaces $BACKUP_DIR/
cp /etc/hosts $BACKUP_DIR/
cp /etc/resolv.conf $BACKUP_DIR/
cp /etc/iptables/rules.v4 $BACKUP_DIR/

# Для каждого домена
domains=("windows-ad" "freeipa" "samba" "ald")
for domain in "${domains[@]}"; do
    mkdir -p $BACKUP_DIR/$domain
    # Здесь можно добавить команды для бэкапа специфичных конфигов
done

echo "Резервные копии сохранены в $BACKUP_DIR"
```

Эти детальные настройки обеспечат корректную работу всех компонентов лабораторного стенда и позволят провести миграцию без сетевых проблем.