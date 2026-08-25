#!/bin/sh
# ARPAKIT Toolbox - проверка скорости сети сервера
#
# Меряет задержку, загрузку и отдачу по нескольким независимым источникам.
# Любой источник может быть недоступен - это не прерывает проверку,
# такой источник просто помечается как недоступный.
#
# Запуск:
#   bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/speed_test.sh)
#   sh speed_test.sh                  # то же самое локально
#   sh speed_test.sh 1.2.3.4 ya.ru    # добавить свои цели для замера задержки
#
# Настройки через переменные окружения:
#   DL_MAX_TIME=8   секунд на один источник загрузки
#   UL_MAX_TIME=8   секунд на отдачу
#   PING_COUNT=5    пакетов на цель
#   NO_COLOR=1      отключить цвет

set -u

DL_MAX_TIME=${DL_MAX_TIME:-8}
UL_MAX_TIME=${UL_MAX_TIME:-8}
CONNECT_TIMEOUT=${CONNECT_TIMEOUT:-5}
PING_COUNT=${PING_COUNT:-5}
UPLOAD_MB=${UPLOAD_MB:-10}
BAR_WIDTH=24
USER_AGENT="arpakit-toolbox-speed-test/1.0"

# ---------------------------------------------------------------- оформление

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$(printf '\033[0m')
    C_DIM=$(printf '\033[2m')
    C_BOLD=$(printf '\033[1m')
    C_RED=$(printf '\033[31m')
    C_GREEN=$(printf '\033[32m')
    C_YELLOW=$(printf '\033[33m')
    C_BLUE=$(printf '\033[34m')
    C_CYAN=$(printf '\033[36m')
    ERASE=$(printf '\r\033[2K')
    IS_TTY=1
else
    C_RESET='' C_DIM='' C_BOLD='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN=''
    ERASE=''
    IS_TTY=0
fi

# Ширина колонок считается в символах, а не в байтах: у кириллицы и '·'
# по 2 байта на символ, и printf '%-30s' разъезжается на них.
# Кладёт в PAD добивку пробелами до нужной ширины.
pad_to() {
    _n=$(printf '%s' "$1" | wc -m 2>/dev/null | tr -d ' ')
    [ -z "$_n" ] && _n=0
    _i=$(( $2 - _n ))
    PAD=''
    while [ "$_i" -gt 0 ]; do
        PAD="$PAD "
        _i=$((_i - 1))
    done
}

# прогресс имеет смысл только в терминале, где его можно затереть
progress() {
    [ "$IS_TTY" = "1" ] || return 0
    pad_to "$1" "$2"
    printf '  %s%s %s…%s' "$1" "$PAD" "$C_DIM" "$C_RESET"
}

section() {
    printf '\n%s%s%s\n' "$C_BOLD$C_CYAN" "$1" "$C_RESET"
    printf '%s%s%s\n' "$C_DIM" "────────────────────────────────────────────────────────────────" "$C_RESET"
}

info_row() {
    pad_to "$1" 14
    printf '  %s%s %s\n' "$1" "$PAD" "$2"
}

# скорость в Мбит/с из байт/с
to_mbps() {
    LC_ALL=C awk -v b="$1" 'BEGIN { printf "%.1f", b * 8 / 1000000 }'
}

# цвет по скорости: медленно / нормально / быстро
speed_color() {
    LC_ALL=C awk -v v="$1" 'BEGIN { if (v < 20) print "red"; else if (v < 100) print "yellow"; else print "green" }'
}

colorize() {
    case "$1" in
        red) printf '%s' "$C_RED" ;;
        yellow) printf '%s' "$C_YELLOW" ;;
        green) printf '%s' "$C_GREEN" ;;
        *) printf '' ;;
    esac
}

render_bar() {
    LC_ALL=C awk -v v="$1" -v max="$2" -v w="$BAR_WIDTH" 'BEGIN {
        n = (max <= 0) ? 0 : int(v / max * w + 0.5)
        if (n > w) n = w
        if (n < 1 && v > 0) n = 1
        s = ""
        for (i = 0; i < n; i++) s = s "█"
        for (i = n; i < w; i++) s = s "░"
        printf "%s", s
    }'
}

# ---------------------------------------------------------------- подготовка

if ! command -v curl >/dev/null 2>&1; then
    printf '%sНе найден curl. Установите: sudo apt-get install -y curl%s\n' "$C_RED" "$C_RESET" >&2
    exit 1
fi

TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t arpakit-speed)
DL_RESULTS="$TMP_DIR/dl"
UL_RESULTS="$TMP_DIR/ul"
: > "$DL_RESULTS"
: > "$UL_RESULTS"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

printf '\n%s╔════════════════════════════════════════════════════════════╗%s\n' "$C_BOLD$C_BLUE" "$C_RESET"
printf '%s║   ARPAKIT  ·  проверка скорости сети сервера                ║%s\n' "$C_BOLD$C_BLUE" "$C_RESET"
printf '%s╚════════════════════════════════════════════════════════════╝%s\n' "$C_BOLD$C_BLUE" "$C_RESET"

# ---------------------------------------------------------------- система

section "СИСТЕМА"

os_name="неизвестно"
if [ -r /etc/os-release ]; then
    os_name=$(. /etc/os-release 2>/dev/null && printf '%s' "${PRETTY_NAME:-$NAME}")
fi

cpu_cores=$(nproc 2>/dev/null || printf '?')
cpu_model=$(awk -F': ' '/model name/ { print $2; exit }' /proc/cpuinfo 2>/dev/null)
[ -z "$cpu_model" ] && cpu_model="неизвестно"

ram_total="?"
if [ -r /proc/meminfo ]; then
    ram_total=$(awk '/MemTotal/ { printf "%.1f GB", $2 / 1048576 }' /proc/meminfo)
fi

info_row "Хост" "$(hostname 2>/dev/null || printf '?')"
info_row "ОС" "$os_name"
info_row "Ядро" "$(uname -r 2>/dev/null || printf '?')"
info_row "CPU" "$cpu_model ($cpu_cores ядер)"
info_row "RAM" "$ram_total"
info_row "Аптайм" "$(uptime -p 2>/dev/null || printf '?')"

# ---------------------------------------------------------------- сеть: кто мы

section "ВНЕШНИЙ АДРЕС"

# несколько источников подряд: первый ответивший выигрывает
ip_info=""
for endpoint in \
    "https://ipinfo.io/json" \
    "https://ifconfig.co/json" \
    "http://ip-api.com/json/?fields=query,isp,org,city,country"
do
    ip_info=$(curl -fsS --connect-timeout "$CONNECT_TIMEOUT" --max-time 10 \
        -A "$USER_AGENT" "$endpoint" 2>/dev/null) || ip_info=""
    [ -n "$ip_info" ] && break
done

json_field() {
    printf '%s' "$ip_info" | tr -d '\n' | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}

if [ -n "$ip_info" ]; then
    ext_ip=$(json_field "ip"); [ -z "$ext_ip" ] && ext_ip=$(json_field "query")
    ext_org=$(json_field "org"); [ -z "$ext_org" ] && ext_org=$(json_field "isp")
    ext_asn=$(json_field "asn_org")
    ext_city=$(json_field "city")
    ext_country=$(json_field "country"); [ -z "$ext_country" ] && ext_country=$(json_field "country_iso")

    info_row "IP" "${ext_ip:-?}"
    info_row "Провайдер" "${ext_org:-${ext_asn:-?}}"
    info_row "Локация" "${ext_city:-?}, ${ext_country:-?}"
else
    printf '  %sне удалось определить: все источники недоступны%s\n' "$C_YELLOW" "$C_RESET"
fi

# ---------------------------------------------------------------- задержка

section "ЗАДЕРЖКА"

printf '  %s%-26s %10s %8s %10s%s\n' "$C_DIM" "цель" "ping" "потери" "tcp" "$C_RESET"

check_latency() {
    label=$1
    host=$2

    progress "$label" 26

    ping_avg="—"
    ping_loss="—"
    if command -v ping >/dev/null 2>&1; then
        ping_out=$(ping -n -c "$PING_COUNT" -W 2 "$host" 2>/dev/null)
        if [ -n "$ping_out" ]; then
            avg=$(printf '%s' "$ping_out" | awk -F'/' '/^(rtt|round-trip)/ { printf "%.1f", $5 }')
            [ -n "$avg" ] && ping_avg="$avg ms"
            loss=$(printf '%s' "$ping_out" | sed -n 's/.*[^0-9]\([0-9][0-9]*\)% packet loss.*/\1/p' | head -1)
            [ -n "$loss" ] && ping_loss="$loss%"
        fi
    fi

    # tcp-рукопожатие: работает там, где icmp зарезан
    tcp_ms="—"
    tcp_raw=$(curl -o /dev/null -s --connect-timeout "$CONNECT_TIMEOUT" --max-time 10 \
        -w '%{time_connect}' "http://$host" 2>/dev/null)
    if [ -n "$tcp_raw" ]; then
        tcp_ms=$(LC_ALL=C awk -v t="$tcp_raw" 'BEGIN { if (t > 0) printf "%.1f ms", t * 1000; else printf "—" }')
    fi

    loss_color=""
    case "$ping_loss" in
        "0%") loss_color="$C_GREEN" ;;
        "—") loss_color="$C_DIM" ;;
        *) loss_color="$C_RED" ;;
    esac

    pad_to "$label" 26
    printf '%s  %s%s %10s %s%8s%s %10s\n' \
        "$ERASE" "$label" "$PAD" "$ping_avg" "$loss_color" "$ping_loss" "$C_RESET" "$tcp_ms"
}

