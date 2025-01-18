#!/bin/bash

# Colored output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BLUE='\033[0;34m'

# Проверка наличия curl и установка
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi

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

# Функция проверки статуса выполнения команды
check_error() {
    if [ $? -ne 0 ]; then
        error "$1"
    fi
}

# Функция просмотра логов
show_logs() {
    clear
    log "📋 Запуск просмотра логов... Нажмите Ctrl+C для возврата в меню"
    sleep 2
    sudo journalctl -u vana.service -f
}

# Функция установки базовых зависимостей
install_base_dependencies() {
    clear
    log "🚀 Начало установки базовых зависимостей..."
    
    # Обновление системы
    log "1/8 📦 Обновление системных пакетов..."
    sudo apt update && sudo apt upgrade -y
    check_error "Ошибка обновления системы"
    success "Система успешно обновлена"
    
    # Git
    log "2/8 📥 Установка Git..."
    sudo apt-get install git -y
    check_error "Ошибка установки Git"
    success "Git успешно установлен"
    
    # Unzip
    log "3/8 📦 Установка Unzip..."
    sudo apt install unzip -y
    check_error "Ошибка установки Unzip"
    success "Unzip успешно установлен"
    
    # Nano
    log "4/8 📝 Установка Nano..."
    sudo apt install nano -y
    check_error "Ошибка установки Nano"
    success "Nano успешно установлен"
    
    # Python зависимости
    log "5/8 🐍 Установка зависимостей Python..."
    sudo apt install software-properties-common -y
    check_error "Ошибка установки software-properties-common"
    
    log "➕ Добавление репозитория Python..."
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    check_error "Ошибка добавления репозитория Python"
    
    sudo apt update
    sudo apt install python3.11 -y
    check_error "Ошибка установки Python 3.11"
    
    # Проверка версии Python
    python_version=$(python3.11 --version)
    if [[ $python_version == *"3.11"* ]]; then
        success "Python $python_version успешно установлен"
    else
        error "Ошибка установки Python 3.11"
    fi
    
    # Poetry
    log "6/8 📚 Установка Poetry..."
    sudo apt install python3-pip python3-venv curl -y
    curl -sSL https://install.python-poetry.org | python3 -
    export PATH="$HOME/.local/bin:$PATH"
    source ~/.bashrc
    if command -v poetry &> /dev/null; then
        success "Poetry успешно установлен: $(poetry --version)"
    else
        error "Ошибка установки Poetry"
    fi
    
    # Node.js и npm
    log "7/8 📦 Установка Node.js и npm..."
    curl -fsSL https://fnm.vercel.app/install | bash
    source ~/.bashrc
    fnm use --install-if-missing 22
    check_error "Ошибка установки Node.js"
    
    if command -v node &> /dev/null; then
        success "Node.js успешно установлен: $(node -v)"
    else
        error "Ошибка установки Node.js"
    fi
    
    # Yarn
    log "8/8 🧶 Установка Yarn..."
    apt-get install nodejs -y
    npm install -g yarn
    if command -v yarn &> /dev/null; then
        success "Yarn успешно установлен: $(yarn --version)"
    else
        error "Ошибка установки Yarn"
    fi
    
    log "✨ Все базовые зависимости успешно установлены!"
    echo -e "${YELLOW}⌨️  Нажмите Enter для возврата в главное меню...${NC}"
    read
}

