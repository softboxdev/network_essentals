
---

# Простейшее веб-приложение на Python

## 📋 Что мы создадим?

Мы создадим веб-приложение, которое:
1. Запускает веб-сервер на вашем компьютере
2. Отвечает на запросы из браузера
3. Показывает разные страницы в зависимости от адреса
4. Умеет принимать данные из форм

---

## 🧠 Теория: как работает веб-приложение?

### Что такое веб-сервер?

Представьте, что ваш компьютер — это ресторан:
- **Веб-сервер** — это официант, который принимает заказы (запросы)
- **Браузер** — это клиент, который делает заказ
- **Страницы** — это блюда, которые официант приносит

### Как происходит обмен?

```
1. Браузер: "Привет! Дай мне страницу /" (GET-запрос)
2. Сервер: "OK, держи HTML-страницу" (HTTP-ответ)
3. Браузер: "Спасибо! Показываю пользователю"
```

### Что такое HTTP?

**HTTP** (HyperText Transfer Protocol) — это правила общения между браузером и сервером.

Запрос от браузера выглядит так:
```
GET /index.html HTTP/1.1
Host: localhost:8080
```

Ответ от сервера выглядит так:
```
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>...</html>
```

---

## 🔧 Инструменты

- **Python 3** — язык программирования
- **Модуль http.server** — встроенная библиотека для создания серверов
- **Терминал** — для запуска
- **Браузер** — для просмотра

---

## 📝 Часть 1: Самый простой сервер (5 строк кода)

### Код

Создайте файл `server.py` и напишите:

```python
# Импортируем модули для работы с HTTP-сервером
from http.server import HTTPServer, BaseHTTPRequestHandler

# Создаём класс-обработчик запросов
class MyHandler(BaseHTTPRequestHandler):
    # Этот метод вызывается при GET-запросе
    def do_GET(self):
        # Отправляем статус 200 (всё хорошо)
        self.send_response(200)
        # Указываем, что отправляем HTML
        self.send_header('Content-type', 'text/html')
        # Завершаем заголовки
        self.end_headers()
        # Отправляем HTML-страницу
        self.wfile.write(b'<h1>Hello, World!</h1>')

# Создаём сервер на порту 8080
server = HTTPServer(('localhost', 8080), MyHandler)

print('Сервер запущен на http://localhost:8080')
print('Нажмите Ctrl+C для остановки')

# Запускаем сервер (работает бесконечно)
server.serve_forever()
```

### Как запустить?

1. Откройте терминал
2. Перейдите в папку с файлом: `cd путь/к/папке`
3. Выполните: `python3 server.py`
4. Откройте браузер и перейдите по адресу: `http://localhost:8080`

### Что должно произойти?

Вы увидите большую надпись: **Hello, World!**

### Разбор кода построчно

```python
from http.server import HTTPServer, BaseHTTPRequestHandler
```
- `http.server` — модуль Python для создания веб-серверов
- `HTTPServer` — класс, который создаёт сам сервер
- `BaseHTTPRequestHandler` — класс-основа для обработки запросов

```python
class MyHandler(BaseHTTPRequestHandler):
```
- Создаём свой класс-обработчик
- Он наследуется от `BaseHTTPRequestHandler` (берёт все базовые функции)

```python
def do_GET(self):
```
- Этот метод вызывается, когда приходит GET-запрос
- GET — самый распространённый тип запроса (когда вы просто открываете страницу)

```python
self.send_response(200)
```
- Отправляем код ответа 200 ("OK" — всё хорошо)
- Другие коды: 404 (не найдено), 500 (ошибка), 403 (доступ запрещён)

```python
self.send_header('Content-type', 'text/html')
```
- Указываем, что отправляем HTML-документ
- Браузер поймёт, что это веб-страница

```python
self.end_headers()
```
- Завершаем отправку заголовков
- После этого начинаем отправлять содержимое

```python
self.wfile.write(b'<h1>Hello, World!</h1>')
```
- `wfile` — это "поток" для отправки данных клиенту
- `b'...'` — указывает, что это байты (так надо для отправки)
- Внутри — HTML-код

