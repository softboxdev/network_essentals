
---

# Практическая работа: «Создаём веб-приложение на Python без фреймворков»

**Цель работы:** Создать простое веб-приложение на Python, которое обрабатывает HTTP-запросы, генерирует динамические страницы и взаимодействует с пользователем через формы.

**Время выполнения:** 60-70 минут.

**Оборудование:** Компьютер с ОС Linux, Python 3 (установлен по умолчанию).

**Программное обеспечение:** Терминал, текстовый редактор, браузер.

---

## Теория (5 минут)

**Как работает веб-приложение на Python?**

1. Python запускает веб-сервер.
2. Сервер слушает определённый порт (например, 8080).
3. При получении запроса сервер вызывает функцию-обработчик.
4. Функция генерирует HTML-ответ.
5. Ответ отправляется клиенту (браузеру).

**Что мы будем использовать:**
- Модуль `http.server` — встроенный веб-сервер
- Класс `BaseHTTPRequestHandler` — для обработки запросов
- HTML и формы — для взаимодействия с пользователем

---

## Часть 1. Создаём простейший веб-сервер (10 минут)

### Задание 1.1. Создаём первый сервер

Откройте текстовый редактор и создайте файл `server.py`:

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from http.server import HTTPServer, BaseHTTPRequestHandler
import datetime

