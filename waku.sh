#!/bin/bash

# Определение цветов для текста
ORANGE='\033[0;33m'
TEAL='\033[0;36m'
LIME='\033[1;32m'
INDIGO='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
CRIMSON='\033[0;31m'
RESET='\033[0m'

# Проверка наличия curl
if ! command -v curl &> /dev/null; then
    echo -e "${ORANGE}Установка curl...${RESET}"
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Загрузка и отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Главное меню
echo -e "\n${WHITE}╔═══════════════════════════════╗${RESET}"
echo -e "${WHITE}║        МЕНЮ УПРАВЛЕНИЯ         ║${RESET}"
echo -e "${WHITE}╚═══════════════════════════════╝${RESET}\n"

echo -e "${TEAL}[1]${RESET} ➜ Установка ноды"
echo -e "${TEAL}[2]${RESET} ➜ Обновление ноды"
echo -e "${TEAL}[3]${RESET} ➜ Проверка логов"
echo -e "${TEAL}[4]${RESET} ➜ Замена портов"
echo -e "${TEAL}[5]${RESET} ➜ Удаление ноды\n"

echo -e "${LIME}Выберите опцию (1-5):${RESET} "
read choice

case $choice in
    1)
        echo -e "\n${INDIGO}▶️ Начинаем установку Waku...${RESET}"

        # Обновление системы
        echo -e "${TEAL}📦 Обновление системных пакетов...${RESET}"
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli \
                            pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip

        # Установка Docker
        if ! command -v docker &> /dev/null; then
            echo -e "${TEAL}🐋 Установка Docker 24.0.7...${RESET}"
            curl -fsSL https://get.docker.com | sh
        else
            DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+')
            MIN_DOCKER_VERSION="24.0.7"
            if [[ "$(printf '%s\n' "$MIN_DOCKER_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$MIN_DOCKER_VERSION" ]]; then
                echo -e "${TEAL}🔄 Обновление Docker до версии 24.0.7...${RESET}"
                curl -fsSL https://get.docker.com | sh
            fi
        fi

        # Установка Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            echo -e "${TEAL}🔧 Установка Docker Compose 1.29.2...${RESET}"
            sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        else
            DOCKER_COMPOSE_VERSION=$(docker-compose --version | grep -oP '\d+\.\d+\.\d+')
            MIN_COMPOSE_VERSION="1.29.2"
            if [[ "$(printf '%s\n' "$MIN_COMPOSE_VERSION" "$DOCKER_COMPOSE_VERSION" | sort -V | head -n1)" != "$MIN_COMPOSE_VERSION" ]]; then
                echo -e "${TEAL}🔄 Обновление Docker Compose до версии 1.29.2...${RESET}"
                sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                sudo chmod +x /usr/local/bin/docker-compose
            fi
        fi

        # Настройка репозитория
        echo -e "${TEAL}📥 Клонирование репозитория...${RESET}"
        cd $HOME
        git clone https://github.com/waku-org/nwaku-compose
        cd $HOME/nwaku-compose
        cp .env.example .env

        # Сбор данных
        echo -e "\n${LIME}🌐 Введите RPC URL для доступа к тестнету:${RESET}"
        read RPC_URL
        echo -e "${LIME}🔑 Введите приватный ключ EVM кошелька:${RESET}"
        read ETH_KEY
        echo -e "${LIME}🔒 Введите пароль для RLN Membership:${RESET}"
        read RLN_PASSWORD

        # Обновление конфигурации
        echo -e "${TEAL}⚙️ Настройка конфигурации...${RESET}"
        sed -i "s|RLN_RELAY_ETH_CLIENT_ADDRESS=.*|RLN_RELAY_ETH_CLIENT_ADDRESS=$RPC_URL|" .env
        sed -i "s|ETH_TESTNET_KEY=.*|ETH_TESTNET_KEY=$ETH_KEY|" .env
        sed -i "s|RLN_RELAY_CRED_PASSWORD=.*|RLN_RELAY_CRED_PASSWORD=$RLN_PASSWORD|" .env

        # Регистрация и запуск
        echo -e "${TEAL}📝 Регистрация ноды...${RESET}"
        ./register_rln.sh

        echo -e "${TEAL}🚀 Запуск сервисов...${RESET}"
        docker-compose up -d

        echo -e "\n${LIME}✅ Установка успешно завершена!${RESET}"
        echo -e "\n${WHITE}Для проверки логов используйте:${RESET}"
        echo -e "${TEAL}cd $HOME/nwaku-compose && docker-compose logs -f${RESET}\n"
        ;;

    2)
        echo -e "\n${INDIGO}🔄 Обновление ноды Waku...${RESET}"
        cd $HOME/nwaku-compose

        echo -e "${TEAL}⏳ Остановка сервисов...${RESET}"
        docker-compose down

        echo -e "${TEAL}🧹 Очистка данных...${RESET}"
        sudo rm -r keystore rln_tree

        echo -e "${TEAL}📥 Обновление репозитория...${RESET}"
        git pull origin master

        echo -e "${TEAL}📝 Повторная регистрация...${RESET}"
        ./register_rln.sh

        echo -e "${TEAL}🚀 Перезапуск сервисов...${RESET}"
        docker-compose up -d

        echo -e "\n${LIME}✅ Обновление успешно завершено!${RESET}\n"
        ;;

    3)
        echo -e "\n${INDIGO}📊 Проверка логов...${RESET}"
        cd $HOME/nwaku-compose
        docker-compose logs -f
        ;;

    4)
        COMPOSE_FILE="$HOME/nwaku-compose/docker-compose.yml"
        
        if [[ ! -f "$COMPOSE_FILE" ]]; then
            echo -e "${CRIMSON}⚠️ Файл docker-compose.yml не найден${RESET}"
            exit 1
        fi

        # Функция замены порта
        replace_port() {
            local OLD_PORT="$1"
            local NEW_PORT="$2"
        
            if ! grep -qE "(:|[[:space:]])${OLD_PORT}:([0-9]+)" "$COMPOSE_FILE"; then
                echo -e "${CRIMSON}⚠️ Порт ${OLD_PORT} не найден в файле${RESET}"
                return 1
            fi
        
            sed -i -E "s/(:|[[:space:]])(${OLD_PORT}):([0-9]+)/\1${NEW_PORT}:\3/g" "$COMPOSE_FILE"
        
            if grep -qE "(:|[[:space:]])${NEW_PORT}:([0-9]+)" "$COMPOSE_FILE"; then
                echo -e "${LIME}✓ Порт ${OLD_PORT} заменен на ${NEW_PORT}${RESET}"
            else
                echo -e "${CRIMSON}⚠️ Ошибка замены порта${RESET}"
                return 1
            fi
        }

        echo -e "\n${LIME}🔧 Введите текущий внешний порт:${RESET}"
        read OLD_PORT
        
        if ! [[ "$OLD_PORT" =~ ^[0-9]+$ ]]; then
            echo -e "${CRIMSON}⚠️ Порт должен быть числом${RESET}"
            exit 1
        fi
        
        echo -e "${LIME}🔧 Введите новый внешний порт:${RESET}"
        read NEW_PORT
        
        if ! [[ "$NEW_PORT" =~ ^[0-9]+$ ]]; then
            echo -e "${CRIMSON}⚠️ Порт должен быть числом${RESET}"
            exit 1
        fi
        
        echo -e "${ORANGE}❓ Заменить порт ${OLD_PORT} на ${NEW_PORT}? (y/n):${RESET}"
        read CONFIRM
        if [[ "$CONFIRM" != "y" ]]; then
            echo -e "${TEAL}ℹ️ Операция отменена${RESET}"
            exit 0
        fi
        
        echo -e "${TEAL}⏳ Останавливаем сервисы...${RESET}"
        cd "$HOME/nwaku-compose" || exit
        docker-compose down
        
        echo -e "${TEAL}🔧 Заменяем порты...${RESET}"
        replace_port "$OLD_PORT" "$NEW_PORT"
        
        echo -e "${TEAL}🚀 Перезапускаем сервисы...${RESET}"
        docker-compose up -d
        
        echo -e "\n${LIME}✅ Порты успешно обновлены!${RESET}\n"
        ;;

    5)
        echo -e "\n${INDIGO}🗑️ Удаление ноды Waku...${RESET}"

        echo -e "${TEAL}⏳ Остановка сервисов...${RESET}"
        cd $HOME/nwaku-compose
        docker-compose down

        echo -e "${TEAL}🧹 Удаление файлов...${RESET}"
        cd $HOME
        rm -rf nwaku-compose

        echo -e "${LIME}✅ Нода успешно удалена!${RESET}\n"
        ;;

    *)
        echo -e "${ORANGE}⚠️ Ошибка: выберите число от 1 до 5${RESET}"
        ;;
esac
