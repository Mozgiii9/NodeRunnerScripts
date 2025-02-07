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

# Отображение логотипа
clear
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🚀 RITUAL NODE MANAGER          ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка базовых компонентов${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}📦 Настройка конфигурации${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🔄 Завершение установки${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}💼 Изменить адрес кошелька${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🌐 Изменить RPC адрес${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}8${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}9${WHITE}] ${GREEN}➜ ${WHITE}📊 Проверка состояния ноды${NC}"
    echo -e "${WHITE}[${CYAN}10${WHITE}] ${GREEN}➜ ${WHITE}💾 Управление системой${NC}\n"
}

# Функция установки базовых компонентов
install_ritual() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка базовых компонентов...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновление системы...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt autoremove -y

    echo -e "${WHITE}[${CYAN}2/4${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка необходимых пакетов...${NC}"
    sudo apt -qy install curl git jq lz4 build-essential screen

    echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}🐳 Установка Docker...${NC}"
    if ! command -v docker &> /dev/null; then
        sudo apt install docker.io -y
    fi

    echo -e "${WHITE}[${CYAN}4/4${WHITE}] ${GREEN}➜ ${WHITE}🔧 Установка Docker Compose...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Установка Docker Compose CLI плагина
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

    echo -e "\n${GREEN}✅ Базовые компоненты успешно установлены!${NC}\n"
    
    # Клонирование репозитория
    echo -e "${WHITE}[${CYAN}+${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка Ritual...${NC}"
    git clone https://github.com/ritual-net/infernet-container-starter

    # Настройка версии Docker
    docker_yaml=~/infernet-container-starter/deploy/docker-compose.yaml
    sed -i 's/image: ritualnetwork\/infernet-node:1.3.1/image: ritualnetwork\/infernet-node:1.2.0/' "$docker_yaml"

    echo -e "\n${GREEN}✨ Установка завершена! Запускаем контейнер...${NC}"
    
    # Автоматическое создание screen сессии и запуск контейнера
    screen -S ritual -dm bash -c "cd ~/infernet-container-starter && project=hello-world make deploy-container"
    
    echo -e "${YELLOW}⚡ Screen сессия 'ritual' создана и контейнер запущен${NC}"
    echo -e "${CYAN}Для просмотра логов используйте: screen -r ritual${NC}"
    echo -e "${CYAN}Для выхода из логов используйте: CTRL + A + D${NC}"
    
    # Автоматическое подключение к screen сессии
    sleep 2
    screen -r ritual
}

# Функция настройки конфигурации
install_ritual_2() {
    echo -e "\n${BOLD}${BLUE}⚡ Настройка конфигурации ноды...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}🌐 Настройка RPC...${NC}"
    echo -ne "${BOLD}${YELLOW}Введите RPC URL: ${NC}"
    read -e rpc_url1

    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🔑 Настройка кошелька...${NC}"
    echo -ne "${BOLD}${YELLOW}Введите Private Key (с 0x или без): ${NC}"
    read -e private_key1
    
    # Добавление 0x, если его нет
    if [[ ! $private_key1 =~ ^0x ]]; then
        private_key1="0x$private_key1"
    fi

    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Применение настроек...${NC}"
    
    # Обновление конфигурационных файлов
    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json
    
    # Создание временного файла
    temp_file=$(mktemp)

    # Обновление конфигурации
    jq --arg rpc "$rpc_url1" --arg priv "$private_key1" \
        '.chain.rpc_url = $rpc |
         .chain.wallet.private_key = $priv |
         .chain.trail_head_blocks = 3 |
         .chain.registry_address = "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170" |
         .chain.snapshot_sync.sleep = 3 |
         .chain.snapshot_sync.batch_size = 9500 |
         .chain.snapshot_sync.starting_sub_id = 200000 |
         .chain.snapshot_sync.sync_period = 30' $json_1 > $temp_file

    mv $temp_file $json_1

    jq --arg rpc "$rpc_url1" --arg priv "$private_key1" \
        '.chain.rpc_url = $rpc |
         .chain.wallet.private_key = $priv |
         .chain.trail_head_blocks = 3 |
         .chain.registry_address = "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170" |
         .chain.snapshot_sync.sleep = 3 |
         .chain.snapshot_sync.batch_size = 9500 |
         .chain.snapshot_sync.starting_sub_id = 200000 |
         .chain.snapshot_sync.sync_period = 30' $json_2 > $temp_file

    mv $temp_file $json_2

    # Обновление Makefile
    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile 
    sed -i "s|sender := .*|sender := $private_key1|" "$makefile"
    sed -i "s|RPC_URL := .*|RPC_URL := $rpc_url1|" "$makefile"

    # Обновление версии Docker
    docker_yaml=~/infernet-container-starter/deploy/docker-compose.yaml
    sed -i 's/image: ritualnetwork\/infernet-node:1.2.0/image: ritualnetwork\/infernet-node:1.4.0/' "$docker_yaml"

    echo -e "\n${GREEN}✅ Конфигурация успешно обновлена!${NC}"
    
    # Автоматический запуск docker compose
    echo -e "\n${YELLOW}🚀 Запуск docker compose...${NC}"
    cd ~/infernet-container-starter/deploy && docker compose up -d
    
    echo -e "\n${GREEN}✨ Сервисы запущены в фоновом режиме!${NC}"
    echo -e "${CYAN}Для просмотра логов используйте: docker compose logs -f${NC}"
}

