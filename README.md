# ARPAKIT Toolbox

Набор скриптов для быстрой настройки сервера. Каждый скрипт самодостаточен —
его можно запустить напрямую из репозитория, ничего не клонируя.

## Установка ПО

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_docker.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_nginx.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_certbot.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_xray.sh)
```

| Скрипт | Что делает | Переменные окружения |
| --- | --- | --- |
| `install_docker.sh` | Docker CE из официального репозитория, добавляет пользователя в группу `docker` | — |
| `install_nginx.sh` | nginx, каталог `/etc/nginx/ssl`, автозапуск | — |
| `install_certbot.sh` | certbot через snap + симлинк в `/usr/bin` | — |
| `install_xray.sh` | Xray (скрипт вендорится из [XTLS/Xray-install](https://github.com/XTLS/Xray-install), не правим локально) | см. upstream |

Установщики определяют дистрибутив и кодовое имя релиза автоматически,
поддерживаются Ubuntu и Debian. Запускать можно как от root, так и от
обычного пользователя с `sudo`.

## Docker

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/docker_run_portainer.sh)
```

| Скрипт | Что делает |
| --- | --- |
| `docker_run_portainer.sh [порт]` | Переустанавливает контейнер Portainer CE (порт по умолчанию `9000`). Том с данными сохраняется. Переменные: `PORTAINER_IMAGE`, `PORTAINER_VOLUME`, `CONTAINER_NAME` |

## Диагностика

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/speed_test.sh)
```

`speed_test.sh` меряет задержку, загрузку и отдачу по нескольким независимым
источникам и печатает сводку. Настройки: `DL_MAX_TIME`, `UL_MAX_TIME`,
`PING_COUNT`, `NO_COLOR`. Дополнительные цели для пинга передаются аргументами.
