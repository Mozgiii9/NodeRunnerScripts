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

# Функция для отображения предупреждений
warning_message() {
    echo -e "${YELLOW}[⚠️] $1${NC}"
}

# Очистка экрана
clear

# Отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🔗 T3RN NODE MANAGER           ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка логов${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Проверка наличия bc и установка, если не установлен
if ! command -v bc &> /dev/null; then
    info_message "Установка bc..."
    sudo apt update
    sudo apt install bc -y
    success_message "bc успешно установлен"
fi

# Проверка версии Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    error_message "Для этой ноды нужна минимальная версия Ubuntu 22.04"
    exit 1
fi

# Функция для установки ноды
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка ноды t3rn...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/6${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление пакетов...${NC}"
    sudo apt update
    sudo apt upgrade -y
    sudo apt-get install figlet -y
    success_message "Пакеты обновлены"
    sleep 1

    # Лого специальное
    figlet -f /usr/share/figlet/starwars.flf 

    echo -e "${WHITE}[${CYAN}2/6${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка актуальной версии...${NC}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz"
    curl -L -o executor-linux-${LATEST_VERSION}.tar.gz $EXECUTOR_URL
    success_message "Бинарный файл загружен: $LATEST_VERSION"
    sleep 1

    echo -e "${WHITE}[${CYAN}3/6${WHITE}] ${GREEN}➜ ${WHITE}📦 Распаковка архива...${NC}"
    tar -xzvf executor-linux-${LATEST_VERSION}.tar.gz
    rm -rf executor-linux-${LATEST_VERSION}.tar.gz
    success_message "Архив распакован"
    sleep 1

    echo -e "${WHITE}[${CYAN}4/6${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Настройка конфигурации...${NC}"
    # Определяем пользователя и домашнюю директорию
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)

    # Создаем .t3rn и записываем приватный ключ
    CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
    echo "ENVIRONMENT=testnet" > $CONFIG_FILE
    echo "LOG_LEVEL=debug" >> $CONFIG_FILE
    echo "LOG_PRETTY=false" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_BIDS_ENABLED=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
    echo "PRIVATE_KEY_LOCAL=" >> $CONFIG_FILE
    echo "EXECUTOR_MAX_L3_GAS_PRICE=100" >> $CONFIG_FILE
    echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'" >> $CONFIG_FILE
    cat <<'EOF' >> $CONFIG_FILE
RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
}'
EOF
    if ! grep -q "ENVIRONMENT=testnet" "$HOME/executor/executor/bin/.t3rn"; then
      echo "ENVIRONMENT=testnet" >> "$HOME/executor/executor/bin/.t3rn"
    fi

    echo -e "${YELLOW}🔑 Введите ваш приватный ключ:${NC}"
    read -p "➜ " PRIVATE_KEY
    sed -i "s|PRIVATE_KEY_LOCAL=|PRIVATE_KEY_LOCAL=$PRIVATE_KEY|" $CONFIG_FILE
    success_message "Конфигурация настроена"
    sleep 1

    echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}📝 Создание сервиса...${NC}"
    # Создаем сервисник
    sudo bash -c "cat <<EOT > /etc/systemd/system/t3rn.service
[Unit]
Description=t3rn Service
After=network.target

[Service]
EnvironmentFile=$HOME_DIR/executor/executor/bin/.t3rn
ExecStart=$HOME_DIR/executor/executor/bin/executor
WorkingDirectory=$HOME_DIR/executor/executor/bin/
Restart=on-failure
User=$USERNAME

[Install]
WantedBy=multi-user.target
EOT"
    success_message "Сервис создан"
    sleep 1

    echo -e "${WHITE}[${CYAN}6/6${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск сервиса...${NC}"
    # Запуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-journald
    sleep 1
    sudo systemctl enable t3rn
    sudo systemctl start t3rn
    success_message "Сервис запущен и добавлен в автозагрузку"
    sleep 1

    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода t3rn успешно установлена и запущена!${NC}"
    echo -e "${YELLOW}📝 Команда для проверки логов:${NC}"
    echo -e "${CYAN}sudo journalctl -u t3rn -f${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    sudo journalctl -u t3rn -f
}

