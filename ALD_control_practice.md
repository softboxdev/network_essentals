### **Практическая работа: "Основы мандатного управления доступом в ALD"**

**Цель работы:** Овладеть практическими навыками работы с мандатным контролем доступа в операционной системе ALD.

**Продолжительность:** 2-3 часа

### **Практическая работа: "Работа с мандатными метками в ALD"**

**Цель:** Освоить управление мандатными метками - инициализацию, расшифровку, назначение ролям и просмотр доступных меток.

### **Установка всех зависимостей для работы с мандатным управлением в ALD**

## **1. Предварительная проверка системы**

```bash
# Проверяем дистрибутив и версию
cat /etc/os-release
lsb_release -a

# Проверяем архитектуру
uname -m

# Проверяем текущие установленные пакеты SELinux/ALD
rpm -qa | grep -i selinux
dpkg -l | grep -i selinux  # для Debian-based
```

## **2. Установка базовых пакетов ALD/SELinux**

### **Для дистрибутивов на базе RHEL/CentOS/Fedora/Astra Linux:**

```bash
# Обновление системы
sudo yum update -y
# или для современных версий:
sudo dnf update -y

# Установка основных пакетов ALD
sudo yum install -y \
    ald-server \
    ald-workstation \
    selinux-policy \
    selinux-policy-targeted \
    libselinux \
    libselinux-utils \
    libsemanage \
    policycoreutils \
    policycoreutils-python-utils \
    checkpolicy \
    setools \
    setools-console \
    setroubleshoot \
    setroubleshoot-server \
    mcstrans

# Для разработки и отладки политик
sudo yum install -y \
    selinux-policy-devel \
    policycoreutils-devel \
    setools-devel \
    secilc \
    audit \
    audit-libs
```

### **Для дистрибутивов на базе Debian/Ubuntu/ALT Linux:**

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка основных пакетов
sudo apt install -y \
    selinux-basics \
    selinux-policy-default \
    selinux-policy-dev \
    selinux-utils \
    policycoreutils \
    setools \
    setools-gui \
    setroubleshoot \
    python3-selinux \
    python3-setools \
    auditd \
    mcstrans

# Дополнительные утилиты
sudo apt install -y \
    policycoreutils-python-utils \
    secilc \
    checkpolicy \
    make \
    gcc
```

## **3. Установка специализированных инструментов ALD**

```bash
# Установка графических утилит (если нужен GUI)
sudo yum install -y \
    setools-gui \
    selinux-policy-gui \
    policycoreutils-gui

# Установка утилит для работы с мандатными метками
sudo yum install -y \
    attr \
    libattr-devel \
    libcap \
    libcap-devel

# Установка дополнительных инструментов мониторинга
sudo yum install -y \
    aide \
    psacct \
    acct
```

## **4. Настройка системы после установки**

```bash
# Включаем SELinux/ALD в конфигурации
sudo nano /etc/selinux/config
```
**Содержимое файла /etc/selinux/config:**
```ini
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=enforcing

# SELINUXTYPE= can take one of these three values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=mls

# Установка политики MLS для мандатного контроля
SELINUXTYPE=mcs
# или для полной MLS:
# SELINUXTYPE=mls
```

## **5. Установка зависимостей для разработки политик**

```bash
# Установка компиляторов и инструментов разработки
sudo yum groupinstall -y "Development Tools"

# Установка языковых пакетов для разработки политик
sudo yum install -y \
    gcc \
    make \
    flex \
    bison \
    rpm-build \
    rpmdevtools

# Установка Python-библиотек для работы с ALD
sudo yum install -y \
    python3 \
    python3-devel \
    python3-pip \
    python3-selinux \
    python3-setools

# Установка дополнительных Python-пакетов
sudo pip3 install \
    selinux \
    setools \
    audit
```

## **6. Установка и настройка инструментов мониторинга**

```bash
# Установка и настройка auditd
sudo yum install -y audit audit-libs
sudo systemctl enable auditd
sudo systemctl start auditd

