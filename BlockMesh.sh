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

# Функция обновления системы
update_system() {
    log "🔄 Обновление системных пакетов..."
    apt update && apt upgrade -y
    success "Система успешно обновлена"
}

# Функция очистки
cleanup() {
    log "🧹 Очистка старых файлов..."
    rm -rf blockmesh-cli.tar.gz target
    success "Очистка завершена"
}

# Функция установки Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        log "🐳 Установка Docker..."
        apt-get install -y \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
        success "Docker успешно установлен"
    else
        success "Docker уже установлен"
    fi
}

# Функция установки Docker Compose
install_docker_compose() {
    log "🐋 Установка Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    success "Docker Compose успешно установлен"
}

# Функция установки BlockMesh CLI
install_blockmesh_cli() {
    log "📦 Создание директории для установки..."
    mkdir -p target/release

    log "📥 Загрузка и распаковка BlockMesh CLI..."
    curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.444/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
    tar -xzf blockmesh-cli.tar.gz --strip-components=3 -C target/release

    if [[ ! -f target/release/blockmesh-cli ]]; then
        error "Исполняемый файл blockmesh-cli не найден в target/release"
    fi
    
    success "BlockMesh CLI успешно установлен"
}

# Функция настройки и запуска BlockMesh
configure_and_run() {
    log "⚙️ Настройка BlockMesh..."
    
    echo -e "${YELLOW}⌨️  Введите ваш email BlockMesh:${NC}"
    read email
    
    echo -e "${YELLOW}⌨️  Введите ваш пароль BlockMesh:${NC}"
    read -s password
    echo

    log "🚀 Создание и запуск контейнера BlockMesh..."
    docker run -it --rm \
        --name blockmesh-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"
    
    success "BlockMesh успешно настроен и запущен"
}

# Функция полной установки
full_install() {
    update_system
    cleanup
    install_docker
    install_docker_compose
    install_blockmesh_cli
    configure_and_run
}

# Функция отображения меню
show_menu() {
    clear
    show_logo
    echo -e "${BLUE}╭───────────────────────────────────╮${NC}"
    echo -e "${BLUE}│   🌟 Управление нодой BlockMesh  │${NC}"
    echo -e "${BLUE}╰───────────────────────────────────╯${NC}"
    echo -e "1. 🚀 Полная установка"
    echo -e "2. 🔄 Обновить систему"
    echo -e "3. 🐳 Установить Docker"
    echo -e "4. 🐋 Установить Docker Compose"
    echo -e "5. 📦 Установить BlockMesh CLI"
    echo -e "6. ⚙️ Настроить и запустить BlockMesh"
    echo -e "7. 🧹 Очистить файлы"
    echo -e "8. 🚪 Выход"
    echo
    echo -e "${YELLOW}⌨️  Выберите опцию (1-8):${NC}"
}

# Запуск главного меню
while true; do
    show_menu
    read choice
    
    case $choice in
        1) full_install ;;
        2) update_system ;;
        3) install_docker ;;
        4) install_docker_compose ;;
        5) install_blockmesh_cli ;;
        6) configure_and_run ;;
        7) cleanup ;;
        8)
            log "👋 Выход из установщика..."
            exit 0
            ;;
        *)
            warning "Неверный выбор. Пожалуйста, выберите 1-8"
            ;;
    esac
    
    echo
    echo -e "${YELLOW}⌨️  Нажмите Enter для продолжения...${NC}"
    read
done
