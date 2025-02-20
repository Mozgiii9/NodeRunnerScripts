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
    echo -e "${BOLD}${WHITE}║     🚀 NEXUS NODE PROXY MANAGER        ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📋 Управление сессией${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Настройка прокси${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🌐 Проверка прокси${NC}" 
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
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

# Функция установки proxychains
install_proxychains() {
    if ! command -v proxychains4 &> /dev/null; then
        echo -e "${WHITE}[${CYAN}*${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка proxychains...${NC}"
        sudo apt update
        sudo apt install -y proxychains4
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Ошибка установки proxychains${NC}"
            return 1
        fi
        echo -e "${GREEN}✅ Proxychains установлен успешно${NC}"
    else
        echo -e "${GREEN}✅ Proxychains уже установлен${NC}"
    fi
    
    return 0
}

# Настройка прокси
configure_proxy() {
    echo -e "\n${BOLD}${BLUE}⚡ Настройка прокси для Nexus ноды...${NC}\n"
    
    # Установка proxychains, если не установлен
    install_proxychains
    
    # Запрос параметров прокси
    echo -e "${CYAN}Введите параметры прокси-сервера:${NC}"
    read -p "Тип прокси (http, socks4, socks5): " proxy_type
    read -p "IP адрес прокси: " proxy_ip
    read -p "Порт прокси: " proxy_port
    read -p "Имя пользователя (оставьте пустым, если не требуется): " proxy_user
    read -p "Пароль (оставьте пустым, если не требуется): " proxy_pass
    
    # Сохранение резервной копии конфига
    sudo cp /etc/proxychains4.conf /etc/proxychains4.conf.backup
    
    # Создание новой конфигурации
    echo -e "${WHITE}[${CYAN}*${WHITE}] ${GREEN}➜ ${WHITE}🔧 Настройка конфигурации proxychains...${NC}"
    
    sudo bash -c "cat > /etc/proxychains4.conf" << EOF
# proxychains.conf VER 4.x
#
# Проксификация для ноды Nexus

# Использовать строгий режим цепочки
strict_chain

# Проксификация DNS запросов
proxy_dns

# Таймауты TCP
tcp_read_time_out 15000
tcp_connect_time_out 8000

# Локальные подсети не проксируются
localnet 127.0.0.0/255.0.0.0
localnet 10.0.0.0/255.0.0.0
localnet 172.16.0.0/255.240.0.0
localnet 192.168.0.0/255.255.0.0

# Список прокси
[ProxyList]
EOF

    # Добавление прокси с учетом авторизации
    if [ -n "$proxy_user" ] && [ -n "$proxy_pass" ]; then
        sudo bash -c "echo '$proxy_type $proxy_ip $proxy_port $proxy_user $proxy_pass' >> /etc/proxychains4.conf"
    else
        sudo bash -c "echo '$proxy_type $proxy_ip $proxy_port' >> /etc/proxychains4.conf"
    fi
    
    echo -e "${GREEN}✅ Настройка прокси завершена${NC}"
    
    # Создание скрипта для запуска через прокси
    echo -e "${WHITE}[${CYAN}*${WHITE}] ${GREEN}➜ ${WHITE}📝 Создание скрипта запуска через прокси...${NC}"
    
    cat > $HOME/start-nexus-proxy.sh << EOF
#!/bin/bash
# Скрипт запуска ноды Nexus через proxychains
cd \$HOME
source \$HOME/.cargo/env
proxychains4 cargo run --release
EOF
    
    chmod +x $HOME/start-nexus-proxy.sh
    
    echo -e "${GREEN}✅ Скрипт запуска через прокси создан: ${CYAN}$HOME/start-nexus-proxy.sh${NC}"
}

# Проверка прокси
check_proxy() {
    echo -e "\n${BOLD}${BLUE}⚡ Проверка прокси-соединения...${NC}\n"
    
    if ! command -v proxychains4 &> /dev/null; then
        echo -e "${RED}❌ Proxychains не установлен${NC}"
        echo -e "${YELLOW}Сначала настройте прокси (пункт 4)${NC}"
        return 1
    fi
    
    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}🔍 Текущий IP без прокси:${NC}"
    curl -s https://ifconfig.me
    echo ""
    
    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🔍 IP через прокси:${NC}"
    proxychains4 curl -s https://ifconfig.me
    echo ""
    
    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🔍 DNS через прокси:${NC}"
    proxychains4 ping -c 2 github.com
    
    echo -e "\n${GREEN}✅ Проверка завершена${NC}"
}

