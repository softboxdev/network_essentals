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

