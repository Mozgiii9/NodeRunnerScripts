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

# Очистка экрана
clear

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

# Отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║         🚀 GAIA NODE MANAGER v1.0       ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🤖 Запуск бота${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}ℹ️  Информация по ноде${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}⛔ Удаление бота${NC}\n"
}

# Отображение меню
print_menu

# Запрос выбора пользователя
echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-6]:${NC} "
read -p "➜ " choice

case $choice in
    1)
        echo -e "\n${BOLD}${BLUE}⚡ Установка ноды Gaia...${NC}\n"

        echo -e "${WHITE}[${CYAN}1/6${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление системы...${NC}"
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y python3-pip python3-dev python3-venv curl git
        sudo apt install -y build-essential
        pip3 install aiohttp

        echo -e "${WHITE}[${CYAN}2/6${WHITE}] ${GREEN}➜ ${WHITE}🔓 Освобождение порта 8080...${NC}"
        sudo fuser -k 8080/tcp
        sleep 3

        echo -e "${WHITE}[${CYAN}3/6${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка Gaianet...${NC}"
        curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash
        sleep 2
        
        echo -e "${WHITE}[${CYAN}4/6${WHITE}] ${GREEN}➜ ${WHITE}⚙️  Настройка переменных окружения...${NC}"
        echo "export PATH=\$PATH:$HOME/gaianet/bin" >> $HOME/.bashrc
        sleep 5
        
        source $HOME/.bashrc
        sleep 10

        if ! command -v gaianet &> /dev/null; then
            echo -e "${RED}❌ Ошибка: gaianet не найден! Путь $HOME/gaianet/bin не добавлен в PATH.${NC}"
            exit 1
        fi

        echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}🔧 Инициализация ноды...${NC}"
        gaianet init --config https://raw.githubusercontent.com/GaiaNet-AI/node-configs/main/qwen2-0.5b-instruct/config.json  

        echo -e "${WHITE}[${CYAN}6/6${WHITE}] ${GREEN}➜ ${WHITE}▶️  Запуск ноды...${NC}"
        gaianet start

        echo -e "\n${BOLD}${GREEN}✅ Установка успешно завершена!${NC}\n"
        sleep 2
        ;;

    2)
        echo -e "\n${BOLD}${BLUE}⚡ Запуск бота Gaia...${NC}\n"

        echo -e "${WHITE}[${CYAN}1/4${WHITE}] ${GREEN}➜ ${WHITE}📝 Создание конфигурации...${NC}"
        mkdir -p ~/gaia-bot
        cd ~/gaia-bot
        
        # Добавление фраз в phrases.txt
        echo -e "\"Explain Einstein's theory of general relativity with mathematical proofs and real-world applications.\"" > phrases.txt
        echo -e "\"Describe quantum mechanics and its implications for modern technology.\"" >> phrases.txt
        echo -e "\"How does machine learning differ from traditional programming? Provide examples.\"" >> phrases.txt
        echo -e "\"What are the key challenges in building a decentralized autonomous organization (DAO)?\"" >> phrases.txt
        echo -e "\"Explain the process of photosynthesis in detail, including the chemical reactions involved.\"" >> phrases.txt
        echo -e "\"How do blockchain consensus mechanisms like Proof-of-Work and Proof-of-Stake differ?\"" >> phrases.txt
        echo -e "\"What are the primary components of a neural network, and how do they interact?\"" >> phrases.txt
        echo -e "\"Describe the history and evolution of the Internet, including key milestones.\"" >> phrases.txt
        echo -e "\"How does data encryption work, and what are the most secure algorithms available?\"" >> phrases.txt
        echo -e "\"What are the applications of Fourier transforms in signal processing and image compression?\"" >> phrases.txt
        echo -e "\"Explain the concept of entropy in thermodynamics with examples.\"" >> phrases.txt
        echo -e "\"What are the ethical implications of artificial intelligence in healthcare?\"" >> phrases.txt
        echo -e "\"How do you implement a distributed system for real-time data processing?\"" >> phrases.txt
        echo -e "\"Describe the differences between TCP and UDP protocols.\"" >> phrases.txt
        echo -e "\"What are the key differences between SQL and NoSQL databases?\"" >> phrases.txt
        echo -e "\"How does genetic engineering work, and what are its implications for society?\"" >> phrases.txt
        echo -e "\"Explain the difference between classical and quantum computing with examples.\"" >> phrases.txt
        echo -e "\"What are the challenges in creating an AI that can pass the Turing test?\"" >> phrases.txt
        echo -e "\"How does GPS technology work, and what are its limitations?\"" >> phrases.txt
        echo -e "\"What are the main challenges in developing fusion power plants?\"" >> phrases.txt
        echo -e "\"Describe the history of the Roman Empire in detail, including its rise and fall.\"" >> phrases.txt
        echo -e "\"How did the industrial revolution impact global society and economies?\"" >> phrases.txt
        echo -e "\"What are the key philosophical differences between existentialism and nihilism?\"" >> phrases.txt
        echo -e "\"Explain the causes and consequences of World War II in detail.\"" >> phrases.txt
        echo -e "\"What was the significance of the Renaissance period in European history?\"" >> phrases.txt
        echo -e "\"Describe the history of ancient Egypt, including its cultural and political achievements.\"" >> phrases.txt
        echo -e "\"What are the main ethical principles in utilitarianism and deontology?\"" >> phrases.txt
        echo -e "\"Explain the philosophy of Immanuel Kant and its influence on modern thought.\"" >> phrases.txt
        echo -e "\"How did the Cold War shape the political landscape of the 20th century?\"" >> phrases.txt
        echo -e "\"What are the origins and evolution of human rights as a concept?\"" >> phrases.txt
        echo -e "\"Write a detailed tutorial on how to create a blockchain from scratch in Python.\"" >> phrases.txt
        echo -e "\"How does garbage collection work in modern programming languages?\"" >> phrases.txt
        echo -e "\"Explain the differences between functional and object-oriented programming.\"" >> phrases.txt
        echo -e "\"What are the key principles of RESTful API design?\"" >> phrases.txt
        echo -e "\"How do you implement a graph traversal algorithm in Python?\"" >> phrases.txt
        echo -e "\"What are the best practices for securing a web application?\"" >> phrases.txt
        echo -e "\"How do neural networks use backpropagation for training?\"" >> phrases.txt
        echo -e "\"Describe the key differences between Docker and Kubernetes.\"" >> phrases.txt
        echo -e "\"What is the role of cryptography in securing blockchain networks?\"" >> phrases.txt
        echo -e "\"How do you design a scalable microservices architecture?\"" >> phrases.txt
        
        # Добавление ролей в roles.txt
        echo -e "system\nuser\nassistant\ntool" > roles.txt

        echo -e "${WHITE}[${CYAN}2/4${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка скрипта бота...${NC}"
        curl -L https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/main/gaia_bot.py -o gaia_bot.py

        echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}⚙️  Настройка бота...${NC}"
        echo -e "${YELLOW}🔑 Введите адрес вашей ноды:${NC}"
        read -p "➜ " NODE_ID
        
        sed -i "s|\$NODE_ID|$NODE_ID|g" gaia_bot.py

        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        echo -e "${WHITE}[${CYAN}4/4${WHITE}] ${GREEN}➜ ${WHITE}🚀 Настройка и запуск сервиса...${NC}"
        # Сервис для запуска бота
        echo -e "[Unit]
