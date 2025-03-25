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

# Функция для отображения успешных сообщений
success_message() {
    echo -e "${GREEN}[✅] $1${NC}"
}

# Функция для отображения информационных сообщений
info_message() {
    echo -e "${CYAN}[ℹ️] $1${NC}"
}

# Функция для отображения ошибок
error_message() {
    echo -e "${RED}[❌] $1${NC}"
}

# Функция для отображения предупреждений
warning_message() {
    echo -e "${YELLOW}[⚠️] $1${NC}"
}

# Очистка экрана
clear

# Отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🔗 T3RN NODE MANAGER           ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Откат на версию v0.53.1${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка логов${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🌐 Управление RPC${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Проверка наличия bc и установка, если не установлен
if ! command -v bc &> /dev/null; then
    info_message "Установка bc..."
    sudo apt update
    sudo apt install bc -y
    success_message "bc успешно установлен"
fi

# Проверка версии Ubuntu
UBUNTU_VERSION=$(lsb_release -rs)
REQUIRED_VERSION=22.04

if (( $(echo "$UBUNTU_VERSION < $REQUIRED_VERSION" | bc -l) )); then
    error_message "Для этой ноды нужна минимальная версия Ubuntu 22.04"
    exit 1
fi

# Функция для установки ноды
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка ноды t3rn...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/6${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление пакетов...${NC}"
    sudo apt update
    sudo apt upgrade -y
    sudo apt-get install figlet -y
    success_message "Пакеты обновлены"
    sleep 1

    # Лого специальное
    figlet -f /usr/share/figlet/starwars.flf 

    echo -e "${WHITE}[${CYAN}2/6${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка актуальной версии...${NC}"
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/v0.53.1/executor-linux-v0.53.1.tar.gz"
    curl -L -o executor-linux-v0.53.1.tar.gz $EXECUTOR_URL
    success_message "Бинарный файл успешно загружен!"
    sleep 1

    echo -e "${WHITE}[${CYAN}3/6${WHITE}] ${GREEN}➜ ${WHITE}📦 Распаковка архива...${NC}"
    tar -xzvf executor-linux-v0.53.1.tar.gz
    rm -rf executor-linux-v0.53.1.tar.gz
    success_message "Архив распакован"
    sleep 1

    echo -e "${WHITE}[${CYAN}4/6${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Настройка конфигурации...${NC}"
    # Определяем пользователя и домашнюю директорию
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)

    # Создаем .t3rn и записываем приватный ключ
    CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
    echo "ENVIRONMENT=testnet" > $CONFIG_FILE
    echo "LOG_LEVEL=debug" >> $CONFIG_FILE
    echo "LOG_PRETTY=false" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_BIDS_ENABLED=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
    echo "PRIVATE_KEY_LOCAL=" >> $CONFIG_FILE
    echo "EXECUTOR_MAX_L3_GAS_PRICE=100" >> $CONFIG_FILE
    echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'" >> $CONFIG_FILE
    cat <<'EOF' >> $CONFIG_FILE
RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
}'
EOF
    if ! grep -q "ENVIRONMENT=testnet" "$HOME/executor/executor/bin/.t3rn"; then
      echo "ENVIRONMENT=testnet" >> "$HOME/executor/executor/bin/.t3rn"
    fi

    echo -e "${YELLOW}🔑 Введите ваш приватный ключ:${NC}"
    read -p "➜ " PRIVATE_KEY
    sed -i "s|PRIVATE_KEY_LOCAL=|PRIVATE_KEY_LOCAL=$PRIVATE_KEY|" $CONFIG_FILE
    success_message "Конфигурация настроена"
    sleep 1

    echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}📝 Создание сервиса...${NC}"
    # Создаем сервисник
    sudo bash -c "cat <<EOT > /etc/systemd/system/t3rn.service
[Unit]
Description=t3rn Service
After=network.target

[Service]
EnvironmentFile=$HOME_DIR/executor/executor/bin/.t3rn
ExecStart=$HOME_DIR/executor/executor/bin/executor
WorkingDirectory=$HOME_DIR/executor/executor/bin/
Restart=on-failure
User=$USERNAME