# Функция установки ноды
install_node() {
    clear
    log "Начало установки ноды..."
    
    # Клонирование репозитория
    log "1/5 Клонирование репозитория..."
    if [ -d "vana-dlp-chatgpt" ]; then
        warning "Директория vana-dlp-chatgpt уже существует"
        read -p "Хотите удалить её и склонировать заново? (y/n): " choice
        if [[ $choice == "y" ]]; then
            rm -rf vana-dlp-chatgpt
        else
            error "Невозможно продолжить без чистого репозитория"
        fi
    fi
    
    git clone https://github.com/vana-com/vana-dlp-chatgpt.git
    check_error "Ошибка клонирования репозитория"
    cd vana-dlp-chatgpt
    success "Репозиторий успешно склонирован"
    
    # Создание файла .env
    log "2/5 Создание файла .env..."
    cp .env.example .env
    check_error "Ошибка создания файла .env"
    success "Файл .env создан"
    
    # Установка зависимостей
    log "3/5 Установка зависимостей проекта..."
    poetry install
    check_error "Ошибка установки зависимостей проекта"
    success "Зависимости проекта установлены"
    
    # Установка CLI
    log "4/5 Установка Vana CLI..."
    pip install vana
    check_error "Ошибка установки Vana CLI"
    success "Vana CLI установлен"
    
    # Создание кошелька
    log "5/5 Создание кошелька..."
    vanacli wallet create --wallet.name default --wallet.hotkey default
    check_error "Ошибка создания кошелька"
    
    success "Установка ноды завершена!"
    read -p "Нажмите Enter для возврата в главное меню..."
}

# Функция создания и развертывания DLP
create_and_deploy_dlp() {
    clear
    log "Начало создания и развертывания DLP..."

    # Проверка установки ноды
    log "Проверка установки ноды..."
    if [ ! -d "$HOME/vana-dlp-chatgpt" ]; then
        warning "Директория ноды не найдена в $HOME/vana-dlp-chatgpt"
        log "Проверка текущей рабочей директории..."
        pwd
        log "Содержимое домашней директории:"
        ls -la $HOME
        
        read -p "Хотите переустановить ноду? (y/n): " choice
        if [[ $choice == "y" ]]; then
            install_node
        else
            error "Невозможно продолжить без установленной ноды"
        fi
    fi

    # Регистрация валидатора
    log "1/4 Регистрация валидатора..."
    cd /root/vana-dlp-chatgpt || error "Директория vana-dlp-chatgpt не найдена"
    
    ./vanacli dlp register_validator --stake_amount 10
    check_error "Ошибка регистрации валидатора"
    success "Регистрация валидатора завершена"

    # Подтверждение валидатора
    log "2/4 Подтверждение валидатора..."
    read -p "Введите адрес вашего Hotkey кошелька: " hotkey_address
    
    ./vanacli dlp approve_validator --validator_address="$hotkey_address"
    check_error "Ошибка подтверждения валидатора"
    success "Валидатор подтвержден"

    # Тестирование валидатора
    log "3/4 Тестирование валидатора..."
    poetry run python -m chatgpt.nodes.validator
    
    # Создание и запуск сервиса
    log "4/4 Настройка сервиса валидатора..."
    
    # Поиск пути к poetry
    poetry_path=$(which poetry)
    if [ -z "$poetry_path" ]; then
        error "Poetry не найден в PATH"
    fi
    success "Poetry найден: $poetry_path"

    # Создание файла сервиса
    log "Создание файла сервиса..."
    sudo tee /etc/systemd/system/vana.service << EOF
[Unit]
Description=Сервис Vana Validator
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/vana-dlp-chatgpt
ExecStart=$poetry_path run python -m chatgpt.nodes.validator
Restart=on-failure
RestartSec=10
Environment=PATH=/root/.local/bin:/usr/local/bin:/usr/bin:/bin:/root/vana-dlp-chatgpt/myenv/bin
Environment=PYTHONPATH=/root/vana-dlp-chatgpt

[Install]
WantedBy=multi-user.target
EOF
    check_error "Ошибка создания файла сервиса"
    success "Файл сервиса создан"

    # Запуск сервиса
    log "Запуск сервиса валидатора..."
    sudo systemctl daemon-reload
    sudo systemctl enable vana.service
    sudo systemctl start vana.service
    
    # Проверка статуса сервиса
    service_status=$(sudo systemctl status vana.service)
    if [[ $service_status == *"active (running)"* ]]; then
        success "Сервис валидатора запущен"
    else
        error "Ошибка запуска сервиса валидатора. Проверьте статус командой: sudo systemctl status vana.service"
    fi

    success "Настройка валидатора завершена!"
    read -p "Нажмите Enter для возврата в главное меню..."
}

