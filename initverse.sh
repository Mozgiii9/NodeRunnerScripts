#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Отображаем логотип
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Меню
    echo -e "${YELLOW}🔍 Выберите действие:${NC}"
    echo -e "${CYAN}1) 🚀 Установка ноды${NC}"
    echo -e "${CYAN}2) 🔄 Обновление ноды${NC}"
    echo -e "${CYAN}3) 📋 Проверка логов${NC}"
    echo -e "${CYAN}4) 🗑️  Удаление ноды${NC}"

    echo -e "${YELLOW}⌨️  Введите номер:${NC} "
    read choice

    case $choice in
        1)
            echo -e "${BLUE}🚀 Начинаем установку ноды InitVerse...${NC}"

            # Обновление и установка зависимостей
            sudo apt update -y
            sudo apt upgrade -y
            sudo apt install -y wget

            # Создаем папку и скачиваем бинарник
            mkdir -p $HOME/initverse
            cd $HOME/initverse
            wget https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64
            chmod +x iniminer-linux-x64
            cd

            # Запрос данных у пользователя и запись в файл .env
            echo -e "${YELLOW}💳 Введите адрес вашего EVM кошелька:${NC}"
            read WALLET
            echo -e "${YELLOW}📝 Введите имя вашей ноды-майнера:${NC}"
            read NODE_NAME
            
            # Создаем файл .env и записываем данные
            echo "WALLET=$WALLET" > "$HOME/initverse/.env"
            echo "NODE_NAME=$NODE_NAME" >> "$HOME/initverse/.env"
            sleep 1

            # Определяем имя текущего пользователя и его домашнюю директорию
            USERNAME=$(whoami)
            HOME_DIR=$(eval echo ~$USERNAME)

            # Создание сервиса
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

            # Запуск сервиса
            sudo systemctl daemon-reload
            sudo systemctl restart systemd-journald
            sleep 1
            sudo systemctl enable initverse
            sudo systemctl start initverse

            # Заключительное сообщение
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}📋 Команда для проверки логов:${NC}"
            echo "sudo journalctl -fu initverse.service"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}✨ Установка успешно завершена!${NC}"
            sleep 2
            sudo journalctl -fu initverse.service
            ;;

        2)
            echo -e "${BLUE}🔄 Обновление ноды InitVerse...${NC}"
            echo -e "${GREEN}✅ Установлена актуальная версия ноды!${NC}"
            ;;

        3)
            echo -e "${BLUE}📋 Проверка логов InitVerse...${NC}"
            sudo journalctl -fu initverse.service
            ;;

        4)
            echo -e "${BLUE}🗑️ Удаление ноды InitVerse...${NC}"

            # Остановка и удаление сервиса
            sudo systemctl stop initverse
            sudo systemctl disable initverse
            sudo rm /etc/systemd/system/initverse.service
            sudo systemctl daemon-reload
            sleep 1

            # Удаление папки
            if [ -d "$HOME/initverse" ]; then
                rm -rf $HOME/initverse
                echo -e "${GREEN}✅ Директория InitVerse удалена.${NC}"
            else
                echo -e "${RED}❌ Директория InitVerse не найдена.${NC}"
            fi

            echo -e "${GREEN}✨ Нода InitVerse успешно удалена!${NC}"
            sleep 1
            ;;

        *)
            echo -e "${RED}❌ Неверный выбор. Пожалуйста, введите номер от 1 до 4.${NC}"
            ;;
    esac
