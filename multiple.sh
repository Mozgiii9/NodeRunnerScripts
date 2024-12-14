#!/bin/bash

# Определение цветов для текста
ORANGE='\033[0;33m'
TEAL='\033[0;36m'
LIME='\033[1;32m'
INDIGO='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Проверка и установка curl
if ! command -v curl &> /dev/null; then
    echo -e "${ORANGE}Установка curl...${RESET}"
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Загрузка и отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Главное меню
echo -e "\n${WHITE}╔════════════════════════╗${RESET}"
echo -e "${WHITE}║      МЕНЮ УПРАВЛЕНИЯ    ║${RESET}"
echo -e "${WHITE}╚════════════════════════╝${RESET}\n"

echo -e "${TEAL}[1]${RESET} ➜ Установка ноды"
echo -e "${TEAL}[2]${RESET} ➜ Проверка статуса"
echo -e "${TEAL}[3]${RESET} ➜ Удаление ноды\n"

echo -e "${LIME}Выберите опцию (1-3):${RESET} "
read choice

case $choice in
    1)
        echo -e "\n${INDIGO}▶ Начинаем установку ноды...${RESET}"

        # Обновление системы
        echo -e "${TEAL}📦 Обновление системных пакетов...${RESET}"
        sudo apt update && sudo apt upgrade -y

        # Определение архитектуры
        echo -e "${TEAL}🔍 Определение архитектуры системы...${RESET}"
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
            CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
        elif [[ "$ARCH" == "aarch64" ]]; then
            CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
        else
            echo -e "${ORANGE}⚠ Неподдерживаемая архитектура: $ARCH${RESET}"
            exit 1
        fi

        # Загрузка клиента
        echo -e "${TEAL}📥 Загрузка клиента...${RESET}"
        wget $CLIENT_URL -O multipleforlinux.tar

        # Распаковка
        echo -e "${TEAL}📂 Распаковка файлов...${RESET}"
        tar -xvf multipleforlinux.tar
        cd multipleforlinux

        # Настройка прав
        echo -e "${TEAL}🔧 Настройка прав доступа...${RESET}"
        chmod +x ./multiple-cli
        chmod +x ./multiple-node

        # Настройка PATH
        echo -e "${TEAL}⚙️ Настройка переменных окружения...${RESET}"
        echo "PATH=\$PATH:$(pwd)" >> ~/.bash_profile
        source ~/.bash_profile

        # Запуск ноды
        echo -e "${TEAL}🚀 Запуск ноды...${RESET}"
        nohup ./multiple-node > output.log 2>&1 &

        # Ввод данных
        echo -e "${LIME}Введите Account ID:${RESET}"
        read IDENTIFIER
        echo -e "${LIME}Введите PIN:${RESET}"
        read PIN

        # Привязка аккаунта
        echo -e "${TEAL}🔗 Привязка аккаунта...${RESET}"
        ./multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

        # Завершение
        echo -e "\n${LIME}✅ Установка успешно завершена!${RESET}"
        echo -e "\n${WHITE}Для проверки статуса используйте:${RESET}"
        echo -e "${TEAL}cd ~/multipleforlinux && ./multiple-cli status${RESET}\n"
        
        sleep 2
        cd ~/multipleforlinux && ./multiple-cli status
        ;;

    2)
        echo -e "\n${INDIGO}🔍 Проверка статуса ноды...${RESET}"
        cd ~/multipleforlinux && ./multiple-cli status
        ;;

    3)
        echo -e "\n${INDIGO}🗑 Удаление ноды...${RESET}"
        pkill -f multiple-node
        cd ~
        rm -rf multipleforlinux
        echo -e "${LIME}✅ Нода успешно удалена!${RESET}\n"
        ;;
        
    *)
        echo -e "${ORANGE}⚠ Ошибка: выберите число от 1 до 3${RESET}"
        ;;
esac