# Функция завершения установки
install_ritual_3() {
    echo -e "\n${BOLD}${BLUE}⚡ Завершение установки ноды...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/4${WHITE}] ${GREEN}➜ ${WHITE}🔧 Установка Foundry...${NC}"
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    foundryup

    echo -e "${WHITE}[${CYAN}2/4${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка зависимостей...${NC}"
    cd ~/infernet-container-starter/projects/hello-world/contracts
    rm -rf lib
    forge install --no-commit foundry-rs/forge-std
    forge install --no-commit ritual-net/infernet-sdk

    echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}📝 Деплой контрактов...${NC}"
    cd ~/infernet-container-starter
    project=hello-world make deploy-contracts

    echo -e "${WHITE}[${CYAN}4/4${WHITE}] ${GREEN}➜ ${WHITE}✍️ Настройка контракта...${NC}"
    echo -e "${YELLOW}Проверьте логи выше и найдите адрес deployed Sayshello${NC}"
    echo -ne "${CYAN}Введите адрес Sayshello: ${NC}"
    read -e says_gm

    # Обновление CallContract.s.sol
    callcontractpath="$HOME/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"
    sed -i "s|SaysGM saysGm = SaysGM(.*)|SaysGM saysGm = SaysGM($says_gm)|" "$callcontractpath"

    echo -e "\n${GREEN}🚀 Выполнение финальных команд...${NC}"
    project=hello-world make call-contract

    echo -e "\n${GREEN}✨ Установка ноды успешно завершена!${NC}"
}

# Функция перезапуска ноды
restart_ritual() {
    echo -e "\n${BOLD}${BLUE}🔄 Перезапуск ноды...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}⏹️ Остановка сервисов...${NC}"
    cd ~/infernet-container-starter/deploy
    docker compose down
    
    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}▶️ Запуск сервисов...${NC}"
    echo -e "\n${GREEN}✅ Выполните команду:${NC}"
    echo -e "${CYAN}cd ~/infernet-container-starter/deploy && docker compose up${NC}"
}

