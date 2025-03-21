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
NC='\033[0m' # Нет цвета

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

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

# Функция отображения логотипа
display_logo() {
    clear
    # Загрузка логотипа из репозитория
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash || {
        # Если загрузка не удалась, отображаем стандартный логотип
        echo -e "${BOLD}${PURPLE}"
        echo -e "╔═══════════════════════════════════════════════╗"
        echo -e "║                 LAYER EDGE                    ║"
        echo -e "║               LIGHT NODE (CLI)                ║"
        echo -e "╚═══════════════════════════════════════════════╝${NC}"
    }
    
    # Дополнительная информация о ноде
    echo -e "\n${BOLD}${CYAN}════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}       Инструмент управления Layer Edge         ${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════${NC}\n"
}

# Отображаем логотип
display_logo

# Функция установки зависимостей
install_dependencies() {
    info_message "Установка необходимых пакетов..."
    sudo apt update && sudo apt install -y curl iptables build-essential git wget jq make gcc nano automake autoconf tmux htop nvme-cli pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip screen
    success_message "Зависимости установлены"
}

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🚀 LAYER EDGE MANAGER           ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка зависимостей${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}📋 Запуск Merkle-сервиса${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}📊 Проверка логов ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}⚡ Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}8${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Главный цикл
while true; do
    display_logo
    print_menu
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-8]:${NC} "
    read -p "➜ " choice

    case $choice in
        1)
            echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🔄 Установка зависимостей...${NC}"
            install_dependencies

            # Обновление и установка зависимостей
            sudo apt update && sudo apt-get upgrade -y

            git clone https://github.com/Layer-Edge/light-node.git
            cd light-node

            VER="1.21.3"
            wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
            rm "go$VER.linux-amd64.tar.gz"
            [ ! -f ~/.bash_profile ] && touch ~/.bash_profile
            echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
            source $HOME/.bash_profile
            [ ! -d ~/go/bin ] && mkdir -p ~/go/bin

            if ! command -v rustc &> /dev/null; then
                info_message "Rust не установлен. Устанавливаем Rust через rustup..."
                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                source $HOME/.cargo/env
                success_message "Rust успешно установлен."
            else
                info_message "Rust уже установлен. Обновляем его через rustup update..."
                rustup update
                source $HOME/.cargo/env
                success_message "Rust успешно обновлён."
            fi

            curl -L https://risczero.com/install | bash
            source "$HOME/.bashrc"
            sleep 5
            rzup install

            # Запрашиваем приватный ключ у пользователя
            echo -e "${YELLOW}💼 Введите ваш приватный ключ без 0x:${NC} "
            read -p "➜ " PRIV_KEY
            
            # Создаем файл .env с нужным содержимым
            echo "GRPC_URL=grpc.testnet.layeredge.io:9090" > .env
            echo "CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709" >> .env
            echo "ZK_PROVER_URL=http://127.0.0.1:3001" >> .env
            echo "ZK_PROVER_URL=https://layeredge.mintair.xyz/" >> .env
            echo "API_REQUEST_TIMEOUT=300" >> .env
            echo "POINTS_API=https://light-node.layeredge.io" >> .env
            echo "PRIVATE_KEY='$PRIV_KEY'" >> .env

            cd ~
            
            success_message "Зависимости успешно установлены и настроены!"
            ;;
        2)
            echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запускаем Merkle-сервис...${NC}"

            # Определяем имя текущего пользователя и его домашнюю директорию
            USERNAME=$(whoami)
            HOME_DIR=$(eval echo ~$USERNAME)

            sudo bash -c "cat <<EOT > /etc/systemd/system/merkle.service
[Unit]
Description=Merkle Service for Light Node
After=network.target

[Service]
User=$USERNAME
Environment=PATH=$HOME/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
WorkingDirectory=$HOME_DIR/light-node/risc0-merkle-service
ExecStart=/usr/bin/env bash -c \"cargo build && cargo run --release\"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOT"

            sudo systemctl daemon-reload
            sleep 2
            sudo systemctl enable merkle.service
            sudo systemctl start merkle.service
            # Проверка логов
            success_message "Merkle-сервис успешно запущен!"
            echo -e "${YELLOW}Показать логи сервиса? (y/n)${NC}"
            read -p "➜ " show_logs
            if [[ "$show_logs" == "y" || "$show_logs" == "Y" ]]; then
                sudo journalctl -u merkle.service -f
            fi
            ;;
        3)
            echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запускаем ноду...${NC}"
            USERNAME=$(whoami)
            HOME_DIR=$(eval echo ~$USERNAME)

            # Определяем путь к Go
            GO_PATH=$(which go)
            
            # Проверяем, что GO_PATH не пустой
            if [ -z "$GO_PATH" ]; then
                error_message "Go не найден в PATH. Проверьте установку Go."
                continue
            fi

            sudo bash -c "cat <<EOT > /etc/systemd/system/light-node.service
