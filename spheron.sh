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
echo -e "${TEAL}[4]${RESET} ➜ Удаление ноды\n"

echo -e "${LIME}Выберите опцию (1-4):${RESET} "
read choice

case $choice in
    1)
        echo -e "\n${INDIGO}▶️ Начинаем установку Spheron...${RESET}"

        # Обновление системы
        echo -e "${TEAL}📦 Обновление системных пакетов...${RESET}"
        sudo apt update -y && sudo apt upgrade -y
        
        # Установка Docker
        if ! command -v docker &> /dev/null; then
            echo -e "${TEAL}🐋 Установка Docker...${RESET}"
            sudo apt-get install -y ca-certificates curl gnupg
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
        
            echo "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \"$(. /etc/os-release && echo \"$VERSION_CODENAME\")\" stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
            sudo apt update -y
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            echo -e "${LIME}✓ Docker уже установлен${RESET}"
        fi
        
        # Установка Docker Compose
        if ! command -v docker-compose &> /dev/null; then
            echo -e "${TEAL}🔧 Установка Docker Compose...${RESET}"
            sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
        else
            echo -e "${LIME}✓ Docker Compose уже установлен${RESET}"
        fi
        
        # Проверка установки
        if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
            echo -e "${LIME}✅ Docker и Docker Compose успешно установлены${RESET}"
        else
            echo -e "${CRIMSON}⚠️ Ошибка при установке Docker или Docker Compose${RESET}"
        fi

        # Настройка домашней директории
        HOME_DIR=$(eval echo ~$USER)

        # Настройка прав и запуск
        echo -e "${TEAL}⚙️ Настройка прав доступа...${RESET}"
        chmod +x "$HOME_DIR/fizzup.sh"

        echo -e "${TEAL}🚀 Запуск установочного скрипта...${RESET}"
        "$HOME_DIR/fizzup.sh"

        # Завершение
        echo -e "\n${LIME}✅ Установка успешно завершена!${RESET}"
        echo -e "\n${WHITE}Для проверки логов используйте:${RESET}"
        echo -e "${TEAL}docker-compose -f ~/.spheron/fizz/docker-compose.yml logs -f${RESET}\n"
        sleep 2
        ;;
    2)
        echo -e "\n${LIME}✅ Установлена актуальная версия ноды${RESET}"
        ;;
    3)
        echo -e "\n${INDIGO}📊 Проверка логов...${RESET}"
        docker-compose -f ~/.spheron/fizz/docker-compose.yml logs -f
        ;;
    4)
        echo -e "\n${INDIGO}🗑️ Удаление ноды Spheron...${RESET}"

        echo -e "${TEAL}⏳ Остановка сервисов...${RESET}"
        docker-compose -f ~/.spheron/fizz/docker-compose.yml down
        sleep 3

        echo -e "${TEAL}🧹 Удаление файлов...${RESET}"
        rm -rf ~/.spheron
        rm -f "$HOME_DIR/fizzup.sh"

        echo -e "${LIME}✅ Нода успешно удалена!${RESET}\n"
        ;;
    *)
        echo -e "${ORANGE}⚠️ Ошибка: выберите число от 1 до 4${RESET}"
        ;;
esac
