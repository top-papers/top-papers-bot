


# top-papers-bot

Этот бот предназначен для интеллектуального поиска научных статей в нескольких базах данных (arXiv, PubMed/PMC и Libgen). Он помогает пользователю задать поисковые параметры, получить отфильтрованные результаты и подписаться на регулярные обновления.

## 1. Что умеет бот

### Основные возможности
- **Поиск статей в научных базах данных.**  
  Бот может проводить поиск по ключевым словам в базах:
  - **arXiv:** для препринтов из областей физики, математики, информатики и смежных областей.
  - **PubMed/PMC:** для исследований в области медицины и биологии.
  - **Libgen:** для поиска электронных книг и публикаций (обратите внимание, что поиск по Libgen может быть нестабильным).

- **Умный поиск с LLM.**  
  При наличии подробного текстового запроса (который можно задать дополнительно к ключевым словам) бот использует большую языковую модель для интеллектуального ранжирования результатов и определения релевантности статей.

- **Фильтрация и ранжирование результатов.**  
  Пользователь может задать:
  - Режим поиска по ключевым словам (по принципу "AND" – все слова или "OR" – хотя бы одно из ключевых).
  - Дополнительный подробный запрос (для LLM), который помогает выбрать наиболее подходящие статьи.
  - Ограничение по дате (например, за последние 7 или 30 дней) и минимальное число цитирований.
  - Опцию показывать только обзоры (review/survey) или все статьи.

- **Интерактивное управление.**  
  Бот ведёт разговор (conversation-based flow) с пользователем, последовательно задавая вопросы:
  - Выбор баз данных.
  - Ввод ключевых слов.
  - Определение дополнительных параметров поиска (режим ключевых слов, подробный запрос, площадь науки, максимальное число возвращаемых статей, топ-результаты).
  - Параметры подписки (периодичность обновлений, время рассылки).
  
- **Вывод результатов.**  
  После завершения поиска бот отправляет пользователю:
  - Краткое описание найденных статей (номер, заголовок, авторы, дата, количество цитирований, рейтинг, источник и ссылку для просмотра).
  - Возможность нажать кнопку «Показать аннотацию» для получения подробного описания статьи.
  - Опцию скачать результаты в виде JSON-файла.

- **Подписка на обновления.**  
  Если пользователь выбирает подписку, бот сохраняет настройки (в таблице `subscriptions` в базе данных) и периодически, согласно установленному интервалу, проверяет наличие новых статей по параметрам запроса. При обнаружении новинок бот отправит их в виде сообщений.

- **Отписка.**  
  Пользователь легко может отписаться от рассылки, нажав соответствующую кнопку «Отписаться от рассылки».

---

## 2. Установка и настройка окружения

Чтобы запустить бота, необходимо установить и настроить следующие компоненты:

### 2.1. Требования

- **Операционная система.**  
  Рекомендуется использовать Linux (например, Debian/Ubuntu), поскольку в скрипте установки базы данных используются команды `apt-get` и `systemctl`.
  
- **Python 3.8+**  
  Бот написан на Python, используется модуль `asyncio` и асинхронное подключение к базе данных (asyncpg).

- **PostgreSQL.**  
  База данных используется для хранения информации о подписках. Если PostgreSQL не установлен, его можно установить автоматически с помощью предоставленного скрипта.

- **Необходимые библиотеки Python.**  
  Некоторые из зависимостей (пакеты) включают:
  - python-telegram-bot (v20+)
  - asyncpg
  - nest_asyncio
  - APScheduler и pytz (для фонового выполнения рассылки)
  - arxiv
  - Biopython (для Entrez)
  - libgen_api_enhanced
  - tqdm
  - aiohttp
  - g4f (для LLM – если требуется функция интеллектуального ранжирования)
  
  Рекомендуется установить все зависимости командой:  
  ```bash
  pip install -r requirements.txt
  ```

### 2.2. Установка и настройка PostgreSQL

В репозитории присутствует скрипт `make_postgres.sh`, который:

- Проверяет наличие доступа `sudo` и устанавливает PostgreSQL и клиент psql (если не установлен) для систем на базе Debian/Ubuntu.
- Запускает и активирует службу PostgreSQL (с использованием systemd).
- Создает пользователя (по умолчанию `user`) и базу данных (по умолчанию `mydatabase`).
- Создает таблицу `subscriptions` для хранения настроек подписок с полями (chat_id, keywords, параметры поиска и т.д.).
- Выводит финальное сообщение с рекомендуемым DSN для подключения, например:  
  `postgresql://user:YOUR_PASSWORD@localhost:5432/mydatabase`

**Как запустить скрипт:**
1. Дайте права на выполнение:
   ```bash
   chmod +x make_postgres.sh
   ```