class SimpleHandler(BaseHTTPRequestHandler):
    """Обработчик HTTP-запросов"""

    def do_GET(self):
        """Обработка GET-запросов"""

        # Отправляем статус 200 OK
        self.send_response(200)

        # Отправляем заголовок Content-Type
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()

        # Формируем HTML-страницу
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Мой первый сервер</title>
            <style>
                body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
                .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
                h1 {{ color: #2196f3; }}
                .time {{ font-size: 24px; color: #4caf50; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🚀 Мой первый веб-сервер на Python</h1>
                <p>Сервер работает!</p>
                <p class="time">⏰ Текущее время: {datetime.datetime.now().strftime('%H:%M:%S')}</p>
                <hr>
                <p><b>Путь запроса:</b> {self.path}</p>
                <p><b>Метод:</b> GET</p>
            </div>
        </body>
        </html>
        """

        # Отправляем HTML
        self.wfile.write(html.encode('utf-8'))

def run_server(port=8080):
    """Запуск сервера"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, SimpleHandler)
    print(f'🚀 Сервер запущен на порту {port}')
    print(f'🌐 Откройте в браузере: http://localhost:{port}')
    print('🛑 Для остановки нажмите Ctrl+C')

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n⏹ Сервер остановлен')
        httpd.server_close()

if __name__ == '__main__':
    run_server()
```

### Задание 1.2. Запускаем сервер

В терминале выполните:

```bash
python3 server.py
```

### Задание 1.3. Проверяем работу

1. Откройте браузер.
2. Введите адрес: `http://localhost:8080`
3. Вы должны увидеть страницу с текущим временем.

**Вопросы в отчёт:**
1. Что вы видите на странице?
2. Какой путь отображается в строке "Путь запроса"?
3. Изменяется ли время при обновлении страницы (F5)?

---

## Часть 2. Обработка разных URL (15 минут)

### Задание 2.1. Добавляем обработку разных путей

Обновите файл `server.py`, добавив обработку разных URL:

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from http.server import HTTPServer, BaseHTTPRequestHandler
import datetime
import urllib.parse

class SimpleHandler(BaseHTTPRequestHandler):
    """Обработчик HTTP-запросов"""

    def do_GET(self):
        """Обработка GET-запросов"""

        # Разбираем URL
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path

        # Отправляем заголовки
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()

        # Генерируем HTML в зависимости от пути
        if path == '/' or path == '/index.html':
            html = self.get_index_page()
        elif path == '/about':
            html = self.get_about_page()
        elif path == '/time':
            html = self.get_time_page()
        else:
            html = self.get_404_page(path)

        # Отправляем ответ
        self.wfile.write(html.encode('utf-8'))

    def get_index_page(self):
        """Главная страница"""
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Главная</title>
            <style>
                body { font-family: Arial; margin: 40px; background: #f0f0f0; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
                nav a { margin: 0 10px; color: #2196f3; text-decoration: none; }
                nav a:hover { text-decoration: underline; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🏠 Главная страница</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/about">О нас</a> |
                    <a href="/time">Время</a>
                </nav>
                <p>Добро пожаловать на мой сайт!</p>
                <p>Этот сайт работает на Python без фреймворков.</p>
            </div>
        </body>
        </html>
        """

    def get_about_page(self):
        """Страница "О нас" """
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>О нас</title>
            <style>
                body { font-family: Arial; margin: 40px; background: #f0f0f0; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
                nav a { margin: 0 10px; color: #2196f3; text-decoration: none; }
                nav a:hover { text-decoration: underline; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📖 О нас</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/about">О нас</a> |
                    <a href="/time">Время</a>
                </nav>
                <p>Это страница о нашем проекте.</p>
                <p>Мы создаём веб-приложения на Python!</p>
            </div>
        </body>
        </html>
        """

    def get_time_page(self):
        """Страница с временем"""
        now = datetime.datetime.now()
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Текущее время</title>
            <style>
                body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
                .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
                nav a {{ margin: 0 10px; color: #2196f3; text-decoration: none; }}
                nav a:hover {{ text-decoration: underline; }}
                .time {{ font-size: 36px; color: #4caf50; text-align: center; padding: 20px; }}
                .date {{ font-size: 18px; text-align: center; color: #666; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>⏰ Текущее время</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/about">О нас</a> |
                    <a href="/time">Время</a>
                </nav>
                <div class="time">{now.strftime('%H:%M:%S')}</div>
                <div class="date">{now.strftime('%d.%m.%Y')}</div>
                <p style="text-align: center;">Обновите страницу, чтобы увидеть новое время</p>
            </div>
        </body>
        </html>
        """

    def get_404_page(self, path):
        """Страница 404 - не найдено"""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>404 - Страница не найдена</title>
            <style>
                body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
                .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
                .error {{ color: #f44336; font-size: 48px; text-align: center; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>❌ 404 - Страница не найдена</h1>
                <p>Страница <b>{path}</b> не существует.</p>
                <p><a href="/">Вернуться на главную</a></p>
            </div>
        </body>
        </html>
        """

def run_server(port=8080):
    """Запуск сервера"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, SimpleHandler)
    print(f'🚀 Сервер запущен на порту {port}')
    print(f'🌐 Откройте в браузере: http://localhost:{port}')
    print('📄 Доступные страницы:')
    print('  - /          - Главная')
    print('  - /about     - О нас')
    print('  - /time      - Текущее время')
    print('🛑 Для остановки нажмите Ctrl+C')

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n⏹ Сервер остановлен')
        httpd.server_close()

if __name__ == '__main__':
    run_server()
```

### Задание 2.2. Проверяем работу

1. Остановите старый сервер (Ctrl+C).
2. Запустите обновлённый сервер: `python3 server.py`
3. Откройте в браузере:
   - `http://localhost:8080/` — главная
   - `http://localhost:8080/about` — о нас
   - `http://localhost:8080/time` — время
   - `http://localhost:8080/anything` — страница 404

**Вопросы в отчёт:**
1. Что происходит при переходе на `/time`?
2. Что вы видите на странице 404?
3. Как сервер определяет, какую страницу показывать?

---

## Часть 3. Работа с параметрами запроса (15 минут)

### Задание 3.1. Добавляем обработку GET-параметров

Добавьте в класс `SimpleHandler` новый метод:

```python
def get_greeting_page(self, name=None):
    """Страница приветствия с параметрами"""

    if name is None:
        name = 'Гость'

    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Приветствие</title>
        <style>
            body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
            .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
            nav a {{ margin: 0 10px; color: #2196f3; text-decoration: none; }}
            .greeting {{ font-size: 28px; color: #4caf50; text-align: center; padding: 20px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>👋 Привет!</h1>
            <nav>
                <a href="/">Главная</a> |
                <a href="/about">О нас</a> |
                <a href="/time">Время</a> |
                <a href="/greeting">Приветствие</a>
            </nav>
            <div class="greeting">Привет, <b>{name}</b>!</div>
            <p>Попробуйте перейти по ссылке: <a href="/greeting?name=Вася">Привет, Вася!</a></p>
            <p>Или измените параметр в адресной строке: <code>/greeting?name=Ваше_имя</code></p>
        </div>
    </body>
    </html>
    """
```

И измените метод `do_GET`, добавив новый путь:

```python
def do_GET(self):
    """Обработка GET-запросов"""

    # Разбираем URL
    parsed_path = urllib.parse.urlparse(self.path)
    path = parsed_path.path
    query = urllib.parse.parse_qs(parsed_path.query)

    # Отправляем заголовки
    self.send_response(200)
    self.send_header('Content-Type', 'text/html; charset=utf-8')
    self.end_headers()

    # Генерируем HTML в зависимости от пути
    if path == '/' or path == '/index.html':
        html = self.get_index_page()
    elif path == '/about':
        html = self.get_about_page()
    elif path == '/time':
        html = self.get_time_page()
    elif path == '/greeting':
        # Получаем параметр name из запроса
        name = query.get('name', ['Гость'])[0]
        html = self.get_greeting_page(name)
    else:
        html = self.get_404_page(path)

    # Отправляем ответ
    self.wfile.write(html.encode('utf-8'))
```

### Задание 3.2. Проверяем параметры

Обновите сервер и перейдите по адресам:

1. `http://localhost:8080/greeting` — приветствие для гостя
2. `http://localhost:8080/greeting?name=Иван` — приветствие для Ивана
3. `http://localhost:8080/greeting?name=Маша&age=15` — параметр age игнорируется

**Вопросы в отчёт:**
1. Как меняется страница при добавлении параметра `?name=...`?
2. Где в URL находятся параметры?
3. Сколько параметров можно передать?

---

## Часть 4. Создаём приложение с формами (20 минут)

### Задание 4.1. Добавляем страницу с формой

Создайте новый метод в классе `SimpleHandler`:

```python
def get_form_page(self):
    """Страница с формой"""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Форма</title>
        <style>
            body { font-family: Arial; margin: 40px; background: #f0f0f0; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
            nav a { margin: 0 10px; color: #2196f3; text-decoration: none; }
            .form-group { margin: 15px 0; }
            label { display: inline-block; width: 100px; }
            input[type="text"], input[type="number"] {
                padding: 8px;
                border: 1px solid #ddd;
                border-radius: 4px;
                width: 200px;
            }
            input[type="submit"] {
                background: #2196f3;
                color: white;
                border: none;
                padding: 10px 30px;
                border-radius: 5px;
                cursor: pointer;
            }
            input[type="submit"]:hover {
                background: #1976d2;
            }
            .result {
                background: #e8f5e9;
                padding: 15px;
                border-radius: 5px;
                margin-top: 20px;
                border-left: 4px solid #4caf50;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>📝 Анкета</h1>
            <nav>
                <a href="/">Главная</a> |
                <a href="/about">О нас</a> |
                <a href="/time">Время</a> |
                <a href="/greeting">Приветствие</a> |
                <a href="/form">Анкета</a>
            </nav>

            <form action="/form" method="GET">
                <div class="form-group">
                    <label>Имя:</label>
                    <input type="text" name="name" placeholder="Введите имя">
                </div>
                <div class="form-group">
                    <label>Возраст:</label>
                    <input type="number" name="age" placeholder="Введите возраст">
                </div>
                <div class="form-group">
                    <label>Город:</label>
                    <input type="text" name="city" placeholder="Введите город">
                </div>
                <input type="submit" value="Отправить">
            </form>

            <div id="result"></div>
        </div>
        <script>
            // Показываем данные из URL при загрузке
            const params = new URLSearchParams(window.location.search);
            if (params.size > 0) {
                const result = document.getElementById('result');
                let html = '<div class="result"><h3>Ваши данные:</h3><ul>';
                for (const [key, value] of params) {
                    html += `<li><b>${key}:</b> ${value}</li>`;
                }
                html += '</ul></div>';
                result.innerHTML = html;
            }
        </script>
    </body>
    </html>
    """
```

### Задание 4.2. Добавляем обработку формы в сервер

Добавьте новый путь в `do_GET`:

```python
elif path == '/form':
    html = self.get_form_page()
```

### Задание 4.3. Проверяем работу формы

1. Обновите сервер.
2. Перейдите на `http://localhost:8080/form`
3. Заполните форму и нажмите "Отправить".
4. Обратите внимание на URL после отправки.

**Вопросы в отчёт:**
1. Как выглядят данные в URL после отправки формы?
2. Что произойдёт, если не заполнить поля?
3. Как метод `GET` передаёт данные?

---

## Часть 5. Расширенное приложение: обработка POST-запросов (10 минут)

### Задание 5.1. Добавляем поддержку POST

Добавьте в класс `SimpleHandler` метод для обработки POST:

```python
def do_POST(self):
    """Обработка POST-запросов"""

    # Получаем длину содержимого
    content_length = int(self.headers.get('Content-Length', 0))

    # Читаем тело запроса
    post_data = self.rfile.read(content_length).decode('utf-8')

    # Разбираем параметры
    params = urllib.parse.parse_qs(post_data)

    # Отправляем ответ
    self.send_response(200)
    self.send_header('Content-Type', 'text/html; charset=utf-8')
    self.end_headers()

    # Генерируем страницу с результатом
    html = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Результат POST</title>
        <style>
            body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
            .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
            .result {{ background: #e8f5e9; padding: 15px; border-radius: 5px; border-left: 4px solid #4caf50; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>✅ Данные получены через POST</h1>
            <div class="result">
                <h3>Полученные данные:</h3>
                <ul>
    """

    for key, values in params.items():
        html += f"<li><b>{key}:</b> {values[0]}</li>"

    html += """
                </ul>
            </div>
            <p><a href="/form-post">Вернуться к форме</a></p>
        </div>
    </body>
    </html>
    """

    self.wfile.write(html.encode('utf-8'))
```

### Задание 5.2. Создаём форму для POST-запросов

Добавьте новый метод для страницы с POST-формой:

```python
def get_post_form_page(self):
    """Страница с POST-формой"""
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>POST форма</title>
        <style>
            body { font-family: Arial; margin: 40px; background: #f0f0f0; }
            .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
            nav a { margin: 0 10px; color: #2196f3; text-decoration: none; }
            .form-group { margin: 15px 0; }
            label { display: inline-block; width: 100px; }
            input[type="text"] {
                padding: 8px;
                border: 1px solid #ddd;
                border-radius: 4px;
                width: 200px;
            }
            input[type="submit"] {
                background: #ff9800;
                color: white;
                border: none;
                padding: 10px 30px;
                border-radius: 5px;
                cursor: pointer;
            }
            input[type="submit"]:hover {
                background: #f57c00;
            }
            .info {
                background: #fff3e0;
                padding: 10px;
                border-radius: 5px;
                border-left: 4px solid #ff9800;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>📩 Отправка через POST</h1>
            <nav>
                <a href="/">Главная</a> |
                <a href="/form">GET-форма</a> |
                <a href="/form-post">POST-форма</a>
            </nav>

            <div class="info">
                <b>Отличие от GET:</b> Данные не видны в URL, передаются в теле запроса.
            </div>

            <form action="/form-post" method="POST">
                <div class="form-group">
                    <label>Логин:</label>
                    <input type="text" name="login" placeholder="Введите логин">
                </div>
                <div class="form-group">
                    <label>Пароль:</label>
                    <input type="text" name="password" placeholder="Введите пароль">
                </div>
                <div class="form-group">
                    <label>Сообщение:</label>
                    <input type="text" name="message" placeholder="Ваше сообщение">
                </div>
                <input type="submit" value="Отправить через POST">
            </form>
        </div>
    </body>
    </html>
    """
```

### Задание 5.3. Подключаем новые страницы

Добавьте в `do_GET`:

```python
elif path == '/form-post':
    html = self.get_post_form_page()
```

### Задание 5.4. Проверяем разницу между GET и POST

1. Откройте `http://localhost:8080/form-post`
2. Заполните форму и отправьте.
3. Посмотрите на адресную строку (данных нет!).
4. Сравните с формой GET из предыдущей части.

**Вопросы в отчёт:**
1. В чём разница между GET и POST?
2. Где передаются данные в GET-запросе?
3. Где передаются данные в POST-запросе?
4. Какой метод безопаснее для отправки пароля?

---

## Часть 6. Полный код приложения (для проверки)

Вот полный код финального приложения `server.py`:

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from http.server import HTTPServer, BaseHTTPRequestHandler
import datetime
import urllib.parse

class SimpleHandler(BaseHTTPRequestHandler):
    """Обработчик HTTP-запросов"""

    def do_GET(self):
        """Обработка GET-запросов"""

        # Разбираем URL
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        query = urllib.parse.parse_qs(parsed_path.query)

        # Отправляем заголовки
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()

        # Генерируем HTML в зависимости от пути
        if path == '/' or path == '/index.html':
            html = self.get_index_page()
        elif path == '/about':
            html = self.get_about_page()
        elif path == '/time':
            html = self.get_time_page()
        elif path == '/greeting':
            name = query.get('name', ['Гость'])[0]
            html = self.get_greeting_page(name)
        elif path == '/form':
            html = self.get_form_page()
        elif path == '/form-post':
            html = self.get_post_form_page()
        else:
            html = self.get_404_page(path)

        # Отправляем ответ
        self.wfile.write(html.encode('utf-8'))

    def do_POST(self):
        """Обработка POST-запросов"""

        # Получаем длину содержимого
        content_length = int(self.headers.get('Content-Length', 0))

        # Читаем тело запроса
        post_data = self.rfile.read(content_length).decode('utf-8')

        # Разбираем параметры
        params = urllib.parse.parse_qs(post_data)

        # Отправляем ответ
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()

        # Генерируем страницу с результатом
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Результат POST</title>
            <style>
                body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
                .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
                .result {{ background: #e8f5e9; padding: 15px; border-radius: 5px; border-left: 4px solid #4caf50; }}
                nav a {{ margin: 0 10px; color: #2196f3; text-decoration: none; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>✅ Данные получены через POST</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/form">GET-форма</a> |
                    <a href="/form-post">POST-форма</a>
                </nav>
                <div class="result">
                    <h3>Полученные данные:</h3>
                    <ul>
        """

        for key, values in params.items():
            html += f"<li><b>{key}:</b> {values[0]}</li>"

        html += """
                    </ul>
                </div>
                <p><a href="/form-post">Вернуться к форме</a></p>
            </div>
        </body>
        </html>
        """

        self.wfile.write(html.encode('utf-8'))

    def get_index_page(self):
        """Главная страница"""
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Главная</title>
            <style>
                body { font-family: Arial; margin: 40px; background: #f0f0f0; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
                nav a { margin: 0 10px; color: #2196f3; text-decoration: none; }
                nav a:hover { text-decoration: underline; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🏠 Главная страница</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/about">О нас</a> |
                    <a href="/time">Время</a> |
                    <a href="/greeting">Приветствие</a> |
                    <a href="/form">Анкета (GET)</a> |
                    <a href="/form-post">Анкета (POST)</a>
                </nav>
                <p>Добро пожаловать на мой сайт!</p>
                <p>Это веб-приложение на Python без фреймворков.</p>
                <p>Доступны страницы:</p>
                <ul>
                    <li><a href="/about">О нас</a></li>
                    <li><a href="/time">Текущее время</a></li>
                    <li><a href="/greeting?name=Вася">Приветствие с параметром</a></li>
                    <li><a href="/form">Анкета через GET</a></li>
                    <li><a href="/form-post">Анкета через POST</a></li>
                </ul>
            </div>
        </body>
        </html>
        """

    def get_about_page(self):
        """Страница 'О нас' """
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>О нас</title>
            <style>
                body { font-family: Arial; margin: 40px; background: #f0f0f0; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
                nav a { margin: 0 10px; color: #2196f3; text-decoration: none; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📖 О нас</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/about">О нас</a> |
                    <a href="/time">Время</a>
                </nav>
                <p>Это страница о нашем проекте.</p>
                <p>Мы создаём веб-приложения на Python!</p>
                <p>Используем встроенный модуль http.server.</p>
            </div>
        </body>
        </html>
        """

    def get_time_page(self):
        """Страница с временем"""
        now = datetime.datetime.now()
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Текущее время</title>
            <style>
                body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
                .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
                nav a {{ margin: 0 10px; color: #2196f3; text-decoration: none; }}
                .time {{ font-size: 36px; color: #4caf50; text-align: center; padding: 20px; }}
                .date {{ font-size: 18px; text-align: center; color: #666; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>⏰ Текущее время</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/about">О нас</a> |
                    <a href="/time">Время</a>
                </nav>
                <div class="time">{now.strftime('%H:%M:%S')}</div>
                <div class="date">{now.strftime('%d.%m.%Y')}</div>
                <p style="text-align: center;">Обновите страницу, чтобы увидеть новое время</p>
            </div>
        </body>
        </html>
        """

    def get_greeting_page(self, name=None):
        """Страница приветствия с параметрами"""
        if name is None:
            name = 'Гость'

        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Приветствие</title>
            <style>
                body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
                .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
                nav a {{ margin: 0 10px; color: #2196f3; text-decoration: none; }}
                .greeting {{ font-size: 28px; color: #4caf50; text-align: center; padding: 20px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>👋 Привет!</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/about">О нас</a> |
                    <a href="/time">Время</a> |
                    <a href="/greeting">Приветствие</a>
                </nav>
                <div class="greeting">Привет, <b>{name}</b>!</div>
                <p>Попробуйте перейти по ссылке: <a href="/greeting?name=Вася">Привет, Вася!</a></p>
                <p>Или измените параметр в адресной строке: <code>/greeting?name=Ваше_имя</code></p>
            </div>
        </body>
        </html>
        """

    def get_form_page(self):
        """Страница с GET-формой"""
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>GET форма</title>
            <style>
                body { font-family: Arial; margin: 40px; background: #f0f0f0; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
                nav a { margin: 0 10px; color: #2196f3; text-decoration: none; }
                .form-group { margin: 15px 0; }
                label { display: inline-block; width: 100px; }
                input[type="text"], input[type="number"] {
                    padding: 8px;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                    width: 200px;
                }
                input[type="submit"] {
                    background: #2196f3;
                    color: white;
                    border: none;
                    padding: 10px 30px;
                    border-radius: 5px;
                    cursor: pointer;
                }
                input[type="submit"]:hover {
                    background: #1976d2;
                }
                .result {
                    background: #e8f5e9;
                    padding: 15px;
                    border-radius: 5px;
                    margin-top: 20px;
                    border-left: 4px solid #4caf50;
                }
                .info {
                    background: #fff3e0;
                    padding: 10px;
                    border-radius: 5px;
                    border-left: 4px solid #ff9800;
                    margin-bottom: 20px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📝 Анкета (GET)</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/form">GET-форма</a> |
                    <a href="/form-post">POST-форма</a>
                </nav>

                <div class="info">
                    <b>Внимание:</b> Данные будут видны в адресной строке.
                </div>

                <form action="/form" method="GET">
                    <div class="form-group">
                        <label>Имя:</label>
                        <input type="text" name="name" placeholder="Введите имя">
                    </div>
                    <div class="form-group">
                        <label>Возраст:</label>
                        <input type="number" name="age" placeholder="Введите возраст">
                    </div>
                    <div class="form-group">
                        <label>Город:</label>
                        <input type="text" name="city" placeholder="Введите город">
                    </div>
                    <input type="submit" value="Отправить">
                </form>

                <div id="result"></div>
            </div>
            <script>
                const params = new URLSearchParams(window.location.search);
                if (params.size > 0) {
                    const result = document.getElementById('result');
                    let html = '<div class="result"><h3>Ваши данные:</h3><ul>';
                    for (const [key, value] of params) {
                        html += `<li><b>${key}:</b> ${value}</li>`;
                    }
                    html += '</ul></div>';
                    result.innerHTML = html;
                }
            </script>
        </body>
        </html>
        """

    def get_post_form_page(self):
        """Страница с POST-формой"""
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>POST форма</title>
            <style>
                body { font-family: Arial; margin: 40px; background: #f0f0f0; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }
                nav a { margin: 0 10px; color: #2196f3; text-decoration: none; }
                .form-group { margin: 15px 0; }
                label { display: inline-block; width: 100px; }
                input[type="text"] {
                    padding: 8px;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                    width: 200px;
                }
                input[type="submit"] {
                    background: #ff9800;
                    color: white;
                    border: none;
                    padding: 10px 30px;
                    border-radius: 5px;
                    cursor: pointer;
                }
                input[type="submit"]:hover {
                    background: #f57c00;
                }
                .info {
                    background: #fff3e0;
                    padding: 10px;
                    border-radius: 5px;
                    border-left: 4px solid #ff9800;
                    margin-bottom: 20px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>📩 Отправка через POST</h1>
                <nav>
                    <a href="/">Главная</a> |
                    <a href="/form">GET-форма</a> |
                    <a href="/form-post">POST-форма</a>
                </nav>

                <div class="info">
                    <b>Отличие от GET:</b> Данные не видны в URL, передаются в теле запроса.
                </div>

                <form action="/form-post" method="POST">
                    <div class="form-group">
                        <label>Логин:</label>
                        <input type="text" name="login" placeholder="Введите логин">
                    </div>
                    <div class="form-group">
                        <label>Пароль:</label>
                        <input type="text" name="password" placeholder="Введите пароль">
                    </div>
                    <div class="form-group">
                        <label>Сообщение:</label>
                        <input type="text" name="message" placeholder="Ваше сообщение">
                    </div>
                    <input type="submit" value="Отправить через POST">
                </form>
            </div>
        </body>
        </html>
        """

    def get_404_page(self, path):
        """Страница 404 - не найдено"""
        return f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>404 - Страница не найдена</title>
            <style>
                body {{ font-family: Arial; margin: 40px; background: #f0f0f0; }}
                .container {{ max-width: 600px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; }}
                .error {{ color: #f44336; font-size: 48px; text-align: center; }}
                nav a {{ margin: 0 10px; color: #2196f3; text-decoration: none; }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1>❌ 404 - Страница не найдена</h1>
                <p>Страница <b>{path}</b> не существует.</p>
                <p><a href="/">Вернуться на главную</a></p>
            </div>
        </body>
        </html>
        """

def run_server(port=8080):
    """Запуск сервера"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, SimpleHandler)
    print('🚀' + '='*60)
    print(f'   Сервер запущен на порту {port}')
    print(f'   Откройте в браузере: http://localhost:{port}')
    print('='*60)
    print('📄 Доступные страницы:')
    print('  /          - Главная')
    print('  /about     - О нас')
    print('  /time      - Текущее время')
    print('  /greeting  - Приветствие (с параметром ?name=...)')
    print('  /form      - Анкета через GET')
    print('  /form-post - Анкета через POST')
    print('='*60)
    print('🛑 Для остановки нажмите Ctrl+C')

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n⏹ Сервер остановлен')
        httpd.server_close()

if __name__ == '__main__':
    run_server()
```

---

## Часть 7. Итоговый отчёт

Создайте файл `web_app_report.txt` и запишите:

1. **ФИО, класс, дата**

2. **Ответы на вопросы:**
   - Что такое веб-сервер?
   - Какой модуль Python используется для создания сервера?
   - В чём разница между GET и POST?

3. **Структура приложения:**
   - Какие страницы есть в вашем приложении?
   - Какие функции генерируют HTML?

4. **Практический эксперимент:**
   - Запустите сервер и откройте все страницы
   - Заполните обе формы (GET и POST)
   - Сравните, как передаются данные

5. **Код:**
   - Скопируйте финальный код `server.py`

6. **Вывод (5-7 предложений):**
   - Что нового узнали?
   - Сложно ли было создать веб-приложение?
   - Где можно применить эти знания?

---

## Дополнительное задание (для быстрых)

### Бонус 1: Добавьте новую страницу

Создайте страницу `/calc`, которая принимает два числа через GET-параметры и показывает их сумму.

**Пример URL:** `http://localhost:8080/calc?a=10&b=20`

**Подсказка:** Используйте `int()` для преобразования строк в числа.

### Бонус 2: Стилизация

Добавьте CSS-стили в ваш сервер. Создайте страницу `/style.css`, которая будет возвращать CSS-файл.

**Подсказка:** Используйте заголовок `Content-Type: text/css`.

---

## Критерии оценки

| Балл | Критерий |
|------|----------|
| 5    | Все задания выполнены, приложение работает, отчёт полный |
| 4    | Есть мелкие недочёты, но основное работает |
| 3    | Часть заданий не выполнена, есть ошибки в коде |
| 2    | Работа не сдана или не работает |

---
