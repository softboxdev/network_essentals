Подробная инструкция по созданию Microsoft SQL Server через P6 EPPM Configuration Wizard с указанием всех портов и путей:

## Предварительные требования

### 1. Подготовка SQL Server
- **Порт SQL Server:** 1433 (стандартный)
- **Версия SQL Server:** 2016, 2017, 2019 или 2022
- **Аутентификация:** Mixed Mode (SQL Server and Windows)

### 2. Подготовка WebLogic (из вашего config.xml)
- **Домен:** PrimaveraP6EPPM
- **Admin Server порт:** 7001
- **P6 Server порт:** 8203
- **Java Home:** C:/Program Files/Java/jdk1.8.0_181
- **P6 Home:** C:/P6EPPM/p6

## Пошаговая инструкция

### Запуск P6 EPPM Configuration Wizard

1. **Найдите и запустите Configuration Wizard:**
   ```
   Путь: C:\P6EPPM\p6\bin\p6cfgwb.exe
   Или через меню: Пуск → Oracle Primavera P6 → P6 EPPM Configuration Wizard
   ```

2. **Выберите тип конфигурации:**
   ```
   ○ New Configuration
   ○ Upgrade Existing Configuration
   ● Manage Existing Configuration
   ```
   Выберите **"Manage Existing Configuration"**

### Настройка базы данных

3. **Database Configuration Screen:**
   ```
   Database Type: Microsoft SQL Server
   Database Host: localhost\SQLEXPRESS (или ваш сервер)
   Port: 1433
   Service Name/SID: [оставьте пустым для SQL Server]
   ```

4. **Authentication Method:**
   ```
   ● Windows Authentication
   ○ SQL Server Authentication
   ```
   Или если используете SQL Auth:
   ```
   ○ Windows Authentication  
   ● SQL Server Authentication
     Username: sa (или ваш пользователь)
     Password: [ваш пароль]
   ```

5. **Database Parameters:**
   ```
   Database Name: PMDB
   Unicode: Yes (рекомендуется)
   Schema Owner: dbo
   ```

### Настройка параметров домена

6. **Domain Configuration:**
   ```
   Domain Name: PrimaveraP6EPPM
   Domain Location: C:\Oracle\Middleware\Oracle_Home\user_projects\domains\PrimaveraP6EPPM
   Application Location: C:\P6EPPM\p6
   ```

7. **Admin Server Configuration:**
   ```
   Server Name: AdminServer
   Listen Address: [оставьте пустым для всех интерфейсов]
   Listen Port: 7001
   SSL Listen Port: 7002
   ```

8. **Managed Server Configuration (P6):**
   ```
   Server Name: P6
   Listen Address: [оставьте пустым]
   Listen Port: 8203
   SSL Listen Port: 8204
   ```

### Настройка Java и памяти

9. **Java Settings:**
   ```
   Java Home: C:\Program Files\Java\jdk1.8.0_181
   Java Vendor: Oracle
   ```

10. **JVM Options:**
    ```
    -Dprimavera.bootstrap.home=C:/P6EPPM/p6/../p6
    -Djavax.xml.stream.XMLInputFactory=com.ctc.wstx.stax.WstxInputFactory
    -XX:MaxPermSize=512m
    -Xms512m
    -Xmx1024m
    ```

### Создание базы данных

11. **Database Creation:**
    ```
    Create New Database: Yes
    Database File Path: C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\
    Log File Path: C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\
    
    Data File Name: PMDB.mdf
    Log File Name: PMDB.ldf
    ```

### Настройка безопасности

12. **Security Configuration:**
    ```
    Admin Username: weblogic
    Admin Password: [ваш пароль weblogic]
    Confirm Password: [подтвердите пароль]
    
    Node Manager Username: weblogic
    Node Manager Password: [пароль node manager]
    ```

### Развертывание приложения

13. **Application Deployment:**
    ```
    Deploy P6 Web Application: Yes
    Virtual Directory: /p6
    EAR File Path: C:\P6EPPM\p6\p6.ear
    Target Server: P6
    ```

