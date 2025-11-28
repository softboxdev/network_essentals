# Диаграммы последовательности архитектуры ALD Pro, FreeIPA и Active Directory

## 1. Общая архитектура интеграции систем

```mermaid
graph TB
    subgraph "Внешняя инфраструктура"
        INTERNET[Интернет]
        EXTERNAL_DNS[Внешние DNS серверы]
    end

    subgraph "Периметр безопасности"
        FIREWALL[Фаервол]
        ROUTER[Маршрутизатор]
        VPN[VPN шлюз]
    end

    subgraph "Российские ОТС и СЗИ"
        subgraph "Домен ALD Pro (Основной)"
            ALD_DC[ALD Domain Controller<br/>Astra Linux SE]
            ALD_DNS[ALD DNS]
            ALD_DHCP[ALD DHCP]
            ALD_CA[Центр сертификации]
        end

        subgraph "Домен FreeIPA (Вспомогательный)"
            FREEIPA_DC[FreeIPA Server<br/>RED OS 8]
            FREEIPA_DNS[FreeIPA DNS]
            FREEIPA_CA[FreeIPA CA]
        end

        subgraph "Active Directory (Легаси)"
            AD_DC[AD Domain Controller<br/>Windows Server 2019]
            AD_DNS[AD DNS]
            AD_DHCP[AD DHCP]
        end
    end

    subgraph "Клиентские устройства"
        ALD_CLIENT[Клиент Astra Linux<br/>с СЗИ]
        LINUX_CLIENT[Клиент RED OS/Alt]
        WIN_CLIENT[Клиент Windows 10/11]
        MOBILE[Мобильные устройства]
    end

    subgraph "Служебные соединения"
        ALD_DC -->|Доверие| AD_DC
        ALD_DC -->|Доверие| FREEIPA_DC
        FREEIPA_DC -->|Доверие| AD_DC
        
        ALD_DC -->|Синхронизация<br/>пользователей| FREEIPA_DC
        ALD_DC -->|Миграция данных| AD_DC
    end

    FIREWALL --> INTERNET
    FIREWALL --> ALD_DC
    FIREWALL --> FREEIPA_DC
    FIREWALL --> AD_DC
    
    ALD_CLIENT --> ALD_DC
    LINUX_CLIENT --> FREEIPA_DC
    WIN_CLIENT --> AD_DC
```

## 2. Процесс аутентификации пользователя в комплексной системе

```mermaid
sequenceDiagram
    participant U as Пользователь
    participant C as Клиент Astra Linux
    participant A as ALD Controller
    participant F as FreeIPA
    participant AD as Active Directory
    participant S as СЗИ (Peredatchik)

    Note over U, S: Сценарий 1: Локальный пользователь ALD
    U->>C: Ввод учетных данных
    C->>A: Запрос аутентификации
    A->>A: Проверка в локальной БД
    A->>S: Верификация мандатного уровня
    S->>A: Подтверждение уровня доступа
    A->>C: Успешная аутентификация
    C->>U: Доступ предоставлен

    Note over U, S: Сценарий 2: Пользователь FreeIPA
    U->>C: Ввод login@freeipa.local
    C->>A: Запрос аутентификации
    A->>F: Проверка через доверие
    F->>F: Валидация учетных данных
    F->>A: Подтверждение аутентификации
    A->>S: Проверка мандатных атрибутов
    S->>A: Установка уровня целостности
    A->>C: Успешная аутентификация
    C->>U: Доступ предоставлен

    Note over U, S: Сценарий 3: Пользователь AD (легаси)
    U->>C: Ввод login@ad.local
    C->>A: Запрос аутентификации
    A->>AD: Проверка через доверие
    AD->>AD: Валидация в Active Directory
    AD->>A: Подтверждение аутентификации
    A->>S: Применение политик СЗИ
    S->>A: Назначение временного УЦ
    A->>C: Ограниченный доступ
    C->>U: Доступ с ограничениями
```

## 3. Процесс управления пользователями и группами