# Настройка правил аудита
sudo nano /etc/audit/audit.rules
```
**Добавить в /etc/audit/audit.rules:**
```ini
# Мониторинг изменений SELinux политики
-w /etc/selinux -p wa -k selinux_policy
-w /etc/selinux/targeted -p wa -k selinux_policy
-w /usr/share/selinux -p wa -k selinux_policy

# Мониторинг изменений меток
-w /usr/sbin/setfiles -p x -k selinux_label
-w /usr/sbin/restorecon -p x -k selinux_label
-w /usr/sbin/chcon -p x -k selinux_label
-w /usr/sbin/semanage -p x -k selinux_manage

# Мониторинг нарушений политики
-a always,exit -F arch=b64 -S setxattr -F key=selinux_label
```

## **7. Установка дополнительных утилит для работы с метками**

```bash
# Установка утилит для расширенной работы с атрибутами
sudo yum install -y \
    xattr \
    attr \
    libattr-devel

# Установка утилит для работы с файловыми системами
sudo yum install -y \
    e2fsprogs \
    xfsprogs \
    btrfs-progs

# Установка сетевых утилит с поддержкой SELinux
sudo yum install -y \
    policycoreutils-python-utils \
    network-scripts \
    iptables-services
```

## **8. Проверка установки и настройка окружения**

```bash
# Создаем скрипт проверки установки
cat > check_ald_installation.sh << 'EOF'
#!/bin/bash

echo "=== ПРОВЕРКА УСТАНОВКИ ALD/SELINUX ==="

echo "1. Проверка основных пакетов:"
for pkg in selinux-policy policycoreutils setools libselinux; do
    if rpm -q $pkg &>/dev/null; then
        echo "   ✓ $pkg установлен"
    else
        echo "   ✗ $pkg ОТСУТСТВУЕТ"
    fi
done

echo "2. Проверка утилит:"
for cmd in sestatus seinfo sesearch semanage getenforce getfattr; do
    if command -v $cmd &>/dev/null; then
        echo "   ✓ $cmd доступен"
    else
        echo "   ✗ $cmd ОТСУТСТВУЕТ"
    fi
done

echo "3. Проверка статуса SELinux:"
sestatus

echo "4. Проверка загруженных модулей:"
semodule -l | head -10

echo "5. Проверка типов политик:"
seinfo -t | wc -l
echo "   Доступно типов: $(seinfo -t | wc -l)"

echo "=== ПРОВЕРКА ЗАВЕРШЕНА ==="
EOF

chmod +x check_ald_installation.sh
./check_ald_installation.sh
```

## **9. Установка пропущенных зависимостей (если нужно)**

```bash
# Автоматический поиск и установка пропущенных зависимостей
sudo yum install -y yum-utils
sudo package-cleanup --problems
sudo package-cleanup --dupes
sudo yum-complete-transaction

# Или для Debian-based:
sudo apt --fix-broken install
sudo apt autoremove
sudo apt autoclean
```

## **10. Создание рабочего окружения для практики**

```bash
# Создаем директорию для практических работ
mkdir -p ~/ald_labs/{bin,scripts,policies,logs}
cd ~/ald_labs

# Создаем базовые скрипты для работы
cat > bin/ald_helpers.sh << 'EOF'
#!/bin/bash

# Функции-помощники для работы с ALD

show_labels() {
    echo "=== МЕТКИ ФАЙЛОВ В $1 ==="
    ls -Z $1
}

show_process_labels() {
    echo "=== МЕТКИ ПРОЦЕССОВ ==="
    ps -eZ | head -20
}

search_policy() {
    echo "=== ПОИСК В ПОЛИТИКЕ: $1 ==="
    seinfo -t | grep $1 | head -10
}

check_access() {
    echo "=== ПРОВЕРКА ДОСТУПА: $1 к $2 ==="
    sesearch --allow -s $1 -t $2
}
EOF