# Функция удаления ноды
remove_node() {
    clear
    log "Начало процесса удаления ноды..."

    # Остановка сервиса
    log "1/4 Остановка сервиса валидатора..."
    if systemctl is-active --quiet vana.service; then
        sudo systemctl stop vana.service
        sudo systemctl disable vana.service
        success "Сервис валидатора остановлен и отключен"
    else
        warning "Сервис валидатора не был запущен"
    fi

    # Удаление файла сервиса
    log "2/4 Удаление файла сервиса..."
    if [ -f "/etc/systemd/system/vana.service" ]; then
        sudo rm /etc/systemd/system/vana.service
        sudo systemctl daemon-reload
        success "Файл сервиса удален"
    else
        warning "Файл сервиса не найден"
    fi

    # Удаление директории ноды
    log "3/4 Удаление директорий ноды..."
    cd $HOME
    
    if [ -d "vana-dlp-chatgpt" ]; then
        rm -rf vana-dlp-chatgpt
        success "Директория vana-dlp-chatgpt удалена"
    else
        warning "Директория vana-dlp-chatgpt не найдена"
    fi
    
    if [ -d "vana-dlp-smart-contracts" ]; then
        rm -rf vana-dlp-smart-contracts
        success "Директория vana-dlp-smart-contracts удалена"
    else
        warning "Директория vana-dlp-smart-contracts не найдена"
    fi

    # Удаление директории .vana с конфигурацией
    log "4/4 Удаление файлов конфигурации..."
    if [ -d "$HOME/.vana" ]; then
        rm -rf $HOME/.vana
        success "Директория конфигурации .vana удалена"
    else
        warning "Директория конфигурации .vana не найдена"
    fi

    log "Удаление ноды завершено! Теперь вы можете установить новую ноду при необходимости."
    read -p "Нажмите Enter для возврата в главное меню..."
}

# Функция отображения логотипа
show_logo() {
    echo -e "${BLUE}
░▒▓███████▓▒░ ░▒▓██████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░▒▓███████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░ ░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████▓▒░ ░▒▓███████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░ 


 ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓██████████████▓▒░░▒▓██████████████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░░▒▓█▓▒░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░       
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░       
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░   ░▒▓█▓▒░░▒▓█▓▒░       
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░    ░▒▓██████▓▒░        
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░      ░▒▓█▓▒░           
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░      ░▒▓█▓▒░           
 ░▒▓██████▓▒░ ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░  ░▒▓█▓▒░      ░▒▓█▓▒░           
${RESET}"
}

# Функция главного меню
show_menu() {
    clear
    show_logo
    echo -e "${BLUE}╭───────────────────────────────────╮${NC}"
    echo -e "${BLUE}│     🌟 Управление нодой Vana     │${NC}"
    echo -e "${BLUE}╰───────────────────────────────────╯${NC}"
    echo -e "1. 📦 Установить базовые зависимости"
    echo -e "2. 🚀 Установить ноду"
    echo -e "3. 🔨 Создать и развернуть DLP"
    echo -e "4. 🛠️ Установить валидатор"
    echo -e "5. 📝 Зарегистрировать и запустить валидатор"
    echo -e "6. 📋 Просмотр логов валидатора"
    echo -e "7. 🗑️ Удалить ноду"
    echo -e "8. 🚪 Выход"
    echo
    echo -e "${YELLOW}⌨️  Выберите опцию (1-8):${NC} "
    read choice
    
    case $choice in
        1)
            install_base_dependencies
            show_menu
            ;;
        2)
            install_node
            show_menu
            ;;
        3)
            create_and_deploy_dlp
            show_menu
            ;;
        4)
            install_validator
            show_menu
            ;;
        5)
            register_and_start_validator
            show_menu
            ;;
        6)
            show_logs
            show_menu
            ;;
        7)
            remove_node
            show_menu
            ;;
        8)
            log "👋 Выход из установщика..."
            exit 0
            ;;
        *)
            warning "Неверный выбор. Пожалуйста, выберите 1-8"
            read -p "Нажмите Enter для продолжения..."
            show_menu
            ;;
    esac
}

# Запуск скрипта с отображения меню
show_menu
