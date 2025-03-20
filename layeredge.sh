#!/bin/bash

# LayerEdge CLI Light Node - Скрипт автоматической установки

set -e
clear 

# Цвета для лучшей читаемости
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # Без цвета

# Функции для отображения сообщений
success_message() {
    echo -e "${GREEN}✅ $1${NC}"
}

info_message() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

error_message() {
    echo -e "${RED}❌ $1${NC}"
}

warning_message() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

# Функция отображения логотипа
display_logo() {
    clear
    # Загрузка логотипа из репозитория
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash || {
        # Если загрузка не удалась, отображаем стандартный логотип
        echo -e "${BOLD}${PURPLE}"
        echo -e "╔═══════════════════════════════════════════════╗"
        echo -e "║                 LAYER EDGE                    ║"
        echo -e "║               LIGHT NODE (CLI)                ║"
        echo -e "╚═══════════════════════════════════════════════╝${NC}"
    }
    
    # Дополнительная информация о ноде
    echo -e "\n${BOLD}${CYAN}════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${CYAN}       Инструмент управления Layer Edge         ${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════${NC}\n"
}

# Функция очистки для удаления существующих установок
cleanup() {
    info_message "Очистка предыдущих установок..."
    # Удаляем директорию light-node, если она существует
    if [ -d "light-node" ]; then
        rm -rf light-node
    fi
    # Останавливаем все процессы, связанные с light-node или merkle service
    pkill -f './light-node' 2>/dev/null || true
    pkill -f 'cargo run' 2>/dev/null || true
    # Удаляем временные файлы Go
    rm -f go1.24.1.linux-amd64.tar.gz 2>/dev/null
    success_message "Очистка завершена."
}

# Функция для настройки файрвола (ufw)
configure_firewall() {
    info_message "Настройка файрвола (ufw) для разрешения необходимых портов..."
    # Проверяем, установлен ли ufw
    if ! command -v ufw >/dev/null 2>&1; then
        info_message "Установка ufw..."
        sudo apt-get update
        sudo apt-get install -y ufw
    fi
    # Включаем ufw, если он не активен
    sudo ufw status | grep -q "Status: active" || sudo ufw enable
    # Разрешаем необходимые порты
    sudo ufw allow 3001/tcp  # ZK Prover (Merkle service)
    sudo ufw allow 8080/tcp  # Points API
    sudo ufw allow 9090/tcp  # gRPC endpoint
    success_message "Файрвол настроен. Разрешенные порты: 3001, 8080, 9090."
}

# Функция для проверки существования команды
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Проверка зависимостей
check_dependencies() {
    info_message "Проверка зависимостей..."

    # Проверка Go - обновлено до версии 1.24.1
    if ! command_exists go || [[ $(go version) != *"go1.24"* ]]; then
        info_message "Установка Go 1.24.1..."
        wget https://go.dev/dl/go1.24.1.linux-amd64.tar.gz
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf go1.24.1.linux-amd64.tar.gz
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        echo 'export GOPATH=$HOME/go' >> ~/.bashrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
        source ~/.bashrc
        rm -f go1.24.1.linux-amd64.tar.gz
    fi
    
    # Проверка версии Go
    go version
    if [[ $(go version) != *"go1.24"* ]]; then
        warning_message "Внимание: Версия Go может отличаться от 1.24. Текущая версия: $(go version)"
        info_message "Пытаемся использовать корректную версию..."
        export PATH="/usr/local/go/bin:$PATH"
    fi

    # Проверка Rust
    if ! command_exists rustc; then
        info_message "Установка Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    # Проверка и установка Risc0 Toolchain
    if ! command_exists rzup; then
        info_message "Установка Risc0 Toolchain (rzup)..."
        curl -L https://risczero.com/install | bash || { error_message "Установка Risc0 не удалась"; exit 1; }
        export PATH="$HOME/.risc0/bin:$PATH"
        echo 'export PATH="$HOME/.risc0/bin:$PATH"' >> ~/.bashrc
    fi

    # Убедимся, что компоненты Risc0 toolchain установлены
    info_message "Проверка компонентов Risc0 toolchain..."
    rzup install || { error_message "Ошибка: Не удалось установить компоненты Risc0 toolchain."; exit 1; }
    
    # Проверка rzup и toolchain
    if ! command -v rzup >/dev/null 2>&1; then
        error_message "Ошибка: rzup не найден после установки."
        exit 1
    fi
    success_message "Risc0 Toolchain проверен: $(rzup --version)"
    success_message "Все зависимости установлены"
}

