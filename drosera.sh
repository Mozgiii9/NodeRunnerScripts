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
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
    
    info_message "Установка специфических инструментов..."
    curl -L https://app.drosera.io/install | bash
    curl -L https://foundry.paradigm.xyz | bash
    curl -fsSL https://bun.sh/install | bash
    
    # Проверка и открытие портов
    info_message "Настройка портов..."
    if ! sudo iptables -C INPUT -p tcp --dport 31313 -j ACCEPT 2>/dev/null; then
        sudo iptables -I INPUT -p tcp --dport 31313 -j ACCEPT
        success_message "Порт 31313 открыт"
    else
        info_message "Порт 31313 уже открыт"
    fi
    
    if ! sudo iptables -C INPUT -p tcp --dport 31314 -j ACCEPT 2>/dev/null; then
        sudo iptables -I INPUT -p tcp --dport 31314 -j ACCEPT
        success_message "Порт 31314 открыт"
    else
        info_message "Порт 31314 уже открыт"
    fi
    
    success_message "Зависимости установлены"
}

# Функция для деплоя Trap
deploy_trap() {
    info_message "Запуск процесса деплоя Trap..."
    
    echo -e "${WHITE}[${CYAN}1/5${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление инструментов...${NC}"
    droseraup
    foundryup
    
    echo -e "${WHITE}[${CYAN}2/5${WHITE}] ${GREEN}➜ ${WHITE}📂 Создание директории...${NC}"
    mkdir my-drosera-trap
    cd my-drosera-trap
    
    echo -e "${WHITE}[${CYAN}3/5${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Настройка Git...${NC}"
    echo -e "${YELLOW}📧 Введите вашу Github почту:${NC}"
    read -p "➜ " GITHUB_EMAIL
    
    echo -e "${YELLOW}👤 Введите ваш Github юзернейм:${NC}"
    read -p "➜ " GITHUB_USERNAME
    
    git config --global user.email "$GITHUB_EMAIL"
    git config --global user.name "$GITHUB_USERNAME"
    
    echo -e "${WHITE}[${CYAN}4/5${WHITE}] ${GREEN}➜ ${WHITE}🛠️ Инициализация проекта...${NC}"
    forge init -t drosera-network/trap-foundry-template
    bun install
    forge build
    
    echo -e "${WHITE}[${CYAN}5/5${WHITE}] ${GREEN}➜ ${WHITE}🔑 Применение конфигурации...${NC}"
    echo -e "${YELLOW}🔐 Введите ваш приватный ключ от EVM кошелька:${NC}"
    read -p "➜ " PRIV_KEY
    
    export DROSERA_PRIVATE_KEY="$PRIV_KEY"
    drosera apply
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    success_message "Trap успешно настроен!"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для установки ноды
install_node() {
    info_message "Запуск установки ноды..."
    
    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}📁 Настройка конфигурации...${NC}"
    TARGET_FILE="$HOME/my-drosera-trap/drosera.toml"
    
    [ -f "$TARGET_FILE" ] && {
        sed -i '/^private_trap/d' "$TARGET_FILE"
        sed -i '/^whitelist/d' "$TARGET_FILE"
    }
    
    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}💼 Настройка кошелька...${NC}"
    echo -e "${YELLOW}📝 Введите адрес вашего EVM кошелька:${NC}"
    read -p "➜ " WALLET_ADDRESS
    
    echo "private_trap = true" >> "$TARGET_FILE"
    echo "whitelist = [\"$WALLET_ADDRESS\"]" >> "$TARGET_FILE"
    
    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🔑 Применение конфигурации...${NC}"
    cd my-drosera-trap
    
    echo -e "${YELLOW}🔐 Введите ваш приватный ключ от EVM кошелька:${NC}"
    read -p "➜ " PRIV_KEY
    
    export DROSERA_PRIVATE_KEY="$PRIV_KEY"
    drosera apply
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    success_message "Нода успешно установлена!"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    cd
}

# Функция для запуска ноды
start_node() {
    info_message "Запуск ноды Drosera..."
    
    echo -e "${WHITE}[${CYAN}1/4${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка бинарных файлов...${NC}"
    cd ~
    curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
    tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
    sudo cp drosera-operator /usr/bin
    
    echo -e "${WHITE}[${CYAN}2/4${WHITE}] ${GREEN}➜ ${WHITE}🔑 Регистрация оператора...${NC}"
    echo -e "${YELLOW}🔐 Введите ваш приватный ключ от EVM кошелька:${NC}"
    read -p "➜ " PRIV_KEY
    
    export DROSERA_PRIVATE_KEY="$PRIV_KEY"
    drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $DROSERA_PRIVATE_KEY
    
    echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Создание сервиса...${NC}"
    SERVER_IP=$(curl -s https://api.ipify.org)
    
    sudo bash -c "cat <<EOF > /etc/systemd/system/drosera.service
[Unit]
Description=drosera node service
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
LimitNOFILE=65535
ExecStart=$(which drosera-operator) node --db-file-path \$HOME/.drosera.db --network-p2p-port 31313 --server-port 31314 \\
    --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com \\
    --eth-backup-rpc-url https://1rpc.io/holesky \\
    --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \\
    --eth-private-key $DROSERA_PRIVATE_KEY \\
    --listen-address 0.0.0.0 \\
    --network-external-p2p-address $SERVER_IP \\
    --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF"
    
    echo -e "${WHITE}[${CYAN}4/4${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск сервиса...${NC}"
    sudo systemctl daemon-reload
    sudo systemctl enable drosera
    sudo systemctl start drosera
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    success_message "Нода успешно запущена!"
    info_message "Для просмотра логов используйте команду:"
    echo -e "${CYAN}journalctl -u drosera.service -f${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    journalctl -u drosera.service -f
}

# Функция для удаления ноды
remove_node() {
    info_message "Удаление ноды Drosera..."
    
    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервисов...${NC}"
    sudo systemctl stop drosera.service
    sudo systemctl disable drosera.service
    sudo rm /etc/systemd/system/drosera.service
    sudo systemctl daemon-reload
    
    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    rm -rf my-drosera-trap
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    success_message "Нода Drosera успешно удалена!"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Очистка экрана
clear

# Функция для отображения меню
print_menu() {
    # Отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🚀 DROSERA NODE MANAGER        ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка зависимостей${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🚀 Деплой Trap${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🛠️ Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}▶️ Запуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🔄 Просмотр статуса${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}📋 Просмотр логов${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}8${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}9${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Основной цикл программы
while true; do
    clear
    print_menu
    
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-9]:${NC} "
    read -p "➜ " choice
    
    case $choice in
        1)
            install_dependencies
            ;;
        2)
            deploy_trap
            ;;
        3)
            install_node
            ;;
        4)
            start_node
            ;;
        5)
            info_message "Проверка статуса ноды..."
            echo -e "${GREEN}У вас актуальная версия ноды Drosera!${NC}"
            ;;
        6)
            info_message "Просмотр логов ноды..."
            journalctl -u drosera.service -f
            ;;
        7)
            info_message "Перезапуск ноды..."
            sudo systemctl restart drosera
            journalctl -u drosera.service -f
            ;;
        8)
            remove_node
            ;;
        9)
            echo -e "\n${GREEN}👋 До свидания!${NC}\n"
            exit 0
            ;;
        *)
            error_message "Неверный выбор! Пожалуйста, введите номер от 1 до 9."
            ;;
    esac
    
    echo -e "\nНажмите Enter, чтобы вернуться в меню..."
    read
done


       
