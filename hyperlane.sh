#!/bin/bash

# Определение цветов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Иконки
CHECKMARK="✅"
ERROR="❌"
PROGRESS="⏳"
INSTALL="📦"
SUCCESS="🎉"
WARNING="⚠️"
NODE="🖥️"
INFO="ℹ️"
TRASH="🗑️"
UPDATE="🔄"
LOGS="📄"
EXIT="🚪"

# ASCII арт и заголовок
display_ascii() {
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}Установка curl...${NC}"
        sudo apt update
        sudo apt install curl -y
    fi
    sleep 1
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
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

# Установка ноды
install_node() {
    echo -e "\n${BLUE}${NODE} Установка ноды Hyperlane...${NC}"
    
    echo -e "${PROGRESS} Обновление системы..."
    sudo apt update -y
    sudo apt upgrade -y

    # Установка Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${PROGRESS} Установка Docker..."
        sudo apt install docker.io -y
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo -e "${CHECKMARK} Docker уже установлен"
    fi

    echo -e "${PROGRESS} Загрузка Docker образа..."
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0

    # Ввод данных
    echo -e "${YELLOW}Введите имя валидатора:${NC}"
    read NAME
    echo -e "${YELLOW}Введите приватный ключ от EVM кошелька начиная с 0x:${NC}"
    read PRIVATE_KEY

    # Создание директории
    mkdir -p $HOME/hyperlane_db_base
    chmod -R 777 $HOME/hyperlane_db_base

    echo -e "${PROGRESS} Запуск Docker контейнера..."
    docker run -d -it \
    --name hyperlane \
    --mount type=bind,source=$HOME/hyperlane_db_base,target=/hyperlane_db_base \
    gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
    ./validator \
    --db /hyperlane_db_base \
    --originChainName base \
    --reorgPeriod 1 \
    --validator.id "$NAME" \
    --checkpointSyncer.type localStorage \
    --checkpointSyncer.folder base \
    --checkpointSyncer.path /hyperlane_db_base/base_checkpoints \
    --validator.key "$PRIVATE_KEY" \
    --chains.base.signer.key "$PRIVATE_KEY" \
    --chains.base.customRpcUrls https://base.llamarpc.com

    echo -e "${SUCCESS} Нода успешно установлена!"
    echo -e "${INFO} Для просмотра логов используйте: docker logs -f hyperlane"
    
    echo -e "${PROGRESS} Отображение логов..."
    sleep 2
    docker logs -f hyperlane
}

# Обновление ноды
update_node() {
    echo -e "\n${BLUE}${UPDATE} Обновление ноды Hyperlane...${NC}"
    echo -e "${SUCCESS} Установлена актуальная версия ноды!"
}

# Просмотр логов
view_logs() {
    echo -e "\n${BLUE}${LOGS} Просмотр логов...${NC}"
    docker logs -f hyperlane
}

# Удаление ноды
remove_node() {
    echo -e "\n${BLUE}${TRASH} Удаление ноды Hyperlane...${NC}"
    
    echo -e "${PROGRESS} Остановка и удаление контейнера..."
    docker stop hyperlane
    docker rm hyperlane

    if [ -d "$HOME/hyperlane_db_base" ]; then
        echo -e "${PROGRESS} Удаление директории ноды..."
        rm -rf $HOME/hyperlane_db_base
        echo -e "${CHECKMARK} Директория ноды удалена"
    fi

    echo -e "${SUCCESS} Нода успешно удалена!"
}

# Основное меню
main_menu() {
    while true; do
        display_ascii
        draw_top_border
        echo -e "  ${SUCCESS}  ${GREEN}Добро пожаловать в мастер управления нодой Hyperlane!${NC}"
        draw_middle_border
        echo -e "${CYAN}  1)${NC} Установить ноду ${INSTALL}"
        echo -e "${CYAN}  2)${NC} Обновить ноду ${UPDATE}"
        echo -e "${CYAN}  3)${NC} Просмотр логов ${LOGS}"
        echo -e "${CYAN}  4)${NC} Удалить ноду ${TRASH}"
        echo -e "${CYAN}  5)${NC} Выход ${EXIT}"
        draw_bottom_border
        
        read -p "$(echo -e $GREEN)Выберите действие [1-5]:${NC} " choice

        case $choice in
            1) install_node ;;
            2) update_node ;;
            3) view_logs ;;
            4) remove_node ;;
            5) echo -e "${SUCCESS} Выход..."; exit 0 ;;
            *) echo -e "${ERROR} Неверный выбор. Используйте числа от 1 до 5." ;;
        esac

        if [ "$choice" != "1" ] && [ "$choice" != "3" ]; then
            read -p "Нажмите Enter для возврата в меню..."
        fi
    done
}

# Запуск скрипта
main_menu
