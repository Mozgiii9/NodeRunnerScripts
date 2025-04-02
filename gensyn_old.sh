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

# Функция установки базовых зависимостей
install_dependencies() {
    info_message "Установка необходимых пакетов..."
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install -y curl build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip
    success_message "Базовые зависимости установлены"
}

# Функция для проверки и определения правильного формата docker-compose команды
check_docker_compose_format() {
    info_message "Проверка формата docker-compose команды..."
    # Проверяем, работает ли docker compose
    if docker compose version &>/dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
        success_message "Будет использоваться команда: docker compose"
    else
        DOCKER_COMPOSE_CMD="docker-compose"
        success_message "Будет использоваться команда: docker-compose"
    fi
}

# Функция для установки Docker и Docker Compose
install_docker() {
    info_message "Проверка наличия Docker..."
    if ! command -v docker &> /dev/null; then
        warning_message "Docker не установлен. Устанавливаем Docker..."
        sudo apt install docker.io -y
        success_message "Docker успешно установлен"
    else
        success_message "Docker уже установлен"
    fi

    info_message "Проверка наличия Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        warning_message "Docker Compose не установлен. Устанавливаем Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        success_message "Docker Compose успешно установлен"
    else
        success_message "Docker Compose уже установлен"
    fi

    # Определяем правильный формат команды docker-compose
    check_docker_compose_format

    sudo usermod -aG docker $USER
    success_message "Пользователь добавлен в группу docker"
}

# Очистка экрана
clear

# Отображение логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║       🧠 GENSYN NODE MANAGER          ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📋 Просмотр логов${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Функция для создания docker-compose файла
create_docker_compose() {
    info_message "Создание docker-compose.yaml..."
    
    mv docker-compose.yaml docker-compose.yaml.old 2>/dev/null
    
    cat << 'EOF' > docker-compose.yaml
version: '3'

services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:0.120.0
    ports:
      - "4317:4317"  # OTLP gRPC
      - "4318:4318"  # OTLP HTTP
      - "55679:55679"  # Prometheus metrics (optional)
    environment:
      - OTEL_LOG_LEVEL=DEBUG

  swarm_node:
    image: europe-docker.pkg.dev/gensyn-public-b7d9/public/rl-swarm:v0.0.2
    command: ./run_hivemind_docker.sh
    #runtime: nvidia  # Enables GPU support; remove if no GPU is available
    environment:
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - PEER_MULTI_ADDRS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
      - HOST_MULTI_ADDRS=/ip4/0.0.0.0/tcp/38331
    ports:
      - "38331:38331"  # Exposes the swarm node's P2P port
    depends_on:
      - otel-collector

  fastapi:
    build:
      context: .
      dockerfile: Dockerfile.webserver
    environment:
      - OTEL_SERVICE_NAME=rlswarm-fastapi
      - OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317
      - INITIAL_PEERS=/ip4/38.101.215.13/tcp/30002/p2p/QmQ2gEXoPJg6iMBSUFWGzAabS2VhnzuS782Y637hGjfsRJ
    ports:
      - "8177:8000"  # Maps port 8177 on the host to 8000 in the container 
    depends_on:
      - otel-collector
      - swarm_node
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/healthz"]
      interval: 30s
      retries: 3
EOF

    success_message "docker-compose.yaml успешно создан"
}

# Функция для установки ноды
install_node() {
    echo -e "\n${BOLD}${BLUE}⚡ Установка ноды Gensyn...${NC}\n"

    echo -e "${WHITE}[${CYAN}1/6${WHITE}] ${GREEN}➜ ${WHITE}🔄 Установка базовых зависимостей...${NC}"
    install_dependencies
    sleep 1

    echo -e "${WHITE}[${CYAN}2/6${WHITE}] ${GREEN}➜ ${WHITE}🐳 Установка Docker и Docker Compose...${NC}"
    install_docker
    sleep 1

    echo -e "${WHITE}[${CYAN}3/6${WHITE}] ${GREEN}➜ ${WHITE}📦 Установка дополнительных компонентов...${NC}"
    sudo apt-get install -y python3 python3-pip
    success_message "Python и pip установлены"
    sleep 1

    echo -e "${WHITE}[${CYAN}4/6${WHITE}] ${GREEN}➜ ${WHITE}📥 Клонирование репозитория...${NC}"
    git clone https://github.com/gensyn-ai/rl-swarm/
    cd rl-swarm
    success_message "Репозиторий успешно клонирован"
    sleep 1

    echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Настройка конфигурации...${NC}"
    create_docker_compose
    sleep 1

    echo -e "${WHITE}[${CYAN}6/6${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запуск контейнеров...${NC}"
    $DOCKER_COMPOSE_CMD pull
    $DOCKER_COMPOSE_CMD up -d
    success_message "Контейнеры успешно запущены"

    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода Gensyn успешно установлена и запущена!${NC}"
    echo -e "${YELLOW}📝 Команда для проверки логов:${NC}"
    echo -e "${CYAN}cd rl-swarm && $DOCKER_COMPOSE_CMD logs swarm_node${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    $DOCKER_COMPOSE_CMD logs swarm_node
}