# Функция для обновления ноды
update_node() {
    echo -e "\n${BOLD}${BLUE}⬆️ Обновление ноды t3rn...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/4${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервиса...${NC}"
    sudo systemctl stop t3rn
    success_message "Сервис остановлен"
    sleep 1
    
    echo -e "${WHITE}[${CYAN}2/4${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление старых файлов...${NC}"
    cd
    rm -rf executor/
    success_message "Старые файлы удалены"
    sleep 1
    
    echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка новой версии...${NC}"
    LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz"
    curl -L -o executor-linux-${LATEST_VERSION}.tar.gz $EXECUTOR_URL
    tar -xzvf executor-linux-${LATEST_VERSION}.tar.gz
    rm -rf executor-linux-${LATEST_VERSION}.tar.gz
    success_message "Новая версия загружена: $LATEST_VERSION"
    sleep 1
    
    echo -e "${WHITE}[${CYAN}4/4${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Обновление конфигурации...${NC}"
    # Определяем пользователя и домашнюю директорию
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)
    
    # Создаем .t3rn и записываем приватный ключ
    CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
    echo "ENVIRONMENT=testnet" > $CONFIG_FILE
    echo "LOG_LEVEL=debug" >> $CONFIG_FILE
    echo "LOG_PRETTY=false" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_BIDS_ENABLED=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
    echo "PRIVATE_KEY_LOCAL=" >> $CONFIG_FILE
    echo "EXECUTOR_MAX_L3_GAS_PRICE=100" >> $CONFIG_FILE
    echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'" >> $CONFIG_FILE
    cat <<'EOF' >> $CONFIG_FILE
RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
}'
EOF

    if ! grep -q "ENVIRONMENT=testnet" "$HOME/executor/executor/bin/.t3rn"; then
      echo "ENVIRONMENT=testnet" >> "$HOME/executor/executor/bin/.t3rn"
    fi

    echo -e "${YELLOW}🔑 Введите ваш приватный ключ:${NC}"
    read -p "➜ " PRIVATE_KEY
    sed -i "s|PRIVATE_KEY_LOCAL=|PRIVATE_KEY_LOCAL=$PRIVATE_KEY|" $CONFIG_FILE
    
    # Перезапуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-journald
    sudo systemctl start t3rn
    success_message "Конфигурация обновлена и сервис перезапущен"
    sleep 1
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода t3rn успешно обновлена!${NC}"
    echo -e "${YELLOW}📝 Команда для проверки логов:${NC}"
    echo -e "${CYAN}sudo journalctl -u t3rn -f${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    sudo journalctl -u t3rn -f
}

# Функция для проверки логов
check_logs() {
    echo -e "\n${BOLD}${BLUE}📋 Просмотр логов ноды t3rn...${NC}\n"
    
    info_message "Отображение логов ноды..."
    sudo journalctl -u t3rn -f
}

# Функция для перезапуска ноды
restart_node() {
    echo -e "\n${BOLD}${BLUE}🔄 Перезапуск ноды t3rn...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск сервиса...${NC}"
    sudo systemctl restart t3rn
    success_message "Нода успешно перезапущена"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода t3rn успешно перезапущена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    sudo journalctl -u t3rn -f
}

# Функция для удаления ноды
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды t3rn...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервисов...${NC}"
    sudo systemctl stop t3rn
    sudo systemctl disable t3rn
    sudo rm /etc/systemd/system/t3rn.service
    sudo systemctl daemon-reload
    sleep 2
    success_message "Сервисы остановлены и удалены"
    
    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    rm -rf $HOME/executor
    success_message "Файлы ноды удалены"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Нода t3rn успешно удалена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Основной цикл программы
while true; do
    clear
    # Отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    
    print_menu
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-6]:${NC} "
    read -p "➜ " choice

    case $choice in
        1)
            install_node
            ;;
        2)
            update_node
            ;;
        3)
            check_logs
            ;;
        4)
            restart_node
            ;;
        5)
            remove_node
            ;;
        6)
            echo -e "\n${GREEN}👋 До свидания!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 6.${NC}\n"
            ;;
    esac
    
    if [[ "$choice" != "3" ]]; then
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    fi
done
