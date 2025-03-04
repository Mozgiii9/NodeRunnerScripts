#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Функция для отображения успешных сообщений
success_message() {
    echo -e "${GREEN}[✅] $1${NC}"
}

# Функция для отображения информационных сообщений
info_message() {
    echo -e "${CYAN}[ℹ️] $1${NC}"
}

# Функция для отображения ошибок
error_message() {
    echo -e "${RED}[❌] $1${NC}"
}

# Функция для отображения предупреждений
warning_message() {
    echo -e "${YELLOW}[⚠️] $1${NC}"
}

# Очистка экрана
clear

# Отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Отображение заголовка
echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${WHITE}║      🔄 VANA АВТОПЕРЕЗАПУСК            ║${NC}"
echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"

# Убеждаемся, что скрипт запускается с правами root
if [ "$EUID" -ne 0 ]; then
  error_message "Пожалуйста, запустите скрипт от имени root (sudo)"
  exit 1
fi

# Отображение информации о процессе установки
echo -e "${BOLD}${BLUE}🛠️ Установка сервиса автоперезапуска Vana...${NC}\n"

echo -e "${WHITE}[${CYAN}1/6${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка необходимых пакетов...${NC}"
# Устанавливаем curl, если его нет
if ! command -v curl &> /dev/null; then
    info_message "Установка curl..."
    apt-get update && apt-get install -y curl
    success_message "Curl успешно установлен!"
else
    success_message "Curl уже установлен!"
fi
sleep 1

echo -e "${WHITE}[${CYAN}2/6${WHITE}] ${GREEN}➜ ${WHITE}📝 Создание скрипта мониторинга...${NC}"
info_message "Создаём скрипт мониторинга /root/vana_monitor.sh..."
cat << 'EOF' > /root/vana_monitor.sh
#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Интервал проверки в секундах (5 минут)
CHECK_INTERVAL=300

# Ключевые слова для поиска ошибок
ERROR_PATTERNS=("ERROR" "RuntimeError" "Traceback" "exception")

echo -e "${BLUE}🔍 Запуск мониторинга Vana...${NC}"
echo -e "${YELLOW}⏱️ Интервал проверки: ${CHECK_INTERVAL} секунд${NC}"

while true; do
    echo -e "${CYAN}[$(date +"%Y-%m-%d %H:%M:%S")] 🔍 Проверка логов vana.service на ошибки...${NC}"

    # Получаем последние 50 строк логов за последние 5 минут
    LOGS=$(journalctl -u vana.service --since "5 minutes ago" -n 50)

    # Флаг для отслеживания ошибок
    ERROR_FOUND=false

    # Проверяем логи на наличие ошибок
    for PATTERN in "${ERROR_PATTERNS[@]}"; do
        if echo "$LOGS" | grep -i "$PATTERN" > /dev/null; then
            echo -e "${RED}[$(date +"%Y-%m-%d %H:%M:%S")] ⚠️ Найдена ошибка: $PATTERN${NC}"
            ERROR_FOUND=true
            break
        fi
    done

    # Если ошибка найдена, перезапускаем службу
    if [ "$ERROR_FOUND" = true ]; then
        echo -e "${YELLOW}[$(date +"%Y-%m-%d %H:%M:%S")] 🔄 Обнаружены ошибки в логах. Перезапуск vana.service...${NC}"
        systemctl restart vana.service
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[$(date +"%Y-%m-%d %H:%M:%S")] ✅ Служба успешно перезапущена. Ждём 30 секунд перед следующей проверкой...${NC}"
            sleep 30  # Даём время службе запуститься
        else
            echo -e "${RED}[$(date +"%Y-%m-%d %H:%M:%S")] ❌ Ошибка при перезапуске службы!${NC}"
        fi
    else
        echo -e "${GREEN}[$(date +"%Y-%m-%d %H:%M:%S")] ✅ Ошибок не найдено. Всё работает нормально.${NC}"
    fi

    # Ждём до следующей проверки
    echo -e "${BLUE}[$(date +"%Y-%m-%d %H:%M:%S")] ⏱️ Следующая проверка через $CHECK_INTERVAL секунд...${NC}"
    sleep $CHECK_INTERVAL
done
EOF
success_message "Скрипт мониторинга создан!"
sleep 1

echo -e "${WHITE}[${CYAN}3/6${WHITE}] ${GREEN}➜ ${WHITE}🔐 Настройка прав доступа...${NC}"
chmod +x /root/vana_monitor.sh
success_message "Права доступа установлены!"
sleep 1

echo -e "${WHITE}[${CYAN}4/6${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Создание systemd-сервиса...${NC}"
info_message "Создаем файл сервиса /etc/systemd/system/vana_monitor.service..."
cat << 'EOF' > /etc/systemd/system/vana_monitor.service
[Unit]
Description=Vana Service Monitor and Restart
After=network.target vana.service

[Service]
ExecStart=/root/vana_monitor.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
success_message "Файл сервиса создан!"
sleep 1

echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск сервиса...${NC}"
info_message "Настраиваем и запускаем сервис..."
systemctl daemon-reload
systemctl enable vana_monitor.service
systemctl start vana_monitor.service
success_message "Сервис запущен и добавлен в автозагрузку!"
sleep 1

echo -e "${WHITE}[${CYAN}6/6${WHITE}] ${GREEN}➜ ${WHITE}📊 Проверка статуса сервиса...${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════${NC}"
systemctl status vana_monitor.service
echo -e "${PURPLE}═══════════════════════════════════════════════${NC}"

# Заключительный вывод
echo -e "\n${PURPLE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Установка завершена успешно!${NC}"
echo -e "${YELLOW}🔄 Сервис мониторинга Vana настроен и запущен.${NC}"
echo -e "${CYAN}📋 Сервис будет автоматически перезапускать Vana при обнаружении ошибок.${NC}"
echo -e "${CYAN}🔍 Проверка выполняется каждые 5 минут.${NC}"
echo -e "${YELLOW}📝 Для просмотра логов мониторинга используйте команду:${NC}"
echo -e "${CYAN}   sudo journalctl -u vana_monitor.service -f${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════${NC}"
