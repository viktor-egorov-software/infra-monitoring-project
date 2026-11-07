#!/bin/bash

# Должен быть передан как минимум один аргумент и он не должен быть пустым
if [[ $# -lt 1 || -z "$1" ]]; then
    echo "Использование: $0 <URL>" >&2
    exit 1
fi

if ! status_code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 15 -- "$1"); then
    echo "API недоступен, код ответа: ${status_code:-000}"
    exit 1
fi

if [[ "$status_code" == "200" ]]; then
    echo "API доступен"
    exit 0
fi

echo "API недоступен, код ответа: $status_code"
exit 1
