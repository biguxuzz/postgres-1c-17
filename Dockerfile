FROM ubuntu:22.04

# Установка необходимых зависимостей
RUN apt-get update && apt-get install -y \
    wget \
    apt-utils \
    apt-transport-https \
    ca-certificates \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Установка локали
RUN locale-gen ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8

# Добавление репозитория PostgresPro 1C-17
RUN wget -O pgpro-repo-add.sh https://repo.postgrespro.ru/1c/1c-17/keys/pgpro-repo-add.sh \
    && sh pgpro-repo-add.sh \
    && rm pgpro-repo-add.sh

# Установка PostgresPro 1C-17
RUN apt-get update && apt-get install -y postgrespro-1c-17-contrib \
    && rm -rf /var/lib/apt/lists/*

# Создание каталога данных
RUN mkdir -p /var/lib/pgpro/1c-17/data 

# Инициализация базы данных
RUN /opt/pgpro/1c-17/bin/pg-setup initdb -D /var/lib/pgpro/1c-17/data

# Настройка конфигурации
RUN echo "listen_addresses = '*'" >> /var/lib/pgpro/1c-17/data/postgresql.conf \
    && echo "host all all all scram-sha-256" >> /var/lib/pgpro/1c-17/data/pg_hba.conf

# Копирование скрипта запуска
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Открытие порта
EXPOSE 5432

# Точка монтирования
VOLUME ["/var/lib/pgpro/1c-17/data"]

# Установка переменной PATH
ENV PATH $PATH:/opt/pgpro/1c-17/bin

# Точка входа
ENTRYPOINT ["/docker-entrypoint.sh"]

# Команда по умолчанию
CMD ["postgres", "-D", "/var/lib/pgpro/1c-17/data"] 