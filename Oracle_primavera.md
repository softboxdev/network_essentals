
## Архитектура Oracle Primavera P6 EPPM R8.3

### Основные компоненты системы

```mermaid
graph TB
    A[P6 Web Client] --> B[P6 Web Services]
    C[P6 Professional Client] --> D[P6 Database]
    B --> D
    E[P6 Progress Reporter] --> B
    F[P6 Integration API] --> B
    
    B --> G[Application Server<br/>WebLogic/WebSphere]
    G --> D[(Oracle Database<br/>SQL Server)]
    
    H[Batch Services] --> D
    I[P6 Reports] --> D
```

## Диаграммы последовательности

### 1. Последовательность входа пользователя в систему

```mermaid
sequenceDiagram
    participant U as Пользователь
    participant WC as P6 Web Client
    participant WS as P6 Web Services
    participant DB as P6 Database
    participant AD as Active Directory
    
    U->>WC: Запрос страницы входа
    WC->>WS: GET /login
    WS->>WC: Возврат формы входа
    
    U->>WC: Ввод учетных данных
    WC->>WS: POST /authenticate
    WS->>AD: Проверка учетных данных
    AD->>WS: Результат аутентификации
    
    alt Успешная аутентификация
        WS->>DB: Запрос прав пользователя
        DB->>WS: Данные пользователя и права
        WS->>WC: Токен сессии + данные пользователя
        WC->>U: Перенаправление на главную страницу
    else Ошибка аутентификации
        WS->>WC: Ошибка аутентификации
        WC->>U: Сообщение об ошибке
    end
```

### 2. Последовательность загрузки проекта

```mermaid
sequenceDiagram
    participant U as Пользователь
    participant WC as P6 Web Client
    participant WS as P6 Web Services
    participant DB as P6 Database
    participant Cache as Кэш сессии
    
    U->>WC: Запрос списка проектов
    WC->>WS: GET /api/projects
    WS->>DB: SELECT FROM PROJPROJECT
    DB->>WS: Данные проектов
    WS->>WC: Список проектов (JSON)
    WC->>U: Отображение списка проектов
    
    U->>WC: Выбор проекта для загрузки
    WC->>WS: GET /api/projects/{id}/details
    WS->>DB: Запрос основных данных проекта
    DB->>WS: Данные проекта (WBS, задачи)
    
    WS->>DB: Запрос ресурсов проекта
    DB->>WS: Данные ресурсов
    
    WS->>DB: Запрос связей задач
    DB->>WS: Данные связей
    
    WS->>WC: Полные данные проекта
    WC->>Cache: Сохранение в кэш сессии
    WC->>U: Отображение проекта в интерфейсе
```

### 3. Последовательность обновления прогресса задачи

```mermaid
sequenceDiagram
    participant U as Пользователь
    participant WC as P6 Web Client
    participant WS as P6 Web Services
    participant DB as P6 Database
    participant Val as Валидатор бизнес-правил
    participant Calc as Движок пересчета
    
    U->>WC: Изменение прогресса задачи
    WC->>Val: Локальная валидация
    Val->>WC: Результат валидации
    
    U->>WC: Сохранение изменений
    WC->>WS: PUT /api/tasks/{id}/progress
    WS->>Val: Серверная валидация
    Val->>WS: Результат валидации
    
    alt Валидация успешна
        WS->>DB: BEGIN TRANSACTION
        WS->>DB: UPDATE TASKPROGRESS
        DB->>WS: Подтверждение обновления
        
        WS->>Calc: Запрос пересчета расписания
        Calc->>DB: Пересчет критического пути
        Calc->>DB: Обновление дат задач
        DB->>Calc: Результаты пересчета
        
        WS->>DB: COMMIT TRANSACTION
        WS->>WC: Успешное обновление + новые даты
        WC->>U: Обновление интерфейса
    else Ошибка валидации
        WS->>WC: Ошибка с описанием
        WC->>U: Сообщение об ошибке
    end
```

