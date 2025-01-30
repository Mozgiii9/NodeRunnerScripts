#!/bin/bash

# Цветовые коды для вывода в терминал
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_BLUE='\033[0;34m'
NC='\033[0m'

# Функция для печати цветного текста
print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

# Функция для отображения логотипа
display_logo() {
    curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
}

# Функция для изменения Chain ID в конфигурационном файле mainnet
update_mainnet_chain_ids() {
    local config_path="$HOME/abstract-node/external-node/mainnet-external-node.yml"
    print_color "$COLOR_BLUE" "🔧 Обновляем Chain ID в конфигурации mainnet..."
    
    # Проверяем существование файла
    if [ ! -f "$config_path" ]; then
        print_color "$COLOR_RED" "❌ Файл конфигурации не найден: $config_path"
        return 1
    fi
    
    # Создаем временный файл
    local temp_file="${config_path}.tmp"
    
    # Заменяем значения Chain ID
    sed -e 's/l1_chain_id: .*/l1_chain_id: 1/' \
        -e 's/l2_chain_id: .*/l2_chain_id: 2741/' \
        "$config_path" > "$temp_file"
    
    # Проверяем успешность операции
    if [ $? -eq 0 ]; then
        mv "$temp_file" "$config_path"
        print_color "$COLOR_GREEN" "✅ Chain ID успешно обновлены в mainnet конфигурации"
    else
        print_color "$COLOR_RED" "❌ Ошибка при обновлении Chain ID"
        rm -f "$temp_file"
        return 1
    fi
}

# Функция проверки установки Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_color "$COLOR_RED" "🔍 Docker не установлен. Устанавливаем Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo systemctl enable docker
        sudo systemctl start docker
    else
        print_color "$COLOR_GREEN" "✅ Docker уже установлен"
    fi
}

# Функция проверки установки Docker Compose
check_docker_compose() {
    if ! command -v docker compose &> /dev/null; then
        print_color "$COLOR_RED" "🔍 Docker Compose не установлен. Устанавливаем Docker Compose..."
        sudo apt update
        sudo apt install -y docker-compose-plugin
    else
        print_color "$COLOR_GREEN" "✅ Docker Compose уже установлен"
    fi
}

# Функция установки ноды Abstract
install_node() {
    local network=$1
    
    print_color "$COLOR_BLUE" "📥 Клонируем репозиторий..."
    git clone https://github.com/Abstract-Foundation/abstract-node
    cd abstract-node/external-node
    
    if [ "$network" == "testnet" ]; then
        print_color "$COLOR_BLUE" "🚀 Запускаем testnet ноду..."
        docker compose -f testnet-external-node.yml up -d
    else
        update_mainnet_chain_ids
        print_color "$COLOR_BLUE" "🚀 Запускаем mainnet ноду..."
        docker compose -f mainnet-external-node.yml up -d
    fi
    
    print_color "$COLOR_GREEN" "✅ Установка ноды завершена!"
}

# Функция просмотра логов контейнера
check_logs() {
    echo "📋 Доступные контейнеры:"
    docker ps --format "{{.Names}}"
    echo
    read -p "Введите имя контейнера для просмотра логов: " container_name
    
    if [ -n "$container_name" ]; then
        docker logs -f --tail=100 "$container_name"
    else
        print_color "$COLOR_RED" "❌ Имя контейнера не указано"
    fi
}

# Функция сброса состояния ноды
reset_node() {
    local network=$1
    
    print_color "$COLOR_YELLOW" "🔄 Сбрасываем состояние ноды..."
    cd ~/abstract-node/external-node
    if [ "$network" == "testnet" ]; then
        docker compose -f testnet-external-node.yml down --volumes
    else
        docker compose -f mainnet-external-node.yml down --volumes
    fi
    
    print_color "$COLOR_GREEN" "✅ Сброс ноды завершен!"
}

# Функция перезапуска контейнера
restart_container() {
    echo "📋 Доступные контейнеры:"
    docker ps --format "{{.Names}}"
    echo
    read -p "Введите имя контейнера для перезапуска: " container_name
    
    if [ -n "$container_name" ]; then
        print_color "$COLOR_YELLOW" "🔄 Перезапускаем контейнер $container_name..."
        docker restart "$container_name"
        print_color "$COLOR_GREEN" "✅ Контейнер успешно перезапущен!"
    else
        print_color "$COLOR_RED" "❌ Имя контейнера не указано"
    fi
}

# Функция полного удаления ноды
remove_node() {
    print_color "$COLOR_YELLOW" "⚠️ Внимание! Это действие удалит все контейнеры и данные ноды!"
    read -p "Вы уверены, что хотите продолжить? (y/n): " confirm
    
    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
        print_color "$COLOR_BLUE" "🗑️ Удаляем контейнеры..."
        cd ~/abstract-node/external-node
        docker compose -f testnet-external-node.yml down --volumes
        docker compose -f mainnet-external-node.yml down --volumes
        
        print_color "$COLOR_BLUE" "🗑️ Удаляем файлы ноды..."
        cd ~/
        rm -rf abstract-node
        
        print_color "$COLOR_GREEN" "✅ Нода успешно удалена!"
    else
        print_color "$COLOR_YELLOW" "🛑 Операция отменена"
    fi
}

# Главное меню скрипта
main_menu() {
    while true; do
        clear
        display_logo
        echo
        print_color "$COLOR_BLUE" "=== 🌟 Меню установки ноды Abstract === "
        echo "1. 🛠️  Установить необходимые компоненты (Docker и Docker Compose)"
        echo "2. 🌐 Установить Testnet ноду"
        echo "3. 🌍 Установить Mainnet ноду"
        echo "4. 📋 Просмотр логов контейнера"
        echo "5. 🔄 Сбросить Testnet ноду"
        echo "6. 🔄 Сбросить Mainnet ноду"
        echo "7. 🔃 Перезапустить контейнер"
        echo "8. 🗑️  Удалить ноду"
        echo "9. 🚪 Выход"
        echo
        read -p "Выберите опцию (1-9): " choice
        
        case $choice in
            1)
                check_docker
                check_docker_compose
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                install_node "testnet"
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                install_node "mainnet"
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                check_logs
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                reset_node "testnet"
                read -p "Нажмите Enter для продолжения..."
                ;;
            6)
                reset_node "mainnet"
                read -p "Нажмите Enter для продолжения..."
                ;;
            7)
                restart_container
                read -p "Нажмите Enter для продолжения..."
                ;;
            8)
                remove_node
                read -p "Нажмите Enter для продолжения..."
                ;;
            9)
                print_color "$COLOR_GREEN" "👋 Спасибо за использование установщика Abstract Node!"
                exit 0
                ;;
            *)
                print_color "$COLOR_RED" "❌ Неверная опция. Попробуйте снова."
                read -p "Нажмите Enter для продолжения..."
                ;;
        esac
    done
}

# Запуск главного меню
main_menu
