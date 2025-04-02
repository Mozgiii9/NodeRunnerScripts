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
NC='\033[0m' # Нет цвета (сброс цвета)

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

# Функция для отображения предупреждений
warning_message() {
    echo -e "${YELLOW}[⚠️] $1${NC}"
}

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║       🧠 GENSYN NODE MANAGER          ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📋 Просмотр логов${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Очистка экрана
clear

# Отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для установки ноды
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка ноды Gensyn...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/5${WHITE}] ${GREEN}➜ ${WHITE}🔄 Установка базовых зависимостей...${NC}"
    # Обновление и установка зависимостей
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
    success_message "Базовые зависимости установлены"
    sleep 1

    echo -e "${WHITE}[${CYAN}2/5${WHITE}] ${GREEN}➜ ${WHITE}🐳 Установка Docker и Docker Compose...${NC}"
    # Проверка наличия Docker
    if ! command -v docker &> /dev/null; then
        info_message "Docker не установлен. Устанавливаем Docker..."
        sudo apt update
        sudo apt install docker.io -y
        # Запуск Docker-демона, если он не запущен
        sudo systemctl enable --now docker
        success_message "Docker успешно установлен"
    else
        success_message "Docker уже установлен"
    fi
    
    # Проверка наличия Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        info_message "Docker Compose не установлен. Устанавливаем Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        success_message "Docker Compose успешно установлен"
    else
        success_message "Docker Compose уже установлен"
    fi

    sudo usermod -aG docker $USER
    success_message "Пользователь добавлен в группу docker"
    sleep 1

    echo -e "${WHITE}[${CYAN}3/5${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка зависимостей Python и Node.js...${NC}"
    sudo apt-get install python3 python3-pip python3-venv python3-dev -y
    success_message "Python и зависимости установлены"
    sleep 1
    
    sudo apt-get update
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
    node -v
    sudo npm install -g yarn
    yarn -v
    
    curl -o- -L https://yarnpkg.com/install.sh | bash
    export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    source ~/.bashrc
    success_message "Node.js и Yarn установлены"

    echo -e "${WHITE}[${CYAN}4/5${WHITE}] ${GREEN}➜ ${WHITE}📥 Клонирование репозитория...${NC}"
    cd
    git clone https://github.com/gensyn-ai/rl-swarm/
    success_message "Репозиторий успешно клонирован"
    sleep 1
    
    echo -e "${WHITE}[${CYAN}5/5${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Завершение установки...${NC}"
    
    echo -e "\n${PURPLE}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Первый этап установки завершен успешно!${NC}"
    echo -e "${YELLOW}📝 Следуйте дальнейшим инструкциям в текстовом гайде в Notion.${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════${NC}\n"
}

# Функция для проверки логов
check_logs() {
    echo -e "\n${BOLD}${BLUE}📋 Просмотр логов ноды Gensyn...${NC}\n"
    
    cd
    screen -r gensyn
}

# Функция для удаления ноды
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды Gensyn...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка процессов...${NC}"
    screen -XS swarm quit
    success_message "Процессы остановлены"
    
    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    # Удаление папки
    if [ -d "$HOME/rl-swarm" ]; then
        rm -rf $HOME/rl-swarm
        success_message "Директория ноды удалена"
    else
        warning_message "Директория ноды не найдена"
    fi
    
    echo -e "\n${PURPLE}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Нода Gensyn успешно удалена!${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════${NC}\n"
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
            echo -e "${GREEN}У вас актуальная версия ноды Gensyn!${NC}"
            ;;
        3)
            check_logs
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
    
    if [[ "$choice" != "3" ]]; then
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    fi
done