# Функция изменения адреса кошелька
change_Wallet_Address() {
    echo -e "\n${BOLD}${BLUE}💼 Изменение адреса кошелька...${NC}\n"
    
    echo -ne "${BOLD}${YELLOW}Введите новый Private Key (с 0x или без): ${NC}"
    read -e private_key1
    
    # Добавление 0x, если его нет
    if [[ ! $private_key1 =~ ^0x ]]; then
        private_key1="0x$private_key1"
    fi

    # Обновление конфигурационных файлов
    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json
    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile

    temp_file=$(mktemp)

    jq --arg priv "$private_key1" \
        '.chain.wallet.private_key = $priv' $json_1 > $temp_file
    mv $temp_file $json_1

    jq --arg priv "$private_key1" \
        '.chain.wallet.private_key = $priv' $json_2 > $temp_file
    mv $temp_file $json_2

    sed -i "s|sender := .*|sender := $private_key1|" "$makefile"

    echo -e "\n${GREEN}✅ Адрес кошелька успешно обновлен!${NC}"
    
    echo -e "\n${YELLOW}🔄 Переустановка контрактов...${NC}"
    cd ~/infernet-container-starter
    project=hello-world make deploy-contracts

    echo -e "\n${YELLOW}Проверьте логи выше и найдите адрес deployed Sayshello${NC}"
    echo -ne "${CYAN}Введите адрес Sayshello: ${NC}"
    read -e says_gm

    callcontractpath="$HOME/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"
    sed -i "s|SaysGM saysGm = SaysGM(.*)|SaysGM saysGm = SaysGM($says_gm)|" "$callcontractpath"

    project=hello-world make call-contract
}

# Функция изменения RPC адреса
change_RPC_Address() {
    echo -e "\n${BOLD}${BLUE}🌐 Изменение RPC адреса...${NC}\n"
    
    echo -ne "${BOLD}${YELLOW}Введите новый RPC URL: ${NC}"
    read -e rpc_url1

    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json
    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile

    temp_file=$(mktemp)

    jq --arg rpc "$rpc_url1" \
        '.chain.rpc_url = $rpc' $json_1 > $temp_file
    mv $temp_file $json_1

    jq --arg rpc "$rpc_url1" \
        '.chain.rpc_url = $rpc' $json_2 > $temp_file
    mv $temp_file $json_2

    sed -i "s|RPC_URL := .*|RPC_URL := $rpc_url1|" "$makefile"

    echo -e "\n${GREEN}✅ RPC адрес успешно обновлен!${NC}"
    
    echo -e "\n${YELLOW}🔄 Перезапуск контейнеров...${NC}"
    docker restart infernet-anvil
    docker restart hello-world
    docker restart infernet-node
    docker restart infernet-fluentbit
    docker restart infernet-redis

    echo -e "\n${GREEN}✨ Все сервисы перезапущены!${NC}"
}

# Функция обновления ноды
update_ritual() {
    echo -e "\n${BOLD}${BLUE}⬆️ Обновление ноды...${NC}\n"

    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json
    temp_file=$(mktemp)

    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Обновление конфигурации...${NC}"
    jq '.chain.snapshot_sync.sleep = 3 |
        .chain.snapshot_sync.batch_size = 9500 |
        .chain.snapshot_sync.starting_sub_id = 200000 |
        .chain.snapshot_sync.sync_period = 30' "$json_1" > "$temp_file"
    mv "$temp_file" "$json_1"

    jq '.chain.snapshot_sync.sleep = 3 |
        .chain.snapshot_sync.batch_size = 9500 |
        .chain.snapshot_sync.starting_sub_id = 200000 |
        .chain.snapshot_sync.sync_period = 30' "$json_2" > "$temp_file"
    mv "$temp_file" "$json_2"

    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск сервисов...${NC}"
    cd ~/infernet-container-starter/deploy && docker compose down

    echo -e "\n${GREEN}✅ Обновление завершено!${NC}"
    echo -e "${YELLOW}Выполните команду:${NC}"
    echo -e "${CYAN}cd ~/infernet-container-starter/deploy && docker compose up${NC}"
}

# Функция удаления ноды
uninstall_ritual() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}⏹️ Остановка контейнеров...${NC}"
    docker stop infernet-anvil infernet-node hello-world infernet-redis infernet-fluentbit
    docker rm -f infernet-anvil infernet-node hello-world infernet-redis infernet-fluentbit
    cd ~/infernet-container-starter/deploy && docker compose down

    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление образов...${NC}"
    docker image ls -a | grep "infernet" | awk '{print $3}' | xargs docker rmi -f
    docker image ls -a | grep "fluent-bit" | awk '{print $3}' | xargs docker rmi -f
    docker image ls -a | grep "redis" | awk '{print $3}' | xargs docker rmi -f

    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🧹 Очистка файлов...${NC}"
    rm -rf ~/foundry
    sed -i '/\/root\/.foundry\/bin/d' ~/.bashrc
    rm -rf ~/infernet-container-starter/projects/hello-world/contracts/lib
    cd $HOME
    rm -rf infernet-container-starter

    echo -e "\n${GREEN}✅ Нода успешно удалена!${NC}"
}