## Полная конфигурация параметров

### Параметры SQL Server:
```ini
# Database Configuration
db.type=SQLSERVER
db.host=localhost\SQLEXPRESS
db.port=1433
db.name=PMDB
db.unicode=true
db.schema.owner=dbo

# Authentication
db.auth.type=WINDOWS  # или SQLSERVER
db.username=sa
db.password=YourPassword123!

# File Paths
db.datafile.path=C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\PMDB.mdf
db.logfile.path=C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\PMDB.ldf
```

### Параметры WebLogic Domain:
```ini
# Domain Settings
domain.name=PrimaveraP6EPPM
domain.path=C:\Oracle\Middleware\Oracle_Home\user_projects\domains\PrimaveraP6EPPM

# Admin Server
admin.server.name=AdminServer
admin.server.port=7001
admin.server.ssl.port=7002

# Managed Server
managed.server.name=P6
managed.server.port=8203
managed.server.ssl.port=8204

# Java Settings
java.home=C:\Program Files\Java\jdk1.8.0_181
java.vendor=Oracle
jvm.args=-Xms512m -Xmx1024m -XX:MaxPermSize=512m
```

### Параметры приложения P6:
```ini
# P6 Application
p6.home=C:\P6EPPM\p6
p6.ear.path=C:\P6EPPM\p6\p6.ear
p6.web.context=/p6
p6.bootstrap.home=C:\P6EPPM\p6
```

## Проверка конфигурации

### Проверка портов:
```cmd
# Проверка занятых портов
netstat -an | findstr 7001
netstat -an | findstr 8203
netstat -an | findstr 1433
```

### Проверка файловой структуры:
```cmd
# Проверка существующих путей
dir "C:\Program Files\Microsoft SQL Server\MSSQL15.SQLEXPRESS\MSSQL\DATA\"
dir "C:\P6EPPM\p6\"
dir "C:\Oracle\Middleware\Oracle_Home\user_projects\domains\PrimaveraP6EPPM\"
```

## Процесс выполнения Configuration Wizard

### Этапы выполнения:
1. **Валидация параметров** - проверка корректности введенных данных
2. **Создание базы данных** - создание PMDB в SQL Server
3. **Настройка домена** - обновление config.xml
4. **Развертывание приложения** - деплой p6.ear на сервер P6
5. **Завершение** - вывод отчета о выполнении

### Время выполнения:
- **Создание БД:** 10-15 минут
- **Настройка домена:** 5-10 минут  
- **Деплой приложения:** 15-20 минут
- **Общее время:** 30-45 минут

## Возможные проблемы и решения

### Проблема: "Cannot connect to database"
```sql
-- Проверка SQL Server
-- Запустите SQL Server Management Studio
-- Убедитесь что:
-- 1. SQL Server запущен
-- 2. TCP/IP протокол включен
-- 3. Порт 1433 доступен
```

### Проблема: "Port already in use"
```cmd
# Освобождение портов
netstat -ano | findstr :7001
taskkill /PID [PID] /F
```

### Проблема: "Insufficient disk space"
```cmd
# Проверка свободного места
dir C:\
# Требуется минимум 10GB свободного места
```

## Последующие шаги

### После успешной конфигурации:

1. **Запустите WebLogic Server:**
   ```
   C:\Oracle\Middleware\Oracle_Home\user_projects\domains\PrimaveraP6EPPM\startWebLogic.cmd
   ```

2. **Проверьте доступность:**
   ```
   WebLogic Console: http://localhost:7001/console
   P6 Web Access: http://localhost:8203/p6
   ```

3. **Войдите в систему:**
   ```
   Username: admin (или ваш пользователь P6)
   Password: [ваш пароль P6]
   ```

Эта инструкция учитывает вашу существующую конфигурацию домена и обеспечит корректную настройку Microsoft SQL Server для P6 EPPM.