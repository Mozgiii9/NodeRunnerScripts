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

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

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

# Функция установки зависимостей
install_dependencies() {
    info_message "Установка необходимых пакетов..."
    sudo apt update && sudo apt install -y curl iptables build-essential git wget jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip screen
    success_message "Зависимости установлены"
}

# Очистка экрана
clear

# Отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🚀 PIPE NODE MANAGER           ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка статуса${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}💰 Проверка поинтов${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Функция для установки ноды
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка ноды Pipe...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/5${WHITE}] ${GREEN}➜ ${WHITE}🔄 Установка зависимостей...${NC}"
    install_dependencies

    echo -e "${WHITE}[${CYAN}2/5${WHITE}] ${GREEN}➜ ${WHITE}📂 Создание директории...${NC}"
    mkdir -p ~/pipe/download_cache
    cd ~/pipe

    echo -e "${WHITE}[${CYAN}3/5${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка файлов...${NC}"
    wget https://dl.pipecdn.app/v0.2.2/pop
    chmod +x pop

    echo -e "${WHITE}[${CYAN}4/5${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Настройка параметров...${NC}"
    screen -S pipe2 -dm

    echo -e "${YELLOW}💳 Введите ваш публичный адрес Solana:${NC}"
    read -p "➜ " SOLANA_PUB_KEY
    
    echo -e "${YELLOW}🖥️ Введите количество RAM в ГБ:${NC}"
    read -p "➜ " RAM
    
    echo -e "${YELLOW}💾 Введите количество max-disk в ГБ:${NC}"
    read -p "➜ " DISK

    echo -e "${WHITE}[${CYAN}5/5${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск ноды...${NC}"
    screen -S pipe2 -X stuff "./pop --ram $RAM --max-disk $DISK --cache-dir ~/pipe/download_cache --pubKey $SOLANA_PUB_KEY\n"
    sleep 3
    screen -S pipe2 -X stuff "e4313e9d866ee3df\n"

    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода успешно установлена и запущена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для проверки статуса
check_status() {
    echo -e "\n${BOLD}${BLUE}📋 Проверка статуса ноды...${NC}\n"
    cd pipe
    ./pop --status
    cd ..
}

# Функция для проверки поинтов
check_points() {
    echo -e "\n${BOLD}${BLUE}💰 Проверка поинтов ноды...${NC}\n"
    cd pipe
    ./pop --points
    cd ..
}

# Функция для удаления ноды
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды Pipe...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервисов...${NC}"
    pkill -f pop
    screen -S pipe2 -X quit

    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    sudo rm -rf ~/pipe

    echo -e "\n${GREEN}✅ Нода успешно удалена!${NC}\n"
    sleep 2
}

# Основной цикл программы
while true; do
    clear
    # Отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    
    print_menu
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-5]:${NC} "
    read -p "➜ " choice

    case $choice in
        1)
            install_node
            ;;
        2)
            check_status
            ;;
        3)
            check_points
            ;;
        4)
            remove_node
            ;;
        5)
            echo -e "\n${GREEN}👋 До свидания!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 5.${NC}\n"
            ;;
    esac
    
    echo -e "\nНажмите Enter, чтобы вернуться в меню..."
    read
done
