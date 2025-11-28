# Лекция: Samba Domain Controller (DC) 

## Введение в Samba DC

### Что такое Samba DC?

**Samba** — это набор программ, который позволяет Linux-системам взаимодействовать с системами Windows по протоколам SMB/CIFS. Когда мы говорим **Samba Domain Controller (DC)**, мы имеем в виду, что Samba может выполнять роль контроллера домена, аналогично Windows Server Active Directory.

### Основные возможности Samba DC:

- **Аутентификация пользователей** в домене
- **Централизованное управление** учетными записями
- **Служба каталогов** (аналогично Active Directory)
- **Служба времени** (NTP)
- **DNS-сервер**
- **Управление групповыми политиками** (через RSAT)

---

## 1. Установка и настройка Samba DC

### Предварительные требования

1. **Статический IP-адрес**
2. **Правильное имя хоста** (FQDN)
3. **Синхронизированное время**
4. **Закрытые порты** в firewall

### Процесс установки

#### Шаг 1: Установка пакетов

```bash
# Для RHEL-based систем (RED OS)
sudo dnf install samba samba-dc samba-client samba-winbind

# Для Debian-based систем (Astra Linux)
sudo apt update && sudo apt install samba samba-dsdb-modules samba-vfs-modules winbind
```

#### Шаг 2: Остановка и отключение служб

```bash
sudo systemctl stop samba smbd nmbd winbind
sudo systemctl disable samba smbd nmbd winbind
```

#### Шаг 3: Настройка сети и имени хоста

```bash
# Установка FQDN
sudo hostnamectl set-hostname samba-dc01.company.local

# Проверка разрешения имен
sudo nano /etc/hosts
# Добавить: 192.168.1.10 samba-dc01.company.local samba-dc01
```

#### Шаг 4: Преобразование сервера в контроллер домена

```bash
# Удаляем старую конфигурацию Samba
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Создаем новый домен
sudo samba-tool domain provision --use-rfc2307 --interactive
```

**Параметры создания домена:**
- Realm: COMPANY.LOCAL
- Domain: COMPANY
- Server Role: dc
- DNS backend: SAMBA_INTERNAL
- DNS forwarder: 8.8.8.8 (опционально)

#### Шаг 5: Настройка служб

```bash
# Останавливаем старые демоны
sudo systemctl stop smbd nmbd winbind

# Запускаем новые службы Samba DC
sudo systemctl enable samba-ad-dc
sudo systemctl start samba-ad-dc

# Настраиваем DNS клиент
sudo nano /etc/resolv.conf
# nameserver 127.0.0.1
# search company.local
```

#### Шаг 6: Проверка установки

```bash
# Проверка работы домена
sudo samba-tool domain level show

# Проверка DNS
sudo samba-tool dns query 127.0.0.1 company.local @ ALL

# Проверка аутентификации
sudo samba-tool user list
```

---

## 2. Создание доверительных отношений и управление общим доступом

### Доверительные отношения с другими доменами

#### С Windows Active Directory

```bash
# Создание доверия с доменом Windows
sudo samba-tool domain trust create WINDOWS-DOMAIN -U WINDOWS-DOMAIN\\administrator --type=forest --direction=outgoing
```

#### С FreeIPA

```bash
# Настройка доверия с FreeIPA
sudo samba-tool domain trust create FREEIPA-DOMAIN --type=forest --direction=bidirectional
```

### Управление общим доступом к ресурсам

#### Создание файловых ресурсов

**Пример конфигурации /etc/samba/smb.conf для общего ресурса:**

```ini
[global]
    workgroup = COMPANY
    realm = COMPANY.LOCAL
    netbios name = SAMBA-DC01
    server role = active directory domain controller
    dns forwarder = 8.8.8.8
    
    # Настройки безопасности
    security = ads
    encrypt passwords = yes
    
    # Логирование
    log level = 1
    log file = /var/log/samba/log.%m
    
    # Настройки Kerberos
    dedicated keytab file = /etc/krb5.keytab
    kerberos method = secrets and keytab

[public]
    comment = Public Share
    path = /srv/samba/public
    browseable = yes
    read only = no
    guest ok = no
    valid users = @COMPANY\Domain Users

[departments]
    comment = Departmental Share
    path = /srv/samba/departments
    browseable = yes
    read only = no
    guest ok = no
    valid users = @COMPANY\managers
    write list = @COMPANY\managers
```

#### Управление пользователями и группами

```bash
# Создание пользователя
sudo samba-tool user create ivanov "Ivan123!" --given-name=Ivan --surname=Ivanov

# Создание группы
sudo samba-tool group add managers

# Добавление пользователя в группу
sudo samba-tool group addmembers managers ivanov

# Сброс пароля
sudo samba-tool user setpassword ivanov

# Просмотр пользователей
sudo samba-tool user list
```

---

## 3. Лабораторная работа: Samba DC как контроллер домена

### Топология сети