### 4. Последовательность генерации отчета

```mermaid
sequenceDiagram
    participant U as Пользователь
    participant WC as P6 Web Client
    participant WS as P6 Web Services
    participant DB as P6 Database
    participant RS as Reporting Services
    participant BR as Business Intelligence Publisher
    
    U->>WC: Запрос создания отчета
    WC->>WS: GET /api/reports/templates
    WS->>DB: Запрос шаблонов отчетов
    DB->>WS: Список шаблонов
    WS->>WC: Доступные шаблоны
    
    U->>WC: Выбор шаблона и параметров
    WC->>WS: POST /api/reports/generate
    WS->>DB: Запрос данных для отчета
    DB->>WS: Данные проекта/задач/ресурсов
    
    WS->>RS: Передача данных и параметров
    RS->>BR: Генерация отчета в BI Publisher
    BR->>RS: Сгенерированный отчет (PDF/Excel)
    
    RS->>WS: Ссылка на отчет
    WS->>WC: URL для скачивания
    WC->>U: Отображение ссылки на отчет
```

### 5. Последовательность интеграции с внешними системами

```mermaid
sequenceDiagram
    participant ES as Внешняя система
    participant API as P6 Integration API
    participant WS as P6 Web Services
    participant Val as Валидатор данных
    participant DB as P6 Database
    participant Q as Очередь сообщений
    
    ES->>API: SOAP/REST запрос (XML/JSON)
    API->>Val: Валидация структуры данных
    Val->>API: Результат валидации
    
    alt Структура корректна
        API->>Q: Помещение в очередь
        Q->>WS: Извлечение сообщения
        
        WS->>Val: Бизнес-валидация
        Val->>WS: Результат валидации
        
        alt Бизнес-правила соблюдены
            WS->>DB: BEGIN TRANSACTION
            WS->>DB: Вставка/обновление данных
            DB->>WS: Подтверждение операции
            WS->>DB: COMMIT TRANSACTION
            WS->>API: Успешный ответ
        else Нарушение бизнес-правил
            WS->>API: Ошибка валидации
        end
        
        API->>ES: Ответ с результатом
    else Ошибка структуры
        API->>ES: Ошибка формата данных
    end
```

### 6. Архитектура базы данных P6

```mermaid
erDiagram
    PROJPROJECT ||--o{ PROJWBS : contains
    PROJWBS ||--o{ TASK : contains
    TASK ||--o{ TASKPRED : has_predecessors
    TASK ||--o{ TASKSUCC : has_successors
    TASK ||--o{ TASKRSC : has_resources
    RSRC ||--o{ TASKRSC : assigned_to
    PROJECT ||--o{ BASELINE : has_baselines
    TASK ||--o{ TASKPROG : has_progress
    USER ||--o{ USESSION : has_sessions
    
    PROJPROJECT {
        bigint project_id PK
        varchar project_name
        date start_date
        date finish_date
    }
    
    PROJWBS {
        bigint wbs_id PK
        bigint project_id FK
        varchar wbs_name
    }
    
    TASK {
        bigint task_id PK
        bigint wbs_id FK
        varchar task_name
        date start_date
        date finish_date
        float complete_percent
    }
    
    RSRC {
        bigint rsrc_id PK
        varchar rsrc_name
        varchar rsrc_type
    }
```

## Ключевые особенности архитектуры:

1. **Многоуровневая архитектура** с разделением на клиентский, серверный и базу данных уровни
2. **Сервис-ориентированная архитектура** через P6 Web Services
3. **Поддержка различных клиентов**: Web, Professional, Mobile
4. **Интеграция через API** для связи с внешними системами
5. **Сложная бизнес-логика** с валидацией и движком пересчета расписания
6. **Масштабируемость** через кэширование и очереди сообщений

Эта архитектура обеспечивает надежную работу системы управления проектами с поддержкой сложных вычислений расписания и интеграционных возможностей.
