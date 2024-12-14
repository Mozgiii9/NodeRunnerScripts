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

# Проверка наличия bc
echo -e "${INDIGO}🔍 Проверка версии операционной системы...${RESET}"
if ! command -v bc &> /dev/null; then
    sudo apt update
    sudo apt install bc -y
fi
sleep 1

# Проверка версии Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    echo -e "${CRIMSON}⚠️ Ошибка: требуется Ubuntu версии 22.04 или выше${RESET}"
    exit 1
fi

# Главное меню
echo -e "\n${WHITE}╔═══════════════════════════════╗${RESET}"
echo -e "${WHITE}║        МЕНЮ УПРАВЛЕНИЯ         ║${RESET}"
echo -e "${WHITE}╚═══════════════════════════════╝${RESET}\n"

echo -e "${TEAL}[1]${RESET} ➜ Установка ноды"
echo -e "${TEAL}[2]${RESET} ➜ Обновление ноды"
echo -e "${TEAL}[3]${RESET} ➜ Проверка работы ноды"
echo -e "${TEAL}[4]${RESET} ➜ Проверка поинтов"
echo -e "${TEAL}[5]${RESET} ➜ Бекап ноды"
echo -e "${TEAL}[6]${RESET} ➜ Регистрация ноды"
echo -e "${TEAL}[7]${RESET} ➜ Удаление ноды\n"

echo -e "${LIME}Выберите опцию (1-7):${RESET} "
read choice

case $choice in
    1)
        echo -e "\n${INDIGO}▶️ Начинаем установку Sonaric...${RESET}"

        # Обновление и установка зависимостей
        echo -e "${TEAL}📦 Установка необходимых пакетов...${RESET}"
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install git jq build-essential gcc unzip wget lz4 -y

        # Установка Node.js
        echo -e "${TEAL}⚙️ Установка Node.js...${RESET}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install nodejs -y

        # Установка Sonaric
        echo -e "${TEAL}🚀 Установка Sonaric...${RESET}"
        sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"

        # Завершение
        echo -e "\n${LIME}✅ Установка успешно завершена!${RESET}"
        echo -e "\n${WHITE}Для проверки состояния используйте:${RESET}"
        echo -e "${TEAL}sonaric node-info${RESET}\n"
        
        sleep 2
        sonaric node-info
        ;;
    2)
        echo -e "\n${INDIGO}🔄 Обновление ноды Sonaric...${RESET}"
        sh -c "$(curl -fsSL http://get.sonaric.xyz/scripts/install.sh)"
        
        echo -e "\n${LIME}✅ Обновление завершено!${RESET}"
        sleep 2
        sonaric node-info
        ;;
    3)
        echo -e "\n${INDIGO}📊 Проверка состояния ноды...${RESET}"
        sonaric node-info
        ;;
    4)
        echo -e "\n${INDIGO}🎯 Проверка поинтов...${RESET}"
        sonaric points
        ;;
    5)
        echo -e "\n${LIME}Введите имя ноды:${RESET}"
        read NODE_NAME

        sonaric identity-export -o "$NODE_NAME.identity"

        echo -e "${LIME}✅ Бекап создан: ${NODE_NAME}.identity${RESET}"
        cd && cat ${NODE_NAME}.identity
        ;;
    6)
        echo -e "\n${LIME}Введите код из Discord:${RESET}"
        read DISCORD_CODE

        if [ -z "$DISCORD_CODE" ]; then
            echo -e "${ORANGE}⚠️ Код не введен. Попробуйте снова.${RESET}"
            exit 1
        fi
        
        echo -e "${TEAL}🔗 Регистрация ноды...${RESET}"
        sonaric node-register "$DISCORD_CODE"
        ;;
    7)
        echo -e "\n${INDIGO}🗑️ Удаление ноды Sonaric...${RESET}"
        sudo systemctl stop sonaricd
        sudo rm -rf $HOME/.sonaric
        echo -e "${LIME}✅ Нода успешно удалена!${RESET}\n"
        ;;
    *)
        echo -e "${ORANGE}⚠️ Ошибка: выберите число от 1 до 7${RESET}"
        ;;
esac