chmod +x bin/ald_helpers.sh
```

## **11. Установка последних обновлений безопасности**

```bash
# Установка обновлений безопасности
sudo yum update --security -y

# Обновление политик SELinux
sudo semodule -u

# Пересборка политики (если требуется)
sudo semodule -B
```

## **12. Проверка готовности системы**

```bash
# Финальная проверка системы
echo "=== ФИНАЛЬНАЯ ПРОВЕРКА СИСТЕМЫ ==="

# Проверка режима SELinux
sudo getenforce

# Проверка загрузки политики
sudo sestatus

# Проверка аудита
sudo systemctl status auditd

# Проверка логов
sudo ausearch -m AVC -ts today 2>/dev/null | head -5

# Проверка инструментов разработки
which secilc
which checkpolicy

echo "=== СИСТЕМА ГОТОВА К РАБОТЕ ==="
```

## **13. Решение распространенных проблем**

### **Если пакеты не находятся:**
```bash
# Обновление репозиториев
sudo yum clean all
sudo yum makecache

# Или для Debian:
sudo apt update

# Поиск пакетов по имени
yum search selinux
apt search selinux
```

### **Если возникают конфликты пакетов:**
```bash
# Удаление конфликтующих пакетов
sudo yum remove old-selinux-package

# Чистая установка
sudo yum reinstall selinux-policy-targeted
```

### **Если система не загружается после настройки:**
```bash
# В аварийном режиме:
# 1. Добавить 'selinux=0' в параметры загрузки
# 2. Запустить: sudo setenforce 0
# 3. Проверить логи: sudo sealert -a /var/log/audit/audit.log
```



---

## **ЧАСТЬ 1: Инициализация и базовая работа с метками**

### **1.1. Инициализация системы мандатного контроля**

```bash
# 1. Проверка текущего статуса SELinux/ALD
sudo getenforce
sudo sestatus

# 2. Если отключен - включаем
sudo setenforce Enforcing
# Или для постоянного включения:
sudo nano /etc/selinux/config
# Установить: SELINUX=enforcing

# 3. Инициализация базы политик (если требуется)
sudo semodule -B
```

### **1.2. Создание тестового окружения**

```bash
# Создаем тестовую структуру
sudo mkdir -p /lab/{public,secret,topsecret,department_{a,b,c}}
sudo touch /lab/public/notice.txt
sudo touch /lab/secret/contract.txt  
sudo touch /lab/topsecret/strategy.txt
sudo touch /lab/department_a/report.txt
sudo touch /lab/department_b/data.txt
sudo touch /lab/department_c/plan.txt

# Создаем тестовых пользователей
sudo useradd -s /bin/bash alice
sudo useradd -s /bin/bash bob
sudo useradd -s /bin/bash carol
sudo echo "password123" | passwd --stdin alice
sudo echo "password123" | passwd --stdin bob  
sudo echo "password123" | passwd --stdin carol
```

---

## **ЧАСТЬ 2: Расшифровка мандатных меток**

### **2.1. Просмотр и расшифровка текущих меток**

```bash
# 1. Просмотр меток файлов и каталогов
ls -Z /lab/
ls -Z /lab/public/

# 2. Детальный просмотр меток с помощью getfattr
sudo getfattr -d -m security.selinux /lab/secret/
sudo getfattr -d -m security.selinux /lab/secret/contract.txt

# 3. Просмотр меток процессов
ps -eZ | head -10
ps -Z -u alice

# 4. Просмотр меток сетевых портов
sudo netstat -tulpnZ
```

### **2.2. Утилиты для расшифровки меток**

```bash
# 1. Расшифровка меток с помощью seinfo
sudo seinfo -u  # Показать всех пользователей SELinux
sudo seinfo -r  # Показать все роли
sudo seinfo -t  # Показать все типы

# 2. Поиск по меткам
sesearch --allow -s staff_r -t secret_data_t
sesearch --allow -t ssh_port_t

