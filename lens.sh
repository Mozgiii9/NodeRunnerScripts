#!/bin/bash

# Определение цветов и иконок
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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
TELEGRAM="🚀"
TOOL="🛠️"
TRASH="🗑️"
UPDATE="🔄"
LOGS="📄"
CONFIG="⚙️"
EXIT="🚪"

# ASCII арт и заголовок
display_ascii() {
    # Проверка наличия curl
    if ! command -v curl &> /dev/null; then
        echo -e "${ORANGE}Установка curl...${NC}"
        apt update
        apt install curl -y
    fi
    sleep 1

    # Загрузка и отображение логотипа
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

# Функция установки Docker
install_docker() {
    echo -e "\n${INFO} Проверка наличия Docker..."
    if ! command -v docker &> /dev/null; then
        echo -e "${INSTALL} Docker не найден. Установка Docker..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        echo -e "${CHECKMARK} Docker установлен"
    else
        echo -e "${CHECKMARK} Docker уже установлен"
    fi

    echo -e "\n${INFO} Проверка наличия Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${INSTALL} Docker Compose не найден. Установка Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${CHECKMARK} Docker Compose установлен"
    else
        echo -e "${CHECKMARK} Docker Compose уже установлен"
    fi
}

# Функция клонирования репозитория
clone_lens_node() {
    echo -e "\n${PROGRESS} Клонирование репозитория Lens Node..."
    if [ -d "lens-node" ]; then
        echo -e "${WARNING} Директория lens-node уже существует"
    else
        git clone https://github.com/lens-network/lens-node && cd lens-node
        echo -e "${CHECKMARK} Репозиторий Lens Node успешно клонирован"
    fi
}

# Функция запуска ноды
start_lens_node() {
    echo -e "\n${PROGRESS} Запуск Lens Node..."
    if [ -d "lens-node" ]; then
        cd lens-node
        docker-compose --file testnet-external-node.yml up -d
        if [ $? -eq 0 ]; then
            echo -e "${SUCCESS} Lens Node успешно запущена"
        else
            echo -e "${ERROR} Ошибка при запуске Lens Node"
        fi
    else
        echo -e "${ERROR} Директория lens-node не найдена"
    fi
}

# Функция остановки ноды
stop_lens_node() {
    echo -e "\n${PROGRESS} Остановка Lens Node..."
    if [ -d "lens-node" ]; then
        cd lens-node
        docker-compose --file testnet-external-node.yml down
        if [ $? -eq 0 ]; then
            echo -e "${SUCCESS} Lens Node успешно остановлена"
        else
            echo -e "${ERROR} Ошибка при остановке Lens Node"
        fi
    else
        echo -e "${ERROR} Директория lens-node не найдена"
    fi
}

# Функция просмотра логов
view_lens_node_logs() {
    echo -e "\n${LOGS} Последние 100 строк логов Lens Node..."
    docker logs -f --tail=100 lens-node-external-node-1
    echo -e "\n${INFO} Логи выведены"
}

# Функция проверки состояния ноды
check_lens_node_health() {
    echo -e "\n${INFO} Проверка состояния Lens Node..."
    if ! command -v jq &> /dev/null; then
        echo -e "${INSTALL} Установка jq..."
        sudo apt-get install -y jq
    fi
    
    response=$(curl -s http://localhost:3081/health)
    if [ $? -eq 0 ]; then
        echo "$response" | jq .
        echo -e "${CHECKMARK} Lens Node работает нормально"
    else
        echo -e "${ERROR} Lens Node не отвечает или недоступна"
    fi
}

# Основное меню
main_menu() {
    while true; do
        display_ascii
        draw_top_border
        echo -e "  ${SUCCESS}  ${GREEN}Добро пожаловать в мастер установки Lens Node!${NC}"
        draw_middle_border
        echo -e "${CYAN}  1) Установить и запустить ноду ${INSTALL}${NC}"
        echo -e "${CYAN}  2) Остановить ноду ${TRASH}${NC}"
        echo -e "${CYAN}  3) Просмотр логов ${LOGS}${NC}"
        echo -e "${CYAN}  4) Проверить состояние ноды ${CONFIG}${NC}"
        echo -e "${CYAN}  5) Выход ${EXIT}${NC}"
        draw_bottom_border
        
        read -p "$(echo -e ${GREEN}Выберите действие:${NC} )" action

        case $action in
            1)
                install_docker
                clone_lens_node
                start_lens_node
                read -p "Нажмите Enter для возврата в меню..." ;;
            2)
                stop_lens_node
                read -p "Нажмите Enter для возврата в меню..." ;;
            3)
                view_lens_node_logs
                read -p "Нажмите Enter для возврата в меню..." ;;
            4)
                check_lens_node_health
                read -p "Нажмите Enter для возврата в меню..." ;;
            5)
                echo -e "${SUCCESS} Выход из программы..."
                exit 0
                ;;
            *)
                echo -e "${ERROR} Неверный выбор. Попробуйте снова."
                read -p "Нажмите Enter для возврата в меню..." ;;
        esac
    done
}

# Запуск основного меню
main_menu