#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Функция создания кошелька
create_wallet() {
    local wallet_number=$1
    local output_file=$2
    
    # Создание tBTC кошелька
    ./keygen -secp256k1 -json -net="testnet" > temp_wallet.json
    
    # Извлечение данных из JSON и запись в файл
    echo "=== Wallet #$wallet_number ===" >> "$output_file"
    echo "Private Key: $(jq -r .priv_key temp_wallet.json)" >> "$output_file"
    echo "Public Key: $(jq -r .pub_key temp_wallet.json)" >> "$output_file"
    echo "Public Key Hash: $(jq -r .pub_key_hash temp_wallet.json)" >> "$output_file"
    echo "================================" >> "$output_file"
    echo "" >> "$output_file"
    
    rm temp_wallet.json
}

# Функция множественного создания кошельков
create_multiple_wallets() {
    echo -e "${YELLOW}Сколько кошельков вы хотите создать? 🎭${NC}"
    read wallet_count
    
    if ! [[ "$wallet_count" =~ ^[0-9]+$ ]] || [ "$wallet_count" -lt 1 ]; then
        echo -e "${RED}Ошибка: Введите корректное число кошельков ❌${NC}"
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="hemi_wallets_$timestamp.txt"
    
    echo -e "${BLUE}Создаем $wallet_count кошельков... ⚙️${NC}"
    
    for ((i=1; i<=wallet_count; i++)); do
        echo -e "${CYAN}Создание кошелька $i из $wallet_count... 🔄${NC}"
        create_wallet $i "$output_file"
    done
    
    echo -e "${GREEN}Все кошельки созданы и сохранены в файл: $output_file 📝${NC}"
    echo -e "${RED}Обязательно сохраните данные кошельков в надежном месте! 🔒${NC}"
}

# Меню
clear
echo -e "${YELLOW}🌟 Меню установки ноды:${NC}"
echo -e "${CYAN}1) 📥 Установка ноды${NC}"
echo -e "${CYAN}2) 🔄 Обновление ноды${NC}"
echo -e "${CYAN}3) 💰 Изменение комиссии${NC}"
echo -e "${CYAN}4) 🗑️ Удаление ноды${NC}"
echo -e "${CYAN}5) 📜 Проверка логов (выход: CTRL+C)${NC}"
echo -e "${CYAN}6) 👛 Создание множества кошельков${NC}"

echo -e "${YELLOW}Введите номер действия: 🔢${NC}"
read choice

case $choice in
    1)
        echo -e "${BLUE}Устанавливаем ноду... 🛠️${NC}"
        
        # Обновление системы
        sudo apt update && sudo apt upgrade -y
        sleep 1
        
        # Проверка и установка зависимостей
        for pkg in tar jq; do
            if ! command -v $pkg &> /dev/null; then
                sudo apt install $pkg -y
            fi
        done

        # Установка бинарника
        echo -e "${BLUE}Загружаем бинарник... ⏳${NC}"
        curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.8.0/heminetwork_v0.8.0_linux_amd64.tar.gz

        mkdir -p hemi
        tar --strip-components=1 -xzvf heminetwork_v0.8.0_linux_amd64.tar.gz -C hemi
        cd hemi

        # Создание кошелька
        echo -e "${YELLOW}Хотите создать новый кошелек? (y/n) 👛${NC}"
        read create_new
        
        if [[ $create_new == "y" ]]; then
            ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json
            echo -e "${RED}Сохраните эти данные в надежное место: 🔒${NC}"
            cat ~/popm-address.json
            echo -e "${PURPLE}Ваш pubkey_hash — это ваш tBTC адрес для получения тестовых токенов ℹ️${NC}"
        fi

        echo -e "${YELLOW}Введите приватный ключ кошелька: 🔑${NC}"
        read PRIV_KEY
        echo -e "${YELLOW}Укажите размер комиссии (мин. 50): 💸${NC}"
        read FEE

        # Создание конфигурационного файла
        echo "POPM_BTC_PRIVKEY=$PRIV_KEY" > popmd.env
        echo "POPM_STATIC_FEE=$FEE" >> popmd.env
        echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env
        sleep 1

        # Определение пользователя и директории
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Создание сервиса
        cat <<EOT | sudo tee /etc/systemd/system/hemi.service > /dev/null
