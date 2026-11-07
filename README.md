# infra-monitoring-project

Учебный проект: мониторинг доступности API, анализ логов Bash-скриптами,
анализ сетевого трафика и запуск echo-сервиса за Nginx в Docker Compose.

## Передача проекта на сервер по SSH и SCP

### Настройка SSH-ключа

При выполнении команд замените `deploy@server.example.com` на пользователя и адрес своего сервера.

Создайте отдельную пару ключей:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_infra_monitoring -C "infra-monitoring-project"
```

Отправьте на сервер публичный ключ:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_infra_monitoring.pub deploy@server.example.com
```

### Передача архива

Из корня проекта на локальной машине упакуйте файлы, необходимые для запуска:

```bash
mkdir -p build
tar -czf build/infra-monitoring-project.tar.gz \
    check_api.sh analyze_logs.sh docker-compose.yml nginx
```

Передайте архив на сервер:

```bash
scp -i ~/.ssh/id_ed25519_infra_monitoring \
    build/infra-monitoring-project.tar.gz deploy@server.example.com:~/
```

Подключитесь к серверу:

```bash
ssh -i ~/.ssh/id_ed25519_infra_monitoring deploy@server.example.com
```

Распакуйте архив:

```bash
mkdir -p ~/infra-monitoring-project
tar -xzf ~/infra-monitoring-project.tar.gz -C ~/infra-monitoring-project
```

### Запуск сервисов

```bash
cd ~/infra-monitoring-project
docker compose up -d
```

Nginx (`proxy`) принимает запросы на порту 80 и передаёт их сервису
`api` (`hashicorp/http-echo`) на порт 8080 через общую сеть `monitoring`.
Порт API доступен внутри Docker-сети и не публикуется на хосте.

### Запуск скриптов

Войдите в директорию проекта и сделайте скрипты исполняемыми:

```bash
cd ~/infra-monitoring-project
chmod +x check_api.sh analyze_logs.sh
```

#### Проверка API

`check_api.sh` принимает URL первым аргументом и проверяет HTTP-код ответа.

```bash
./check_api.sh https://httpbin.org/status/200
```

При HTTP 200 выводится `API доступен`, код возврата — `0`.
При другом HTTP-коде или ошибке запроса выводится `API недоступен, код ответа: ...`,
код возврата — `1`. Если HTTP-ответ не получен, код ответа — `000`.
Время запроса ограничено 15 секундами. Отсутствующий или пустой URL также
приводит к завершению с кодом `1`.

#### Анализ логов

```bash
./analyze_logs.sh
```

Скрипт создаёт в текущей папке `access.log` из 300 случайных записей и выводит
общее количество запросов, топ-3 IP-адреса и количество ответов 4xx и 5xx.
При каждом запуске лог перезаписывается, а результаты меняются.

## CI — GitHub Actions

При открытии Pull Request в `main` и добавлении новых коммитов в него
запускается workflow `.github/workflows/ci.yml`. Он проверяет синтаксис
обоих скриптов через `bash -n` и запускает `check_api.sh` для
`https://httpbin.org/status/200`. Проверка успешна, если скрипт возвращает `0`.
