#!/bin/bash

# Цветовые коды
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Сброс цвета

# Функция логирования
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Функция отображения успеха
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Функция отображения ошибки
error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Функция отображения предупреждения
warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Функция отображения логотипа
show_logo() {
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    echo
}

# Установка необходимых пакетов
echo -e "${BLUE}🔧 Установка необходимых пакетов...${NC}"
sudo apt install curl docker.io docker-compose jq -y

echo -e "${BLUE}🚀 Запуск сервиса Docker...${NC}"
sudo systemctl start docker
sudo systemctl enable docker

if ! sudo systemctl is-active --quiet docker; then
    error "Docker сервис не запущен. Проверьте статус командой: 'systemctl status docker'"
fi

sudo usermod -aG docker $USER

BASE_DIR="$HOME/citrea-node"
INITIAL_DIR=$(pwd)

add_watchtower() {
    awk '/volumes:/{print "  watchtower:\n    image: containrrr/watchtower\n    container_name: watchtower\n    volumes:\n      - /var/run/docker.sock:/var/run/docker.sock\n    command: --interval 3600 bitcoin-testnet4 full-node\n    environment:\n      - WATCHTOWER_CLEANUP=true\n    restart: unless-stopped\n    networks:\n      - citrea-testnet-network\n"}1' docker-compose.yml > temp.yml
    mv temp.yml docker-compose.yml
}

install_default() {
    if [ -d "$BASE_DIR" ]; then
        warning "Нода Citrea уже установлена! Сначала удалите её."
        return
    }

    log "🚀 Установка ноды Citrea со стандартными настройками..."
    mkdir -p $BASE_DIR && cd $BASE_DIR
    curl https://raw.githubusercontent.com/chainwayxyz/citrea/refs/heads/nightly/docker/docker-compose.yml --output docker-compose.yml
    add_watchtower
    docker-compose up -d
    success "Установка со стандартными настройками завершена!"
    cd $INITIAL_DIR
}

install_custom() {
    if [ -d "$BASE_DIR" ]; then
        warning "Нода Citrea уже установлена! Сначала удалите её."
        return
    }

    log "⚙️ Установка ноды Citrea с пользовательскими настройками..."
    
    echo -e "${YELLOW}⌨️  Введите новое имя пользователя RPC (по умолчанию: citrea):${NC}"
    read rpc_user
    rpc_user=${rpc_user:-citrea}
    
    echo -e "${YELLOW}⌨️  Введите новый пароль RPC (по умолчанию: citrea):${NC}"
    read rpc_password
    rpc_password=${rpc_password:-citrea}
    
    echo -e "${YELLOW}⌨️  Введите новый порт RPC (по умолчанию: 8080):${NC}"
    read rpc_port
    rpc_port=${rpc_port:-8080}
    
    mkdir -p $BASE_DIR && cd $BASE_DIR
    
    curl https://raw.githubusercontent.com/chainwayxyz/citrea/refs/heads/nightly/docker/docker-compose.yml --output docker-compose.yml
    
    sed -i "s/-rpcuser=citrea/-rpcuser=$rpc_user/" docker-compose.yml
    sed -i "s/-rpcpassword=citrea/-rpcpassword=$rpc_password/" docker-compose.yml
    sed -i "s/ROLLUP__DA__NODE_USERNAME=citrea/ROLLUP__DA__NODE_USERNAME=$rpc_user/" docker-compose.yml
    sed -i "s/ROLLUP__DA__NODE_PASSWORD=citrea/ROLLUP__DA__NODE_PASSWORD=$rpc_password/" docker-compose.yml
    sed -i "s/ROLLUP__RPC__BIND_PORT=8080/ROLLUP__RPC__BIND_PORT=$rpc_port/" docker-compose.yml
    sed -i "s/- \"8080:8080\"/- \"$rpc_port:$rpc_port\"/" docker-compose.yml
    
    add_watchtower
    docker-compose up -d
    success "Установка с пользовательскими настройками завершена!"
    cd $INITIAL_DIR
}

uninstall_node() {
    log "🗑️ Удаление ноды Citrea..."
    
    if [ ! -d "$BASE_DIR" ]; then
        error "Директория citrea-node не найдена!"
    fi
    
    cd $BASE_DIR
    log "📥 Остановка и удаление контейнеров с томами..."
    docker-compose down -v || true
    
    log "🧹 Удаление Docker образов..."
    docker rmi -f bitcoin/bitcoin:28.0rc1 chainwayxyz/citrea-full-node:testnet containrrr/watchtower || true
    
    cd $INITIAL_DIR
    log "🗑️ Удаление директории citrea-node..."
    rm -rf $BASE_DIR
    
    success "Нода Citrea успешно удалена!"
    success "Все контейнеры, тома, сети и образы были удалены."
}

view_logs() {
    if [ ! -d "$BASE_DIR" ]; then
        error "Нода не установлена! Директория citrea-node не найдена."
    }
    
    log "📋 Просмотр логов..."
    cd $BASE_DIR && docker-compose logs
    cd $INITIAL_DIR
}

check_sync() {
    if [ ! -d "$BASE_DIR" ]; then
        error "Нода не установлена! Директория citrea-node не найдена."
    }
    
    local current_port=$(grep "ROLLUP__RPC__BIND_PORT=" $BASE_DIR/docker-compose.yml | cut -d'=' -f2)
    if [ -z "$current_port" ]; then
        current_port="8080"
    fi
    
    log "🔄 Проверка статуса синхронизации..."
    curl -X POST --header "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"citrea_syncStatus","params":[], "id":31}' \
        "http://0.0.0.0:$current_port" | jq
}

show_menu() {
    clear
    show_logo
    echo -e "${BLUE}╭───────────────────────────────────╮${NC}"
    echo -e "${BLUE}│    🌟 Управление нодой Citrea    │${NC}"
    echo -e "${BLUE}╰───────────────────────────────────╯${NC}"
    echo -e "1. 📦 Установить ноду (стандартные настройки)"
    echo -e "2. ⚙️ Установить ноду (свои настройки)"
    echo -e "3. 🗑️ Удалить ноду"
    echo -e "4. 📋 Просмотр логов"
    echo -e "5. 🔄 Проверить статус синхронизации"
    echo -e "6. 🚪 Выход"
    echo
    echo -e "${YELLOW}⌨️  Выберите опцию (1-6):${NC}"
}

while true; do
    show_menu
    read choice
    
    case $choice in
        1) install_default ;;
        2) install_custom ;;
        3) uninstall_node ;;
        4) view_logs ;;
        5) check_sync ;;
        6)
            log "👋 Выход из установщика..."
            exit 0
            ;;
        *)
            warning "Неверный выбор. Пожалуйста, выберите 1-6"
            ;;
    esac
    
    echo
    echo -e "${YELLOW}⌨️  Нажмите Enter для продолжения...${NC}"
    read
done
