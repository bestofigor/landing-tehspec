#!/usr/bin/env bash
# Ставит и настраивает nginx под лендинг. Запускать на сервере под root.
#
# Использование (с локальной машины, одной командой):
#   Get-Content deploy/setup-nginx.sh | ssh igor-vps "bash -s -- landing.bestofigor.tech"
#
# Без аргумента сайт будет отвечать на любое имя и на голый IP.

set -euo pipefail

DOMAIN="${1:-_}"
SITE="landing-tehspec"
ROOT="/var/www/$SITE"

echo "==> Домен: $DOMAIN"
echo "==> Каталог сайта: $ROOT"

# 1. nginx
if command -v nginx >/dev/null 2>&1; then
    echo "==> nginx уже установлен: $(nginx -v 2>&1)"
else
    echo "==> Ставлю nginx"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq nginx
fi

# 2. Каталог сайта + заглушка, если файлы ещё не залиты
mkdir -p "$ROOT"
if [ ! -f "$ROOT/index.html" ]; then
    echo "==> index.html пока нет, кладу заглушку"
    cat > "$ROOT/index.html" <<'HOLD'
<!doctype html>
<meta charset="utf-8">
<title>Скоро</title>
<p style="font:17px/1.5 system-ui;padding:40px">Сайт готовится к публикации.</p>
HOLD
fi
chown -R www-data:www-data "$ROOT"
chmod 755 "$ROOT"

# 3. Конфиг сайта
echo "==> Пишу /etc/nginx/sites-available/$SITE"
cat > "/etc/nginx/sites-available/$SITE" <<NGINX
server {
    listen 80;
    listen [::]:80;

    server_name $DOMAIN;
    root $ROOT;
    index index.html;

    location = / {
        try_files /index.html =404;
    }

    location ~* \.(png|jpe?g|svg|webp|ico|woff2?)\$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location = /index.html {
        expires -1;
        add_header Cache-Control "no-cache, must-revalidate";
    }

    location ~ /\. {
        deny all;
        return 404;
    }

    gzip on;
    gzip_vary on;
    gzip_min_length 512;
    gzip_types text/plain text/css text/javascript application/javascript image/svg+xml;

    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    access_log /var/log/nginx/landing-access.log;
    error_log  /var/log/nginx/landing-error.log;
}
NGINX

# 4. Включаем свой сайт, выключаем дефолтный
ln -sfn "../sites-available/$SITE" "/etc/nginx/sites-enabled/$SITE"
if [ -e /etc/nginx/sites-enabled/default ]; then
    echo "==> Отключаю сайт по умолчанию"
    rm -f /etc/nginx/sites-enabled/default
fi

# 5. Прячем версию nginx в заголовках
if ! grep -rqs "server_tokens" /etc/nginx/conf.d/ /etc/nginx/nginx.conf; then
    echo "server_tokens off;" > /etc/nginx/conf.d/00-server-tokens.conf
fi

# 6. Проверка и запуск
echo "==> Проверяю конфигурацию"
nginx -t

systemctl enable nginx >/dev/null 2>&1 || true
systemctl reload nginx 2>/dev/null || systemctl restart nginx
echo "==> nginx перезагружен"

# 7. Файрвол, если включён
if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
    echo "==> ufw активен, открываю HTTP/HTTPS"
    ufw allow 'Nginx Full' >/dev/null
fi

echo
echo "==> Готово. Проверка изнутри сервера:"
curl -sS -o /dev/null -w "    http://localhost -> %{http_code}\n" http://localhost/ || true
echo "==> Файлы сайта складывать в $ROOT"
