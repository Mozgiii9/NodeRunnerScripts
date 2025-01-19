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
    
    # Установка NVM
    log "Установка NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    # Загрузка NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Установка Node.js
    nvm install 22
    nvm use 22
    check_error "Ошибка установки Node.js"
    
    if command -v node &> /dev/null; then
        success "Node.js успешно установлен: $(node -v)"
        success "NPM успешно установлен: $(npm -v)"
    else
        error "Ошибка установки Node.js"
    fi
    
    # Yarn
    log "8/8 🧶 Установка Yarn..."
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

    # Детальная проверка директории
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

    # Генерация ключей
    log "1/5 Генерация ключей..."
    cd $HOME/vana-dlp-chatgpt || error "Нет доступа к директории ноды"
    
    log "Текущая директория:"
    pwd
    log "Содержимое директории:"
    ls -la
    
    if [ ! -f "keygen.sh" ]; then
        error "keygen.sh не найден. Содержимое директории некорректно"
    fi
    
    chmod +x keygen.sh
    ./keygen.sh
    check_error "Ошибка генерации ключей"
    success "Ключи успешно сгенерированы"
    warning "Обязательно сохраните все 4 ключа:"
    echo "- public_key.asc и public_key_base64.asc (для UI)"
    echo "- private_key.asc и private_key_base64.asc (для валидатора)"

    # Остановка сервиса ноды если запущен
    log "2/5 Остановка сервиса vana..."
    if systemctl is-active --quiet vana.service; then
        sudo systemctl stop vana.service
        success "Сервис остановлен"
    else
        log "Активный сервис не найден, продолжаем..."
    fi

    # Настройка развертывания смарт-контракта
    log "3/5 Настройка развертывания смарт-контракта..."
    cd $HOME
    if [ -d "vana-dlp-smart-contracts" ]; then
        rm -rf vana-dlp-smart-contracts
    fi
    git clone https://github.com/Josephtran102/vana-dlp-smart-contracts
    cd vana-dlp-smart-contracts || error "Нет доступа к директории смарт-контрактов"
    yarn install
    check_error "Ошибка установки зависимостей смарт-контракта"
    success "Зависимости смарт-контракта установлены"

    # Настройка окружения
    log "4/5 Настройка окружения..."
    cp .env.example .env
    check_error "Ошибка создания файла .env"
    
    echo -e "${YELLOW}Пожалуйста, предоставьте следующую информацию:${NC}"
    read -p "Введите приватный ключ coldkey (с префиксом 0x): " private_key
    read -p "Введите адрес кошелька coldkey (с префиксом 0x): " owner_address
    read -p "Введите название DLP: " dlp_name
    read -p "Введите название токена DLP: " token_name
    read -p "Введите символ токена DLP: " token_symbol

    # Обновление файла .env
    sed -i "s/^DEPLOYER_PRIVATE_KEY=.*/DEPLOYER_PRIVATE_KEY=$private_key/" .env
    sed -i "s/^OWNER_ADDRESS=.*/OWNER_ADDRESS=$owner_address/" .env
    sed -i "s/^DLP_NAME=.*/DLP_NAME=$dlp_name/" .env
    sed -i "s/^DLP_TOKEN_NAME=.*/DLP_TOKEN_NAME=$token_name/" .env
    sed -i "s/^DLP_TOKEN_SYMBOL=.*/DLP_TOKEN_SYMBOL=$token_symbol/" .env
    
    success "Окружение настроено"

    # Развертывание контракта
    log "5/5 Развертывание смарт-контракта..."
    warning "Убедитесь, что у вас есть тестовые токены в кошельках Coldkey и Hotkey перед продолжением"
    read -p "У вас есть тестовые токены и вы хотите продолжить развертывание? (y/n): " proceed
    
    if [[ $proceed == "y" ]]; then
        npx hardhat deploy --network moksha --tags DLPDeploy
        check_error "Ошибка развертывания контракта"
        success "Контракт успешно развернут"
        warning "ВАЖНО: Сохраните адреса DataLiquidityPoolToken и DataLiquidityPool из вывода выше!"
    else
        warning "Развертывание пропущено. Получите тестовые токены и запустите развертывание позже."
    fi

    log "Процесс создания и развертывания DLP завершен!"
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
