#!/usr/bin/env bash
# ARPAKIT Toolbox - установка Docker CE конкретной версии и фиксация её через apt-mark
#
# Нужно для старого Portainer, который не умеет работать с новым Docker API.
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_docker_for_old_portainer.sh)
#
# Версия задаётся переменной окружения:
#   DOCKER_VERSION=28.5.2 bash install_docker_for_old_portainer.sh

set -euo pipefail

DOCKER_VERSION=${DOCKER_VERSION:-28.5.2}

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Нужны права root: запустите от root или установите sudo" >&2
        exit 1
    fi
    SUDO="sudo"
fi

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

echo "==> Дистрибутив: $DISTRO_ID $CODENAME, целевая версия Docker: $DOCKER_VERSION"

export DEBIAN_FRONTEND=noninteractive

$SUDO apt-get update -y

for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    $SUDO apt-get remove -y "$pkg" >/dev/null 2>&1 || true
done

$SUDO apt-get install -y ca-certificates curl gnupg

$SUDO install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${DISTRO_ID}/gpg" \
    | $SUDO gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
$SUDO chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DISTRO_ID} ${CODENAME} stable" \
    | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

$SUDO apt-get update -y

# полная версия пакета зависит от релиза дистрибутива (5:28.5.2-1~ubuntu.24.04~noble),
# поэтому подбираем её в репозитории, а не хардкодим
resolve_version() {
    apt-cache madison "$1" 2>/dev/null \
        | awk -v v="$DOCKER_VERSION" -F'|' '$2 ~ v { gsub(/ /, "", $2); print $2; exit }'
}

DOCKER_CE_VERSION=$(resolve_version docker-ce)
DOCKER_CLI_VERSION=$(resolve_version docker-ce-cli)

if [ -z "$DOCKER_CE_VERSION" ] || [ -z "$DOCKER_CLI_VERSION" ]; then
    echo "Версия $DOCKER_VERSION не найдена в репозитории для $DISTRO_ID $CODENAME" >&2
    echo "Доступные версии docker-ce:" >&2
    apt-cache madison docker-ce | awk -F'|' '{ print "  " $2 }' >&2
    exit 1
fi

echo "==> Устанавливаем docker-ce=$DOCKER_CE_VERSION"
$SUDO apt-get install -y \
    "docker-ce=$DOCKER_CE_VERSION" \
    "docker-ce-cli=$DOCKER_CLI_VERSION" \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

if command -v systemctl >/dev/null 2>&1; then
    $SUDO systemctl enable docker
    $SUDO systemctl start docker
fi

echo "==> Проверка"
$SUDO docker run --rm hello-world

$SUDO groupadd -f docker

TARGET_USER=${SUDO_USER:-$(id -un)}
if [ "$TARGET_USER" != "root" ]; then
    $SUDO usermod -aG docker "$TARGET_USER"
    echo "==> Пользователь '$TARGET_USER' добавлен в группу docker"
    echo "    Чтобы работать с docker без sudo, перелогиньтесь или выполните: newgrp docker"
fi

# без hold обычный apt upgrade снова поднимет версию
echo "==> Фиксация версии (apt-mark hold)"
$SUDO apt-mark hold docker-ce docker-ce-cli

echo
echo "Docker установлен и зафиксирован: $(docker --version)"
echo "Снять фиксацию: sudo apt-mark unhold docker-ce docker-ce-cli"
