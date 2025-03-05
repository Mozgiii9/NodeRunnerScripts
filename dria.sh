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

# Функция установки зависимостей
install_dependencies() {
    info_message "Установка необходимых пакетов..."
    sudo apt update && sudo apt-get upgrade -y
    sudo apt install -y git make jq build-essential gcc unzip wget lz4 aria2 curl
    success_message "Зависимости установлены"
}

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Очистка экрана
clear

# Отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🚀 DRIA NODE MANAGER           ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}▶️  Запуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔌 Изменение порта${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка логов${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Функция для установки ноды
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка ноды Dria...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}🔄 Установка зависимостей...${NC}"
    install_dependencies

    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка установщика...${NC}"
    info_message "Загрузка и установка Dria Compute Node..."
    curl -fsSL https://dria.co/launcher | bash
    success_message "Установщик загружен и выполнен"

    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск ноды...${NC}"
    dkn-compute-launcher start

    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода успешно установлена и запущена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для запуска ноды как сервиса
start_node_service() {
    echo -e "\n${BOLD}${BLUE}🚀 Запуск ноды Dria как сервиса...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Создание файла сервиса...${NC}"
    # Определяем имя текущего пользователя и его домашнюю директорию
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)

    # Создание файла сервиса
    sudo bash -c "cat <<EOT > /etc/systemd/system/dria.service
[Unit]
Description=Dria Compute Node Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/.dria/dkn-compute-launcher/.env
ExecStart=/usr/local/bin/dkn-compute-launcher start
WorkingDirectory=$HOME_DIR/.dria/dkn-compute-launcher/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"
    success_message "Файл сервиса создан"

    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🔄 Настройка системных служб...${NC}"
    # Перезагрузка и старт сервиса
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-journald
    sleep 1
    sudo systemctl enable dria
    sudo systemctl start dria
    success_message "Сервис настроен и запущен"

    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка логов...${NC}"
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📝 Команда для проверки логов:${NC}"
    echo -e "${CYAN}sudo journalctl -u dria -f --no-hostname -o cat${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"

    # Проверка логов
    sudo journalctl -u dria -f --no-hostname -o cat
}

# Функция для обновления ноды
update_node() {
    echo -e "\n${BOLD}${GREEN}✅ У вас установлена актуальная версия ноды Dria${NC}\n"
}

# Функция для изменения порта
change_port() {
    echo -e "\n${BOLD}${BLUE}🔌 Изменение порта ноды Dria...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервиса...${NC}"
    sudo systemctl stop dria
    success_message "Сервис остановлен"

    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Настройка нового порта...${NC}"
    # Запрашиваем новый порт у пользователя
    echo -e "${YELLOW}🔢 Введите новый порт для Dria:${NC}"
    read -p "➜ " NEW_PORT

    # Путь к файлу .env
    ENV_FILE="$HOME/.dria/dkn-compute-launcher/.env"

    # Обновляем порт в файле .env
    sed -i "s|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/[0-9]*|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/$NEW_PORT|" "$ENV_FILE"
    success_message "Порт изменен на $NEW_PORT"

    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🚀 Перезапуск сервиса...${NC}"
    # Перезапуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-journald
    sudo systemctl start dria
    success_message "Сервис перезапущен с новым портом"

    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}📝 Команда для проверки логов:${NC}"
    echo -e "${CYAN}sudo journalctl -u dria -f --no-hostname -o cat${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"

    # Проверка логов
    sudo journalctl -u dria -f --no-hostname -o cat
}

# Функция для проверки логов
check_logs() {
    echo -e "\n${BOLD}${BLUE}📋 Проверка логов ноды Dria...${NC}\n"
    sudo journalctl -u dria -f --no-hostname -o cat
}

# Функция для удаления ноды
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды Dria...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервисов...${NC}"
    # Остановка и удаление сервиса
    sudo systemctl stop dria
    sudo systemctl disable dria
    sudo rm /etc/systemd/system/dria.service
    sudo systemctl daemon-reload
    sleep 2
    success_message "Сервисы остановлены и удалены"

    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    # Удаление папки ноды
    rm -rf $HOME/.dria
    rm -rf ~/dkn-compute-node
    success_message "Файлы ноды удалены"

    echo -e "\n${GREEN}✅ Нода Dria успешно удалена!${NC}\n"
    sleep 2
}

# Основной цикл программы
while true; do
    clear
    # Отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    
    print_menu
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-7]:${NC} "
    read -p "➜ " choice

    case $choice in
        1)
            install_node
            ;;
        2)
            start_node_service
            ;;
        3)
            update_node
            ;;
        4)
            change_port
            ;;
        5)
            check_logs
            ;;
        6)
            remove_node
            ;;
        7)
            echo -e "\n${GREEN}👋 До свидания!${NC}\n"
            exit 0
            ;;a
        *)
            echo -e "\n${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 7.${NC}\n"
            ;;
    esac
    
    if [ "$choice" != "2" ] && [ "$choice" != "4" ] && [ "$choice" != "5" ]; then
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    fi
done
