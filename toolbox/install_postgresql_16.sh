#!/usr/bin/env bash
# ARPAKIT Toolbox - установка PostgreSQL 16 из репозитория PGDG
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_postgresql_16.sh)
#
# Другая мажорная версия:
#   PG_VERSION=17 bash install_postgresql_16.sh

set -euo pipefail

PG_VERSION=${PG_VERSION:-16}

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Нужны права root: запустите от root или установите sudo" >&2
        exit 1
    fi
    SUDO="sudo"
fi

# кодовое имя релиза берём из системы: раньше здесь был захардкожен noble,
# и на любом другом релизе подключался чужой репозиторий
. /etc/os-release
CODENAME=${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}
if [ -z "$CODENAME" ] && command -v lsb_release >/dev/null 2>&1; then
    CODENAME=$(lsb_release -cs)
fi
if [ -z "$CODENAME" ]; then
    echo "Не удалось определить кодовое имя релиза" >&2
    exit 1
fi

echo "==> Релиз: $CODENAME, PostgreSQL: $PG_VERSION"

export DEBIAN_FRONTEND=noninteractive

echo "==> Обновление списка пакетов"
$SUDO apt-get update -y

echo "==> Установка зависимостей"
$SUDO apt-get install -y ca-certificates curl gnupg

echo "==> Добавление GPG-ключа PGDG"
$SUDO install -m 0755 -d /usr/share/keyrings
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | $SUDO gpg --dearmor --yes -o /usr/share/keyrings/postgresql.gpg
$SUDO chmod a+r /usr/share/keyrings/postgresql.gpg

echo "==> Подключение репозитория PGDG"
echo "deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" \
    | $SUDO tee /etc/apt/sources.list.d/pgdg.list >/dev/null

$SUDO apt-get update -y

if ! apt-cache show "postgresql-${PG_VERSION}" >/dev/null 2>&1; then
    echo "Пакет postgresql-${PG_VERSION} недоступен для релиза ${CODENAME}" >&2
    echo "Проверьте список релизов: https://apt.postgresql.org/pub/repos/apt/dists/" >&2
    exit 1
fi

echo "==> Установка PostgreSQL"
$SUDO apt-get install -y \
    "postgresql-${PG_VERSION}" \
    "postgresql-contrib-${PG_VERSION}" \
    "postgresql-client-${PG_VERSION}"

echo "==> Запуск сервиса"
$SUDO systemctl enable postgresql.service
$SUDO systemctl start postgresql.service

echo
echo "PostgreSQL установлен: $(psql --version)"
$SUDO systemctl --no-pager --lines=0 status postgresql || true
echo
echo "Вход в консоль:        sudo -u postgres psql"
echo "Пароль для postgres:   sudo -u postgres psql -c \"ALTER USER postgres WITH PASSWORD 'пароль';\""