Description=Gaia Bot
After=network.target

[Service]
ExecStart=/usr/bin/python3 $HOME_DIR/gaia-bot/gaia_bot.py
Restart=always
User=$USERNAME
Group=$USERNAME
WorkingDirectory=$HOME_DIR/gaia-bot

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/gaia-bot.service

        # Запуск бота
        sudo systemctl daemon-reload
        sleep 1
        sudo systemctl enable gaia-bot.service
        sudo systemctl start gaia-bot.service

        echo -e "\n${BOLD}${GREEN}✅ Бот успешно запущен!${NC}"
        echo -e "\n${WHITE}📋 Для просмотра логов используйте команду:${NC}"
        echo -e "${CYAN}sudo journalctl -u gaia-bot -f${NC}\n"
        
        sudo journalctl -u gaia-bot -f
        ;;

    3)
        echo -e "\n${BOLD}${GREEN}✅ У вас установлена актуальная версия ноды Gaia.${NC}\n"
        ;;

    4)
        echo -e "\n${BOLD}${BLUE}ℹ️ Информация о ноде:${NC}\n"
        gaianet info
        ;;

    5)
        echo -e "\n${BOLD}${RED}⚠️ Удаление ноды Gaia...${NC}\n"
        gaianet stop
        rm -rf ~/gaianet
        echo -e "\n${BOLD}${GREEN}✅ Нода успешно удалена${NC}\n"
        sleep 2
        ;;

    6)
        echo -e "\n${BOLD}${RED}⚠️ Удаление бота Gaia...${NC}\n"
        sudo systemctl stop gaia-bot.service
        sudo systemctl disable gaia-bot.service
        sudo rm /etc/systemd/system/gaia-bot.service
        sudo systemctl daemon-reload
        sleep 1
        rm -rf ~/gaia-bot
        echo -e "\n${BOLD}${GREEN}✅ Бот успешно удален${NC}\n"
        sleep 2
        ;;

    *)
        echo -e "\n${BOLD}${RED}❌ Ошибка: Неверный выбор!${NC}\n"
        ;;
esac
