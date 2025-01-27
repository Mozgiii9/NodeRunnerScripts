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

# Отображение логотипа
clear
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Меню
echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${WHITE}║      🚀 PRIVASEA NODE MANAGER          ║${NC}"
echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"

echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}▶️  Запуск ноды${NC}"
echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка логов${NC}"
echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Рестарт ноды${NC}"
echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}\n"

echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-6]:${NC} "
read -p "➜ " choice

case $choice in
    1)
        echo -e "\n${BOLD}${BLUE}⚡ Установка ноды Privasea...${NC}\n"

        echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление системы...${NC}"
        sudo apt update && sudo apt upgrade -y

        # Проверка наличия Docker и Docker Compose
        if ! command -v docker &> /dev/null; then
            echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🐳 Установка Docker...${NC}"
            sudo apt install docker.io -y
            if ! command -v docker &> /dev/null; then
                echo -e "${RED}❌ Ошибка: Docker не был установлен${NC}"
                exit 1
            fi
        fi

        if ! command -v docker-compose &> /dev/null; then
            echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🔧 Установка Docker Compose...${NC}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            if ! command -v docker-compose &> /dev/null; then
                echo -e "${RED}❌ Ошибка: Docker Compose не был установлен${NC}"
                exit 1
            fi
        fi

        echo -e "${WHITE}[${CYAN}+${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка образа ноды...${NC}"
        docker pull privasea/acceleration-node-beta:latest
        mkdir -p ~/privasea/config

        echo -e "\n${GREEN}✅ Установка успешно завершена!${NC}\n"
        ;;

    2)
        echo -e "\n${BOLD}${BLUE}🚀 Запуск ноды Privasea...${NC}\n"

        echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}📂 Переход в директорию...${NC}"
        cd ~/privasea

        echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🔑 Создание нового keystore...${NC}"
        docker run --rm -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore

        echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}📝 Настройка keystore...${NC}"
        mv $HOME/privasea/config/UTC--* $HOME/privasea/config/wallet_keystore

        echo -e "\n${CYAN}📄 Содержимое wallet_keystore(вставьте в MetaMask):${NC}"
        cat $HOME/privasea/config/wallet_keystore
        echo -e "\n"

        echo -e "${YELLOW}🔑 Введите пароль от кошелька:${NC}"
        read -s -p "➜ " PASS
        echo

        echo -e "\n${WHITE}[${CYAN}+${WHITE}] ${GREEN}➜ ${WHITE}▶️  Запуск контейнера...${NC}"
        docker run -d --name privanetix-node -v "$HOME/privasea/config:/app/config" -e KEYSTORE_PASSWORD=$PASS privasea/acceleration-node-beta:latest
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Ошибка: Не удалось запустить контейнер${NC}"
            exit 1
        fi

        echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}📋 Команда для проверки логов:${NC}"
        echo "docker logs -f privanetix-node"
        echo -e "${PURPLE}═════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✅ Нода успешно запущена!${NC}\n"
        sleep 2

        docker logs -f privanetix-node
        ;;

    3)
        echo -e "\n${BOLD}${BLUE}📋 Просмотр логов Privasea...${NC}\n"
        docker logs -f privanetix-node
        ;;

    4)
        echo -e "\n${BOLD}${BLUE}🔄 Рестарт ноды Privasea...${NC}\n"

        echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск контейнера...${NC}"
        docker restart privanetix-node
        echo -e "${GREEN}✅ Нода успешно перезапущена!${NC}\n"
        sleep 2

        docker logs -f privanetix-node
        ;;

    5)
        echo -e "\n${BOLD}${GREEN}✅ У вас установлена актуальная версия ноды Privasea${NC}\n"
        ;;

    6)
        echo -e "\n${BOLD}${RED}⚠️  Удаление ноды Privasea...${NC}\n"

        echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка контейнера...${NC}"
        docker stop privanetix-node
        docker rm privanetix-node

        echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление файлов...${NC}"
        rm -rf ~/privasea

        echo -e "\n${GREEN}✅ Нода успешно удалена!${NC}\n"
        sleep 2
        ;;

    *)
        echo -e "\n${BOLD}${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 6${NC}\n"
        ;;
esac
