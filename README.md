# PostgresPro 1C-17 Docker

Этот проект предоставляет Docker-образ для развертывания СУБД PostgresPro 1C-17 в изолированном окружении.

## Требования

- Docker версии 20.10+
- Docker Compose версии 1.29+ (для использования docker-compose.yml)

## Быстрый старт

### Запуск с использованием Docker Compose

1. Клонируйте репозиторий:
   ```bash
   git clone <url-репозитория>
   cd <директория-репозитория>
   ```

2. Запустите контейнер:
   ```bash
   docker-compose up -d
   ```

### Запуск с использованием Docker

1. Соберите образ:
   ```bash
   docker build -t postgrespro-1c-17:latest .
   ```

2. Запустите контейнер:
   ```bash
   docker run -d \
     --name postgrespro-1c \
     -e POSTGRES_PASSWORD=mysecretpassword \
     -v pgdata:/var/lib/pgpro/1c-17/data \
     -p 5432:5432 \
     postgrespro-1c-17:latest
   ```

## Переменные окружения

| Переменная              | Значение по умолчанию | Описание                  |
|-------------------------|-----------------------|---------------------------|
| `POSTGRES_USER`         | `postgres`            | Суперпользователь БД.     |
| `POSTGRES_PASSWORD`     | *Обязательно*         | Пароль суперпользователя. |
| `POSTGRES_DB`           | `postgres`            | Имя базы данных.          |

## Тома данных

Данные PostgreSQL сохраняются в Docker-томе `pgdata`. Чтобы обеспечить сохранность данных при перезапуске контейнера, всегда используйте этот том.

## Подключение к базе данных

```bash
# Из другого контейнера
psql -h postgrespro-1c -U postgres

# С хост-машины
psql -h localhost -U postgres
```

## Тестирование

1. Проверка доступности порта:  
   ```bash
   telnet localhost 5432
   ```
2. Подключение к БД:  
   ```bash
   psql -U postgres -h localhost
   ```

## Примечания

- Данные БД сохраняются в Docker-томе `pgdata`.
- Для кастомизации конфигурации используйте файлы в `/var/lib/pgpro/1c-17/data`. 