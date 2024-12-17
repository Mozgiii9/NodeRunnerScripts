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
echo -e "${TEAL}[3]${RESET} ➜ Просмотр логов"
echo -e "${TEAL}[4]${RESET} ➜ Удаление ноды\n"

echo -e "${LIME}Выберите опцию (1-4):${RESET} "
read choice

case $choice in
    1)
        echo -e "\n${INDIGO}▶️ Начинаем установку Glacier...${RESET}"

        # Обновление системы
        echo -e "${TEAL}📦 Обновление системных пакетов...${RESET}"
        sudo apt update -y
        sudo apt upgrade -y

        # Установка Docker
        if ! command -v docker &> /dev/null; then
            echo -e "${TEAL}🐋 Установка Docker...${RESET}"
            sudo apt install docker.io -y
        else
            echo -e "${LIME}✓ Docker уже установлен${RESET}"
        fi

        # Ввод ключа
        echo -e "\n${LIME}🔑 Введите приватный ключ кошелька:${RESET}"
        read -r YOUR_PRIVATE_KEY

        # Запуск контейнера
        echo -e "${TEAL}🚀 Запуск контейнера...${RESET}"
        docker run -d -e PRIVATE_KEY=$YOUR_PRIVATE_KEY --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.4

        # Завершение
        echo -e "\n${LIME}✅ Установка успешно завершена!${RESET}"
        echo -e "\n${WHITE}Для просмотра логов используйте:${RESET}"
        echo -e "${TEAL}docker logs -f glacier-verifier${RESET}\n"
        
        sleep 2
        docker logs -f glacier-verifier
        ;;

    2)
        echo -e "\n${INDIGO}🔄 Обновление ноды Glacier...${RESET}"

        # Ввод ключа
        echo -e "${LIME}🔑 Введите приватный ключ кошелька:${RESET}"
        read -r YOUR_PRIVATE_KEY

        # Обновление контейнера
        echo -e "${TEAL}⏳ Остановка текущего контейнера...${RESET}"
        docker stop glacier-verifier
        docker rm glacier-verifier

        echo -e "${TEAL}🧹 Удаление старых образов...${RESET}"
        docker images --filter=reference='glaciernetwork/glacier-verifier:*' -q | xargs -r docker rmi

        echo -e "${TEAL}🚀 Запуск обновленного контейнера...${RESET}"
        docker run -d -e PRIVATE_KEY=$YOUR_PRIVATE_KEY --name glacier-verifier docker.io/glaciernetwork/glacier-verifier:v0.0.4

        # Завершение
        echo -e "\n${LIME}✅ Обновление успешно завершено!${RESET}"
        echo -e "\n${WHITE}Для просмотра логов используйте:${RESET}"
        echo -e "${TEAL}docker logs -f glacier-verifier${RESET}\n"
        
        sleep 2
        docker logs -f glacier-verifier
        ;;

    3)
        echo -e "\n${INDIGO}📊 Просмотр логов...${RESET}"
        docker logs -f glacier-verifier
        ;;

    4)
        echo -e "\n${INDIGO}🗑️ Удаление ноды Glacier...${RESET}"

        echo -e "${TEAL}⏳ Остановка и удаление контейнера...${RESET}"
        docker stop glacier-verifier
        docker rm glacier-verifier

        echo -e "${TEAL}🧹 Удаление образов...${RESET}"
        docker images --filter=reference='glaciernetwork/glacier-verifier:*' -q | xargs -r docker rmi

        echo -e "${LIME}✅ Нода успешно удалена!${RESET}\n"
        ;;

    *)
        echo -e "${ORANGE}⚠️ Ошибка: выберите число от 1 до 4${RESET}"
        ;;
esac