# 3. Анализ метки процесса
ps -eZ | grep nginx
# Пример вывода: system_u:system_r:httpd_t:s0
# Расшифровка:
# - system_u: пользователь системы
# - system_r: роль системы  
# - httpd_t: тип процесса веб-сервера
# - s0: уровень конфиденциальности
```

### **2.3. Практика расшифровки меток**

**Задание:** Расшифруйте следующие метки:

```bash
# Создаем файлы с разными метками
sudo touch /tmp/test{1..5}.txt

# Назначаем разные метки
sudo chcon -t etc_t /tmp/test1.txt
sudo chcon -t var_log_t /tmp/test2.txt 
sudo chcon -t user_home_t /tmp/test3.txt
sudo chcon -t sshd_exec_t /tmp/test4.txt
sudo chcon -t bin_t /tmp/test5.txt

# Анализируем метки
ls -Z /tmp/test*.txt

# Расшифровываем с помощью seinfo
for file in /tmp/test*.txt; do
    label=$(ls -Z $file | awk '{print $4}')
    echo "Файл: $file"
    echo "Метка: $label"
    sudo seinfo -t$label 2>/dev/null | head -5
    echo "---"
done
```

---

## **ЧАСТЬ 3: Добавление меток к ролям**

### **3.1. Просмотр существующих ролей и их меток**

```bash
# 1. Просмотр всех доступных ролей
sudo seinfo -r

# 2. Просмотр ролей пользователей
sudo semanage user -l

# 3. Просмотр закрепленных ролей за логинами
sudo semanage login -l
```

### **3.2. Создание и настройка пользовательских ролей**

```bash
# 1. Создаем нового пользователя SELinux
sudo semanage user -a -R "staff_r system_r" -L s0 -r s0-s0:c0.c100 user_custom_r

# 2. Назначаем роль пользователю ОС
sudo semanage login -a -s user_custom_r -r "s0-s0:c0.c50" alice

# 3. Проверяем назначение
sudo semanage login -l | grep alice

# 4. Тестируем
su - alice
id -Z  # Должна отображаться новая роль
```

### **3.3. Настройка ролей для разных уровней доступа**

```bash
# 1. Создаем роли с разными уровнями доступа
sudo semanage user -a -R "staff_r" -L s0 -r s0-s0:c0.c10 user_junior_r
sudo semanage user -a -R "staff_r system_r" -L s0 -r s0-s2:c0.c100 user_senior_r  
sudo semanage user -a -R "staff_r sysadm_r" -L s0 -r s0-s3:c0.c200.c300 user_admin_r

# 2. Назначаем роли пользователям
sudo semanage login -a -s user_junior_r -r "s0-s1:c0.c10" bob
sudo semanage login -a -s user_senior_r -r "s0-s2:c0.c50" carol

# 3. Создаем тестовые файлы с разными уровнями
sudo mkdir -p /security/{unclassified,confidential,secret,topsecret}

# 4. Назначаем метки каталогам
sudo semanage fcontext -a -t unclassified_t "/security/unclassified(/.*)?"
sudo semanage fcontext -a -t confidential_t "/security/confidential(/.*)?"
sudo semanage fcontext -a -t secret_t "/security/secret(/.*)?"
sudo semanage fcontext -a -t topsecret_t "/security/topsecret(/.*)?"

# 5. Применяем метки
sudo restorecon -R /security/
```

---

## **ЧАСТЬ 4: Вывод всех доступных меток**

### **4.1. Просмотр всех типов меток**

```bash
# 1. Все типы файлов/процессов
sudo seinfo -t | head -20
sudo seinfo -t | wc -l  # Общее количество типов

# 2. Все пользователи SELinux
sudo seinfo -u

# 3. Все роли
sudo seinfo -r

# 4. Все уровни чувствительности
sudo seinfo -l