# Функция для обновления ноды
update_node() {
    echo -e "\n${BOLD}${BLUE}⬆️ Обновление ноды Gensyn...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка директории...${NC}"
    if [ ! -d "$HOME/rl-swarm" ]; then
        error_message "Директория ноды не найдена. Сначала установите ноду."
        return 1
    fi
    
    cd rl-swarm
    success_message "Перешли в директорию ноды"
    
    # Определяем правильный формат команды docker-compose
    check_docker_compose_format
    
    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}⬆️ Обновление образа...${NC}"
    VER=rl-swarm:v0.0.2
    sed -i "s#\(image: europe-docker.pkg.dev/gensyn-public-b7d9/public/\).*#\1$VER#g" docker-compose.yaml
    $DOCKER_COMPOSE_CMD pull
    success_message "Образ обновлен до версии $VER"
    
    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск контейнеров...${NC}"
    $DOCKER_COMPOSE_CMD up -d --force-recreate
    success_message "Контейнеры перезапущены с обновленной версией"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода Gensyn успешно обновлена!${NC}"
    echo -e "${YELLOW}📝 Команда для проверки логов:${NC}"
    echo -e "${CYAN}cd rl-swarm && $DOCKER_COMPOSE_CMD logs swarm_node${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    $DOCKER_COMPOSE_CMD logs swarm_node
}

# Функция для проверки логов
check_logs() {
    echo -e "\n${BOLD}${BLUE}📋 Просмотр логов ноды Gensyn...${NC}\n"
    
    if [ ! -d "$HOME/rl-swarm" ]; then
        error_message "Директория ноды не найдена. Сначала установите ноду."
        return 1
    fi
    
    cd rl-swarm
    
    # Определяем правильный формат команды docker-compose
    check_docker_compose_format
    
    info_message "Отображение логов ноды..."
    $DOCKER_COMPOSE_CMD logs swarm_node
}

# Функция для рестарта ноды
restart_node() {
    echo -e "\n${BOLD}${BLUE}🔄 Перезапуск ноды Gensyn...${NC}\n"
    
    if [ ! -d "$HOME/rl-swarm" ]; then
        error_message "Директория ноды не найдена. Сначала установите ноду."
        return 1
    fi
    
    cd rl-swarm
    
    # Определяем правильный формат команды docker-compose
    check_docker_compose_format
    
    echo -e "${WHITE}[${CYAN}1/1${WHITE}] ${GREEN}➜ ${WHITE}🔄 Перезапуск контейнеров...${NC}"
    $DOCKER_COMPOSE_CMD restart
    success_message "Контейнеры успешно перезапущены"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода Gensyn успешно перезапущена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
    
    info_message "Отображение логов ноды..."
    $DOCKER_COMPOSE_CMD logs swarm_node
}

# Функция для удаления ноды
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды Gensyn...${NC}\n"
    
    if [ ! -d "$HOME/rl-swarm" ]; then
        warning_message "Директория ноды не найдена. Возможно, нода уже удалена."
        return 0
    fi
    
    cd rl-swarm
    
    # Определяем правильный формат команды docker-compose
    check_docker_compose_format
    
    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка контейнеров...${NC}"
    $DOCKER_COMPOSE_CMD down -v
    success_message "Контейнеры остановлены и удалены"
    
    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
    cd $HOME
    rm -rf $HOME/rl-swarm
    success_message "Директория ноды удалена"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ Нода Gensyn успешно удалена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Основной цикл программы
while true; do
    clear
    # Отображение логотипа
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
    
    print_menu
    echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-6]:${NC} "
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
            remove_node
            ;;
        6)
            echo -e "\n${GREEN}👋 До свидания!${NC}\n"
            exit 0
            ;;
        *)
            echo -e "\n${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 6.${NC}\n"
            ;;
    esac
    
    if [[ "$choice" != "3" ]]; then
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    fi
done
