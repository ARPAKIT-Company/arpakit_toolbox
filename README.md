# ARPAKIT Toolbox

Набор скриптов для быстрой настройки сервера. Каждый скрипт самодостаточен —
его можно запустить напрямую из репозитория, ничего не клонируя.

## Установка ПО

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_docker.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_nginx.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_certbot.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_postgresql_16.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/install_xray.sh)
```

| Скрипт | Что делает | Переменные окружения |
| --- | --- | --- |
| `install_docker.sh` | Docker CE из официального репозитория, добавляет пользователя в группу `docker` | — |
| `install_docker_for_old_portainer.sh` | Docker CE фиксированной версии + `apt-mark hold` (для старого Portainer) | `DOCKER_VERSION` (по умолчанию `28.5.2`) |
| `install_nginx.sh` | nginx, каталог `/etc/nginx/ssl`, автозапуск | — |
| `install_certbot.sh` | certbot через snap + симлинк в `/usr/bin` | — |
| `install_postgresql_16.sh` | PostgreSQL из репозитория PGDG | `PG_VERSION` (по умолчанию `16`) |
| `install_xray.sh` | Xray (скрипт вендорится из [XTLS/Xray-install](https://github.com/XTLS/Xray-install), не правим локально) | см. upstream |

Установщики определяют дистрибутив и кодовое имя релиза автоматически,
поддерживаются Ubuntu и Debian. Запускать можно как от root, так и от
обычного пользователя с `sudo`.

## Docker

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/docker_run_portainer.sh)
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/docker_rm_all.sh)
```

| Скрипт | Что делает |
| --- | --- |
| `docker_run_portainer.sh [порт]` | Переустанавливает контейнер Portainer CE (порт по умолчанию `9000`). Том с данными сохраняется. Переменные: `PORTAINER_IMAGE`, `PORTAINER_VOLUME`, `CONTAINER_NAME` |
| `docker_rm_all.sh [-y]` | **Удаляет все** контейнеры, образы, тома, пользовательские сети и кеш сборки. Показывает, что будет удалено, и требует ввести `yes`; `-y` пропускает подтверждение |

> `docker_rm_all.sh` необратим: данные в томах восстановить нельзя.

## Диагностика

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/arpakit-company/arpakit_toolbox/master/toolbox/speed_test.sh)
```

`speed_test.sh` меряет задержку, загрузку и отдачу по нескольким независимым
источникам и печатает сводку. Настройки: `DL_MAX_TIME`, `UL_MAX_TIME`,
`PING_COUNT`, `NO_COLOR`. Дополнительные цели для пинга передаются аргументами.

## Git-команды

Скрипты в `command/git_command_group/` работают с этим репозиторием и
находят его корень сами — их можно запускать из любой директории.

| Скрипт | Что делает |
| --- | --- |
| `git_status.sh` | Ветка и `git status` |
| `git_remote_v.sh` | Список remote |
| `git_commit.sh [сообщение]` | `git add -A` + коммит (по умолчанию `no_message`), молча выходит на чистом дереве |
| `git_push_master_to_all_remotes.sh [сообщение]` | Коммит и push во **все** remote репозитория. Переменная `BRANCH` (по умолчанию `master`) |
