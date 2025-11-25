prim-db-srv-07.novaenergies.local

Подробная инструкция по настройке доступа к БД через WebLogic Server после добавления в толстый клиент:

## Предварительные требования

- Установленный и настроенный **Oracle WebLogic Server**
- **P6 EPPM Web Administration** должен быть установлен
- Существующая база данных, настроенная в толстом клиенте P6 Professional
- Данные для подключения к БД: хост, порт, имя базы, логин/пароль

## Получение данных о существующей БД из толстого клиента

### Способ 1: Из файла конфигурации P6

1. **Найдите файлы конфигурации:**
   ```
   C:\Program Files\Oracle\Primavera P6\P6 Professional\
   Ищите файлы: *.ini, *.cfg, *.properties
   ```

2. **Ключевые файлы:**
   - `p6professional.ini`
   - `database.properties`
   - `connection.properties`

### Способ 2: Через реестр Windows

1. **Откройте regedit**
2. **Перейдите к:**
   ```
   HKEY_CURRENT_USER\Software\Oracle\Primavera P6\Professional\21.12\
   ```
3. **Найдите параметры подключения к БД**

### Способ 3: Из самого P6 Professional

1. **Запустите P6 Professional**
2. **Файл → Информация о базе данных**
3. **Запишите параметры:**
   - Database Type: Oracle/MSSQL
   - Database Host
   - Database Port
   - Database Name
   - Database User

## Настройка через Web Administration Console

### Шаг 1: Вход в WebLogic Administration Console

1. **Откройте браузер** и перейдите:
   ```
   http://localhost:7001/console
   или
   http://[сервер]:[порт]/console
   ```

2. **Войдите в систему:**
   - Username: `weblogic`
   - Password: [ваш пароль WebLogic]

### Шаг 2: Создание Data Source

1. **В левом меню разверните:**
   ```
   Services → Data Sources
   ```

2. **Нажмите "New" → "Generic Data Source"**

3. **Заполните основные параметры:**
   ```
   Name: P6EPPMDataSource
   JNDI Name: jdbc/p6pdb
   Database Type: (выберите ваш тип БД)
   ```

4. **Нажмите "Next"**

### Шаг 3: Настройка драйвера БД

**Для Oracle Database:**
```
Database Driver: *Oracle's Driver (Thin) for Service Connections; Versions:Any
```

**Для Microsoft SQL Server:**
```
Database Driver: *Microsoft's SQL Server Driver
```

Нажмите "Next"

### Шаг 4: Параметры транзакций
```
○ Supports Global Transactions
○ One-Phase Commit
```
Нажмите "Next"

### Шаг 5: Параметры подключения к БД

**Заполните данные из толстого клиента:**

```
Database Name: PMDB (или ваше имя БД)
Host Name: localhost (или ваш сервер БД)
Port: 1433 (для MSSQL) или 1521 (для Oracle)
Database User Name: p6user (пользователь БД из толстого клиента)
Password: [пароль пользователя БД]
Confirm Password: [повторите пароль]
```

Нажмите "Next"

### Шаг 6: Тест подключения

1. **Нажмите "Test Configuration"**
2. **Если тест успешен** - появится сообщение "Connection test succeeded"
3. **Если ошибка** - проверьте:
   - Доступность БД с сервера WebLogic
   - Правильность логина/пароля
   - Настройки сети и firewall

### Шаг 7: Выбор целевого сервера

1. **Выберите сервер** для развертывания Data Source
2. **Обычно:** AdminServer или ваш Managed Server
3. **Нажмите "Finish"**

## Настройка P6 EPPM приложения

### Шаг 8: Развертывание P6 Web Application

1. **В левом меню:** Deployments
2. **Нажмите "Install"**
3. **Выберите путь к P6 EAR/WAR файлу:**
   ```
   Обычно в: C:\Oracle\Middleware\P6_EPPM\deployments\
   ```
4. **Выберите "Install this deployment as an application"**
5. **Нажмите "Next"**

### Шаг 9: Настройка контекста приложения

1. **Укажите контекстный корень:**
   ```
   Context Root: /p6
   ```

2. **Настройте параметры безопасности:**
   - Выберите созданный Data Source
   - Настройте security realm при необходимости

### Шаг 10: Активация изменений

1. **После создания Data Source** нажмите "Activate Changes"
2. **Перезапустите сервер** если требуется

## Проверка настройки

### Проверка Data Source:

1. **В Administration Console:** Services → Data Sources
2. **Найдите ваш P6EPPMDataSource**
3. **Проверьте статус:** "Deployed successfully"

### Проверка подключения:

1. **Перейдите к Monitoring → Testing**
2. **Выберите ваш Data Source**
3. **Нажмите "Test"** - должно быть "Test successful"

### Проверка приложения:

1. **Откройте в браузере:**
   ```
   http://localhost:7001/p6
   или
   http://[сервер]:[порт]/p6
   ```

2. **Должна открыться страница входа P6 EPPM**

## Решение распространенных проблем

### Проблема: "Connection refused"
**Решение:**
- Проверьте доступность БД с сервера WebLogic
- Убедитесь, что БД запущена
- Проверьте настройки firewall