```python
server = HTTPServer(('localhost', 8080), MyHandler)
```
- Создаём сервер
- `localhost` — слушаем только локальные подключения
- `8080` — порт, на котором работает сервер
- `MyHandler` — используем наш обработчик

```python
server.serve_forever()
```
- Запускаем сервер и он работает бесконечно
- Ждёт запросы, обрабатывает их, отправляет ответы

---

## 📝 Часть 2: Отвечаем на разные адреса (15 строк)

### Код

Замените содержимое `server.py` на:

```python
from http.server import HTTPServer, BaseHTTPRequestHandler

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Печатаем в терминал, какой адрес запросили
        print('Запрошен путь:', self.path)

        # Отправляем статус 200
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()

        # Проверяем, какой путь запросили
        if self.path == '/':
            html = '<h1>Главная страница</h1><p>Добро пожаловать!</p>'
        elif self.path == '/about':
            html = '<h1>О нас</h1><p>Это страница о нас.</p>'
        elif self.path == '/time':
            import datetime
            now = datetime.datetime.now()
            html = f'<h1>Текущее время</h1><p>{now}</p>'
        else:
            # Если страница не найдена
            html = '<h1>404</h1><p>Страница не найдена</p>'
            self.send_response(404)  # Меняем статус на 404

        # Отправляем HTML
        self.wfile.write(html.encode('utf-8'))

server = HTTPServer(('localhost', 8080), MyHandler)
print('Сервер запущен на http://localhost:8080')
server.serve_forever()
```

### Как проверить?

1. Запустите: `python3 server.py`
2. Откройте в браузере:
   - `http://localhost:8080/` — главная
   - `http://localhost:8080/about` — о нас
   - `http://localhost:8080/time` — текущее время
   - `http://localhost:8080/anything` — страница 404

### Что нового?

```python
print('Запрошен путь:', self.path)
```
- `self.path` — содержит адрес, который запросил пользователь
- Например, для `http://localhost:8080/about` это будет `/about`

```python
if self.path == '/':
    html = '<h1>Главная страница</h1>'
elif self.path == '/about':
    html = '<h1>О нас</h1>'
```
- Проверяем путь и отправляем разный HTML

```python
self.send_response(404)  # Меняем статус на 404
```
- Если страница не найдена, отправляем статус 404

```python
html.encode('utf-8')
```
- Превращаем текст в байты
- `utf-8` — кодировка для поддержки русских букв

---

## 📝 Часть 3: Принимаем параметры из адресной строки

### Код

Замените содержимое на:

```python
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Разбираем URL на части
        parsed = urlparse(self.path)
        path = parsed.path
        params = parse_qs(parsed.query)

        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()

        if path == '/':
            html = '''
            <h1>Главная страница</h1>
            <p>Добро пожаловать!</p>
            <p><a href="/greeting?name=Вася">Сказать привет Васе</a></p>
            <p><a href="/greeting?name=Маша">Сказать привет Маше</a></p>
            '''
        elif path == '/greeting':
            # Получаем параметр name (если есть)
            name = params.get('name', ['Гость'])[0]
            html = f'<h1>Привет, {name}!</h1>'
        else:
            html = '<h1>404</h1><p>Страница не найдена</p>'
            self.send_response(404)

        self.wfile.write(html.encode('utf-8'))

server = HTTPServer(('localhost', 8080), MyHandler)
print('Сервер запущен на http://localhost:8080')
server.serve_forever()
```

### Что добавилось?

```python
from urllib.parse import urlparse, parse_qs
```
- Импортируем функции для разбора URL

```python
parsed = urlparse(self.path)
path = parsed.path          # Например: /greeting
params = parse_qs(parsed.query)  # Например: {'name': ['Вася']}
```
- `urlparse` разбивает URL на части
- `parse_qs` превращает параметры в словарь

```python
name = params.get('name', ['Гость'])[0]
```
- `params.get('name', ['Гость'])` — если параметр есть, берём его, иначе "Гость"
- `[0]` — берём первое значение (параметров может быть несколько)

### Как проверить?

