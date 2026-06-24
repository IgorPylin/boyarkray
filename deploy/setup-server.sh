#!/usr/bin/env bash
#
# Первичная настройка DigitalOcean Droplet (Ubuntu 22.04/24.04)
# для статического сайта «Боярский Край».
#
# Запускать на сервере ОТ ROOT один раз:
#
#   # 1. Скопировать репозиторий на сервер (или склонировать с GitHub)
#   git clone https://github.com/<user>/<repo>.git
#   cd <repo>
#
#   # 2. Запустить (домен — необязательный аргумент; публичный ключ — через env)
#   DEPLOY_PUBLIC_KEY="ssh-ed25519 AAAA... deploy@boyarskiy-kray" \
#     bash deploy/setup-server.sh boyarskiy-kray.ru
#
# После этого сайт будет доступен по IP / домену, а CI сможет
# заливать файлы по SSH под пользователем deploy.

set -euo pipefail

DOMAIN="${1:-_}"
DEPLOY_USER="${DEPLOY_USER:-deploy}"
WEB_ROOT="${WEB_ROOT:-/var/www/boyarskiy-kray}"
NGINX_CONF_SRC="$(dirname "$0")/../nginx/boyarskiy-kray.conf"

if [ "$(id -u)" -ne 0 ]; then
  echo "Запустите скрипт от root (sudo)." >&2
  exit 1
fi

echo ">> Устанавливаю nginx и rsync..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx rsync

echo ">> Создаю пользователя для деплоя: $DEPLOY_USER"
if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$DEPLOY_USER"
fi

echo ">> Готовлю web-root: $WEB_ROOT"
mkdir -p "$WEB_ROOT"
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$WEB_ROOT"
chmod 755 "$WEB_ROOT"

echo ">> Настраиваю SSH-доступ для $DEPLOY_USER"
install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"
if [ -n "${DEPLOY_PUBLIC_KEY:-}" ]; then
  AUTH_KEYS="/home/$DEPLOY_USER/.ssh/authorized_keys"
  touch "$AUTH_KEYS"
  if ! grep -qxF "$DEPLOY_PUBLIC_KEY" "$AUTH_KEYS"; then
    echo "$DEPLOY_PUBLIC_KEY" >> "$AUTH_KEYS"
  fi
  chmod 600 "$AUTH_KEYS"
  chown "$DEPLOY_USER":"$DEPLOY_USER" "$AUTH_KEYS"
  echo "   Публичный ключ добавлен."
else
  echo "   !! DEPLOY_PUBLIC_KEY не задан — добавьте публичный deploy-ключ вручную в $AUTH_KEYS"
fi

echo ">> Устанавливаю конфиг nginx (домен: $DOMAIN)"
sed "s/__DOMAIN__/${DOMAIN}/g" "$NGINX_CONF_SRC" > /etc/nginx/sites-available/boyarskiy-kray.conf
ln -sf /etc/nginx/sites-available/boyarskiy-kray.conf /etc/nginx/sites-enabled/boyarskiy-kray.conf
rm -f /etc/nginx/sites-enabled/default

# Заглушка, чтобы сайт открывался ещё до первого деплоя
if [ ! -f "$WEB_ROOT/index.html" ]; then
  echo "<h1>Боярский Край — скоро здесь будет сайт</h1>" > "$WEB_ROOT/index.html"
  chown "$DEPLOY_USER":"$DEPLOY_USER" "$WEB_ROOT/index.html"
fi

echo ">> Проверяю и перезагружаю nginx"
nginx -t
systemctl enable nginx
systemctl reload nginx

# Firewall (если включён ufw)
if command -v ufw >/dev/null 2>&1; then
  ufw allow 'Nginx Full' >/dev/null 2>&1 || true
  ufw allow OpenSSH >/dev/null 2>&1 || true
fi

echo ""
echo "================================================================"
echo " Готово. Web-root: $WEB_ROOT"
echo " Пользователь для CI: $DEPLOY_USER"
echo ""
echo " Дальше:"
echo "  1. Добавьте в GitHub Secrets: DEPLOY_HOST, DEPLOY_USER=$DEPLOY_USER,"
echo "     DEPLOY_PATH=$WEB_ROOT, DEPLOY_SSH_KEY (приватный ключ)."
echo "  2. Для HTTPS установите сертификат:"
echo "       apt-get install -y certbot python3-certbot-nginx"
echo "       certbot --nginx -d $DOMAIN -d www.$DOMAIN"
echo "================================================================"
