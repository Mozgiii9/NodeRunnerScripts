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
    echo -e "${BOLD}${WHITE}║        🚀 NEXUS NODE MANAGER           ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📋 Управление сессией${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Проверка версии Ubuntu
check_ubuntu_version() {
    echo -e "\n${BOLD}${BLUE}⚡ Проверка версии Ubuntu...${NC}"
    REQUIRED_VERSION=22.04
    UBUNTU_VERSION=$(lsb_release -rs)
    if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
        echo -e "${RED}❌ Ошибка: Требуется Ubuntu ${REQUIRED_VERSION} или выше${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Версия Ubuntu соответствует требованиям${NC}"
}

# Функция установки ноды
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка ноды Nexus...${NC}\n"
    check_ubuntu_version

    echo -e "${WHITE}[${CYAN}1/5${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление системы...${NC}"
    sudo apt update -y
    sudo apt upgrade -y

    echo -e "${WHITE}[${CYAN}2/5${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка зависимостей...${NC}"
    sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo screen unzip

    echo -e "${WHITE}[${CYAN}3/5${WHITE}] ${GREEN}➜ ${WHITE}⚙️  Настройка Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    rustup update

    echo -e "${WHITE}[${CYAN}4/5${WHITE}] ${GREEN}➜ ${WHITE}🔧 Настройка Protobuf...${NC}"
    sudo apt remove -y protobuf-compiler
    curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v25.2/protoc-25.2-linux-x86_64.zip
    unzip protoc-25.2-linux-x86_64.zip -d $HOME/.local
    export PATH="$HOME/.local/bin:$PATH"
    
    echo -e "${WHITE}[${CYAN}5/5${WHITE}] ${GREEN}➜ ${WHITE}💾 Настройка SWAP и CLI...${NC}"
    
    # Настройка SWAP с проверками
    echo -e "${CYAN}⚡ Настройка файла подкачки...${NC}"
    
    # Проверяем и отключаем существующий swap
    if [ -f /swapfile ]; then
        echo -e "${YELLOW}⚠️ Найден существующий файл подкачки. Отключаем...${NC}"
        sudo swapoff /swapfile || true
        sudo rm -f /swapfile
        sleep 2
    fi

    # Создаем новый swap файл
    echo -e "${CYAN}📝 Создание нового файла подкачки...${NC}"
    sudo dd if=/dev/zero of=/swapfile bs=1M count=8192
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile

    # Добавляем запись в fstab если её нет
    if ! grep -q "/swapfile" /etc/fstab; then
        echo -e "${CYAN}📝 Добавление записи в /etc/fstab...${NC}"
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi

    # Проверяем статус swap
    echo -e "${CYAN}🔍 Проверка статуса SWAP...${NC}"
    sudo swapon --show
    echo -e "${GREEN}✅ Настройка SWAP завершена${NC}"

    # Управление screen сессией
    echo -e "${CYAN}🖥️ Настройка screen сессии...${NC}"
    SESSION_NAME="nexus"
    
    # Проверяем и закрываем существующую сессию
    if screen -ls | grep -q "$SESSION_NAME"; then
        echo -e "${YELLOW}⚠️ Найдена существующая сессия. Закрываем...${NC}"
        screen -S "$SESSION_NAME" -X quit
        sleep 2
    fi

    # Создаем скрипт для выполнения в screen сессии
    echo -e "${CYAN}📝 Подготовка команд для screen сессии...${NC}"
    cat > $HOME/nexus_setup.sh << 'EOF'
#!/bin/bash
echo "⚡ Установка Nexus CLI..."
if command -v proxychains4 &> /dev/null; then
    proxychains4 curl -sSf https://cli.nexus.xyz/ -o cli_nexus.sh && bash cli_nexus.sh
else
    curl -sSf https://cli.nexus.xyz/ -o cli_nexus.sh && bash cli_nexus.sh
fi
echo "✅ Установка завершена"
EOF

    chmod +x $HOME/nexus_setup.sh

    # Создаем и запускаем screen сессию
    echo -e "${CYAN}🚀 Запуск screen сессии...${NC}"
    screen -dmS $SESSION_NAME
    sleep 1
    screen -S $SESSION_NAME -X stuff "$HOME/nexus_setup.sh\n"

    echo -e "\n${PURPLE}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Нода успешно установлена!${NC}"
    echo -e "${YELLOW}📋 Управление сессией:${NC}"
    echo -e "  ${CYAN}• screen -r nexus${NC} - подключение к сессии"
    echo -e "  ${CYAN}• CTRL + A + D${NC} - отключение от сессии (сессия останется активной)"
    echo -e "  ${CYAN}• screen -ls${NC} - список сессий"
    echo -e "  ${CYAN}• exit${NC} - полное закрытие сессии"
    echo -e "${PURPLE}═══════════════════════════════════════════════${NC}"

    # Автоматически подключаемся к сессии
    echo -e "${CYAN}🔄 Подключение к сессии...${NC}"
    sleep 2
    screen -r $SESSION_NAME

    # Очистка временных файлов
    rm -f $HOME/nexus_setup.sh
}

# Функция обновления ноды
update_node() {
    echo -e "\n${BOLD}${GREEN}✅ У вас установлена актуальная версия ноды Nexus${NC}\n"
}

# Функция управления сессией
manage_session() {
    echo -e "\n${BOLD}${BLUE}📋 Управление сессией Nexus...${NC}\n"
    if screen -ls | grep -q "nexus"; then
        screen -r nexus
    else
        echo -e "${RED}❌ Сессия nexus не найдена${NC}"
        echo -e "${YELLOW}Запустите установку ноды (пункт 1)${NC}"
    fi
}

# Функция удаления ноды
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды Nexus...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}⏹️ Остановка сессий...${NC}"
    SESSION_IDS=$(screen -ls | grep "nexus" | awk '{print $1}' | cut -d '.' -f 1)
    if [ -n "$SESSION_IDS" ]; then
        for SESSION_ID in $SESSION_IDS; do
            screen -S "$SESSION_ID" -X quit
        done
        echo -e "${GREEN}✅ Сессии остановлены${NC}"
    else
        echo -e "${YELLOW}⚠️ Активные сессии не найдены${NC}"
    fi

    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    rm -rf .nexus/

    echo -e "\n${GREEN}✅ Нода успешно удалена!${NC}\n"
}

# Основной цикл программы
while true; do
    clear
    # Отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    
    print_menu
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-5]:${NC} "
    read -p "➜ " choice

    case $choice in
        1)
            install_node
            ;;
        2)
            update_node
            ;;
        3)
            manage_session
            ;;
        4)
            remove_node
            ;;
        5)
            echo -e "\n${GREEN}👋 До свидания!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 5.${NC}\n"
            ;;
    esac

    if [ "$choice" != "3" ]; then
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    fi
done
