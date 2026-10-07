#!/usr/bin/env bash
# Обновляет лендинг на сервере: забирает свежий коммит с GitHub
# и раскладывает нужные файлы в корень сайта.
#
# Ставится на сервер как /usr/local/bin/deploy-landing.
# Запуск с локальной машины:  ssh igor-vps deploy-landing
#
# Репозиторий намеренно лежит ОТДЕЛЬНО от корня сайта: иначе наружу
# открылись бы CLAUDE.md, deploy/ и оригиналы фото на 4 МБ.

set -euo pipefail

SRC="/var/www/landing-src"
WEB="/var/www/landing-tehspec"
FILES=(index.html photo-web.jpg)

echo "==> Репозиторий: $SRC"
git -C "$SRC" fetch --quiet origin
BEFORE=$(git -C "$SRC" rev-parse --short HEAD)
git -C "$SRC" pull --quiet --ff-only
AFTER=$(git -C "$SRC" rev-parse --short HEAD)

if [ "$BEFORE" = "$AFTER" ]; then
    echo "==> Изменений нет, коммит прежний: $AFTER"
else
    echo "==> Обновлено: $BEFORE -> $AFTER"
    git -C "$SRC" log --oneline "$BEFORE..$AFTER" | sed "s/^/    /"
fi

# Проверяем, что всё нужное есть, и только потом трогаем корень сайта
for f in "${FILES[@]}"; do
    [ -f "$SRC/$f" ] || { echo "ОШИБКА: в репозитории нет $f, ничего не меняю"; exit 1; }
done

echo "==> Копирую в $WEB"
for f in "${FILES[@]}"; do
    install -o www-data -g www-data -m 644 "$SRC/$f" "$WEB/$f"
    echo "    $f"
done

CODE=$(curl -sS -o /dev/null -w "%{http_code}" https://landing.bestofigor.tech/)
echo "==> Сайт отвечает по https: $CODE"
[ "$CODE" = "200" ] || { echo "ВНИМАНИЕ: ожидали 200"; exit 1; }
echo "==> Готово, версия сайта: $AFTER"
