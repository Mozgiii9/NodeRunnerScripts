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
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Меню
echo -e "${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${WHITE}║      🚀 INITVERSE NODE MANAGER        ║${NC}"
echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"

echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление ноды${NC}"
echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка логов${NC}"
echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}\n"

echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-4]:${NC} "
read -p "➜ " choice

case $choice in
    1)
        echo -e "\n${BOLD}${BLUE}⚡ Установка ноды InitVerse...${NC}\n"

        echo -e "${WHITE}[${CYAN}1/6${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление системы...${NC}"
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y wget

        echo -e "${WHITE}[${CYAN}2/6${WHITE}] ${GREEN}➜ ${WHITE}📂 Создание директории...${NC}"
        mkdir -p $HOME/initverse
        cd $HOME/initverse
        wget https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64
        chmod +x iniminer-linux-x64
        cd

        echo -e "${WHITE}[${CYAN}3/6${WHITE}] ${GREEN}➜ ${WHITE}🔑 Настройка данных...${NC}"
        echo -e "${YELLOW}💳 Введите адрес вашего EVM кошелька:${NC}"
        read WALLET
        echo -e "${YELLOW}📝 Введите имя вашей ноды-майнера:${NC}"
        read NODE_NAME
        
        echo -e "${WHITE}[${CYAN}4/6${WHITE}] ${GREEN}➜ ${WHITE}⚙️  Сохранение конфигурации...${NC}"
        echo "WALLET=$WALLET" > "$HOME/initverse/.env"
        echo "NODE_NAME=$NODE_NAME" >> "$HOME/initverse/.env"
        sleep 1

        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}📝 Создание сервиса...${NC}"
        sudo bash -c "cat <<EOT > /etc/systemd/system/initverse.service
[Unit]
Description=InitVerse Miner Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/initverse
EnvironmentFile=$HOME_DIR/initverse/.env
ExecStart=/bin/bash -c 'source $HOME_DIR/initverse/.env && $HOME_DIR/initverse/iniminer-linux-x64 --pool stratum+tcp://${WALLET}.${NODE_NAME}@pool-core-testnet.inichain.com:32672 --cpu-devices 1 --cpu-devices 2'
Restart=on-failure
Environment=WALLET=\$WALLET NODE_NAME=\$NODE_NAME

[Install]
WantedBy=multi-user.target
EOT"

        echo -e "${WHITE}[${CYAN}6/6${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск сервиса...${NC}"
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sleep 1
        sudo systemctl enable initverse
        sudo systemctl start initverse

        echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}📋 Команда для проверки логов:${NC}"
        echo "sudo journalctl -fu initverse.service"
        echo -e "${PURPLE}═════════════════════════════════════════════${NC}"
        echo -e "${GREEN}✨ Установка успешно завершена!${NC}"
        sleep 2
        sudo journalctl -fu initverse.service
        ;;

    2)
        echo -e "\n${BOLD}${BLUE}🔄 Обновление ноды InitVerse...${NC}"
        echo -e "${GREEN}✅ Установлена актуальная версия ноды!${NC}\n"
        ;;

    3)
        echo -e "\n${BOLD}${BLUE}📋 Проверка логов InitVerse...${NC}"
        sudo journalctl -fu initverse.service
        ;;

    4)
        echo -e "\n${BOLD}${RED}⚠️  Удаление ноды InitVerse...${NC}\n"

        echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервиса...${NC}"
        sudo systemctl stop initverse
        sudo systemctl disable initverse
        sudo rm /etc/systemd/system/initverse.service
        sudo systemctl daemon-reload
        sleep 1

        echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление файлов...${NC}"
        if [ -d "$HOME/initverse" ]; then
            rm -rf $HOME/initverse
            echo -e "${GREEN}✅ Директория InitVerse удалена${NC}"
        else
            echo -e "${RED}❌ Директория InitVerse не найдена${NC}"
        fi

        echo -e "\n${GREEN}✨ Нода InitVerse успешно удалена!${NC}\n"
        sleep 1
        ;;

    *)
        echo -e "\n${BOLD}${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 4.${NC}\n"
        ;;
esac
