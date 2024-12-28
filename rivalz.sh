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
EXIT="🚪"

# ASCII арт и заголовок
display_ascii() {
    if ! command -v curl &> /dev/null; then
        echo -e "${ORANGE}Установка curl...${NC}"
        apt update
        apt install curl -y
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
    echo -e "\n${BLUE}${NODE} Установка ноды Rivalz...${NC}"
    
    echo -e "${PROGRESS} Обновление системы..."
    sudo apt update -y
    sudo apt upgrade -y
    
    echo -e "${PROGRESS} Установка Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    
    echo -e "${PROGRESS} Установка rivalz-node-cli..."
    npm i -g rivalz-node-cli
    rivalz run

    echo -e "\n${SUCCESS} Нода успешно установлена!"
}

# Обновление ноды
update_node() {
    echo -e "\n${BLUE}${UPDATE} Обновление ноды Rivalz...${NC}"
    echo -e "${SUCCESS} Установлена актуальная версия ноды!"
}

# Удаление ноды
remove_node() {
    echo -e "\n${BLUE}${TRASH} Удаление ноды Rivalz...${NC}"
    npm uninstall -g rivalz-node-cli
    echo -e "${SUCCESS} Нода успешно удалена!"
}

# Основное меню
main_menu() {
    while true; do
        display_ascii
        draw_top_border
        echo -e "  ${SUCCESS}  ${GREEN}Добро пожаловать в мастер управления нодой Rivalz!${NC}"
        draw_middle_border
        echo -e "${CYAN}  1)${NC} Установить ноду ${INSTALL}"
        echo -e "${CYAN}  2)${NC} Обновить ноду ${UPDATE}"
        echo -e "${CYAN}  3)${NC} Удалить ноду ${TRASH}"
        echo -e "${CYAN}  4)${NC} Выход ${EXIT}"
        draw_bottom_border
        
        read -p "$(echo -e $GREEN)Выберите действие [1-4]:${NC} " choice

        case $choice in
            1) install_node ;;
            2) update_node ;;
            3) remove_node ;;
            4) echo -e "${SUCCESS} Выход..."; exit 0 ;;
            *) echo -e "${ERROR} Неверный выбор. Используйте числа от 1 до 4." ;;
        esac

        read -p "Нажмите Enter для возврата в меню..."
    done
}

# Запуск скрипта
main_menu
