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
echo -e "${TEAL}[2]${RESET} ➜ Запуск ноды"
echo -e "${TEAL}[3]${RESET} ➜ Обновление ноды"
echo -e "${TEAL}[4]${RESET} ➜ Изменение порта"
echo -e "${TEAL}[5]${RESET} ➜ Проверка логов"
echo -e "${TEAL}[6]${RESET} ➜ Удаление ноды\n"

echo -e "${LIME}Выберите опцию (1-6):${RESET} "
read choice

case $choice in
    1)
        echo -e "\n${INDIGO}▶️ Начинаем установку Dria...${RESET}"

        # Обновление и установка зависимостей
        echo -e "${TEAL}📦 Обновление системных пакетов...${RESET}"
        sudo apt update && sudo apt-get upgrade -y
        
        echo -e "${TEAL}📦 Установка зависимостей...${RESET}"
        sudo apt install git make jq build-essential gcc unzip wget lz4 aria2 -y

        # Проверка архитектуры
        ARCH=$(uname -m)
        echo -e "${TEAL}🔍 Определение архитектуры системы: ${LIME}$ARCH${RESET}"
        
        if [[ "$ARCH" == "aarch64" ]]; then
            curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-arm64.zip
        elif [[ "$ARCH" == "x86_64" ]]; then
            curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip
        else
            echo -e "${CRIMSON}❌ Не поддерживаемая архитектура системы: $ARCH${RESET}"
            exit 1
        fi

        echo -e "${TEAL}📂 Распаковка файлов...${RESET}"
        unzip dkn-compute-node.zip
        cd dkn-compute-node

        echo -e "${TEAL}🚀 Запуск приложения...${RESET}"
        ./dkn-compute-launcher

        echo -e "${LIME}✅ Установка завершена!${RESET}"
        ;;

    2)
        echo -e "\n${INDIGO}🚀 Запуск ноды Dria...${RESET}"

        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        echo -e "${TEAL}⚙️ Настройка сервиса...${RESET}"
        sudo bash -c "cat <<EOT > /etc/systemd/system/dria.service
[Unit]
Description=Dria Compute Node Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/dkn-compute-node/.env
ExecStart=$HOME_DIR/dkn-compute-node/dkn-compute-launcher
WorkingDirectory=$HOME_DIR/dkn-compute-node/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT"

        echo -e "${TEAL}🔄 Перезагрузка демона...${RESET}"
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sleep 1

        echo -e "${TEAL}▶️ Запуск сервиса...${RESET}"
        sudo systemctl enable dria
        sudo systemctl start dria

        echo -e "\n${LIME}✅ Нода успешно запущена!${RESET}"
        echo -e "${WHITE}Для проверки логов используйте:${RESET}"
        echo -e "${TEAL}sudo journalctl -u dria -f --no-hostname -o cat${RESET}\n"

        sleep 2
        sudo journalctl -u dria -f --no-hostname -o cat
        ;;

    3)
        echo -e "\n${LIME}✅ Установлена актуальная версия ноды${RESET}"
        ;;

    4)
        echo -e "\n${INDIGO}⚙️ Изменение порта...${RESET}"

        echo -e "${TEAL}⏳ Остановка сервиса...${RESET}"
        sudo systemctl stop dria

        echo -e "${YELLOW}Введите новый порт для Dria:${RESET}"
        read NEW_PORT

        ENV_FILE="$HOME/dkn-compute-node/.env"
        echo -e "${TEAL}📝 Обновление конфигурации...${RESET}"
        sed -i "s|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/[0-9]*|DKN_P2P_LISTEN_ADDR=/ip4/0.0.0.0/tcp/$NEW_PORT|" "$ENV_FILE"

        echo -e "${TEAL}🔄 Перезапуск сервиса...${RESET}"
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl start dria

        echo -e "${LIME}✅ Порт успешно изменен!${RESET}"
        echo -e "${WHITE}Для проверки логов используйте:${RESET}"
        echo -e "${TEAL}sudo journalctl -u dria -f --no-hostname -o cat${RESET}\n"

        sleep 2
        sudo journalctl -u dria -f --no-hostname -o cat
        ;;

    5)
        echo -e "\n${INDIGO}📊 Проверка логов...${RESET}"
        sudo journalctl -u dria -f --no-hostname -o cat
        ;;

    6)
        echo -e "\n${INDIGO}🗑️ Удаление ноды Dria...${RESET}"

        echo -e "${TEAL}⏳ Остановка сервиса...${RESET}"
        sudo systemctl stop dria
        sudo systemctl disable dria
        sudo rm /etc/systemd/system/dria.service
        sudo systemctl daemon-reload
        sleep 2

        echo -e "${TEAL}🧹 Удаление файлов...${RESET}"
        rm -rf $HOME/dkn-compute-node

        echo -e "${LIME}✅ Нода успешно удалена!${RESET}\n"
        ;;

    *)
        echo -e "${ORANGE}⚠️ Ошибка: выберите число от 1 до 6${RESET}"
        ;;
esac