# Функция установки ноды
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка ноды Nexus...${NC}\n"
    check_ubuntu_version
    
    # Установка proxychains
    install_proxychains
    
    echo -e "${WHITE}[${CYAN}1/5${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление системы...${NC}"
    sudo apt update -y
    sudo apt upgrade -y

    echo -e "${WHITE}[${CYAN}2/5${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка зависимостей...${NC}"
    sudo apt install -y build-essential pkg-config libssl-dev git-all protobuf-compiler cargo screen unzip

    echo -e "${WHITE}[${CYAN}3/5${WHITE}] ${GREEN}➜ ${WHITE}⚙️  Настройка Rust через прокси...${NC}"
    proxychains4 curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    proxychains4 rustup update

    echo -e "${WHITE}[${CYAN}4/5${WHITE}] ${GREEN}➜ ${WHITE}🔧 Настройка Protobuf...${NC}"
    sudo apt remove -y protobuf-compiler
    proxychains4 curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v25.2/protoc-25.2-linux-x86_64.zip
    unzip protoc-25.2-linux-x86_64.zip -d $HOME/.local
    export PATH="$HOME/.local/bin:$PATH"
    
    # Управление screen сессией
    SESSION_NAME="nexus"
    if screen -ls | grep -q "$SESSION_NAME"; then
        echo -e "${YELLOW}⚠️ Сессия $SESSION_NAME уже существует. Перезапуск...${NC}"
        screen -S "$SESSION_NAME" -X quit
    fi
    
    echo -e "${CYAN}🚀 Создание новой screen сессии...${NC}"
    screen -dmS $SESSION_NAME $HOME/start-nexus-proxy.sh

    echo -e "\n${PURPLE}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Нода успешно установлена!${NC}"
    echo -e "${YELLOW}📋 Управление сессией:${NC}"
    echo -e "  ${CYAN}• screen -r nexus${NC} - подключение к сессии"
    echo -e "  ${CYAN}• CTRL + A + D${NC} - отключение от сессии"
    echo -e "  ${CYAN}• screen -ls${NC} - список сессий"
    echo -e "${PURPLE}═══════════════════════════════════════════════${NC}"
}

# Функция обновления ноды
update_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Обновление ноды Nexus...${NC}\n"
    
    if [ ! -d "$HOME/nexus-node" ]; then
        echo -e "${RED}❌ Директория ноды не найдена. Сначала установите ноду.${NC}"
        return 1
    fi
    
    # Остановка работающей ноды
    SESSION_NAME="nexus"
    if screen -ls | grep -q "$SESSION_NAME"; then
        echo -e "${YELLOW}⚠️ Останавливаем текущую сессию...${NC}"
        screen -S "$SESSION_NAME" -X quit
    fi
    
    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}📥 Обновление репозитория...${NC}"
    cd $HOME/nexus-node
    proxychains4 git pull
    
    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Обновление зависимостей...${NC}"
    proxychains4 rustup update
    
    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🚀 Перезапуск ноды...${NC}"
    screen -dmS $SESSION_NAME $HOME/start-nexus-proxy.sh
    
    echo -e "\n${GREEN}✅ Нода успешно обновлена!${NC}"
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

    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}⏹️ Остановка сессий...${NC}"
    SESSION_IDS=$(screen -ls | grep "nexus" | awk '{print $1}' | cut -d '.' -f 1)
    if [ -n "$SESSION_IDS" ]; then
        for SESSION_ID in $SESSION_IDS; do
            screen -S "$SESSION_ID" -X quit
        done
        echo -e "${GREEN}✅ Сессии остановлены${NC}"
    else
        echo -e "${YELLOW}⚠️ Активные сессии не найдены${NC}"
    fi

    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    rm -rf $HOME/nexus-node
    rm -rf $HOME/.nexus
    rm -f $HOME/start-nexus-proxy.sh

    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Восстановление конфигурации proxychains...${NC}"
    if [ -f "/etc/proxychains4.conf.backup" ]; then
        sudo cp /etc/proxychains4.conf.backup /etc/proxychains4.conf
        echo -e "${GREEN}✅ Конфигурация proxychains восстановлена${NC}"
    fi

    echo -e "\n${GREEN}✅ Нода успешно удалена!${NC}\n"
}

# Основной цикл программы
while true; do
    clear
    # Отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    
    print_menu
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-7]:${NC} "
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
            configure_proxy
            ;;
        5)
            check_proxy
            ;;
        6)
            remove_node
            ;;
        7)
            echo -e "\n${GREEN}👋 До свидания!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 7.${NC}\n"
            ;;
    esac

    if [ "$choice" != "3" ]; then
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    fi
done
