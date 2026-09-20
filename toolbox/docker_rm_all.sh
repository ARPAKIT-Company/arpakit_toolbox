#!/usr/bin/env bash
# ARPAKIT Toolbox - полная очистка Docker на хосте
#
# ВНИМАНИЕ: удаляет ВСЕ контейнеры, образы, тома и пользовательские сети.
# Данные в томах восстановить нельзя.
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/docker_rm_all.sh)
#   bash docker_rm_all.sh -y     # без подтверждения

set -uo pipefail

ASSUME_YES=${FORCE:-0}
for arg in "$@"; do
    case "$arg" in
        -y | --yes) ASSUME_YES=1 ;;
        -h | --help)
            # печатаем шапку файла: всё до первой строки, которая не комментарий
            awk 'NR > 1 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "$0"
            exit 0
            ;;
        *)
            echo "Неизвестный аргумент: $arg" >&2
            exit 1
            ;;
    esac
done

if ! command -v docker >/dev/null 2>&1; then
    echo "docker не найден" >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker-демон недоступен: запустите его или выполните скрипт через sudo" >&2
    exit 1
fi

containers=$(docker ps -aq)
images=$(docker images -aq)
volumes=$(docker volume ls -q)
# дефолтные сети bridge/host/none удалить нельзя, поэтому исключаем их сразу
networks=$(docker network ls --format '{{.ID}} {{.Name}}' \
    | awk '$2 != "bridge" && $2 != "host" && $2 != "none" { print $1 }')

count() { [ -z "$1" ] && echo 0 || printf '%s\n' "$1" | wc -l | tr -d ' '; }

echo "Будет удалено:"
echo "  контейнеров: $(count "$containers")"
echo "  образов:     $(count "$images")"
echo "  томов:       $(count "$volumes")"
echo "  сетей:       $(count "$networks")"
echo "  весь кеш сборки"

if [ -z "$containers$images$volumes$networks" ]; then
    echo
    echo "Нечего удалять, кроме кеша сборки."
fi

if [ "$ASSUME_YES" != "1" ]; then
    echo
    printf 'Данные в томах будут потеряны безвозвратно. Введите "yes" для продолжения: '
    if [ -r /dev/tty ]; then
        read -r answer < /dev/tty
    else
        read -r answer
    fi
    if [ "$answer" != "yes" ]; then
        echo "Отменено."
        exit 0
    fi
fi

# каждый шаг может не найти объектов - это не повод останавливаться,
# поэтому пустые списки пропускаем, а ошибки отдельных объектов игнорируем
[ -n "$containers" ] && { echo "==> Остановка контейнеров"; docker stop $containers >/dev/null 2>&1 || true; }
[ -n "$containers" ] && { echo "==> Удаление контейнеров"; docker rm -f $containers >/dev/null 2>&1 || true; }
[ -n "$images" ] && { echo "==> Удаление образов"; docker rmi -f $images >/dev/null 2>&1 || true; }
[ -n "$volumes" ] && { echo "==> Удаление томов"; docker volume rm -f $volumes >/dev/null 2>&1 || true; }
[ -n "$networks" ] && { echo "==> Удаление сетей"; docker network rm $networks >/dev/null 2>&1 || true; }

echo "==> Очистка кеша сборки"
docker builder prune -af >/dev/null 2>&1 || true

echo
echo "Готово. Осталось:"
echo "  контейнеров: $(docker ps -aq | wc -l | tr -d ' ')"
echo "  образов:     $(docker images -aq | wc -l | tr -d ' ')"
echo "  томов:       $(docker volume ls -q | wc -l | tr -d ' ')"
docker system df 2>/dev/null || true