# Функция проверки состояния ноды
check_node_status() {
    echo -e "\n${BOLD}${BLUE}📊 Проверка состояния ноды...${NC}\n"
    
    # Проверка доступности endpoint
    if curl -s localhost:4000/health > /dev/null; then
        response=$(curl -s localhost:4000/health)
        echo -e "${GREEN}✅ Нода работает нормально${NC}"
        echo -e "${CYAN}Ответ от ноды:${NC}"
        echo $response | jq '.'
    else
        echo -e "${RED}❌ Нода недоступна${NC}"
        echo -e "${YELLOW}Проверьте, что:${NC}"
        echo -e "  ${WHITE}1. Нода запущена${NC}"
        echo -e "  ${WHITE}2. Порт 4000 доступен${NC}"
        echo -e "  ${WHITE}3. Все сервисы работают корректно${NC}"
    fi
}

# Функция управления системой
manage_system() {
    while true; do
        echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${WHITE}║      💾 УПРАВЛЕНИЕ СИСТЕМОЙ           ║${NC}"
        echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
        
        # Показать текущее использование диска
        echo -e "${BOLD}${BLUE}📊 Использование диска:${NC}"
        df -h / | tail -n 1 | awk '{print "Всего: " $2 "\nИспользовано: " $3 " (" $5 ")\nСвободно: " $4}'
        
        echo -e "\n${BOLD}${BLUE}🔧 Доступные действия:${NC}"
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🧹 Очистить системные логи${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}📊 Показать топ-10 крупных файлов${NC}"
        echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🔍 Проверить использование Docker${NC}"
        echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🚪 Вернуться в главное меню${NC}\n"
        
        echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-4]:${NC} "
        read -p "➜ " sys_choice

        case $sys_choice in
            1)
                echo -e "\n${BOLD}${BLUE}🧹 Очистка системных логов...${NC}"
                echo -e "${WHITE}Размер логов до очистки:${NC}"
                ls -lh /var/log/syslog* 2>/dev/null
                
                sudo truncate -s 0 /var/log/syslog
                sudo truncate -s 0 /var/log/syslog.1
                
                echo -e "\n${GREEN}✅ Логи очищены${NC}"
                echo -e "${WHITE}Текущий размер логов:${NC}"
                ls -lh /var/log/syslog* 2>/dev/null
                ;;
            2)
                echo -e "\n${BOLD}${BLUE}📊 Топ-10 крупных файлов:${NC}"
                sudo find / -type f -exec du -Sh {} + 2>/dev/null | sort -rh | head -n 10
                ;;
            3)
                echo -e "\n${BOLD}${BLUE}🔍 Использование Docker:${NC}"
                docker system df -v
                echo -e "\n${YELLOW}Для очистки неиспользуемых ресурсов Docker выполните:${NC}"
                echo -e "${CYAN}docker system prune -a${NC}"
                ;;
            4)
                break
                ;;
            *)
                echo -e "\n${RED}❌ Неверный выбор!${NC}"
                ;;
        esac
        
        echo -e "\nНажмите Enter, чтобы продолжить..."
        read
    done
}

# Основное меню
while true; do
    clear
    # Отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    
    print_menu
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-10]:${NC} "
    read -p "➜ " choice

    case $choice in
        1)
            install_ritual
            ;;
        2)
            install_ritual_2
            ;;
        3)
            install_ritual_3
            ;;
        4)
            restart_ritual
            ;;
        5)
            change_Wallet_Address
            ;;
        6)
            change_RPC_Address
            ;;
        7)
            update_ritual
            ;;
        8)
            uninstall_ritual
            ;;
        9)
            check_node_status
            ;;
        10)
            manage_system
            ;;
        *)
            echo -e "\n${BOLD}${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 10.${NC}\n"
            ;;
    esac

    if [ "$choice" != "10" ]; then
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    fi
done 
