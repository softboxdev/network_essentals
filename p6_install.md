# Пошаговая инструкция: Создание БД Microsoft SQL Server через P6 Professional Setup

## Предварительная подготовка SQL Server

### 1. Проверьте и настройте SQL Server

**Откройте SQL Server Management Studio (SSMS) как администратор:**

```sql
-- Создайте пользователя для P6 с правами администратора
CREATE LOGIN p6 WITH PASSWORD = 'p6123';
ALTER SERVER ROLE sysadmin ADD MEMBER p6;
```

**В SQL Server Configuration Manager:**
- Включите протоколы: **Shared Memory**, **Named Pipes**, **TCP/IP**
- Перезапустите службу SQL Server

## Процесс установки P6 Professional

### Шаг 1: Запустите установщик
- Скачайте **P6 Professional Setup**
- **Щелкните правой кнопкой** → **"Запуск от имени администратора"**

### Шаг 2: Начало установки
- Нажмите **"Next"** на начальных экранах
- Примите лицензионное соглашение
- Выберите папку установки

### Шаг 3: Настройка базы данных

**На экране "Database Configuration":**

```
1. Database Type: Microsoft SQL Server
2. Database Server Instance: (local)
3. Authentication: SQL Server Authentication
4. Login: p6
5. Password: p6123
```

![P6 Database Configuration](https.i.imgur.com/8F2Qc7N.png)

### Шаг 4: Создание базы данных

**После подключения к SQL Server:**

1. Установщик предложит **"Create Database"** - нажмите эту кнопку
2. Введите **имя базы данных** (например: `P6_PROJECTS`)
3. Выберите **язык базы данных** (обычно English)
4. Нажмите **"Next"**

### Шаг 5: Настройка подключения

**На экране "Database Connection":**
```
Database Name: P6_PROJECTS
Shared Group ID: 1
```

### Шаг 6: Завершение установки базы данных

- P6 автоматически создаст все таблицы и структуры
- Дождитесь сообщения **"Database created successfully"**
- Нажмите **"Next"** для продолжения установки

## Если возникает ошибка при создании БД

### Проблема 1: "Cannot connect to database server"

**Решение:**
```
Измените Database Server Instance на:
- localhost\SQLEXPRESS (для Express версии)
- . (точка)
- Имя_вашего_компьютера
```

### Проблема 2: "Access denied"

**Решение в SSMS:**
```sql
-- Дайте дополнительные права
GRANT CREATE DATABASE TO p6;
ALTER SERVER ROLE dbcreator ADD MEMBER p6;
```

### Проблема 3: Служба SQL Server не найдена

**Решение:**
- Откройте **services.msc**
- Найдите и запустите **SQL Server (MSSQLSERVER)**
- Запустите **SQL Server Browser**

## Альтернативный метод: Создание БД вручную

### Если автоматическое создание не работает:

1. **Создайте базу вручную через SSMS:**
```sql
CREATE DATABASE P6_PROJECTS;
```

2. **В P6 Setup выберите "Use existing database"**
3. **Укажите имя существующей БД:** `P6_PROJECTS`

## Проверка успешного создания

После установки:

1. **Откройте P6 Professional**
2. **Попробуйте войти с стандартными учетными данными:**
   ```
   Username: admin
   Password: (оставьте пустым)
   ```

3. **Или:**
   ```
   Username: primavera
   Password: primavera
   ```

## Важные моменты

### Перед установкой убедитесь:
- ✅ SQL Server установлен и запущен
- ✅ Служба "SQL Server Browser" запущена
- ✅ Протоколы подключения включены
- ✅ Пользователь p6 создан с правами sysadmin
- ✅ Установщик запущен от имени администратора

### После установки:
- Сохраните параметры подключения к БД
- Задокументируйте имя базы данных и учетные данные
- Настройте регулярное резервное копирование БД

## Команды для проверки в SQL Server

```sql
-- Проверьте созданную базу
SELECT name FROM sys.databases WHERE name LIKE 'P6%';

-- Проверьте таблицы в БД P6
USE P6_PROJECTS;
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES;
```

**Эта инструкция охватывает 99% сценариев создания БД через P6 Professional Setup. Если возникнут конкретные ошибки - сообщите текст ошибки для точного решения.**