2. Запустите скрипт (при необходимости от имени root или через sudo):
   ```bash
   sudo ./make_postgres.sh
   ```

*Примечание:* Если вы хотите изменить стандартные значения (пользователь, пароль, имя базы, порт), задайте соответствующие переменные окружения перед запуском скрипта (POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, POSTGRES_HOST, POSTGRES_PORT).

### 2.3. Настройка переменных окружения

Для корректной работы бота необходимо задать следующие переменные окружения:

- **TELEGRAM_TOKEN**  
  Ваш токен бота, полученный через BotFather.

- **DATABASE_URL** (опционально)  
  Полная строка подключения к базе PostgreSQL в формате  
  `postgresql://user:password@host:port/dbname`  
  Если переменная не задана, по умолчанию используется `postgresql://user:password@localhost:5432/mydatabase`.

- **ENTREZ_EMAIL**  
  Адрес электронной почты, необходимый для работы модуля Bio.Entrez при поиске в PubMed. Например:  
  `example@example.com`

*Пример задания переменных окружения в Linux (в терминале):*
```bash
export TELEGRAM_TOKEN="ВАШ_ТОКЕН_БОТА"
export DATABASE_URL="postgresql://user:password@localhost:5432/mydatabase"
export ENTREZ_EMAIL="your_email@example.com"
```

### 2.4. Установка зависимостей Python

Убедитесь, что установлены все необходимые пакеты. Установите их командой:
```bash
pip install -r requirements.txt
```
*Либо установите пакеты вручную:*
```bash
pip install python-telegram-bot asyncpg nest_asyncio APScheduler pytz arxiv biopython libgen_api_enhanced tqdm aiohttp g4f
```

### 2.5. Запуск бота

После настройки PostgreSQL и установки зависимостей запустите бота:
```bash
python bot.py
```
Бот начнет опрос (polling) и будет ждать команды `/start` или `/search`.

*Примечание:* Если вы хотите, чтобы бот выполнялся в фоне или перезапускался при сбое, можно использовать менеджеры процессов (например, systemd, supervisor или pm2).

---

## 3. Как пользоваться ботом

1. **Запуск и приветственное сообщение.**  
   Пользователь отправляет команду `/start`. Бот отвечает приветственным сообщением, в котором объясняется функционал и предлагается начать поиск статей.

2. **Инициирование поиска.**  
   При нажатии кнопки «Поиск статей» или команде `/search` бот запускает серию опросов (conversation flow):
   - **Шаг 1:** Выбор баз данных (arXiv, PubMed, Libgen). Можно выбрать одну или несколько.
   - **Шаг 2:** Ввод ключевых слов для поиска. Рекомендуется использовать английский язык для arXiv и PubMed, а для Libgen можно использовать любой.
   - **Шаг 3:** Выбор режима поиска – **AND** (найти статьи, содержащие все слова) или **OR** (найти статьи, содержащие хотя бы одно).
   - **Шаг 4:** (Опционально) Ввод подробного запроса для LLM, который поможет точнее ранжировать результаты.
   - **Шаг 5:** Выбор области науки (например, биология, математика, физика и т.д.) для улучшения качества ранжирования.
   - **Шаг 6 – 10:** Задание параметров поиска: максимальное число артикулов, сколько лучших статей показать, глубина поиска (количество дней), фильтр по количеству цитирований, выбор только обзорных статей.
   - **Шаг 11:** Опциональная подписка на периодические обновления. Если выбрана подписка, дополнительно выбирается интервал (1, 7, 30 дней) и время рассылки (час и минуты в формате UTC).

3. **Просмотр результатов.**  
   После подтверждения параметров бот выполняет поиск, обрабатывает найденные статьи, запрашивает данные о цитированиях, получает ссылки и ранжирует результаты с помощью LLM.  
   - Результаты отправляются сообщениями с краткой информацией по каждой статье.  
   - Пользователь может нажать кнопку «Показать аннотацию», чтобы получить полный текст аннотации, или скачать все результаты в виде JSON.

4. **Подписка и уведомления.**  
   Если пользователь выбрал подписку:
   - Его настройки сохраняются в базе данных.
   - Фоновый планировщик (APScheduler) периодически (каждые 10 минут) проверяет, пора ли отправлять обновления.
   - В назначенное время бот автоматически выполняет поиск и отправляет найденные новые статьи.

5. **Отписка.**  
   Если пользователь больше не хочет получать обновления, он может нажать кнопку «Отписаться от рассылки», после чего его подписка будет удалена из базы данных.

## Контрибьюторы

Спасибо всем, кто участвовал в проектировании и создании бота! Список контрибьюторов есть в файле [contributors](https://github.com/top-papers/top-papers-bot/blob/main/contributors.md).

