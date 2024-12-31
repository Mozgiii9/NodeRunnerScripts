#!/bin/bash

# Определение цветов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # Без цвета

# Показ логотипа
echo "Загрузка анимации... 🎬"
wget -O loader.sh https://raw.githubusercontent.com/MandaNode/main/WM/loader.sh && chmod +x loader.sh && sed -i 's/\r$//' loader.sh && ./loader.sh
wget -O logo.sh https://raw.githubusercontent.com/MandaNode/main/WM/logo.sh && chmod +x logo.sh && sed -i 's/\r$//' logo.sh && ./logo.sh
rm -rf logo.sh loader.sh
sleep 4

# Перехват прерывания скрипта
trap 'echo -e "${RED}Скрипт прерван.${NC}"; exit 1' INT TERM

# Функции для вывода цветных сообщений
print_status() {
    echo -e "${BLUE}[*] ${NC}$1"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Проверка наличия команды
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Проверка системных требований
check_system() {
    print_status "Проверка системных требований... 🔍"
    
    if [[ $EUID -ne 0 ]]; then
        print_warning "Этот скрипт должен быть запущен с правами root или через sudo 🔐"
        exit 1
    fi

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        if [[ "$ID" != "ubuntu" ]]; then
            print_warning "Скрипт оптимизирован для Ubuntu. Ваша система: $ID 💻"
        fi
    fi
}

# Проверка системных ресурсов
check_resources() {
    print_status "Проверка системных ресурсов... 📊"
    
    total_mem=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$total_mem" -lt 4 ]; then
        print_warning "Рекомендуется минимум 4ГБ ОЗУ, у вас ${total_mem}ГБ 🧮"
    fi
    
    free_space=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "${free_space%.*}" -lt 10 ]; then
        print_warning "Мало места на диске. Рекомендуется минимум 10ГБ свободного места 💾"
    fi
}

# Проверка обновлений
check_updates() {
    print_status "Проверка обновлений... 🔄"
    
    if [ -d "hemi-go" ]; then
        cd hemi-go
        git fetch origin
        local_version=$(git rev-parse HEAD)
        remote_version=$(git rev-parse origin/main)
        
        if [ "$local_version" != "$remote_version" ]; then
            print_warning "Доступна новая версия. Обновить? (y/n) 🆕"
            read -r update_choice
            if [[ "$update_choice" =~ ^[Yy]$ ]]; then
                git pull origin main
                print_success "Обновлено до последней версии ✨"
            fi
        fi
        cd ..
    fi
}

# Установка необходимых компонентов
install_prerequisites() {
    print_status "Установка необходимых компонентов... 📦"
    
    apt-get update -qq
    
    PACKAGES="git make snapd curl jq htop"
    apt-get install -y $PACKAGES
    
    if ! command_exists go; then
        print_status "Установка Go... 🔧"
        snap install go --classic
    fi
    
    print_success "Компоненты успешно установлены 🎉"
}

# Резервное копирование конфигурации
backup_env() {
    if [ -f ".env" ]; then
        backup_dir="$HOME/.hemi_backup"
        mkdir -p "$backup_dir"
        cp .env "$backup_dir/.env.backup_$(date +%Y%m%d_%H%M%S)"
        print_success "Создана резервная копия файла конфигурации 💾"
    fi
}

# Настройка базового майнера
setup_hemi() {
    print_status "Настройка базового майнера... ⚙️"
    
    BASE_DIR="$HOME/hemi-miners"
    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR"

    if [ ! -d "hemi-go-base" ]; then
        if ! git clone https://github.com/MandaNode/hemi-go.git hemi-go-base; then
            print_error "Не удалось клонировать репозиторий. Повторная попытка... 🔄"
            sleep 2
            git clone https://github.com/MandaNode/hemi-go.git hemi-go-base
        fi
    fi
}

# Создание экземпляра аккаунта
create_account_instance() {
    local account_name="$1"
    local account_dir="$BASE_DIR/hemi-$account_name"
    
    print_status "Создание экземпляра для аккаунта: $account_name 📝"
    
    if [ ! -d "$account_dir" ]; then
        cp -r "$BASE_DIR/hemi-go-base" "$account_dir"
        cd "$account_dir"
        
        cat > .env << EOL
POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
EVM_PRIVKEY=ваш_приватный_ключ_evm_кошелька
POPM_BTC_PRIVKEY=ваш_приватный_ключ_btc_кошелька
POPM_STATIC_FEE=1
EOL
        
        read -p "Хотите обновить комиссию? (y/n): " update_fee
        if [[ "$update_fee" =~ ^[Yy]$ ]]; then
            check_and_set_fees
        fi
        
        print_warning "Пожалуйста, настройте ключи кошельков для $account_name 🔑"
        sleep 1
        nano .env
        
        chmod +x start_popmd.sh
        print_success "Экземпляр $account_name успешно создан ✅"
    else
        print_warning "Экземпляр $account_name уже существует ⚠️"
    fi
}

