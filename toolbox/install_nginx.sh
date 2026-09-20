#!/usr/bin/env bash
# ARPAKIT Toolbox - установка nginx
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_nginx.sh)

set -euo pipefail

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Нужны права root: запустите от root или установите sudo" >&2
        exit 1
    fi
    SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive

echo "==> Обновление списка пакетов"
$SUDO apt-get update -y

echo "==> Установка nginx"
$SUDO apt-get install -y nginx

echo "==> Каталог для сертификатов"
# -p, чтобы повторный запуск скрипта не падал на уже существующем каталоге
$SUDO mkdir -p /etc/nginx/ssl
$SUDO chmod 700 /etc/nginx/ssl

echo "==> Проверка конфигурации"
$SUDO nginx -t

echo "==> Запуск сервиса"
$SUDO systemctl enable nginx
$SUDO systemctl restart nginx

echo
# hash -r: bash кеширует пути к командам, и свежеустановленный бинарник
# может не найтись в уже запущенной оболочке
hash -r
if command -v nginx >/dev/null 2>&1; then
    echo "nginx установлен: $(nginx -v 2>&1)"
else
    echo "Предупреждение: nginx установлен, но бинарник не найден в PATH" >&2
fi
$SUDO systemctl --no-pager --lines=0 status nginx || true
