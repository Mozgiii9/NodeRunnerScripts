#!/bin/bash

# Определение цветов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Логотип
display_logo() {
    # Проверка наличия curl
    if ! command -v curl &> /dev/null; then
        echo -e "${ORANGE}Установка curl...${NC}"
        apt update
        apt install curl -y
    fi
    sleep 1

    # Загрузка и отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    sleep 2
}

# Функции отрисовки границ меню
draw_top_border() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════╗${NC}"
}

draw_middle_border() {
    echo -e "${BLUE}╠══════════════════════════════════════════════════════╣${NC}"
}

draw_bottom_border() {
    echo -e "${BLUE}╚══════════════════════════════════════════════════════╝${NC}"
}

# Проверка системных требований
check_requirements() {
    echo -e "\n${YELLOW}📊 Проверка системных требований...${NC}"
    CPU=$(grep -c ^processor /proc/cpuinfo)
    RAM=$(free -m | awk '/Mem:/ { print $2 }')
    DISK=$(df -h / | awk '/\// { print $4 }' | sed 's/G//g')

    echo -e "${CYAN}Ядер CPU: ${GREEN}$CPU${NC} (минимум: 2)"
    echo -e "${CYAN}Доступная память: ${GREEN}${RAM}MB${NC} (минимум: 2GB)"

    if [ "$CPU" -lt 2 ] || [ "$RAM" -lt 2000 ]; then
        echo -e "${RED}❌ Системные требования не соответствуют минимальным!${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Системные требования соответствуют!${NC}"
}

# Установка Docker
install_docker() {
    echo -e "\n${YELLOW}🐳 Установка Docker...${NC}"
    if ! command -v docker &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        sudo usermod -aG docker $USER
        echo -e "${GREEN}✅ Docker успешно установлен${NC}"
    else
        echo -e "${GREEN}✅ Docker уже установлен${NC}"
    fi
}

# Установка Node.js и NVM
install_node() {
    echo -e "\n${YELLOW}📦 Установка Node.js и NVM...${NC}"
    if ! command -v nvm &> /dev/null; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        source ~/.bashrc
        nvm install 20
        echo -e "${GREEN}✅ Node.js и NVM успешно установлены${NC}"
    else
        echo -e "${GREEN}✅ Node.js и NVM уже установлены${NC}"
    fi
}

# Установка Foundry
install_foundry() {
    echo -e "\n${YELLOW}🛠️ Установка Foundry...${NC}"
    if ! command -v foundryup &> /dev/null; then
        curl -L https://foundry.paradigm.xyz | bash
        source ~/.bashrc
        foundryup
        echo -e "${GREEN}✅ Foundry успешно установлен${NC}"
    else
        echo -e "${GREEN}✅ Foundry уже установлен${NC}"
    fi
}

# Установка Hyperlane
install_hyperlane() {
    echo -e "\n${YELLOW}🚀 Установка Hyperlane...${NC}"
    if ! command -v hyperlane &> /dev/null; then
        npm install -g @hyperlane-xyz/cli
        echo -e "${GREEN}✅ Hyperlane CLI установлен${NC}"
    fi

    echo -e "${YELLOW}📥 Загрузка образа Hyperlane...${NC}"
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0
    echo -e "${GREEN}✅ Образ Hyperlane загружен${NC}"
}

# Настройка и запуск валидатора
configure_validator() {
    echo -e "\n${YELLOW}⚙️ Настройка валидатора...${NC}"
    
    read -p "Введите имя валидатора: " VALIDATOR_NAME
    
    while true; do
        read -s -p "Введите приватный ключ (формат: 0x + 64 hex символа): " PRIVATE_KEY
        echo
        if [[ $PRIVATE_KEY =~ ^0x[0-9a-fA-F]{64}$ ]]; then
            break
        else
            echo -e "${RED}❌ Неверный формат ключа!${NC}"
        fi
    done
    
    read -p "Введите RPC URL: " RPC_URL

    DB_DIR="/opt/hyperlane_db_base"
    mkdir -p $DB_DIR
    chmod -R 777 $DB_DIR

    CONTAINER_NAME="hyperlane"
    if docker ps -a --format '{{.Names}}' | grep -q "^hyperlane$"; then
        echo -e "${YELLOW}⚠️ Найден существующий контейнер 'hyperlane'${NC}"
        read -p "Удалить старый контейнер? (y/n): " choice
        if [[ "$choice" == "y" ]]; then
            docker rm -f hyperlane
            echo -e "${GREEN}✅ Старый контейнер удален${NC}"
        else
            read -p "Введите новое имя контейнера: " CONTAINER_NAME
        fi
    fi

    docker run -d \
        -it \
        --name "$CONTAINER_NAME" \
        --mount type=bind,source="$DB_DIR",target=/hyperlane_db_base \
        gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
        ./validator \
        --db /hyperlane_db_base \
        --originChainName base \
        --reorgPeriod 1 \
        --validator.id "$VALIDATOR_NAME" \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.folder base \
        --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
        --validator.key "$PRIVATE_KEY" \
        --chains.base.signer.key "$PRIVATE_KEY" \
        --chains.base.customRpcUrls "$RPC_URL"

    echo -e "${GREEN}✅ Валидатор успешно запущен${NC}"
}

# Просмотр логов
view_logs() {
    echo -e "\n${YELLOW}📄 Просмотр логов...${NC}"
    if docker ps -a --format '{{.Names}}' | grep -q "^hyperlane$"; then
        docker logs -f hyperlane
    else
        echo -e "${RED}❌ Контейнер 'hyperlane' не найден${NC}"
    fi
}

# Главное меню
main_menu() {
    while true; do
        display_logo
        draw_top_border
        echo -e "  ${GREEN}Добро пожаловать в мастер установки Hyperlane Node!${NC}"
        draw_middle_border
        echo -e "${CYAN}  1)${NC} Проверить системные требования 📊"
        echo -e "${CYAN}  2)${NC} Установить зависимости (Docker, Node.js, Foundry) 📦"
        echo -e "${CYAN}  3)${NC} Установить Hyperlane 🚀"
        echo -e "${CYAN}  4)${NC} Настроить и запустить валидатор ⚙️"
        echo -e "${CYAN}  5)${NC} Просмотр логов 📄"
        echo -e "${CYAN}  6)${NC} Выполнить все шаги автоматически ✨"
        echo -e "${CYAN}  0)${NC} Выход 🚪"
        draw_bottom_border
        
        read -p "$(echo -e $GREEN)Выберите действие [0-6]:${NC} " choice

        case $choice in
            1) check_requirements ;;
            2) install_docker && install_node && install_foundry ;;
            3) install_hyperlane ;;
            4) configure_validator ;;
            5) view_logs ;;
            6)
                check_requirements
                install_docker
                install_node
                install_foundry
                install_hyperlane
                configure_validator
                view_logs
                ;;
            0)
                echo -e "${GREEN}👋 До свидания!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Неверный выбор. Попробуйте снова.${NC}"
                read -p "Нажмите Enter для продолжения..."
                ;;
        esac
    done
}

# Запуск основного меню
main_menu