# 5. Все категории
sudo seinfo -c
```

### **4.2. Детальная информация о конкретной метке**

```bash
# 1. Информация о типе
sudo seinfo -thttpd_t -x

# 2. Какие роли могут использовать тип
sesearch -A -s staff_r -t httpd_t

# 3. Разрешения для типа
sesearch -A -t httpd_t

# 4. Атрибуты типа
sudo seinfo -ahttpd_t -x
```

### **4.3. Практическое задание: Аудит системы меток**

```bash
# 1. Создаем скрипт для аудита меток
cat > audit_labels.sh << 'EOF'
#!/bin/bash
echo "=== АУДИТ СИСТЕМЫ МЕТОК ALD ==="
echo
echo "1. СТАТУС СИСТЕМЫ:"
sudo sestatus
echo
echo "2. ПОЛЬЗОВАТЕЛИ SELINUX:"
sudo semanage user -l
echo
echo "3. РОЛИ В СИСТЕМЕ:"
sudo seinfo -r
echo
echo "4. ТИПЫ ФАЙЛОВ (первые 20):"
sudo seinfo -t | head -20
echo
echo "5. УРОВНИ ДОСТУПА:"
sudo seinfo -l
echo
echo "6. КАТЕГОРИИ:"
sudo seinfo -c | head -10
EOF

chmod +x audit_labels.sh
./audit_labels.sh
```

### **4.4. Поиск и фильтрация меток**

```bash
# 1. Поиск меток связанных с веб-сервером
sudo seinfo -t | grep http
sudo seinfo -t | grep apache
sudo seinfo -t | grep nginx

# 2. Поиск меток для баз данных
sudo seinfo -t | grep mysql
sudo seinfo -t | grep postgres
sudo seinfo -t | grep db

# 3. Поиск меток для сетевых служб
sudo seinfo -t | grep port
sudo seinfo -t | grep network

# 4. Создание отчета по меткам
sudo seinfo -t | awk '{print "Тип: "$1}' > selinux_types_report.txt
sudo seinfo -r | awk '{print "Роль: "$1}' > selinux_roles_report.txt
```

---

## **ЧАСТЬ 5: Практические кейсы**

### **Кейс 1: Настройка доступа к веб-серверу**

```bash
# 1. Проверяем текущие метки веб-сервера
ps -eZ | grep nginx
ls -Z /var/www/html/

# 2. Устанавливаем правильные метки для веб-контента
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
sudo restorecon -R /var/www/html/

# 3. Разрешаем веб-серверу доступ к портам
sudo setsebool -P httpd_can_network_connect on
```

### **Кейс 2: Настройка доступа к базе данных**

```bash
# 1. Проверяем метки процесса БД
ps -eZ | grep postgres
ps -eZ | grep mysql

# 2. Настраиваем доступ к данным БД
sudo semanage fcontext -a -t mysqld_db_t "/var/lib/mysql(/.*)?"
sudo restorecon -R /var/lib/mysql/
```

### **Кейс 3: Создание изолированного окружения**

```bash
# 1. Создаем изолированный каталог
sudo mkdir -p /secure/app{1,2,3}

# 2. Создаем кастомные типы
sudo semanage permissive -a custom_app1_t
sudo semanage permissive -a custom_app2_t

# 3. Назначаем типы каталогам
sudo semanage fcontext -a -t custom_app1_t "/secure/app1(/.*)?"
sudo semanage fcontext -a -t custom_app2_t "/secure/app2(/.*)?"
sudo restorecon -R /secure/
```

---

## **КОНТРОЛЬНЫЕ ЗАДАНИЯ**

### **Задание 1: Расшифруйте метки**
```bash
# Даны метки, объясните что они означают:
# 1. system_u:object_r:etc_t:s0
# 2. user_u:object_r:user_home_t:s0
# 3. system_u:system_r:init_t:s0
# 4. unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

### **Задание 2: Настройте роли**
- Создайте 3 роли с разными уровнями доступа
- Назначьте их разным пользователям
- Проверьте работу ограничений

