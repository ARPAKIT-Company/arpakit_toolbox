#!/usr/bin/env bash
# ARPAKIT Toolbox - остановка всех сервисов xray и удаление их конфигов
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/rm_xray_services.sh)
#
# Останавливает и отключает xray и все xray@*, удаляет *.json из каталога конфигов.
# Сам xray (бинарник, юниты, geodata) остаётся.
#
# Настройки через переменные окружения:
#   XRAY_CONFIGS_DIR=/usr/local/etc/xray

set -euo pipefail

XRAY_CONFIGS_DIR=${XRAY_CONFIGS_DIR:-/usr/local/etc/xray}

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "Нужны права root: запустите от root или установите sudo" >&2
        exit 1
    fi
    SUDO="sudo"
fi

declare -A SERVICES=()

# юниты без конфига тоже останавливаем: иначе продолжат крутиться со старым конфигом в памяти
# имя юнита ищем среди полей строки: у упавших юнитов systemd ставит перед ним ●
while read -r -a fields; do
    for field in "${fields[@]}"; do
        case "$field" in
            xray@*) SERVICES["$field"]=1; break ;;
        esac
    done
done < <(systemctl list-units --plain --no-legend --all 'xray@*' 2>/dev/null || true)

CONFIGS=()
if $SUDO test -d "$XRAY_CONFIGS_DIR"; then
    while IFS= read -r -d '' filepath; do
        CONFIGS+=("$filepath")
        filename=$(basename "$filepath")
        # config.json - конфиг основного юнита xray, остальные - xray@<имя>
        if [ "$filename" != "config.json" ]; then
            SERVICES["xray@${filename%.json}.service"]=1
        fi
    done < <($SUDO find "$XRAY_CONFIGS_DIR" -maxdepth 1 -type f -name '*.json' -print0)
fi

STOPPED_COUNT=0

stop_and_disable() {
    local unit=$1
    # юнита может уже не быть - тогда и останавливать нечего
    if [ -z "$(systemctl list-units --plain --no-legend --all "$unit" 2>/dev/null)" ] \
        && [ -z "$(systemctl list-unit-files --no-legend "$unit" 2>/dev/null)" ]; then
        return 0
    fi
    echo "==> Остановка $unit"
    $SUDO systemctl stop "$unit" || true
    $SUDO systemctl disable "$unit" >/dev/null 2>&1 || true
    STOPPED_COUNT=$((STOPPED_COUNT + 1))
}

if [ "${#SERVICES[@]}" -gt 0 ]; then
    while IFS= read -r unit; do
        stop_and_disable "$unit"
    done < <(printf '%s\n' "${!SERVICES[@]}" | sort)
fi

stop_and_disable xray.service

for filepath in "${CONFIGS[@]}"; do
    echo "==> Удаление $filepath"
    $SUDO rm -f "$filepath"
done

echo
echo "Готово: остановлено юнитов xray: $STOPPED_COUNT, удалено конфигов: ${#CONFIGS[@]}"
