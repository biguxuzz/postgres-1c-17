#!/bin/bash
set -e

# Проверка необходимых переменных окружения
if [ -z "$POSTGRES_PASSWORD" ]; then
    echo "Ошибка: переменная POSTGRES_PASSWORD не задана"
    exit 1
fi

# Имена пользователя и БД по умолчанию
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_DB=${POSTGRES_DB:-postgres}

# Директория с данными
PGDATA="/var/lib/postgresql/17/main"

# Проверка прав доступа к каталогу данных
chown -R postgres:postgres "$PGDATA"
chmod 700 "$PGDATA"

# Функция для выполнения SQL-запросов от имени postgres
postgres_exec() {
    su - postgres -c "psql -v ON_ERROR_STOP=1 --username postgres --no-password -c \"$1\""
}

# Если сервер еще не инициализирован
if [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ]; then
    echo "Инициализация базы данных..."
    # Запуск pg-setup от root
    /opt/pgpro/ent-17/bin/pg-setup initdb --tune=1c -D "$PGDATA" --locale-provider=icu --locale=ru_RU.UTF-8 --lc-collate=ru_RU.UTF-8 --lc-ctype=ru_RU.UTF-8 --lc-messages=ru_RU.UTF-8 --lc-monetary=ru_RU.UTF-8 --lc-numeric=ru_RU.UTF-8 --lc-time=ru_RU.UTF-8
    
    # Настройка конфигурации
    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
    echo "host all all all md5" >> "$PGDATA/pg_hba.conf"
    
    # Запуск сервера для настройки
    su - postgres -c "pg_ctl -D $PGDATA -o '-c listen_addresses=localhost' -w start"
    
    # Смена пароля postgres
    postgres_exec "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"
    
    # Создание пользователя и БД, если нужно
    if [ "$POSTGRES_USER" != "postgres" ]; then
        postgres_exec "CREATE USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';"
    fi
    
    if [ "$POSTGRES_DB" != "postgres" ]; then
        postgres_exec "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER LOCALE_PROVIDER=icu LOCALE='ru_RU.UTF-8' LC_COLLATE='ru_RU.UTF-8' LC_CTYPE='ru_RU.UTF-8' LC_MESSAGES='ru_RU.UTF-8' LC_MONETARY='ru_RU.UTF-8' LC_NUMERIC='ru_RU.UTF-8' LC_TIME='ru_RU.UTF-8' TEMPLATE=template0;"
    fi
    
    # Остановка сервера
    su - postgres -c "pg_ctl -D $PGDATA -m fast -w stop"
    
    echo "Инициализация базы данных завершена."
else
    echo "База данных уже инициализирована."
fi

# Запуск PostgreSQL
if [ "$1" = 'postgres' ]; then
    exec su - postgres -c "postgres -D $PGDATA"
fi

# Если передана другая команда, выполнить её
exec "$@" 