[Install]
WantedBy=multi-user.target
EOT"
    success_message "Сервис создан"
    sleep 1

    echo -e "${WHITE}[${CYAN}6/6${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск сервиса...${NC}"
    # Запуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-journald
    sleep 1
    sudo systemctl enable t3rn
    sudo systemctl start t3rn
    success_message "Сервис запущен и добавлен в автозагрузку"
    sleep 1

    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода t3rn успешно установлена и запущена!${NC}"
    echo -e "${YELLOW}📝 Команда для проверки логов:${NC}"
    echo -e "${CYAN}sudo journalctl -u t3rn -f${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    sudo journalctl -u t3rn -f
}

# Функция для обновления ноды
update_node() {
    echo -e "\n${BOLD}${BLUE}⬆️ Откат на версию v0.53.1 запущен...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/4${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервиса...${NC}"
    sudo systemctl stop t3rn
    success_message "Сервис остановлен"
    sleep 1
    
    echo -e "${WHITE}[${CYAN}2/4${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление старых файлов...${NC}"
    cd
    rm -rf executor/
    success_message "Старые файлы удалены"
    sleep 1
    
    echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка новой версии...${NC}"
    EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/v0.53.1/executor-linux-v0.53.1.tar.gz"
    curl -L -o executor-linux-v0.53.1.tar.gz $EXECUTOR_URL
    tar -xzvf executor-linux-v0.53.1.tar.gz
    rm -rf executor-linux-v0.53.1.tar.gz
    success_message "Откат успешно установлен. Версия ноды T3rn: v0.53.1"
    sleep 1
    
    echo -e "${WHITE}[${CYAN}4/4${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Обновление конфигурации...${NC}"
    # Определяем пользователя и домашнюю директорию
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)
    
    # Создаем .t3rn и записываем приватный ключ
    CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
    echo "ENVIRONMENT=testnet" > $CONFIG_FILE
    echo "LOG_LEVEL=debug" >> $CONFIG_FILE
    echo "LOG_PRETTY=false" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_BIDS_ENABLED=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
    echo "PRIVATE_KEY_LOCAL=" >> $CONFIG_FILE
    echo "EXECUTOR_MAX_L3_GAS_PRICE=100" >> $CONFIG_FILE
    echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l2rn'" >> $CONFIG_FILE
    cat <<'EOF' >> $CONFIG_FILE
RPC_ENDPOINTS='{
    "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
    "arbt": ["https://arbitrum-sepolia.drpc.org", "https://sepolia-rollup.arbitrum.io/rpc"],
    "bast": ["https://base-sepolia-rpc.publicnode.com", "https://base-sepolia.drpc.org"],
    "opst": ["https://sepolia.optimism.io", "https://optimism-sepolia.drpc.org"],
    "unit": ["https://unichain-sepolia.drpc.org", "https://sepolia.unichain.org"]
}'
EOF

    if ! grep -q "ENVIRONMENT=testnet" "$HOME/executor/executor/bin/.t3rn"; then
      echo "ENVIRONMENT=testnet" >> "$HOME/executor/executor/bin/.t3rn"
    fi

    echo -e "${YELLOW}🔑 Введите ваш приватный ключ:${NC}"
    read -p "➜ " PRIVATE_KEY
    sed -i "s|PRIVATE_KEY_LOCAL=|PRIVATE_KEY_LOCAL=$PRIVATE_KEY|" $CONFIG_FILE
    
    # Перезапуск сервиса
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-journald
    sudo systemctl start t3rn
    success_message "Конфигурация обновлена и сервис перезапущен"
    sleep 1
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода t3rn успешно обновлена!${NC}"
    echo -e "${YELLOW}📝 Команда для проверки логов:${NC}"
    echo -e "${CYAN}sudo journalctl -u t3rn -f${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    sudo journalctl -u t3rn -f
}

# Функция для проверки логов
check_logs() {
    echo -e "\n${BOLD}${BLUE}📋 Просмотр логов ноды t3rn...${NC}\n"
    
    info_message "Отображение логов ноды..."
    sudo journalctl -u t3rn -f
}

# Функция для перезапуска ноды
restart_node() {
    echo -e "\n${BOLD}${BLUE}🔄 Перезапуск ноды t3rn...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск сервиса...${NC}"
    sudo systemctl restart t3rn
    success_message "Нода успешно перезапущена"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода t3rn успешно перезапущена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    sudo journalctl -u t3rn -f
}

# Функция для удаления ноды
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды t3rn...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка сервисов...${NC}"
    sudo systemctl stop t3rn
    sudo systemctl disable t3rn
    sudo rm /etc/systemd/system/t3rn.service
    sudo systemctl daemon-reload
    sleep 2
    success_message "Сервисы остановлены и удалены"
    
    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    rm -rf $HOME/executor
    success_message "Файлы ноды удалены"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Нода t3rn успешно удалена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для управления RPC