[Unit]
Description=LayerEdge Light Node Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/light-node
ExecStartPre=$GO_PATH build
ExecStart=$HOME_DIR/light-node/light-node
Restart=always
RestartSec=10
TimeoutStartSec=200

[Install]
WantedBy=multi-user.target
EOT"

            sudo systemctl daemon-reload
            sleep 2
            sudo systemctl enable light-node.service
            sudo systemctl start light-node.service

            # Заключительный вывод
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Команда для проверки логов:${NC}"
            echo "sudo journalctl -u light-node.service -f"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            success_message "Нода успешно запущена!"
            echo -e "${YELLOW}Показать логи ноды? (y/n)${NC}"
            read -p "➜ " show_logs
            if [[ "$show_logs" == "y" || "$show_logs" == "Y" ]]; then
                sudo journalctl -u light-node.service -f
            fi
            ;;
        4)
            echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}📊 Проверяем логи ноды...${NC}"
            sudo journalctl -u light-node.service -f
            ;;
        5)
            echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапускаем ноду...${NC}"
            sudo systemctl restart light-node.service
            success_message "Нода успешно перезапущена!"
            echo -e "${YELLOW}Показать логи ноды? (y/n)${NC}"
            read -p "➜ " show_logs
            if [[ "$show_logs" == "y" || "$show_logs" == "Y" ]]; then
                sudo journalctl -u light-node.service -f
            fi
            ;;
        6)
            echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}⚡ Обновляем ноду...${NC}"
            cd light-node
            sudo systemctl stop light-node.service
            success_message "Нода остановлена"

            echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление конфигурации...${NC}"
            rm -f .env

            # Запрашиваем приватный ключ у пользователя
            echo -e "${YELLOW}💼 Введите ваш приватный ключ без 0x:${NC} "
            read -p "➜ " PRIV_KEY
            
            # Создаем файл .env с нужным содержимым
            echo "GRPC_URL=grpc.testnet.layeredge.io:9090" > .env
            echo "CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709" >> .env
            echo "ZK_PROVER_URL=http://127.0.0.1:3001" >> .env
            echo "ZK_PROVER_URL=https://layeredge.mintair.xyz/" >> .env
            echo "API_REQUEST_TIMEOUT=300" >> .env
            echo "POINTS_API=https://light-node.layeredge.io" >> .env
            echo "PRIVATE_KEY='$PRIV_KEY'" >> .env

            cd ~
            
            echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск обновленной ноды...${NC}"
            sudo systemctl restart light-node.service
            success_message "Нода успешно обновлена и запущена!"
            echo -e "${YELLOW}Показать логи ноды? (y/n)${NC}"
            read -p "➜ " show_logs
            if [[ "$show_logs" == "y" || "$show_logs" == "Y" ]]; then
                sudo journalctl -u light-node.service -f
            fi
            ;;
        7)
            echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление ноды...${NC}"
            echo -e "${BOLD}${RED}⚠️ ВНИМАНИЕ: Все данные ноды будут удалены! ⚠️${NC}"
            echo -e "${YELLOW}Вы уверены, что хотите продолжить? (y/n)${NC}"
            read -p "➜ " confirm
            
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🧹 Очистка системы...${NC}"
                sudo systemctl stop light-node.service
                sudo systemctl disable light-node.service
                sudo systemctl stop merkle.service
                sudo systemctl disable merkle.service

                sudo rm /etc/systemd/system/light-node.service
                sudo rm /etc/systemd/system/merkle.service
                sudo systemctl daemon-reload

                rm -rf ~/light-node

                success_message "Нода успешно удалена!"
            else
                info_message "Операция отменена."
            fi
            ;;
        8)
            echo -e "\n${GREEN}👋 До свидания!${NC}\n"
            exit 0
            ;;
        *)
            error_message "Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 8."
            ;;
    esac
    
    echo -e "\nНажмите Enter, чтобы вернуться в меню..."
    read
done