1. `http://localhost:8080/greeting?name=Иван` → "Привет, Иван!"
2. `http://localhost:8080/greeting?name=Петя` → "Привет, Петя!"
3. `http://localhost:8080/greeting` → "Привет, Гость!"

---

## 📝 Часть 4: Форма для ввода данных

### Код

Замените на:

```python
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        params = parse_qs(parsed.query)

        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()

        if path == '/':
            html = '''
            <h1>Главная страница</h1>
            <p><a href="/form">Перейти к форме</a></p>
            '''
        elif path == '/form':
            # Показываем форму
            html = '''
            <h1>Форма ввода</h1>
            <form action="/result" method="GET">
                <p>Ваше имя: <input type="text" name="name"></p>
                <p>Ваш возраст: <input type="text" name="age"></p>
                <p><input type="submit" value="Отправить"></p>
            </form>
            <p><a href="/">На главную</a></p>
            '''
        elif path == '/result':
            # Показываем результат
            name = params.get('name', [''])[0]
            age = params.get('age', [''])[0]

            if name and age:
                html = f'''
                <h1>Результат</h1>
                <p>Привет, <b>{name}</b>!</p>
                <p>Тебе <b>{age}</b> лет.</p>
                <p><a href="/form">Вернуться к форме</a></p>
                <p><a href="/">На главную</a></p>
                '''
            else:
                html = '''
                <h1>Ошибка</h1>
                <p>Заполните все поля!</p>
                <p><a href="/form">Вернуться к форме</a></p>
                '''
        else:
            html = '<h1>404</h1><p>Страница не найдена</p>'
            self.send_response(404)

        self.wfile.write(html.encode('utf-8'))

server = HTTPServer(('localhost', 8080), MyHandler)
print('Сервер запущен на http://localhost:8080')
server.serve_forever()
```

### Что здесь важно?

```html
<form action="/result" method="GET">
```
- `action="/result"` — куда отправлять данные
- `method="GET"` — как отправлять (GET — данные в URL)

```html
<input type="text" name="name">
```
- `name="name"` — имя параметра
- В результате получится `?name=значение`

### Как проверить?

1. Откройте `http://localhost:8080/form`
2. Введите имя и возраст
3. Нажмите "Отправить"
4. Посмотрите на URL: там будут данные

---

## 📝 Часть 5: POST-запросы (отправка данных скрыто)

### Код

```python
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()

        if path == '/':
            html = '''
            <h1>Главная страница</h1>
            <p><a href="/form">Форма с GET</a></p>
            <p><a href="/form-post">Форма с POST</a></p>
            '''
        elif path == '/form':
            html = '''
            <h1>Форма с GET</h1>
            <form action="/result" method="GET">
                <p>Имя: <input type="text" name="name"></p>
                <p><input type="submit" value="Отправить"></p>
            </form>
            <p><a href="/">На главную</a></p>
            '''
        elif path == '/form-post':
            html = '''
            <h1>Форма с POST</h1>
            <form action="/result-post" method="POST">
                <p>Имя: <input type="text" name="name"></p>
                <p><input type="submit" value="Отправить"></p>
            </form>
            <p><a href="/">На главную</a></p>
            '''
        elif path == '/result':
            # GET - параметры в URL
            params = parse_qs(parsed.query)
            name = params.get('name', [''])[0]
            html = f'<h1>Результат GET</h1><p>Привет, {name}!</p>'
        else:
            html = '<h1>404</h1><p>Страница не найдена</p>'
            self.send_response(404)

        self.wfile.write(html.encode('utf-8'))

    def do_POST(self):
        """Обработка POST-запросов"""
        # Получаем длину данных
        content_length = int(self.headers.get('Content-Length', 0))

        # Читаем данные из тела запроса
        post_data = self.rfile.read(content_length).decode('utf-8')

        # Разбираем параметры
        params = parse_qs(post_data)
        name = params.get('name', [''])[0]

        # Отправляем ответ
        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()

        html = f'''
        <h1>Результат POST</h1>
        <p>Привет, {name}!</p>
        <p>Данные были отправлены скрыто (не видны в URL)</p>
        <p><a href="/">На главную</a></p>
        '''
        self.wfile.write(html.encode('utf-8'))

server = HTTPServer(('localhost', 8080), MyHandler)
print('Сервер запущен на http://localhost:8080')
server.serve_forever()
```

