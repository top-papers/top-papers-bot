# top-papers-bot
код телеграм-бота для регулярного поиска научной литературы по сложным запросам пользователей



# Scientific Papers Search Bot 🔬📚

Интеллектуальный Telegram-бот для поиска научных статей с использованием LLM-ранжирования и поддержкой сложных запросов. Бот осуществляет поиск в arXiv, PubMed (PMC) и Libgen, применяет искусственный интеллект для ранжирования результатов и предоставляет систему подписок для периодических обновлений.

## 🚀 Основные возможности

### 🔍 Мультиисточниковый поиск
- **arXiv**: Препринты и научные статьи по физике, математике, CS и другим областям
- **PubMed (PMC)**: Медицинские и биологические публикации
- **Libgen**: Научные книги и монографии

### 🧠 Интеллектуальное ранжирование
- Использование больших языковых моделей (LLM) для оценки релевантности
- Поддержка сложных, многоаспектных запросов
- Контекстное понимание междисциплинарных тем
- Настраиваемые области науки для точного ранжирования

### 📊 Расширенная фильтрация
- **Временные фильтры**: поиск за определенный период
- **Цитирование**: минимальное количество цитирований
- **Тип публикаций**: только обзорные статьи или все типы
- **Режимы поиска**: AND/OR логика для ключевых слов
- **Количество результатов**: настраиваемые лимиты

### 📬 Система подписок
- Периодические уведомления о новых статьях
- Настраиваемое время рассылки (UTC)
- Персистентное хранение настроек в PostgreSQL
- Автоматическая фильтрация дубликатов

### 📁 Экспорт данных
- Скачивание результатов в формате JSON
- Детальная информация о статьях включая:
  - Метаданные авторов
  - Аннотации
  - Ссылки на источники
  - Данные о цитировании
  - Списки литературы (references)

## 🏗️ Архитектура и технологии

### Основной стек
- **Python 3.8+** с asyncio для асинхронной обработки
- **python-telegram-bot** для интеграции с Telegram API
- **PostgreSQL** для хранения подписок и настроек
- **APScheduler** для фоновых задач и планирования

### Внешние API и библиотеки
- **arxiv-py**: официальная библиотека для arXiv API
- **Biopython (Entrez)**: доступ к PubMed/PMC
- **libgen-api-enhanced**: поиск в Library Genesis
- **Semantic Scholar API**: получение данных о цитировании
- **g4f**: интеграция с бесплатными LLM-сервисами

### Базы данных и хранение
```sql
-- Структура таблицы подписок
CREATE TABLE subscriptions (
    chat_id BIGINT PRIMARY KEY,
    keywords TEXT,
    field_of_study TEXT,
    subscription_period INTEGER,
    last_update DATE,
    max_results INTEGER,
    days INTEGER,
    review_only BOOLEAN,
    keyword_mode TEXT,
    detailed_query TEXT,
    min_citations INTEGER,
    databases TEXT,
    subscription_hour INTEGER,
    subscription_minute INTEGER
);
```

## 📋 Требования

### Системные зависимости
- Python 3.8+
- PostgreSQL 12+
- Доступ к интернету для API-запросов

### Python-зависимости
```
python-telegram-bot>=20.0
arxiv>=1.4.0
biopython>=1.79
aiohttp>=3.8.0
asyncpg>=0.27.0
tqdm>=4.64.0
apscheduler>=3.9.0
pytz>=2022.1
nest-asyncio>=1.5.0
libgen-api-enhanced
g4f
```

## 🔧 Установка и настройка

### 1. Клонирование репозитория
```bash
git clone https://github.com/your-username/scientific-papers-bot.git
cd scientific-papers-bot
```

### 2. Установка зависимостей
```bash
pip install -r requirements.txt
```

### 3. Настройка PostgreSQL

#### Автоматическая настройка (Linux/Ubuntu)
```bash
chmod +x make_postgres.sh
sudo ./make_postgres.sh
```

#### Ручная настройка
```bash
# Создание пользователя и базы данных
sudo -u postgres psql
CREATE USER bot_user WITH PASSWORD 'your_password';
CREATE DATABASE bot_database OWNER bot_user;
GRANT ALL PRIVILEGES ON DATABASE bot_database TO bot_user;
\q

# Создание таблицы
psql -h localhost -U bot_user -d bot_database
CREATE TABLE subscriptions (
    chat_id BIGINT PRIMARY KEY,
    keywords TEXT,
    field_of_study TEXT,
    subscription_period INTEGER,
    last_update DATE,
    max_results INTEGER,
    days INTEGER,
    review_only BOOLEAN,
    keyword_mode TEXT,
    detailed_query TEXT,
    min_citations INTEGER,
    databases TEXT,
    subscription_hour INTEGER,
    subscription_minute INTEGER
);
```

### 4. Настройка переменных окружения

Создайте файл `.env` или установите переменные окружения:

```env
# Обязательные переменные
TELEGRAM_TOKEN=your_telegram_bot_token
DATABASE_URL=postgresql://bot_user:your_password@localhost:5432/bot_database

# Опциональные переменные
ENTREZ_EMAIL=your_email@example.com  # для PubMed API
```

### 5. Создание Telegram-бота