### **Задание 3: Аудит системы**
- Создайте полный отчет по всем меткам в системе
- Найдите все метки связанные с сетевыми службами
- Определите, какие роли имеют доступ к конфиденциальным данным

### **Задание 4: Решение проблем**
```bash
# Создайте проблемную ситуацию:
sudo touch /var/www/html/test.php
sudo chcon -t bin_t /var/www/html/test.php
# Объясните, почему веб-сервер не сможет обслуживать этот файл?
# Как исправить?
```

---

## **ШПАРГАЛКА КОМАНД**

| Действие | Команда |
|----------|---------|
| Просмотр меток файлов | `ls -Z`, `getfattr -d -m security.selinux` |
| Просмотр меток процессов | `ps -eZ`, `ps -Z -u username` |
| Изменение метки файла | `chcon -t new_type file`, `restorecon file` |
| Просмотр всех типов | `seinfo -t` |
| Просмотр всех ролей | `seinfo -r` |
| Поиск разрешений | `sesearch --allow -s role -t type` |
| Назначение роли пользователю | `semanage login -a -s role -r range user` |
| Создание пользователя SELinux | `semanage user -a -R roles -L level -r range username` |


---

## **Теоретическая часть (15 минут)**

### **Основные понятия:**

1. **Мандатная метка** - комбинация уровня конфиденциальности и набора категорий
2. **Уровни конфиденциальности:** 
   - `s0` - Общедоступно
   - `s1` - Конфиденциально  
   - `s2` - Секретно
   - `s3` - Совершенно секретно
3. **Категории:** `c0` (Финансы), `c1` (Разработка), `c2` (Персонал)

### **Ключевые команды:**
- `chcat` - управление категориями
- `getfattr` - просмотр меток
- `setfattr` - установка меток
- `ps -Z` - просмотр меток процессов

---

## **Практическая часть**

### **Задание 1: Настройка рабочего окружения**

**Цель:** Создать тестовую структуру каталогов и пользователей

```bash
# 1. Создаем тестовые каталоги
sudo mkdir -p /test/{public,finance,development,hr}

# 2. Создаем тестовые файлы
echo "Общедоступная информация" | sudo tee /test/public/info.txt
echo "Финансовый отчет" | sudo tee /test/finance/report.txt
echo "Исходный код проекта" | sudo tee /test/development/code.py
echo "Данные сотрудников" | sudo tee /test/hr/staff.csv

# 3. Создаем тестовых пользователей
sudo useradd -s /bin/bash user_finance
sudo useradd -s /bin/bash user_dev
sudo useradd -s /bin/bash user_hr

# Устанавливаем пароли
echo "user_finance:password123" | sudo chpasswd
echo "user_dev:password123" | sudo chpasswd
echo "user_hr:password123" | sudo chpasswd
```
```


# 1. Просмотр меток файлов и каталогов
ls -Z /lab/
ls -Z /lab/public/

# 2. Детальный просмотр меток с помощью getfattr
sudo getfattr -d -m security.selinux /lab/secret/
sudo getfattr -d -m security.selinux /lab/secret/contract.txt

# 3. Просмотр меток процессов
ps -eZ | head -10
ps -Z -u alice

# 4. Просмотр меток сетевых портов
sudo netstat -tulpnZ
```
### **Задание 2: Назначение мандатных меток**

**Цель:** Научиться назначать и просматривать мандатные метки

```bash
# 1. Просмотр текущих меток
sudo getfattr -d /test/public/info.txt
sudo getfattr -d /test/finance/report.txt

# 2. Установка мандатных меток для каталогов
sudo setfattr -n security.selinux -v "s0" /test/public/
sudo setfattr -n security.selinux -v "s1:c0" /test/finance/
sudo setfattr -n security.selinux -v "s1:c1" /test/development/ 
sudo setfattr -n security.selinux -v "s2:c0,c2" /test/hr/

# 3. Рекурсивное применение меток ко всем файлам в каталогах
sudo chcat -R --type=s1:c0 /test/finance/
sudo chcat -R --type=s1:c1 /test/development/
sudo chcat -R --type=s2:c0,c2 /test/hr/

# 4. Проверка установленных меток
sudo ls -laZ /test/
```