# Клонирование репозитория и навигация
setup_repository() {
    info_message "Клонирование репозитория LayerEdge Light Node..."
    git clone https://github.com/Layer-Edge/light-node.git
    cd light-node || exit
}

# Получение приватного ключа пользователя и настройка окружения
configure_environment() {
    echo -e "\n${BOLD}${CYAN}Настройка окружения:${NC}"
    # Принудительное чтение из терминала, а не из перенаправленного stdin
    read -p "$(echo -e ${BOLD}${YELLOW}"Введите ваш приватный ключ для ноды: "${NC})" private_key < /dev/tty || {
        error_message "Ошибка: Не удалось прочитать ввод. Запустите скрипт в интерактивном терминале."
        exit 1
    }
    echo

    if [ -z "$private_key" ]; then
        error_message "Ошибка: Приватный ключ не введен. Пожалуйста, попробуйте снова."
        exit 1
    fi

    success_message "Приватный ключ получен."

    cat > .env << EOL
GRPC_URL=34.31.74.109:9090
CONTRACT_ADDR=cosmos1ufs3tlq4umljk0qfe8k5ya0x6hpavn897u2cnf9k0en9jr7qarqqt56709
ZK_PROVER_URL=http://127.0.0.1:3001
API_REQUEST_TIMEOUT=100
POINTS_API=http://127.0.0.1:8080
PRIVATE_KEY=$private_key
EOL

    source .env
    success_message "Файл конфигурации .env создан."
}

# Сборка и запуск сервиса Merkle
start_merkle_service() {
    info_message "Сборка и запуск сервиса Merkle..."
    cd risc0-merkle-service || exit
    cargo build || { error_message "Ошибка: Не удалось собрать risc0-merkle-service."; exit 1; }
    
    # Запуск в фоновом режиме
    cargo run &
    MERKLE_PID=$!
    
    # Ожидание запуска сервиса
    info_message "Ожидание запуска сервиса Merkle на порту 3001..."
    timeout 30s bash -c "until curl -s http://127.0.0.1:3001/process >/dev/null 2>&1; do sleep 1; done" || {
        error_message "Ошибка: Сервис Merkle не запустился в течение 30 секунд."
        kill $MERKLE_PID 2>/dev/null
        exit 1
    }
    success_message "Сервис Merkle запущен и работает."
    cd ..
}

# Сборка и запуск Light Node
run_light_node() {
    info_message "Сборка и запуск LayerEdge Light Node..."
    go build
    ./light-node &
    NODE_PID=$!
    success_message "Light Node запущен успешно."
}

# Отображение информации о подключении
show_connection_info() {
    echo -e "\n${BOLD}${GREEN}Установка завершена!${NC}"
    echo -e "${CYAN}Ваша нода запущена с настроенным приватным ключом кошелька${NC}"
    echo -e "${CYAN}Для подключения к панели управления:${NC}"
    echo -e "${WHITE}1. Посетите: dashboard.layeredge.io${NC}"
    echo -e "${WHITE}2. Подключите ваш кошелек${NC}"
    echo -e "${WHITE}3. Привяжите публичный ключ вашей ноды${NC}"
    echo -e "\n${CYAN}Для проверки поинтов используйте API:${NC}"
    echo -e "${WHITE}https://light-node.layeredge.io/api/cli-node/points/{walletAddress}${NC}"
    echo -e "\n${CYAN}Для поддержки присоединяйтесь: discord.gg/layeredge${NC}"
}