### Что нового?

```python
def do_POST(self):
```
- Метод для обработки POST-запросов

```python
content_length = int(self.headers.get('Content-Length', 0))
```
- Получаем размер данных из заголовка

```python
post_data = self.rfile.read(content_length).decode('utf-8')
```
- Читаем данные из тела запроса

### Разница между GET и POST

| GET | POST |
|-----|------|
| Данные в URL | Данные в теле запроса |
| Видно в адресной строке | Не видно в адресной строке |
| Можно сохранить в закладках | Нельзя сохранить |
| Ограниченный размер | Большой размер |
| Для получения данных | Для отправки данных |

---

## 📝 Часть 6: Полный код (финальная версия)

```python
# -*- coding: utf-8 -*-
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class MyHandler(BaseHTTPRequestHandler):
    """Обработчик HTTP-запросов"""

    def do_GET(self):
        """Обработка GET-запросов"""
        parsed = urlparse(self.path)
        path = parsed.path

        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()

        if path == '/':
            html = self.get_main_page()
        elif path == '/about':
            html = self.get_about_page()
        elif path == '/form':
            html = self.get_form_page('GET')
        elif path == '/form-post':
            html = self.get_form_page('POST')
        elif path == '/result':
            params = parse_qs(parsed.query)
            html = self.get_result_page(params, 'GET')
        else:
            html = self.get_404_page(path)
            self.send_response(404)

        self.wfile.write(html.encode('utf-8'))

    def do_POST(self):
        """Обработка POST-запросов"""
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8')
        params = parse_qs(post_data)

        self.send_response(200)
        self.send_header('Content-type', 'text/html; charset=utf-8')
        self.end_headers()

        html = self.get_result_page(params, 'POST')
        self.wfile.write(html.encode('utf-8'))

    def get_main_page(self):
        """Главная страница"""
        return '''
        <h1>🏠 Главная страница</h1>
        <ul>
            <li><a href="/about">О нас</a></li>
            <li><a href="/form">Форма с GET</a></li>
            <li><a href="/form-post">Форма с POST</a></li>
        </ul>
        '''

    def get_about_page(self):
        """Страница 'О нас'"""
        return '''
        <h1>📖 О нас</h1>
        <p>Это простое веб-приложение на Python.</p>
        <p><a href="/">На главную</a></p>
        '''

    def get_form_page(self, method):
        """Страница с формой"""
        return f'''
        <h1>📝 Форма ({method})</h1>
        <form action="/result" method="{method}">
            <p>Ваше имя: <input type="text" name="name"></p>
            <p><input type="submit" value="Отправить"></p>
        </form>
        <p><a href="/">На главную</a></p>
        '''

    def get_result_page(self, params, method):
        """Страница с результатом"""
        name = params.get('name', [''])[0]

        if name:
            return f'''
            <h1>✅ Результат ({method})</h1>
            <p>Привет, <b>{name}</b>!</p>
            <p>Данные отправлены через {method}</p>
            <p><a href="/">На главную</a></p>
            '''
        else:
            return '''
            <h1>⚠️ Ошибка</h1>
            <p>Вы не ввели имя!</p>
            <p><a href="/form">Вернуться к форме</a></p>
            '''

    def get_404_page(self, path):
        """Страница 404"""
        return f'''
        <h1>❌ 404</h1>
        <p>Страница "{path}" не найдена</p>
        <p><a href="/">На главную</a></p>
        '''

def run_server(port=8080):
    """Запуск сервера"""
    server = HTTPServer(('localhost', port), MyHandler)
    print('=' * 50)
    print('🚀 Сервер запущен!')
    print(f'📡 Адрес: http://localhost:{port}')
    print('📄 Доступные страницы:')
    print('  /          - Главная')
    print('  /about     - О нас')
    print('  /form      - Форма (GET)')
    print('  /form-post - Форма (POST)')
    print('=' * 50)
    print('🛑 Для остановки нажмите Ctrl+C')
    print('=' * 50)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\n⏹ Сервер остановлен')
        server.server_close()

if __name__ == '__main__':
    run_server()
```

