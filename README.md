# infra-monitoring-project

Учебный проект: мониторинг доступности API, анализ логов Bash-скриптами,
анализ сетевого трафика и запуск echo-сервиса за Nginx в Docker Compose.

## Запуск Docker Compose

Из корня проекта:

```bash
docker compose up -d
```

Nginx (`proxy`) принимает запросы на порту 80 и передаёт их сервису
`api` (`hashicorp/http-echo`) на порт 8080 через общую сеть `monitoring`.
Порт API доступен внутри Docker-сети и не публикуется на хосте.