manage_rpc() {
    echo -e "\n${BOLD}${BLUE}🌐 Управление RPC эндпоинтами...${NC}\n"
    
    # Определяем пользователя и домашнюю директорию
    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)
    CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
    
    # Проверка существования конфигурационного файла
    if [ ! -f "$CONFIG_FILE" ]; then
        error_message "Конфигурационный файл не найден. Нода установлена некорректно."
        return
    fi
    
    echo -e "${BOLD}${CYAN}Выберите действие:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}📋 Просмотр текущих RPC${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}✏️  Изменение RPC${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🔙 Вернуться в главное меню${NC}\n"
    
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-3]:${NC} "
    read -p "➜ " rpc_choice
    
    case $rpc_choice in
        1)
            echo -e "\n${BOLD}${BLUE}📋 Текущие RPC эндпоинты:${NC}\n"
            # Извлечение и форматирование RPC из конфигурационного файла
            rpc_content=$(grep -A 20 "RPC_ENDPOINTS" "$CONFIG_FILE" | grep -v "ENVIRONMENT" | sed '/^[[:space:]]*$/d')
            echo -e "${CYAN}$rpc_content${NC}\n"
            
            # Объяснение структуры RPC
            echo -e "${YELLOW}ℹ️ Пояснение структуры RPC:${NC}"
            echo -e "${WHITE}• ${CYAN}l2rn${WHITE} - обозначение сети Layer2 для t3rn${NC}"
            echo -e "${WHITE}• ${CYAN}arbt${WHITE} - обозначение сети Arbitrum Sepolia${NC}"
            echo -e "${WHITE}• ${CYAN}bast${WHITE} - обозначение сети Base Sepolia${NC}"
            echo -e "${WHITE}• ${CYAN}opst${WHITE} - обозначение сети Optimism Sepolia${NC}"
            echo -e "${WHITE}• ${CYAN}unit${WHITE} - обозначение сети Unichain${NC}"
            echo -e "${WHITE}Массив в квадратных скобках содержит URL-адреса RPC для соответствующей сети.${NC}"
            ;;
        2)
            echo -e "\n${BOLD}${BLUE}✏️ Изменение RPC эндпоинтов:${NC}\n"
            
            # Подробная инструкция по формату ввода
            echo -e "${YELLOW}📋 Руководство по вводу RPC:${NC}"
            echo -e "${WHITE}1. Формат ввода должен начинаться с ${CYAN}RPC_ENDPOINTS='${WHITE} и заканчиваться ${CYAN}'${NC}"
            echo -e "${WHITE}2. Внутри должен быть корректный JSON в фигурных скобках {}${NC}"
            echo -e "${WHITE}3. Каждая сеть указывается в формате: ${CYAN}\"имя_сети\": [\"url1\", \"url2\", ...]${NC}"
            echo -e "${WHITE}4. Все кавычки и символы должны быть сохранены в точности${NC}"
            echo -e "${WHITE}5. При замене можно изменить как все эндпоинты, так и отдельные для конкретных сетей${NC}\n"
            
            echo -e "${YELLOW}Пример правильного формата:${NC}"
            echo -e "${CYAN}RPC_ENDPOINTS='{
    \"l2rn\": [\"https://b2n.rpc.caldera.xyz/http\"],
    \"arbt\": [\"https://arbitrum-sepolia.drpc.org\", \"https://sepolia-rollup.arbitrum.io/rpc\"],
    \"bast\": [\"https://base-sepolia-rpc.publicnode.com\", \"https://base-sepolia.drpc.org\"],
    \"opst\": [\"https://sepolia.optimism.io\", \"https://optimism-sepolia.drpc.org\"],
    \"unit\": [\"https://unichain-sepolia.drpc.org\", \"https://sepolia.unichain.org\"]
}'${NC}\n"
            
            # Показываем текущие RPC
            echo -e "${PURPLE}╔════════════════════════════════════════════╗${NC}"
            echo -e "${PURPLE}║    ТЕКУЩИЕ НАСТРОЙКИ RPC ЭНДПОИНТОВ       ║${NC}"
            echo -e "${PURPLE}╚════════════════════════════════════════════╝${NC}"
            rpc_content=$(grep -A 20 "RPC_ENDPOINTS" "$CONFIG_FILE" | grep -v "ENVIRONMENT" | sed '/^[[:space:]]*$/d')
            echo -e "${CYAN}$rpc_content${NC}\n"
            
            # Простой пример для изменения только одного эндпоинта
            echo -e "${YELLOW}💡 Совет: Если вы хотите изменить только один эндпоинт, например для Arbitrum (arbt):${NC}"
            echo -e "${CYAN}RPC_ENDPOINTS='{
    \"l2rn\": [\"https://b2n.rpc.caldera.xyz/http\"],
    \"arbt\": [\"https://новый.эндпоинт.здесь\"],
    \"bast\": [\"https://base-sepolia-rpc.publicnode.com\", \"https://base-sepolia.drpc.org\"],
    \"opst\": [\"https://sepolia.optimism.io\", \"https://optimism-sepolia.drpc.org\"],
    \"unit\": [\"https://unichain-sepolia.drpc.org\", \"https://sepolia.unichain.org\"]
}'${NC}\n"
            
            echo -e "${YELLOW}Введите новые RPC эндпоинты (или нажмите Enter для отмены):${NC}"
            echo -e "${RED}ВНИМАНИЕ: Вводите текст со всеми кавычками и скобками точно в указанном формате!${NC}"
            read -r -p "➜ " new_rpc
            
            if [ -z "$new_rpc" ]; then
                warning_message "Операция отменена пользователем."
                return
            fi
            
            # Базовая проверка формата
            if ! [[ "$new_rpc" == RPC_ENDPOINTS=\'* && "$new_rpc" == *\'\$ ]]; then
                error_message "Неверный формат ввода! Убедитесь, что вы начали с RPC_ENDPOINTS='{' и закончили }'."
                warning_message "Операция отменена."
                return
            fi
            
            # Сохраняем временный файл конфигурации
            temp_file=$(mktemp)
            grep -v "RPC_ENDPOINTS" "$CONFIG_FILE" > "$temp_file"
            echo "$new_rpc" >> "$temp_file"
            
            # Проверяем валидность JSON в RPC_ENDPOINTS
            valid_json=true
            json_part=$(echo "$new_rpc" | grep -o '{.*}' || echo "")
            
            if [ -z "$json_part" ]; then
                valid_json=false
            else
                # Используем простую проверку скобок и кавычек
                open_braces=$(echo "$json_part" | grep -o "{" | wc -l)
                close_braces=$(echo "$json_part" | grep -o "}" | wc -l)
                open_quotes=$(echo "$json_part" | grep -o "\"" | wc -l)
                
                if [ "$open_braces" != "$close_braces" ] || [ $((open_quotes % 2)) -ne 0 ]; then
                    valid_json=false
                fi
            fi
            
            if [ "$valid_json" = true ]; then
                # Заменяем существующий файл конфигурации
                mv "$temp_file" "$CONFIG_FILE"
                success_message "RPC эндпоинты успешно обновлены"
                
                # Перезапускаем сервис
                echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск сервиса...${NC}"
                sudo systemctl restart t3rn
                success_message "Сервис успешно перезапущен с новыми RPC"
                
                # Показываем новые настройки
                echo -e "\n${BOLD}${GREEN}✅ Новые настройки RPC:${NC}"
                rpc_content=$(grep -A 20 "RPC_ENDPOINTS" "$CONFIG_FILE" | grep -v "ENVIRONMENT" | sed '/^[[:space:]]*$/d')
                echo -e "${CYAN}$rpc_content${NC}\n"
            else
                rm "$temp_file"
                error_message "Ошибка в формате JSON. Пожалуйста, проверьте синтаксис и попробуйте снова."
                echo -e "${YELLOW}Убедитесь, что:${NC}"
                echo -e "${WHITE}• У каждой открывающей скобки { есть закрывающая }${NC}"
                echo -e "${WHITE}• У каждой открывающей скобки [ есть закрывающая ]${NC}"
                echo -e "${WHITE}• У каждой кавычки \" есть парная кавычка${NC}"
                echo -e "${WHITE}• Все ключи и значения разделены двоеточием :${NC}"
                echo -e "${WHITE}• Все элементы разделены запятыми ,${NC}"
            fi
            ;;
        3)
            return
            ;;
        *)
            echo -e "\n${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 3.${NC}\n"
            ;;
    esac
    
    echo -e "\nНажмите Enter, чтобы продолжить..."
    read
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
            check_logs
            ;;
        4)
            restart_node
            ;;
        5)
            manage_rpc
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
    
    if [[ "$choice" != "3" ]]; then
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    fi
done
