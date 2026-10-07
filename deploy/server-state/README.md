# Снимок настроек сервера

Копии конфигов с VPS (`ssh igor-vps`) на случай, если сервер придётся
поднимать заново. Это **снимок для чтения**, а не то, что применяется
автоматически: правки здесь сами на сервер не попадут.

| Файл | Откуда снят |
|---|---|
| `nginx-sites-available-landing-tehspec.conf` | `/etc/nginx/sites-available/landing-tehspec` |
| `sshd_config.d-01-no-password.conf` | `/etc/ssh/sshd_config.d/01-no-password.conf` |

Снято 07.10.2026.

## Чем отличается от `../nginx-landing.conf`

`../nginx-landing.conf` — исходный конфиг, который кладёт
`setup-nginx.sh`: только 80 порт, без SSL. Файл здесь — то, во что он
превратился **после** работы certbot: добавились блок на 443, пути
к сертификату и редирект с http на https. Строки, помеченные
`# managed by Certbot`, дописаны им автоматически.

## Почему имя файла начинается с `01-`

В `/etc/ssh/sshd_config.d/` уже лежит `50-cloud-init.conf`
с `PasswordAuthentication yes`. В SSH побеждает **первое** встреченное
значение, а файлы читаются по возрастанию имени — поэтому перекрыть
хостерскую настройку можно только файлом с меньшим номером.

## Восстановление сервера с нуля

1. `setup-nginx.sh` — поставит nginx и создаст базовый конфиг
2. `certbot --nginx -d landing.bestofigor.tech -d www.landing.bestofigor.tech`
   — выпустит сертификат и сам допишет SSL-блок
3. Скопировать `sshd_config.d-01-no-password.conf`
   в `/etc/ssh/sshd_config.d/01-no-password.conf`, проверить `sshd -t`,
   перезапустить `ssh`
4. `git clone` репозитория в `/var/www/landing-src` и установить
   `deploy-landing.sh` как `/usr/local/bin/deploy-landing`

Секретов в этих файлах нет: указаны только пути к сертификату и ключу,
сами они лежат в `/etc/letsencrypt/` и в репозиторий не попадают.
