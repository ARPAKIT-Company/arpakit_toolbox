#!/usr/bin/env bash
# ARPAKIT Toolbox - установка Docker CE из официального репозитория
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_docker.sh)
#
# Поддерживаются Ubuntu и Debian.

set -euo pipefail

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Нужны права root: запустите от root или установите sudo" >&2
        exit 1
    fi
    SUDO="sudo"
fi

# дистрибутив и кодовое имя релиза берём из системы, а не хардкодим
. /etc/os-release
DISTRO_ID=${ID:-ubuntu}
CODENAME=${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}
if [ -z "$CODENAME" ] && command -v lsb_release >/dev/null 2>&1; then
    CODENAME=$(lsb_release -cs)
fi
if [ -z "$CODENAME" ]; then
    echo "Не удалось определить кодовое имя релиза" >&2
    exit 1
fi

case "$DISTRO_ID" in
    ubuntu | debian) ;;
    *)
        echo "Дистрибутив '$DISTRO_ID' не поддерживается этим скриптом" >&2
        exit 1
        ;;
esac

echo "==> Дистрибутив: $DISTRO_ID $CODENAME"

export DEBIAN_FRONTEND=noninteractive

echo "==> Обновление списка пакетов"
$SUDO apt-get update -y

echo "==> Удаление конфликтующих пакетов"
# старые имена пакетов Docker: если их нет, apt-get не должен валить скрипт
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    $SUDO apt-get remove -y "$pkg" >/dev/null 2>&1 || true
done

echo "==> Установка зависимостей"
$SUDO apt-get install -y ca-certificates curl gnupg

echo "==> Добавление GPG-ключа Docker"
$SUDO install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" \
    | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
$SUDO chmod a+r /etc/apt/keyrings/docker.gpg

echo "==> Подключение репозитория Docker"
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO_ID} ${CODENAME} stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

$SUDO apt-get update -y

echo "==> Установка Docker CE"
$SUDO apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "==> Запуск сервиса"
if command -v systemctl >/dev/null 2>&1; then
    $SUDO systemctl enable docker
    $SUDO systemctl start docker
fi

echo "==> Проверка"
$SUDO docker run --rm hello-world

# группа docker может уже существовать - это не ошибка
$SUDO groupadd -f docker

# добавляем в группу того, кто запустил sudo, а не root
TARGET_USER=${SUDO_USER:-$(id -un)}
if [ "$TARGET_USER" != "root" ]; then
    $SUDO usermod -aG docker "$TARGET_USER"
    echo "==> Пользователь '$TARGET_USER' добавлен в группу docker"
    echo "    Чтобы работать с docker без sudo, перелогиньтесь или выполните: newgrp docker"
fi

echo
hash -r
if command -v docker >/dev/null 2>&1; then
    echo "Docker установлен: $(docker --version)"
else
    echo "Предупреждение: бинарник docker не найден в PATH" >&2
fi
