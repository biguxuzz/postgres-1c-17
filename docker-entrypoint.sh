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
PGDATA="/var/lib/pgpro/1c-17/data"

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
    su - postgres -c "/opt/pgpro/1c-17/bin/initdb -D $PGDATA"
    
    # Настройка конфигурации
    echo "listen_addresses = '*'" >> "$PGDATA/postgresql.conf"
    echo "host all all all scram-sha-256" >> "$PGDATA/pg_hba.conf"
    
    # Запуск сервера для настройки
    su - postgres -c "/opt/pgpro/1c-17/bin/pg_ctl -D $PGDATA -o '-c listen_addresses=localhost' -w start"
    
    # Смена пароля postgres
    postgres_exec "ALTER USER postgres WITH PASSWORD '$POSTGRES_PASSWORD';"
    
    # Создание пользователя и БД, если нужно
    if [ "$POSTGRES_USER" != "postgres" ]; then
        postgres_exec "CREATE USER $POSTGRES_USER WITH SUPERUSER PASSWORD '$POSTGRES_PASSWORD';"
    fi
    
    if [ "$POSTGRES_DB" != "postgres" ]; then
        postgres_exec "CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER;"
    fi
    
    # Остановка сервера
    su - postgres -c "/opt/pgpro/1c-17/bin/pg_ctl -D $PGDATA -m fast -w stop"
    
    echo "Инициализация базы данных завершена."
else
    echo "База данных уже инициализирована."
fi

# Запуск PostgreSQL
if [ "$1" = 'postgres' ]; then
    exec su - postgres -c "/opt/pgpro/1c-17/bin/postgres -D $PGDATA"
fi

# Если передана другая команда, выполнить её
exec "$@" 