### **Практическая работа: "Основы мандатного управления доступом в ALD"**

**Цель работы:** Овладеть практическими навыками работы с мандатным контролем доступа в операционной системе ALD.

**Продолжительность:** 2-3 часа


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
