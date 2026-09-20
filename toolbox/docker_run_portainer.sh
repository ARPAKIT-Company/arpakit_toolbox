#!/usr/bin/env bash
# ARPAKIT Toolbox - запуск (или переустановка) Portainer CE
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/docker_run_portainer.sh)
#   bash docker_run_portainer.sh 9443    # свой HTTP-порт
#
# Настройки через переменные окружения:
#   PORTAINER_IMAGE=portainer/portainer-ce:lts
#   PORTAINER_VOLUME=portainer_volume

set -euo pipefail

HTTP_PORT=${1:-9000}
PORTAINER_IMAGE=${PORTAINER_IMAGE:-portainer/portainer-ce:lts}
PORTAINER_VOLUME=${PORTAINER_VOLUME:-portainer_volume}
CONTAINER_NAME=${CONTAINER_NAME:-portainer}

case "$HTTP_PORT" in
    '' | *[!0-9]*)
        echo "Порт должен быть числом, получено: '$HTTP_PORT'" >&2
        exit 1
        ;;
esac
if [ "$HTTP_PORT" -lt 1 ] || [ "$HTTP_PORT" -gt 65535 ]; then
    echo "Порт должен быть в диапазоне 1-65535, получено: $HTTP_PORT" >&2
    exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "docker не найден: установите его через install_docker.sh" >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker-демон недоступен: запустите его или выполните скрипт через sudo" >&2
    exit 1
fi

echo "==> Загрузка образа $PORTAINER_IMAGE"
docker pull "$PORTAINER_IMAGE"

# контейнера может не быть - тогда удалять нечего, и это не ошибка
if docker ps -aq -f "name=^${CONTAINER_NAME}$" | grep -q .; then
    echo "==> Удаление старого контейнера '$CONTAINER_NAME'"
    docker rm -f "$CONTAINER_NAME" >/dev/null
fi

# том намеренно не удаляем: в нём пользователи, настройки и стеки Portainer
echo "==> Запуск контейнера"
docker run -d \
    --name "$CONTAINER_NAME" \
    --restart=always \
    -p "${HTTP_PORT}:9000" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${PORTAINER_VOLUME}:/data" \
    "$PORTAINER_IMAGE" >/dev/null

docker ps -f "name=^${CONTAINER_NAME}$" --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

HOST_IP=$(hostname -I 2>/dev/null | awk '{ print $1 }')
echo
echo "Portainer: http://${HOST_IP:-localhost}:${HTTP_PORT}"
echo "Данные в томе '$PORTAINER_VOLUME' сохранены между перезапусками."