### **Задание 3: Назначение ролей пользователям**

**Цель:** Назначить пользователям роли с соответствующими мандатными метками

```bash
# 1. Назначение ролей пользователям
sudo usermod -R staff_r user_finance
sudo usermod -R staff_r user_dev  
sudo usermod -R staff_r user_hr

# 2. Настройка мандатных меток для пользователей
sudo semanage login -a -s staff_r -r "s1:c0" user_finance
sudo semanage login -a -s staff_r -r "s1:c1" user_dev
sudo semanage login -a -s staff_r -r "s2:c0,c2" user_hr

# 3. Проверка назначенных ролей
sudo semanage login -l
```

### **Задание 4: Тестирование мандатного контроля доступа**

**Цель:** Проверить работу мандатного контроля на практике

**Тест 1:** Проверка доступа пользователя финансового отдела

```bash
# Войдите как user_finance
su - user_finance

# Попробуйте прочитать файлы:
cat /test/public/info.txt          # Должно получиться ✓
cat /test/finance/report.txt       # Должно получиться ✓  
cat /test/development/code.py      # Должно быть отказано ✗
cat /test/hr/staff.csv            # Должно быть отказано ✗

# Проверьте свою текущую метку:
id -Z
```

**Тест 2:** Проверка доступа пользователя отдела разработки

```bash
# Войдите как user_dev
su - user_dev

# Попробуйте прочитать файлы:
cat /test/public/info.txt          # Должно получиться ✓
cat /test/finance/report.txt       # Должно быть отказано ✗
cat /test/development/code.py      # Должно получиться ✓
cat /test/hr/staff.csv            # Должно быть отказано ✗
```

**Тест 3:** Проверка доступа пользователя отдела кадров

```bash
# Войдите как user_hr  
su - user_hr

# Попробуйте прочитать файлы:
cat /test/public/info.txt          # Должно получиться ✓
cat /test/finance/report.txt       # Должно быть отказано ✗
cat /test/development/code.py      # Должно быть отказано ✗
cat /test/hr/staff.csv            # Должно получиться ✓
```

### **Задание 5: Анализ и отладка**

**Цель:** Научиться анализировать нарушения мандатной политики

```bash
# 1. Просмотр логов нарушений
sudo tail -f /var/log/audit/audit.log | grep AVC

# 2. Поиск конкретных нарушений доступа
sudo ausearch -m avc -ts today

# 3. Анализ меток процессов
ps -eZ | grep staff_r

# 4. Проверка контекста файлов
ls -Z /test/hr/

# 5. Анализ успешных доступов
sudo ausearch -m MAC_OBJECT_OPEN -su user_finance
```

### **Задание 6: Создание собственной политики доступа**

**Цель:** Настроить custom-политику для нового отдела

```bash
# 1. Создаем каталог для маркетинга
sudo mkdir /test/marketing
echo "План маркетинга" | sudo tee /test/marketing/plan.txt

# 2. Создаем пользователя маркетинга
sudo useradd -s /bin/bash user_marketing
echo "user_marketing:password123" | sudo chpasswd

# 3. Назначаем метку для маркетинга (уровень s1, категория c3)
sudo setfattr -n security.selinux -v "s1:c3" /test/marketing/
sudo chcat -R --type=s1:c3 /test/marketing/

# 4. Настраиваем пользователя
sudo semanage login -a -s staff_r -r "s1:c3" user_marketing

# 5. Тестируем доступ
su - user_marketing
cat /test/marketing/plan.txt      # Должно получиться ✓
cat /test/finance/report.txt      # Должно быть отказано ✗
```

---