```mermaid
sequenceDiagram
    participant Admin as Администратор
    participant Web as Web-интерфейс ALD
    participant ALD as ALD Controller
    participant FreeIPA as FreeIPA
    participant AD as Active Directory
    participant DB as База данных LDAP

    Admin->>Web: Создание нового пользователя
    Web->>ALD: API запрос на создание
    ALD->>DB: Запись в LDAP ALD
    DB->>ALD: Подтверждение создания
    
    alt Настройка синхронизации с FreeIPA
        ALD->>FreeIPA: Создание shadow-записи
        FreeIPA->>FreeIPA: Валидация данных
        FreeIPA->>ALD: Подтверждение синхронизации
    end

    alt Миграция из AD
        ALD->>AD: Запрос данных пользователя
        AD->>ALD: Передача атрибутов
        ALD->>ALD: Трансформация атрибутов
        ALD->>DB: Запись мигрированных данных
    end

    Note over ALD, DB: Применение политик безопасности
    ALD->>ALD: Назначение мандатного уровня
    ALD->>ALD: Применение групповых политик
    ALD->>ALD: Настройка квот доступа
    
    ALD->>Web: Подтверждение операции
    Web->>Admin: Пользователь создан
```

## 4. Процесс репликации и синхронизации данных

```mermaid
sequenceDiagram
    participant ALD1 as ALD DC (Основной)
    participant ALD2 as ALD DC (Резервный)
    participant FreeIPA as FreeIPA Server
    participant AD as Active Directory
    participant Monitor as Мониторинг

    Note over ALD1, AD: Ежедневная синхронизация 02:00
    loop Каждые 24 часа
        ALD1->>AD: Запрос изменений пользователей
        AD->>ALD1: Выгрузка дельты изменений
        ALD1->>ALD1: Обработка и трансформация
        ALD1->>FreeIPA: Синхронизация изменений
        FreeIPA->>ALD1: Подтверждение приема
    end

    Note over ALD1, ALD2: Репликация в реальном времени
    ALD1->>ALD2: Многомастерная репликация
    ALD2->>ALD1: Подтверждение получения
    ALD1->>Monitor: Статус репликации
    ALD2->>Monitor: Статус репликации

    Note over ALD1, FreeIPA: Синхронизация политик
    ALD1->>FreeIPA: Передача политик паролей
    FreeIPA->>ALD1: Подтверждение применения
    FreeIPA->>ALD1: Статистика использования

    Note over ALD1, AD: Мониторинг доверительных отношений
    ALD1->>AD: Проверка работоспособности trust
    AD->>ALD1: Ответ о статусе
    ALD1->>Monitor: Логирование состояния
```

## 5. Процесс авторизации доступа к ресурсам

```mermaid
sequenceDiagram
    participant U as Пользователь
    participant C as Клиентское устройство
    participant ALD as ALD Controller
    participant SZI as СЗИ (Peredatchik)
    participant RES as Ресурс (файл/сервис)
    participant AUDIT as Подсистема аудита

    U->>C: Запрос доступа к ресурсу
    C->>ALD: Запрос авторизации
    ALD->>ALD: Проверка групповых политик
    
    alt Локальный пользователь ALD
        ALD->>SZI: Запрос мандатного уровня
        SZI->>ALD: Уровень целостности пользователя
        ALD->>ALD: Сравнение с уровнем ресурса
        ALD->>C: Разрешение/запрет доступа
    end

    alt Пользователь FreeIPA
        ALD->>ALD: Проверка RBAC ролей
        ALD->>ALD: Валидация временных привилегий
        ALD->>C: Доступ с ограничениями
    end

    alt Пользователь AD
        ALD->>ALD: Применение строгих ограничений
        ALD->>C: Доступ только к разрешенным ресурсам
    end

    C->>RES: Предоставление доступа
    RES->>AUDIT: Логирование операции
    AUDIT->>ALD: Уведомление о событии
    
    Note over U, AUDIT: При нарушении политики
    ALD->>AUDIT: Аварийное событие
    AUDIT->>AUDIT: Активация реакции на инцидент
```

## 6. Процесс миграции пользователей из AD в ALD

