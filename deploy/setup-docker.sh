#!/usr/bin/env bash
#
# Первичная настройка контейнера «Боярский Край» на сервере,
# где уже работает Traefik (порты 80/443 заняты).
#
# Сайт поднимается отдельным nginx-контейнером и публикуется на порт 8080,
# не затрагивая Traefik и проект bbmarket.
#
# Запуск на сервере:
#
#   sudo mkdir -p /opt/apps/boyarskiy-kray
#   sudo git clone https://github.com/IgorPylin/boyarkray.git /opt/apps/boyarskiy-kray
#   cd /opt/apps/boyarskiy-kray
#   sudo DEPLOY_USER=deploy bash deploy/setup-docker.sh
#
# После этого сайт доступен по http://<IP_СЕРВЕРА>:8080

set -euo pipefail

PROJECT_DIR="${PROJECT_DIR:-/opt/apps/boyarskiy-kray}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
HTTP_PORT="${HTTP_PORT:-8080}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Запустите скрипт от root (sudo)." >&2
  exit 1
fi

cd "$PROJECT_DIR"

echo ">> Создаю папку site/ и наполняю стартовым содержимым"
mkdir -p site
rsync -a --delete \
  --exclude 'site' \
  --exclude '.git' \
  --exclude '.github' \
  --exclude 'deploy' \
  --exclude 'nginx' \
  --exclude 'docker-compose.yml' \
  --exclude '.gitignore' \
  --exclude '.gitattributes' \
  --exclude '*.md' \
  ./ site/

echo ">> Назначаю владельцем папки пользователя $DEPLOY_USER (для деплоя по SSH)"
if id "$DEPLOY_USER" >/dev/null 2>&1; then
  chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$PROJECT_DIR"
fi

echo ">> Открываю порт $HTTP_PORT в ufw (если ufw активен)"
if command -v ufw >/dev/null 2>&1; then
  ufw allow "${HTTP_PORT}/tcp" >/dev/null 2>&1 || true
fi

echo ">> Запускаю контейнер"
docker compose up -d
docker compose ps

echo ""
echo "================================================================"
echo " Готово. Сайт: http://<IP_СЕРВЕРА>:${HTTP_PORT}"
echo ""
echo " Не забудьте:"
echo "  - В firewall DigitalOcean добавить inbound-правило TCP ${HTTP_PORT}"
echo "    (публикация Docker-порта может не учитывать ufw)."
echo "  - В GitHub Secrets: DEPLOY_PATH=${PROJECT_DIR}/site, DEPLOY_USER=${DEPLOY_USER}"
echo "================================================================"
