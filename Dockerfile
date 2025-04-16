FROM ubuntu:24.04

# Установка необходимых зависимостей
RUN apt-get update && apt-get install -y \
    apt-utils \
    apt-transport-https \
    ca-certificates \
    locales \
    libgssapi-krb5-2 \
    libldap2 \
    libicu74 \
    libreadline8t64 \
    libxml2 \
    libxslt1.1 \
    libunwind8 \
    tzdata \
    ssl-cert \
    && rm -rf /var/lib/apt/lists/*

# Установка локали
RUN locale-gen ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LC_ALL ru_RU.UTF-8

# Создание директории для .deb файлов
RUN mkdir -p /opt/pgpro/debs

# Копирование .deb файлов
COPY debs/postgrespro-ent-17_17.4.1-1.noble_amd64.deb /opt/pgpro/debs/
COPY debs/postgrespro-ent-17-libs_17.4.1-1.noble_amd64.deb /opt/pgpro/debs/
COPY debs/postgrespro-ent-17-client_17.4.1-1.noble_amd64.deb /opt/pgpro/debs/
COPY debs/postgrespro-ent-17-contrib_17.4.1-1.noble_amd64.deb /opt/pgpro/debs/
COPY debs/postgrespro-ent-17-server_17.4.1-1.noble_amd64.deb /opt/pgpro/debs/

# Установка PostgresPro из .deb файлов
RUN apt-get update && \
    dpkg -i /opt/pgpro/debs/postgrespro-ent-17_17.4.1-1.noble_amd64.deb || true && \
    dpkg -i /opt/pgpro/debs/postgrespro-ent-17-libs_17.4.1-1.noble_amd64.deb || true && \
    dpkg -i /opt/pgpro/debs/postgrespro-ent-17-client_17.4.1-1.noble_amd64.deb || true && \
    dpkg -i /opt/pgpro/debs/postgrespro-ent-17-contrib_17.4.1-1.noble_amd64.deb || true && \
    dpkg -i /opt/pgpro/debs/postgrespro-ent-17-server_17.4.1-1.noble_amd64.deb || true && \
    apt-get -f install -y && \
    rm -rf /var/lib/apt/lists/*

# Создание каталога данных
RUN mkdir -p /var/lib/postgresql/17/main

# Копирование скрипта запуска
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Открытие порта
EXPOSE 5432

# Точка монтирования
VOLUME ["/var/lib/postgresql/17/main"]

# Установка переменной PATH
ENV PATH $PATH:/usr/lib/postgresql/17/bin

# Точка входа
ENTRYPOINT ["/docker-entrypoint.sh"]

# Команда по умолчанию
CMD ["postgres", "-D", "/var/lib/postgresql/17/main"] 