---

## 📋 Инструкция по запуску

### Шаг 1: Создайте файл

Откройте любой текстовый редактор и создайте файл `server.py`

### Шаг 2: Скопируйте код

Скопируйте финальный код из Части 6 в файл

### Шаг 3: Сохраните файл

Сохраните в домашней папке или в отдельной папке

### Шаг 4: Откройте терминал

- В Linux: `Ctrl+Alt+T`
- В Windows: Win+R → `cmd`
- В macOS: Cmd+Space → `Terminal`

### Шаг 5: Перейдите в папку с файлом

```bash
cd путь/к/папке
```

### Шаг 6: Запустите сервер

```bash
python3 server.py
```

### Шаг 7: Откройте браузер

Введите в адресной строке: `http://localhost:8080`

### Шаг 8: Изучайте

Переходите по ссылкам, заполняйте формы, смотрите результат

### Шаг 9: Остановите сервер

Нажмите `Ctrl+C` в терминале

---

## 🔍 Пошаговый разбор кода (для абсолютных новичков)

### Что такое `from ... import ...`?

```python
from http.server import HTTPServer, BaseHTTPRequestHandler
```

Это как сказать: "Из библиотеки `http.server` возьми классы `HTTPServer` и `BaseHTTPRequestHandler` и дай мне их использовать".

### Что такое класс?

```python
class MyHandler(BaseHTTPRequestHandler):
```

Класс — это как "чертёж" для создания объектов. Мы создаём свой класс-обработчик, который умеет обрабатывать запросы.

### Что такое метод?

```python
def do_GET(self):
```

Метод — это функция внутри класса. `do_GET` вызывается, когда приходит GET-запрос.

### Что такое `self`?

`self` — это ссылка на сам объект. Через `self` мы обращаемся к методам и свойствам объекта.

### Что такое `self.send_response(200)`?

Отправляет код ответа. 200 означает "OK".

### Что такое `self.send_header(...)`?

Отправляет заголовок. Заголовки — это служебная информация для браузера.

### Что такое `self.end_headers()`?

Завершает отправку заголовков.

### Что такое `self.wfile.write(...)`?

Отправляет содержимое (HTML-код) клиенту.

### Что такое `self.path`?

Содержит путь из запроса. Например, для `http://localhost:8080/about` это будет `/about`.

---

## 🐛 Частые ошибки и их решение

### Ошибка: "Address already in use"

```
OSError: [Errno 98] Address already in use
```

**Что значит:** Порт 8080 уже занят другим приложением.

**Решение:**
1. Найдите процесс: `sudo netstat -tulpn | grep 8080`
2. Завершите его: `sudo kill PID`
3. Или используйте другой порт: измените `8080` на `8000`

### Ошибка: "No module named http.server"

**Что значит:** Python не нашёл модуль http.server.

**Решение:** Это встроенный модуль, он должен быть всегда. Проверьте версию Python: `python3 --version`

### Ошибка: "SyntaxError"

**Что значит:** Ошибка в синтаксисе (опечатка, лишняя скобка и т.д.).

**Решение:** Проверьте код, сравните с примером.

### Ошибка: "Connection refused"

**Что значит:** Браузер не может подключиться к серверу.

**Решение:**
1. Сервер запущен?
2. Правильный порт?
3. Правильный адрес? (`localhost` или `127.0.0.1`)

---

## 📚 Что дальше?

Теперь вы знаете основы! Можете:
1. Добавить больше страниц
2. Использовать шаблоны (заменить HTML на отдельные файлы)
3. Добавить стили (CSS)
4. Добавить JavaScript (интерактивность)
5. Изучить фреймворки: Flask, Django, FastAPI

---

## 📝 Задания для самостоятельной работы

1. **Добавьте страницу `/weather`**, которая показывает случайную погоду
2. **Добавьте страницу `/calc`**, которая складывает два числа из параметров
3. **Добавьте страницу `/counter`**, которая считает количество посещений

---