### Проблема: "Invalid username/password"
**Решение:**
- Проверьте логин/пароль в толстом клиенте
- Убедитесь, что пользователь существует в БД
- Проверьте права доступа пользователя

### Проблема: "JNDI name not found"
**Решение:**
- Убедитесь, что JNDI имя совпадает в Data Source и настройках приложения
- Перезапустите сервер

## Дополнительные настройки

### Настройка Connection Pool:

1. **В Data Source → Connection Pool**
2. **Рекомендуемые параметры для P6:**
   ```
   Initial Capacity: 5
   Maximum Capacity: 50
   Capacity Increment: 5
   ```

### Настройка мониторинга:

1. **В Data Source → Monitoring**
2. **Включите статистику использования**
3. **Настройте оповещения при высокой нагрузке**

После успешной настройки ваша БД из толстого клиента будет доступна через веб-интерфейс P6 EPPM, и пользователи смогут работать с проектами через браузер.

**НЕТ, не нужен администратор БД!** Использование администратора - это серьезная ошибка безопасности.

## Почему НЕ нужно использовать администратора:

### ⚠️ Риски использования admin-пользователя:
- **Полный доступ ко всей БД** - нарушение принципа минимальных привилегий
- **Безопасность** - компрометация ведет к полному контролю над БД
- **Аудит** - невозможно отследить действия конкретного приложения
- **Производительность** - случайное изменение системных настроек

## Правильный подход: Создание отдельного пользователя для P6 EPPM

### Шаг 1: Создание специализированного пользователя в SQL Server

```sql
-- Подключитесь к SQL Server с правами администратора
-- Создайте логин для P6 Web Application
CREATE LOGIN p6_web_user WITH PASSWORD = 'StrongPassword123!'
GO

-- Создайте пользователя в базе PMDB
USE PMDB
GO
CREATE USER p6_web_user FOR LOGIN p6_web_user
GO
```

### Шаг 2: Назначение минимально необходимых прав

```sql
USE PMDB
GO

-- Базовые права для работы P6 EPPM
GRANT CONNECT TO p6_web_user
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO p6_web_user
GRANT EXECUTE ON SCHEMA::dbo TO p6_web_user

-- Дополнительные права которые могут потребоваться
GRANT VIEW DEFINITION TO p6_web_user
```

### Шаг 3: Проверка пользователя из толстого клиента

**Посмотрите какого пользователя использует толстый клиент:**
```sql
-- Запустите в контексте вашей БД PMDB
SELECT 
    SYSTEM_USER AS current_user,
    ORIGINAL_LOGIN() AS original_login,
    USER_NAME() AS database_user
```

## Какие пользователи обычно есть в P6 EPPM:

### 1. **Пользователь для толстого клиента** (P6 Professional)
- Обычно: `pubuser`, `pmdb`, `p6user`
- Имеет права на чтение/запись в схеме P6

### 2. **Пользователь для веб-приложения** (WebLogic)
- Должен быть отдельным: `p6_web_user`, `p6appuser`
- Те же права что у пользователя толстого клиента

### 3. **Администратор БД** (ТОЛЬКО для администрирования)
- `sa`, `admin` - НЕ ИСПОЛЬЗОВАТЬ В ПРИЛОЖЕНИИ!

## Как определить правильного пользователя:

### Из толстого клиента P6 Professional:
1. **Откройте P6 Professional**
2. **Файл → Информация о базе данных**
3. **Посмотрите "Database User"**

### Из конфигурационных файлов:
```
Ищите в:
C:\Program Files\Oracle\Primavera P6\P6 Professional\database.properties

Содержимое:
database.user=pubuser
database.password=encrypted_password
```

### Через SQL запрос (если есть доступ к БД):
```sql
-- Посмотреть активные подключения к P6 базе
SELECT 
    login_name,
    program_name,
    host_name
FROM sys.dm_exec_sessions 
WHERE database_id = DB_ID('PMDB')
AND program_name LIKE '%P6%'
```

## Правильная настройка в WebLogic:

### В Data Source укажите:
```
Database User Name: pubuser (или пользователь из толстого клиента)
Password: [пароль этого пользователя]
```

### Если нужно создать нового пользователя:
```sql
-- Создайте идентичного пользователя
CREATE LOGIN p6_web_user WITH PASSWORD = 'WebPassword123!'
USE PMDB
CREATE USER p6_web_user FOR LOGIN p6_web_user

-- Скопируйте права от существующего пользователя
EXEC sp_addrolemember 'db_owner', 'p6_web_user'
-- ИЛИ более безопасно:
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO p6_web_user
```

## Проверка правильности настройки:

1. **Тест подключения в WebLogic** - должен пройти успешно
2. **Попробуйте войти в P6 через веб** - должна открыться главная страница
3. **Проверьте логи** - не должно быть ошибок прав доступа

**Итог:** Используйте того же пользователя, что и в толстом клиенте, или создайте нового с такими же правами. Администратор БД не нужен и опасен для работы приложения.

user=pubuser7
url=jdbc:microsoft:sqlserver://prim-db-srv-07.novaenergies.local:1433
selectMethod=cursor
dataSourceName=SQL2000JDBC
userName=pubuser7
databaseName=Project_R
serverName=prim-db-srv-07.novaenergies.local