# Управление аккаунтами
manage_accounts() {
    while true; do
        clear
        echo -e "${PURPLE}================================${NC}"
        echo -e "${CYAN}    Менеджер Майнинг-Аккаунтов    ${NC}"
        echo -e "${PURPLE}================================${NC}"
        echo -e "${YELLOW}1. Создать новый аккаунт 📝${NC}"
        echo -e "${YELLOW}2. Список всех аккаунтов 📋${NC}"
        echo -e "${YELLOW}3. Запустить определенный аккаунт ▶️${NC}"
        echo -e "${YELLOW}4. Запустить все аккаунты ⏯️${NC}"
        echo -e "${YELLOW}5. Остановить определенный аккаунт ⏹️${NC}"
        echo -e "${YELLOW}6. Остановить все аккаунты ⏏️${NC}"
        echo -e "${YELLOW}7. Проверить статус аккаунтов 📊${NC}"
        echo -e "${YELLOW}8. Редактировать конфигурацию аккаунта ⚙️${NC}"
        echo -e "${YELLOW}9. Мониторинг производительности 📈${NC}"
        echo -e "${YELLOW}10. Удалить аккаунт ❌${NC}"
        echo -e "${YELLOW}11. Выход 🚪${NC}"
        
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                read -p "Введите имя аккаунта (например, acc1): " acc_name
                create_account_instance "$acc_name"
                ;;
            2)
                list_accounts
                ;;
            3)
                list_accounts
                read -p "Введите имя аккаунта для запуска: " acc_name
                start_specific_account "$acc_name"
                ;;
            4)
                start_all_accounts
                ;;
            5)
                list_accounts
                read -p "Введите имя аккаунта для остановки: " acc_name
                stop_specific_account "$acc_name"
                ;;
            6)
                stop_all_accounts
                ;;
            7)
                check_accounts_status
                ;;
            8)
                edit_account_config
                ;;
            9)
                monitor_all_accounts
                ;;
            10)
                delete_account_instance
                ;;
            11)
                print_success "Выход из менеджера аккаунтов 👋"
                exit 0
                ;;
            *)
                print_error "Неверная опция ❌"
                ;;
        esac
        
        read -p "Нажмите Enter для продолжения..."
    done
}

# Список всех аккаунтов
list_accounts() {
    print_status "Доступные аккаунты: 📋"
    for dir in "$BASE_DIR"/hemi-*/; do
        if [ -d "$dir" ]; then
            account_name=$(basename "$dir" | sed 's/hemi-//')
            if [ "$account_name" = "go-base" ]; then
                continue
            fi
            
            if screen -ls | grep -q "hemi-$account_name"; then
                echo -e "${GREEN}● ${account_name} (Работает)${NC} ✅"
            else
                echo -e "${RED}○ ${account_name} (Остановлен)${NC} ⏹️"
            fi
        fi
    done
}

# Запуск определенного аккаунта
start_specific_account() {
    local account_name="$1"
    local account_dir="$BASE_DIR/hemi-$account_name"
    
    if [ -d "$account_dir" ]; then
        cd "$account_dir"
        screen -dmS "hemi-$account_name" ./start_popmd.sh
        print_success "Запущен майнер для аккаунта $account_name ▶️"
    else
        print_error "Аккаунт $account_name не найден ❌"
    fi
}

# Запуск всех аккаунтов
start_all_accounts() {
    for dir in "$BASE_DIR"/hemi-*/; do
        if [ -d "$dir" ]; then
            account_name=$(basename "$dir" | sed 's/hemi-//')
            if [ "$account_name" != "go-base" ]; then
                start_specific_account "$account_name"
            fi
        fi
    done
}

# Остановка определенного аккаунта
stop_specific_account() {
    local account_name="$1"
    
    if screen -ls | grep -q "hemi-$account_name"; then
        screen -S "hemi-$account_name" -X quit
        pkill -f "hemi-$account_name/start_popmd"
        print_success "Остановлен майнер для аккаунта $account_name ⏹️"
    else
        print_warning "Не найдена запущенная сессия для $account_name ⚠️"
    fi
}

# Остановка всех аккаунтов
stop_all_accounts() {
    for dir in "$BASE_DIR"/hemi-*/; do
        if [ -d "$dir" ]; then
            account_name=$(basename "$dir" | sed 's/hemi-//')
            if [ "$account_name" != "go-base" ]; then
                stop_specific_account "$account_name"
            fi
        fi
    done
    print_success "Остановлены все майнеры ⏏️"
}

# Мониторинг всех аккаунтов
monitor_all_accounts() {
    print_status "Мониторинг всех аккаунтов (Нажмите Ctrl+C для остановки)... 📊"
    while true; do
        clear
        echo -e "${PURPLE}================================${NC}"
        echo -e "${CYAN}    Монитор Производительности    ${NC}"
        echo -e "${PURPLE}================================${NC}"
        
        for dir in "$BASE_DIR"/hemi-*/; do
            if [ -d "$dir" ]; then
                account_name=$(basename "$dir" | sed 's/hemi-//')
                if [ "$account_name" = "go-base" ]; then
                    continue
                fi
                
                if screen -ls | grep -q "hemi-$account_name"; then
                    echo -e "${GREEN}● ${account_name}${NC} ✅"
                    if pgrep -f "hemi-$account_name/start_popmd" > /dev/null; then
                        pid=$(pgrep -f "hemi-$account_name/start_popmd")
                        cpu=$(ps -p $pid -o %cpu | tail -n 1)
                        mem=$(ps -p $pid -o %mem | tail -n 1)
                        echo -e "   CPU: ${cpu}% | Память: ${mem}% 📈"
                    fi
                else
                    echo -e "${RED}○ ${account_name} (Остановлен)${NC} ⏹️"
                fi
            fi
        done
        
        sleep 5