```
                    +-----------------+
                    |     Роутер      |
                    |      gate       |
                    +-----------------+
                            |
        +---------------------------------------+
        |                   |                   |
    +---+---+           +---+---+           +---+---+
    |  Net1 |           |  Net2 |           |  Net3 |
    +-------+           +-------+           +-------+
    
Сети:
- Net1: 192.168.1.0/24 - Windows AD
- Net2: 192.168.2.0/24 - FreeIPA
- Net3: 192.168.3.0/24 - Samba DC
- Net4: 192.168.4.0/24 - ALD Pro
```

### Конфигурация Samba DC (Net3)

#### Настройка сети

```bash
# На Samba DC сервере
sudo nano /etc/sysconfig/network-scripts/ifcfg-eth0
# DEVICE=eth0
# BOOTPROTO=static
# IPADDR=192.168.3.10
# NETMASK=255.255.255.0
# GATEWAY=192.168.3.1
# DNS1=192.168.3.10
# DOMAIN=company.local

sudo systemctl restart network
```

#### Создание домена Samba

```bash
sudo samba-tool domain provision --use-rfc2307 --interactive
```
**Параметры:**
- Realm: COMPANY.LOCAL
- Domain: COMPANY
- DNS: SAMBA_INTERNAL

#### Настройка DNS для маршрутизации между доменами

```bash
# Добавление conditional forwarders для других доменов
sudo samba-tool dns zonelist 127.0.0.1 -U administrator

# Для домена windows-ad.local
sudo samba-tool dns zonecreate 127.0.0.1 windows-ad.local -U administrator
sudo samba-tool dns add 127.0.0.1 windows-ad.local @ NS samba-dc01.company.local -U administrator
```

### Присоединение клиентов к домену

#### Клиент Astra Linux

```bash
# Установка необходимых пакетов
sudo apt install samba-client winbind krb5-user

# Настройка Kerberos
sudo nano /etc/krb5.conf
[libdefaults]
    default_realm = COMPANY.LOCAL
    dns_lookup_realm = true
    dns_lookup_kdc = true

# Присоединение к домену
sudo net ads join -U administrator

# Настройка SSSD
sudo authselect select sssd with-mkhomedir --force

# Перезапуск служб
sudo systemctl restart sssd
```

#### Клиент Windows

```powershell
# В PowerShell от имени администратора
Add-Computer -DomainName "company.local" -Credential "COMPANY\administrator" -Restart

# Или через графический интерфейс:
# System Properties → Computer Name → Change → Domain: company.local
```

### Создание доверительных отношений между доменами

#### Между Samba DC и Windows AD

**На стороне Samba:**
```bash
sudo samba-tool domain trust create WINDOWS-AD.LOCAL -U WINDOWS-AD\administrator --type=forest --direction=bidirectional
```

**На стороне Windows AD:**
```powershell
# В PowerShell на Windows Server
New-ADTrust -Name "COMPANY.LOCAL" -Type Forest -Direction Bidirectional
```

#### Между Samba DC и FreeIPA

```bash
# На Samba DC
sudo samba-tool domain trust create FREEIPA.LOCAL --type=forest --direction=bidirectional

# На FreeIPA
ipa trust-add --type=ad COMPANY.LOCAL --admin Administrator --password
```

### Тестирование функциональности

#### Проверка аутентификации

```bash
# На клиенте Astra Linux - аутентификация пользователя из Samba DC
kinit ivanov@COMPANY.LOCAL
klist

# Проверка доступа к ресурсам Windows
smbclient //windows-server/share -U COMPANY\\ivanov

# Проверка доступа к ресурсам FreeIPA
smbclient //freeipa-server/share -U COMPANY\\ivanov
```

#### Проверка общего доступа

```bash
# Создание тестового ресурса на Samba DC
sudo mkdir -p /srv/samba/test
sudo chmod 755 /srv/samba/test

# Добавление в smb.conf
[test_share]
    path = /srv/samba/test
    read only = no
    browseable = yes
    valid users = @COMPANY\"Domain Users"

# Перезагрузка Samba
sudo systemctl restart samba-ad-dc
```

### Управление групповыми политиками

```bash
# Установка инструментов управления групповыми политиками
sudo apt install samba-gpupdate

# Создание базовой политики
sudo samba-tool gpo create "Default Domain Policy"

# Применение политики
sudo samba-tool gpo list
```

### Мониторинг и диагностика

```bash
# Просмотр логов Samba
sudo tail -f /var/log/samba/log.samba-dc01

# Проверка репликации (если есть дополнительные DC)
sudo samba-tool drs showrepl

# Проверка DNS
sudo samba-tool dns query 127.0.0.1 company.local @ ALL

# Проверка работы Kerberos
sudo kinit administrator@COMPANY.LOCAL
sudo klist
```

## Заключение

Samba DC предоставляет полнофункциональную альтернативу Windows Active Directory, позволяя создавать среды с участием Linux и Windows клиентов. Основные преимущества:

- **Экономия средств** (отсутствие лицензионных отчислений)
- **Гибкость настройки**
- **Интеграция с существующей инфраструктурой**
- **Поддержка стандартных протоколов** (LDAP, Kerberos, DNS)