```mermaid
sequenceDiagram
    participant Admin as Администратор
    participant MT as Миграционный инструмент
    participant ALD as ALD Controller
    participant AD as Active Directory
    participant FreeIPA as FreeIPA
    participant Audit as Аудит безопасности

    Admin->>MT: Запуск процесса миграции
    MT->>AD: Запрос списка пользователей
    AD->>MT: Выгрузка данных пользователей
    
    loop Для каждого пользователя
        MT->>MT: Трансформация атрибутов
        MT->>MT: Генерация временного пароля
        MT->>ALD: Создание учетной записи
        ALD->>ALD: Применение политик СЗИ
        ALD->>ALD: Назначение мандатного уровня
        ALD->>FreeIPA: Создание зеркальной записи
        FreeIPA->>ALD: Подтверждение
        ALD->>Audit: Логирование миграции
    end

    MT->>AD: Отключение исходных учетных записей
    AD->>MT: Подтверждение отключения
    
    Note over MT, ALD: Тестирование миграции
    Admin->>ALD: Проверка входа мигрированных пользователей
    ALD->>Admin: Результаты тестирования
    
    MT->>Admin: Отчет о миграции
    Audit->>Admin: Отчет о событиях безопасности
```

## 7. Архитектура резервного копирования и восстановления

```mermaid
sequenceDiagram
    participant Backup as Система резервного копирования
    participant ALD as ALD Controller
    participant FreeIPA as FreeIPA Server
    participant AD as Active Directory
    participant Storage as Хранилище备份
    participant Monitor as Мониторинг

    Note over Backup, Storage: Ежедневное резервное копирование 03:00
    loop Каждые 24 часа
        Backup->>ALD: Инициация бэкапа
        ALD->>ALD: Создание снепшота LDAP
        ALD->>Backup: Передача данных конфигурации
        Backup->>FreeIPA: Запрос бэкапа
        FreeIPA->>Backup: Данные FreeIPA
        Backup->>AD: Запрос бэкапа (только чтение)
        AD->>Backup: Экспорт критичных данных
        Backup->>Storage: Запись бэкапа
        Storage->>Backup: Подтверждение записи
        Backup->>Monitor: Статус выполнения
    end

    Note over Backup, ALD: Восстановление по требованию
    participant Admin as Администратор
    Admin->>Backup: Запрос восстановления
    Backup->>Storage: Поиск нужного бэкапа
    Storage->>Backup: Предоставление данных
    Backup->>ALD: Восстановление конфигурации
    ALD->>ALD: Применение бэкапа
    ALD->>Backup: Подтверждение восстановления
    Backup->>Admin: Уведомление о завершении
```

## 8. Мониторинг и управление инцидентами

```mermaid
sequenceDiagram
    participant SIEM as SIEM система
    participant ALD as ALD Controller
    participant FreeIPA as FreeIPA
    participant AD as Active Directory
    participant SZI as СЗИ
    participant Admin as Администратор
    participant SOC as Центр мониторинга

    ALD->>SIEM: Логи аутентификации
    FreeIPA->>SIEM: Логи доступа
    AD->>SIEM: События безопасности
    SZI->>SIEM: События СЗИ
    
    SIEM->>SIEM: Корреляция событий
    alt Обнаружение аномалии
        SIEM->>SOC: Предупреждение об инциденте
        SOC->>Admin: Уведомление
        Admin->>ALD: Блокировка учетной записи
        ALD->>FreeIPA: Синхронизация блокировки
        ALD->>AD: Уведомление о инциденте
        ALD->>SZI: Активация усиленного контроля
    end

    Note over SOC, Admin: Расследование инцидента
    SOC->>SIEM: Запрос детальных логов
    SIEM->>SOC: Предоставление данных
    SOC->>Admin: Рекомендации по реагированию
    Admin->>ALD: Применение корректирующих действий
```

## Ключевые особенности архитектуры для российской компании:

1. **Централизация управления** через ALD Pro как основной контроллер
2. **Поддержка легаси-систем** через доверительные отношения
3. **Соответствие требованиям регуляторов** (ФСТЭК, ФСБ)
4. **Мандатный контроль доступа** интегрирован во все процессы
5. **Поэтапная миграция** с сохранением функциональности
6. **Мониторинг и аудит** всех операций безопасности
7. **Резервное копирование** критичных компонентов
8. **Интеграция с отечественными СЗИ**