# Функция отображения меню
print_menu() {
    display_logo
    
    # Проверка статуса ноды
    if [ -d "light-node" ]; then
        echo -e "${BOLD}${WHITE}Статус LayerEdge Light Node: ${GREEN}Установлена${NC}"
        
        # Проверка PID процессов
        if pgrep -f "risc0-merkle-service" > /dev/null; then
            MERKLE_STATUS="${GREEN}Запущен${NC}"
        else
            MERKLE_STATUS="${RED}Остановлен${NC}"
        fi
        
        if pgrep -f "./light-node" > /dev/null; then
            NODE_STATUS="${GREEN}Запущен${NC}"
        else
            NODE_STATUS="${RED}Остановлен${NC}"
        fi
        
        echo -e "${BOLD}${WHITE}Статус Merkle Service: $MERKLE_STATUS${NC}"
        echo -e "${BOLD}${WHITE}Статус Light Node: $NODE_STATUS${NC}"
    else
        echo -e "${BOLD}${WHITE}Статус LayerEdge Light Node: ${RED}Не установлена${NC}"
    fi
    
    echo -e "\n${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    
    if [ -d "light-node" ]; then
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🚀 Запустить ноду${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}⏹️ Остановить ноду${NC}"
        echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🔁 Перезапустить ноду${NC}"
        echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Обновить ноду${NC}"
        echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}📋 Просмотр логов${NC}"
        echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удалить ноду${NC}"
        echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}"
    else
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}📥 Установить LayerEdge Light Node${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}"
    fi
    
    echo
}

# Запуск ноды
start_node() {
    info_message "Запуск LayerEdge Light Node..."
    cd light-node || { error_message "Директория light-node не найдена."; return 1; }
    
    # Проверка, запущены ли уже сервисы
    if pgrep -f "risc0-merkle-service" > /dev/null && pgrep -f "./light-node" > /dev/null; then
        info_message "Нода уже запущена."
        return 0
    fi
    
    # Запуск Merkle сервиса
    if ! pgrep -f "risc0-merkle-service" > /dev/null; then
        cd risc0-merkle-service || exit
        cargo run &
        MERKLE_PID=$!
        cd ..
        success_message "Сервис Merkle запущен (PID: $MERKLE_PID)"
    fi
    
    # Запуск Light Node
    if ! pgrep -f "./light-node" > /dev/null; then
        ./light-node &
        NODE_PID=$!
        success_message "Light Node запущен (PID: $NODE_PID)"
    fi
    
    cd ..
    success_message "LayerEdge Light Node успешно запущен!"
}

# Остановка ноды
stop_node() {
    info_message "Остановка LayerEdge Light Node..."
    
    # Остановка Light Node
    if pgrep -f "./light-node" > /dev/null; then
        pkill -f "./light-node"
        success_message "Light Node остановлен."
    else
        info_message "Light Node уже остановлен."
    fi
    
    # Остановка Merkle сервиса
    if pgrep -f "risc0-merkle-service" > /dev/null; then
        pkill -f "risc0-merkle-service"
        success_message "Сервис Merkle остановлен."
    else
        info_message "Сервис Merkle уже остановлен."
    fi
    
    success_message "LayerEdge Light Node успешно остановлен!"
}

# Перезапуск ноды
restart_node() {
    info_message "Перезапуск LayerEdge Light Node..."
    
    # Остановка сервисов
    stop_node
    
    # Небольшая пауза перед запуском
    sleep 2
    
    # Запуск сервисов
    start_node
    
    success_message "LayerEdge Light Node успешно перезапущен!"
}

# Обновление ноды
update_node() {
    info_message "Обновление LayerEdge Light Node..."
    
    # Проверка существования директории
    if [ ! -d "light-node" ]; then
        error_message "LayerEdge Light Node не установлен."
        return 1
    fi
    
    # Остановка сервисов
    stop_node
    
    # Обновление репозитория
    cd light-node || exit
    info_message "Получение последних изменений..."
    git pull
    
    # Пересборка компонентов
    info_message "Пересборка компонентов..."
    cd risc0-merkle-service || exit
    cargo build
    cd ..
    
    go build
    
    success_message "LayerEdge Light Node успешно обновлен!"
    
    # Запрос на запуск ноды
    echo -e "${YELLOW}Хотите запустить обновленную ноду? (y/n)${NC}"
    read -p "> " start_choice
    
    if [[ "$start_choice" == "y" || "$start_choice" == "Y" ]]; then
        start_node
    fi
    
    cd ..
}