1. Найдите [@BotFather](https://t.me/botfather) в Telegram
2. Отправьте `/newbot` и следуйте инструкциям
3. Получите токен бота и добавьте его в переменные окружения

## 🚀 Запуск

```bash
python bot.py
```

Бот будет доступен в Telegram по команде `/start`.

## 💡 Использование

### Основные команды
- `/start` - Запуск бота и главное меню
- `/search` - Начать новый поиск
- `/cancel` - Отменить текущую операцию

### Пошаговый процесс поиска

1. **Выбор баз данных**: arXiv, PubMed, Libgen (можно несколько)
2. **Ключевые слова**: введите термины для поиска
3. **Режим поиска**: AND (все слова) или OR (любое слово)
4. **Детальный запрос для LLM**: опциональный сложный запрос
5. **Область науки**: для точного LLM-ранжирования
6. **Количество результатов**: сколько статей искать
7. **Топ результатов**: сколько показать после ранжирования
8. **Временной фильтр**: поиск за последние N дней
9. **Фильтр цитирований**: минимальное количество цитирований
10. **Тип статей**: только обзоры или все типы
11. **Подписка**: настройка периодических уведомлений

### Пример использования

**Простой поиск:**
- Ключевые слова: `machine learning, neural networks`
- Режим: OR
- База: arXiv

**Сложный запрос:**
- Ключевые слова: `climate change, biodiversity, arctic`
- Детальный запрос: "Ищу статьи о влиянии изменения климата на биоразнообразие в арктических регионах с фокусом на методы адаптации и мониторинга экосистем"
- Область науки: Науки о Земле
- Минимум цитирований: 10

## 📊 Структура проекта

```
scientific-papers-bot/
├── bot.py                 # Основной файл бота
├── make_postgres.sh       # Скрипт настройки PostgreSQL
├── requirements.txt       # Python-зависимости
├── README.md             # Документация
├── .env.example          # Пример конфигурации
└── docs/                 # Дополнительная документация
    ├── api_reference.md  # Справочник по API
    ├── deployment.md     # Руководство по развертыванию
    └── contributing.md   # Гайд для разработчиков
```

## 🔧 Конфигурация

### Переменные окружения

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `TELEGRAM_TOKEN` | Токен Telegram-бота | **Обязательно** |
| `DATABASE_URL` | DSN PostgreSQL | `postgresql://user:password@localhost:5432/mydatabase` |
| `ENTREZ_EMAIL` | Email для PubMed API | `example@example.com` |

### Настройки поиска

- **Максимальное количество результатов**: до 100 статей
- **Семафор для API**: ограничение 10 одновременных запросов
- **Таймауты**: 10-20 секунд для внешних API
- **Интервал планировщика**: проверка подписок каждые 10 минут

## 🎯 API и интеграции

### arXiv API
- Поиск препринтов и научных статей
- Сортировка по дате публикации
- Получение полных метаданных

### PubMed/PMC API
- Поиск в медицинской литературе
- XML-парсинг полных текстов
- Извлечение структурированных аннотаций

### Semantic Scholar API
- Получение данных о цитировании
- Информация о связанных работах
- Списки литературы (references)

### LLM Integration (g4f)
- Модель: deepseek-r1
- Оценка релевантности: 1-100 баллов
- Контекстное ранжирование по области науки

## 🐛 Устранение неполадок

### Частые проблемы

**1. Ошибки подключения к PostgreSQL**
```bash
# Проверьте статус сервиса
sudo systemctl status postgresql

# Перезапустите сервис
sudo systemctl restart postgresql

# Проверьте подключение
psql -h localhost -U your_user -d your_database
```

**2. Проблемы с Libgen**
- Libgen может быть заблокирован в некоторых регионах
- Используйте VPN или отключите Libgen в настройках поиска

**3. Таймауты LLM**
- Бот автоматически повторяет запросы
- При частых таймаутах увеличьте задержки в коде

### Логирование
Бот ведет подробные логи. Для отладки:
```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

## 🤝 Вклад в проект

### Как внести свой вклад

1. **Fork** репозитория
2. Создайте ветку для новой функции: `git checkout -b feature/amazing-feature`
3. Внесите изменения и добавьте тесты
4. Commit: `git commit -m 'Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Создайте **Pull Request**

### Стиль кода
- Следуйте PEP 8
- Используйте типизацию (type hints)
- Добавляйте docstrings для функций
- Покрывайте код тестами

### Области для улучшения
- [ ] Добавление новых источников данных
- [ ] Улучшение LLM-промптов
- [ ] Интеграция с Google Scholar
- [ ] Веб-интерфейс для администрирования
- [ ] Поддержка других языков интерфейса
- [ ] Кэширование результатов поиска
- [ ] Метрики и аналитика использования

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE` для подробностей.

## 🙏 Благодарности

- **arXiv** за открытый доступ к научным препринтам
- **NCBI/PubMed** за медицинскую литературу
- **Library Genesis** за доступ к научным книгам
- **Semantic Scholar** за API цитирований
- Сообществу open-source разработчиков

## 📞 Поддержка

- **Issues**: [GitHub Issues](https://github.com/your-username/scientific-papers-bot/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-username/scientific-papers-bot/discussions)
- **Email**: your-email@example.com

## 🔄 Changelog

### v1.0.0 (Текущая версия)
- ✅ Мультиисточниковый поиск (arXiv, PubMed, Libgen)
- ✅ LLM-ранжирование результатов
- ✅ Система подписок с PostgreSQL
- ✅ Расширенная фильтрация
- ✅ Экспорт в JSON
- ✅ Автоматический планировщик задач

### Планы на будущее
- 🔜 v1.1.0: Поддержка Google Scholar
- 🔜 v1.2.0: Веб-интерфейс
- 🔜 v2.0.0: Мультиязычность

---

**Создано с ❤️ для научного сообщества**
