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
echo -e "${TEAL}[2]${RESET} ➜ Проверка логов"
echo -e "${TEAL}[3]${RESET} ➜ Получение ключа ноды"
echo -e "${TEAL}[4]${RESET} ➜ Удаление ноды\n"

echo -e "${LIME}Выберите опцию (1-4):${RESET} "
read choice

case $choice in
    1)
        echo -e "\n${INDIGO}▶️ Начинаем установку Network3...${RESET}"

        # Обновление системы
        echo -e "${TEAL}📦 Обновление системных пакетов...${RESET}"
        sudo apt update -y
        sudo apt upgrade -y
        sudo apt install -y screen net-tools

        # Загрузка и распаковка
        echo -e "${TEAL}📥 Загрузка бинарных файлов...${RESET}"
        wget https://network3.io/ubuntu-node-v2.1.0.tar
        if [ -f "ubuntu-node-v2.1.0.tar" ]; then
            tar -xvf ubuntu-node-v2.1.0.tar
            rm ubuntu-node-v2.1.0.tar
            echo -e "${LIME}✓ Временные файлы очищены${RESET}"
        else
            echo -e "${CRIMSON}⚠️ Ошибка: Файл ubuntu-node-v2.1.0.tar не найден${RESET}"
            exit 1
        fi

        # Настройка iptables
        echo -e "${TEAL}🔧 Настройка сетевых правил...${RESET}"
        if ! command -v iptables &> /dev/null; then
            echo -e "${TEAL}📦 Установка iptables...${RESET}"
            sudo apt install -y iptables
        else
            echo -e "${LIME}✓ iptables уже установлен${RESET}"
        fi

        # Настройка портов
        if ! sudo iptables -C INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null; then
            echo -e "${TEAL}🔓 Открытие порта 8080...${RESET}"
            sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
        else
            echo -e "${LIME}✓ Порт 8080 уже открыт${RESET}"
        fi

        # Сохранение правил
        if command -v netfilter-persistent &> /dev/null; then
            echo -e "${TEAL}💾 Сохранение сетевых правил...${RESET}"
            sudo netfilter-persistent save
            sudo netfilter-persistent reload
        else
            echo -e "${TEAL}📦 Установка netfilter-persistent...${RESET}"
            export DEBIAN_FRONTEND=noninteractive
            sudo apt install -y iptables-persistent
            sudo netfilter-persistent save
            sudo netfilter-persistent reload
        fi

        echo -e "${LIME}✓ Настройка сети завершена${RESET}"

        # Настройка сервиса
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        echo -e "${TEAL}⚙️ Настройка системного сервиса...${RESET}"
        sudo bash -c "cat <<EOT > /etc/systemd/system/manager.service
[Unit]
Description=Manager Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/ubuntu-node/
ExecStart=/bin/bash $HOME_DIR/ubuntu-node/manager.sh up
ExecStop=/bin/bash $HOME_DIR/ubuntu-node/manager.sh down
Restart=always
Type=forking

[Install]
WantedBy=multi-user.target
EOT"

        # Запуск сервиса
        echo -e "${TEAL}🚀 Запуск сервиса...${RESET}"
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable manager
        sudo systemctl start manager

        # Проверка статуса
        if sudo systemctl is-active --quiet manager; then
            echo -e "${LIME}✅ Сервис успешно запущен!${RESET}"
        else
            echo -e "${CRIMSON}⚠️ Ошибка запуска сервиса. Проверьте логи:${RESET}"
            echo "sudo journalctl -xe"
            exit 1
        fi

        # Завершение
        echo -e "\n${LIME}✅ Установка успешно завершена!${RESET}"
        echo -e "\n${WHITE}Для проверки логов используйте:${RESET}"
        echo -e "${TEAL}sudo journalctl -fu manager.service${RESET}\n"
        
        sleep 2
        sudo journalctl -fu manager.service
        ;;
    2)
        echo -e "\n${INDIGO}📊 Проверка логов...${RESET}"
        sudo journalctl -fu manager.service
        ;;
    3)
        echo -e "\n${INDIGO}🔑 Получение ключа ноды...${RESET}"
        sudo bash ubuntu-node/manager.sh key
        ;;
    4)
        echo -e "\n${INDIGO}🗑️ Удаление ноды Network3...${RESET}"

        echo -e "${TEAL}⏳ Остановка сервиса...${RESET}"
        sudo systemctl stop manager
        sudo systemctl disable manager
        sudo rm /etc/systemd/system/manager.service
        sudo systemctl daemon-reload
        sleep 1

        echo -e "${TEAL}🧹 Удаление файлов...${RESET}"
        if [ -d "$HOME_DIR/ubuntu-node" ]; then
            rm -rf $HOME_DIR/ubuntu-node
            echo -e "${LIME}✓ Директория ноды удалена${RESET}"
        else
            echo -e "${CRIMSON}⚠️ Директория ноды не найдена${RESET}"
        fi

        echo -e "${LIME}✅ Нода успешно удалена!${RESET}\n"
        ;;
    *)
        echo -e "${ORANGE}⚠️ Ошибка: выберите число от 1 до 4${RESET}"
        ;;
esac