check_latency "Cloudflare · 1.1.1.1" "1.1.1.1"
check_latency "Google · 8.8.8.8" "8.8.8.8"
check_latency "Yandex · 77.88.8.8" "77.88.8.8"
check_latency "Hetzner · Falkenstein" "fsn1-speed.hetzner.com"

# дополнительные цели из аргументов
for extra_host do
    check_latency "своя цель · $extra_host" "$extra_host"
done

# ---------------------------------------------------------------- загрузка

section "ЗАГРУЗКА  (${DL_MAX_TIME}с на источник)"

measure_download() {
    label=$1
    url=$2

    progress "$label" 30

    out=$(curl -o /dev/null -s \
        --connect-timeout "$CONNECT_TIMEOUT" \
        --max-time "$DL_MAX_TIME" \
        -A "$USER_AGENT" \
        -w '%{http_code} %{size_download} %{speed_download}' \
        "$url" 2>/dev/null)

    http=$(printf '%s' "$out" | awk '{ print $1 }')
    size=$(printf '%s' "$out" | awk '{ print $2 }')
    speed=$(printf '%s' "$out" | awk '{ print $3 }')

    # обрыв по --max-time - это штатно, мы сами режем замер;
    # отказ - это когда нет http-ответа 2xx или не пришло ни байта
    ok=$(LC_ALL=C awk -v h="${http:-000}" -v s="${size:-0}" 'BEGIN {
        print (h ~ /^2/ && s + 0 > 0) ? "1" : "0"
    }')

    if [ "$ok" = "1" ]; then
        mbps=$(to_mbps "${speed:-0}")
        mib=$(LC_ALL=C awk -v s="$size" 'BEGIN { printf "%.0f", s / 1048576 }')
        col=$(colorize "$(speed_color "$mbps")")
        pad_to "$label" 30
        printf '%s  %s%s %s%9s Mbit/s%s  %s%s MiB%s\n' \
            "$ERASE" "$label" "$PAD" "$col" "$mbps" "$C_RESET" "$C_DIM" "$mib" "$C_RESET"
        printf '%s|%s\n' "$label" "$mbps" >> "$DL_RESULTS"
    else
        reason="недоступен"
        [ "${http:-000}" != "000" ] && reason="http ${http}"
        pad_to "$label" 30
        printf '%s  %s%s %s%16s%s\n' "$ERASE" "$label" "$PAD" "$C_RED" "$reason" "$C_RESET"
    fi
}

# label|url - источники разнесены географически и по операторам
measure_download "Cloudflare · anycast"      "https://speed.cloudflare.com/__down?bytes=50000000"
measure_download "Hetzner · Falkenstein DE"  "https://fsn1-speed.hetzner.com/100MB.bin"
measure_download "Hetzner · Nürnberg DE"     "https://nbg1-speed.hetzner.com/100MB.bin"
measure_download "Hetzner · Ashburn US"      "https://ash-speed.hetzner.com/100MB.bin"
measure_download "Hetzner · Hillsboro US"    "https://hil-speed.hetzner.com/100MB.bin"
measure_download "OVH · Roubaix FR"          "https://proof.ovh.net/files/100Mb.dat"
measure_download "Linode · Frankfurt DE"     "https://speedtest.frankfurt.linode.com/100MB-frankfurt.bin"
measure_download "ThinkBroadband · UK"       "http://ipv4.download.thinkbroadband.com/100MB.zip"
measure_download "Yandex · Москва RU"        "https://mirror.yandex.ru/ubuntu/ls-lR.gz"
measure_download "Selectel · СПб RU"         "https://mirror.selectel.ru/ubuntu/ls-lR.gz"

# ---------------------------------------------------------------- отдача

