#!/bin/bash

set -euo pipefail

log_file="access.log"

codes=(200 201 204 301 302 400 401 403 404 429 500 502 503 504)
methods=(GET POST PUT PATCH DELETE)
paths=(/api/users /api/login /api/orders /api/products /api/health)
log_date=$(date +%d/%b/%Y)

# Генерируем случайные адреса для 50 клиентов.
clients=()
for ((i = 0; i < 50; i++)); do
    clients+=("$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256)).$((RANDOM % 256))")
done

# Начинаем в случайный час до 22:00, оставляя запас до конца суток.
log_seconds=$((RANDOM % 22 * 3600))

# Каждый запуск заново создаёт тестовый лог из 300 запросов.
for ((i = 0; i < 300; i++)); do
    ip=${clients[RANDOM % ${#clients[@]}]}
    method=${methods[RANDOM % ${#methods[@]}]}
    path=${paths[RANDOM % ${#paths[@]}]}
    code=${codes[RANDOM % ${#codes[@]}]}
    log_seconds=$((log_seconds + 1 + RANDOM % 20))

    printf '%s - - [%s:%02d:%02d:%02d] "%s %s HTTP/1.1" %s\n' \
        "$ip" "$log_date" "$((log_seconds / 3600))" \
        "$((log_seconds / 60 % 60))" "$((log_seconds % 60))" \
        "$method" "$path" "$code"
done > "$log_file"

echo "Общее количество запросов: $(wc -l < "$log_file")"

echo "Топ-3 IP-адреса (адрес — количество запросов):"
grep -Eo '^([0-9]{1,3}\.){3}[0-9]{1,3}' "$log_file" |
    sort | uniq -c | sort -nr | awk 'NR <= 3 {print $2 " — " $1}'

# HTTP-код находится в последнем поле строки.
awk '
    $NF ~ /^4[0-9][0-9]$/ {errors_4xx++}
    $NF ~ /^5[0-9][0-9]$/ {errors_5xx++}
    END {
        printf "Количество запросов 4xx: %d\n", errors_4xx
        printf "Количество запросов 5xx: %d\n", errors_5xx
    }
' "$log_file"
