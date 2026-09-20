#!/usr/bin/env bash
# ARPAKIT Toolbox - установка certbot (Let's Encrypt) через snap
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_certbot.sh)

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

echo "==> Установка snapd"
$SUDO apt-get install -y snapd

echo "==> Обновление snap core"
$SUDO snap install core
$SUDO snap refresh core

# пакетный certbot из apt конфликтует со snap-версией
if dpkg -s certbot >/dev/null 2>&1; then
    echo "==> Удаление apt-версии certbot"
    $SUDO apt-get remove -y certbot
fi

echo "==> Установка certbot"
$SUDO snap install --classic certbot

# snap кладёт бинарник в /snap/bin, который не всегда в PATH у сервисов и cron
$SUDO ln -sf /snap/bin/certbot /usr/bin/certbot

echo
hash -r
if command -v certbot >/dev/null 2>&1; then
    echo "certbot установлен: $(certbot --version 2>&1)"
else
    echo "Предупреждение: certbot установлен, но бинарник не найден в PATH" >&2
fi
echo
echo "Выпуск сертификата для nginx:"
echo "  sudo certbot --nginx -d example.com -d www.example.com"
echo "Автопродление уже настроено systemd-таймером snap, проверить: sudo certbot renew --dry-run"