section "ОТДАЧА  (${UL_MAX_TIME}с на источник)"

UPLOAD_FILE="$TMP_DIR/upload.bin"
dd if=/dev/zero of="$UPLOAD_FILE" bs=1M count="$UPLOAD_MB" 2>/dev/null

measure_upload() {
    label=$1
    url=$2

    progress "$label" 30

    out=$(curl -o /dev/null -s \
        --connect-timeout "$CONNECT_TIMEOUT" \
        --max-time "$UL_MAX_TIME" \
        -A "$USER_AGENT" \
        -X POST --data-binary "@$UPLOAD_FILE" \
        -w '%{size_upload} %{speed_upload}' \
        "$url" 2>/dev/null)

    size=$(printf '%s' "$out" | awk '{ print $1 }')
    speed=$(printf '%s' "$out" | awk '{ print $2 }')

    # при отдаче ответа может не быть вовсе, если мы оборвались по таймауту,
    # поэтому http-код не показателен - смотрим только на отправленные байты
    ok=$(LC_ALL=C awk -v s="${size:-0}" -v v="${speed:-0}" 'BEGIN {
        print (s + 0 > 0 && v + 0 > 0) ? "1" : "0"
    }')

    if [ "$ok" = "1" ]; then
        mbps=$(to_mbps "${speed:-0}")
        mib=$(LC_ALL=C awk -v s="$size" 'BEGIN { printf "%.0f", s / 1048576 }')
        col=$(colorize "$(speed_color "$mbps")")
        pad_to "$label" 30
        printf '%s  %s%s %s%9s Mbit/s%s  %s%s MiB%s\n' \
            "$ERASE" "$label" "$PAD" "$col" "$mbps" "$C_RESET" "$C_DIM" "$mib" "$C_RESET"
        printf '%s|%s\n' "$label" "$mbps" >> "$UL_RESULTS"
    else
        pad_to "$label" 30
        printf '%s  %s%s %s%16s%s\n' "$ERASE" "$label" "$PAD" "$C_RED" "недоступен" "$C_RESET"
    fi
}

if [ -s "$UPLOAD_FILE" ]; then
    measure_upload "Cloudflare · anycast" "https://speed.cloudflare.com/__up"
else
    printf '  %sне удалось подготовить тестовые данные%s\n' "$C_YELLOW" "$C_RESET"
fi

# ---------------------------------------------------------------- итоги

summary() {
    title=$1
    file=$2

    total=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
    [ "${total:-0}" -eq 0 ] 2>/dev/null && {
        printf '\n  %s%s: ни один источник не ответил%s\n' "$C_RED" "$title" "$C_RESET"
        return
    }

    max=$(awk -F'|' '{ if ($2 + 0 > m) m = $2 + 0 } END { printf "%.1f", m }' "$file")

    printf '\n  %s%s%s  %sисточников: %s%s\n' "$C_BOLD" "$title" "$C_RESET" "$C_DIM" "$total" "$C_RESET"

    # по убыванию скорости
    sort -t'|' -k2 -rn "$file" | while IFS='|' read -r label mbps; do
        col=$(colorize "$(speed_color "$mbps")")
        pad_to "$label" 30
        printf '    %s%s %s%s%s %s%8s Mbit/s%s\n' \
            "$label" "$PAD" "$col" "$(render_bar "$mbps" "$max")" "$C_RESET" "$col" "$mbps" "$C_RESET"
    done

    awk -F'|' -v c="$C_DIM" -v r="$C_RESET" '
        { v[NR] = $2 + 0; sum += $2 + 0 }
        END {
            n = NR
            for (i = 1; i <= n; i++)
                for (j = i + 1; j <= n; j++)
                    if (v[j] < v[i]) { t = v[i]; v[i] = v[j]; v[j] = t }
            median = (n % 2) ? v[(n + 1) / 2] : (v[n / 2] + v[n / 2 + 1]) / 2
            printf "    %s%-30s лучшая %.1f · медиана %.1f · средняя %.1f Mbit/s%s\n", \
                c, "", v[n], median, sum / n, r
        }
    ' "$file"
}

section "ИТОГИ"
summary "Загрузка" "$DL_RESULTS"
summary "Отдача" "$UL_RESULTS"

printf '\n%sМедиана честнее средней: один медленный или перегруженный источник%s\n' "$C_DIM" "$C_RESET"
printf '%sне утягивает её вниз, в отличие от среднего.%s\n\n' "$C_DIM" "$C_RESET"