[Unit]
Description=PopMD Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/hemi/popmd.env
ExecStart=$HOME_DIR/hemi/popmd
WorkingDirectory=$HOME_DIR/hemi/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

        # Запуск сервиса
        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl enable hemi
        sudo systemctl start hemi

        echo -e "${GREEN}Установка завершена! 🎉${NC}"
        ;;

    2)
        echo -e "${BLUE}Обновляем ноду... 🔄${NC}"

        # Находим все сессии screen с "hemi"
        SESSION_IDS=$(screen -ls | grep "hemi" | awk '{print $1}' | cut -d '.' -f 1)

        if [ -n "$SESSION_IDS" ]; then
            echo -e "${BLUE}Завершаем сессии screen: $SESSION_IDS 🔍${NC}"
            for SESSION_ID in $SESSION_IDS; do
                screen -S "$SESSION_ID" -X quit
            done
        else
            echo -e "${BLUE}Активные сессии screen не найдены ℹ️${NC}"
        fi

        # Остановка сервиса
        if systemctl list-units --type=service | grep -q "hemi.service"; then
            sudo systemctl stop hemi.service
            sudo systemctl disable hemi.service
            sudo rm /etc/systemd/system/hemi.service
            sudo systemctl daemon-reload
        else
            echo -e "${BLUE}Сервис hemi.service не найден ℹ️${NC}"
        fi
        sleep 1

        echo -e "${BLUE}Удаляем старые файлы... 🗑️${NC}"
        rm -rf *hemi*
        
        # Обновление системы
        sudo apt update && sudo apt upgrade -y

        echo -e "${BLUE}Загружаем новый бинарник... ⏳${NC}"
        curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.8.0/heminetwork_v0.8.0_linux_amd64.tar.gz

        mkdir -p hemi
        tar --strip-components=1 -xzvf heminetwork_v0.8.0_linux_amd64.tar.gz -C hemi
        cd hemi

        echo -e "${YELLOW}Введите приватный ключ кошелька: 🔑${NC}"
        read PRIV_KEY
        echo -e "${YELLOW}Укажите размер комиссии (мин. 50): 💸${NC}"
        read FEE

        echo "POPM_BTC_PRIVKEY=$PRIV_KEY" > popmd.env
        echo "POPM_STATIC_FEE=$FEE" >> popmd.env
        echo "POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public" >> popmd.env
        sleep 1

        # Определение пользователя и директории
        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        # Обновление сервиса
        cat <<EOT | sudo tee /etc/systemd/system/hemi.service > /dev/null
[Unit]
Description=PopMD Service
After=network.target

[Service]
User=$USERNAME
EnvironmentFile=$HOME_DIR/hemi/popmd.env
ExecStart=$HOME_DIR/hemi/popmd
WorkingDirectory=$HOME_DIR/hemi/
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT

        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl enable hemi
        sudo systemctl start hemi

        echo -e "${GREEN}Нода успешно обновлена! 🎉${NC}"
        ;;

    3)
        echo -e "${YELLOW}Укажите новое значение комиссии (мин. 50): 💸${NC}"
        read NEW_FEE

        if [ "$NEW_FEE" -ge 50 ]; then
            sed -i "s/^POPM_STATIC_FEE=.*/POPM_STATIC_FEE=$NEW_FEE/" $HOME/hemi/popmd.env
            sleep 1

            sudo systemctl restart hemi

            echo -e "${GREEN}Комиссия успешно изменена! ✅${NC}"
        else
            echo -e "${RED}Ошибка: комиссия должна быть не меньше 50! ❌${NC}"
        fi
        ;;

    4)
        echo -e "${BLUE}Удаляем ноду... 🗑️${NC}"

        # Находим все сессии screen
        SESSION_IDS=$(screen -ls | grep "hemi" | awk '{print $1}' | cut -d '.' -f 1)

        if [ -n "$SESSION_IDS" ]; then
            echo -e "${BLUE}Завершаем сессии screen: $SESSION_IDS 🔍${NC}"
            for SESSION_ID in $SESSION_IDS; do
                screen -S "$SESSION_ID" -X quit
            done
        else
            echo -e "${BLUE}Активные сессии screen не найдены ℹ️${NC}"
        fi

        # Удаление сервиса
        sudo systemctl stop hemi.service
        sudo systemctl disable hemi.service
        sudo rm /etc/systemd/system/hemi.service
        sudo systemctl daemon-reload
        sleep 1

        echo -e "${BLUE}Удаляем файлы ноды... 🗑️${NC}"
        rm -rf *hemi*
        
        echo -e "${GREEN}Нода успешно удалена! ✅${NC}"
        ;;

    5)
        echo -e "${BLUE}Открываем логи... 📜${NC}"
        sudo journalctl -u hemi -f
        ;;
        
    6)
        # Подготовка окружения для создания кошельков
        if [ ! -d "hemi" ]; then
            echo -e "${BLUE}Подготовка окружения для создания кошельков... ⚙️${NC}"
            
            # Установка необходимых пакетов
            for pkg in tar jq; do
                if ! command -v $pkg &> /dev/null; then
                    sudo apt install $pkg -y
                fi
            done
            
            # Загрузка и распаковка бинарников
            curl -L -O https://github.com/hemilabs/heminetwork/releases/download/v0.8.0/heminetwork_v0.8.0_linux_amd64.tar.gz
            mkdir -p hemi
            tar --strip-components=1 -xzvf heminetwork_v0.8.0_linux_amd64.tar.gz -C hemi
            cd hemi
        else
            cd hemi
        fi
        
        create_multiple_wallets
        ;;
        
    *)
        echo -e "${RED}Неверный выбор ❌${NC}"
        ;;
esac

# Вывод информации о логах
echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
echo -e "${YELLOW}Команда для проверки логов: 📋${NC}"
echo "sudo journalctl -u hemi -f"
echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