# Просмотр логов
view_logs() {
    echo -e "${BOLD}${CYAN}Выберите логи для просмотра:${NC}"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}Логи Merkle сервиса${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}Логи Light Node${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}Вернуться в главное меню${NC}"
    
    read -p "$(echo -e ${BOLD}${BLUE}"Введите ваш выбор [1-3]: "${NC})" log_choice
    
    case $log_choice in
        1)
            echo -e "${BOLD}${CYAN}═════════════════ Логи Merkle сервиса ═════════════════${NC}"
            if [ -d "light-node" ]; then
                cd light-node/risc0-merkle-service || exit
                # Отображаем последние логи из journalctl или из файла
                if pgrep -f "risc0-merkle-service" > /dev/null; then
                    ps -ef | grep "risc0-merkle-service" | grep -v grep
                else
                    echo "Сервис Merkle не запущен."
                fi
                cd ../..
            else
                echo "Директория light-node не найдена."
            fi
            ;;
        2)
            echo -e "${BOLD}${CYAN}═════════════════ Логи Light Node ═════════════════${NC}"
            if [ -d "light-node" ]; then
                cd light-node || exit
                # Отображаем последние логи из journalctl или из файла
                if pgrep -f "./light-node" > /dev/null; then
                    ps -ef | grep "./light-node" | grep -v grep
                else
                    echo "Light Node не запущен."
                fi
                cd ..
            else
                echo "Директория light-node не найдена."
            fi
            ;;
        3)
            return 0
            ;;
        *)
            error_message "Неверный выбор. Попробуйте еще раз."
            sleep 1
            view_logs
            ;;
    esac
}

# Удаление ноды
remove_node() {
    echo -e "${BOLD}${RED}ВНИМАНИЕ: Это полностью удалит LayerEdge Light Node.${NC}"
    read -p "$(echo -e ${BOLD}${YELLOW}"Вы уверены, что хотите продолжить? (y/n): "${NC})" confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        info_message "Операция отменена."
        return 0
    fi
    
    info_message "Удаление LayerEdge Light Node..."
    
    # Остановка сервисов
    stop_node
    
    # Удаление директории
    if [ -d "light-node" ]; then
        rm -rf light-node
        success_message "LayerEdge Light Node успешно удален!"
    else
        error_message "Директория light-node не найдена."
    fi
}

# Основная функция установки
install_node() {
    display_logo
    info_message "Начинаем установку LayerEdge Light Node..."
    
    # Очистка и настройка
    cleanup
    configure_firewall
    
    # Проверка зависимостей
    check_dependencies
    
    # Установка ноды
    setup_repository
    configure_environment
    
    # Сборка и запуск компонентов
    start_merkle_service
    run_light_node
    
    # Вывод информации о подключении
    show_connection_info
    
    success_message "Установка завершена успешно!"
    info_message "PID сервиса Merkle: $MERKLE_PID"
    info_message "PID Light Node: $NODE_PID"
    info_message "Для остановки сервисов используйте: kill $MERKLE_PID $NODE_PID или выберите соответствующую опцию в меню"
    
    cd ..
}

# Обработка ошибок
trap 'echo -e "${RED}⚠️ Произошла ошибка. Установка не удалась.${NC}"; exit 1' ERR

# Основной цикл
main() {
    while true; do
        print_menu
        
        if [ -d "light-node" ]; then
            read -p "$(echo -e ${BOLD}${BLUE}"Введите номер действия [1-7]: "${NC})" choice
            
            case $choice in
                1) start_node ;;
                2) stop_node ;;
                3) restart_node ;;
                4) update_node ;;
                5) view_logs ;;
                6) remove_node ;;
                7) success_message "Спасибо за использование LayerEdge Light Node CLI!"; exit 0 ;;
                *) error_message "Неверный выбор. Попробуйте еще раз."; sleep 1 ;;
            esac
        else
            read -p "$(echo -e ${BOLD}${BLUE}"Введите номер действия [1-2]: "${NC})" choice
            
            case $choice in
                1) install_node ;;
                2) success_message "Спасибо за использование LayerEdge Light Node CLI!"; exit 0 ;;
                *) error_message "Неверный выбор. Попробуйте еще раз."; sleep 1 ;;
            esac
        fi
        
        echo -e "\nНажмите Enter, чтобы вернуться в меню..."
        read
    done
}

main
