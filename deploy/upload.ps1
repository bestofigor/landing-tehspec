# Заливает лендинг на сервер. Запускать из корня проекта:
#   powershell -ExecutionPolicy Bypass -File deploy\upload.ps1

$ErrorActionPreference = "Stop"

$host_alias = "igor-vps"
$remote_dir = "/var/www/landing-tehspec"
$files = @("index.html", "photo-web.jpg")

foreach ($f in $files) {
    if (-not (Test-Path $f)) { throw "Не найден файл: $f" }
}

Write-Host "==> Копирую на $host_alias`:$remote_dir"
scp $files "${host_alias}:${remote_dir}/"

Write-Host "==> Выставляю владельца"
ssh $host_alias "chown -R www-data:www-data $remote_dir"

Write-Host "==> Проверяю ответ сервера"
ssh $host_alias "curl -sS -o /dev/null -w 'http://localhost -> %{http_code}\n' http://localhost/"
