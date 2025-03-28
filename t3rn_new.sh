#!/bin/bash
# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
ORANGE='\033[38;5;214m'
YELLOW='\033[0;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # Без цвета

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

# Очистка экрана
clear

# Вывод локального логотипа
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Функция для отображения меню
print_menu() {
    echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🚀 T3RN NODE MANAGER            ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BOLD}${BLUE}🔧 Доступные действия:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🛠️  Установка ноды${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}▶️  Запуск ноды${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}⬆️  Обновление ноды${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}📋 Проверка логов${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🔍 Статус ноды${NC}"
    echo -e "${WHITE}[${CYAN}6${WHITE}] ${GREEN}➜ ${WHITE}🔌 Управление RPC${NC}"
    echo -e "${WHITE}[${CYAN}7${WHITE}] ${GREEN}➜ ${WHITE}⏮️ Установка конкретной версии${NC}"
    echo -e "${WHITE}[${CYAN}8${WHITE}] ${GREEN}➜ ${WHITE}🗑️  Удаление ноды${NC}"
    echo -e "${WHITE}[${CYAN}9${WHITE}] ${GREEN}➜ ${WHITE}🚪 Выход${NC}\n"
}

# Log file for debugging
LOG_FILE="setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${WHITE}║        🚀 T3RN NODE SETUP          ║${NC}"
    echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"
sleep 2

# Функция для отображения инструкций по использованию
usage() {
    echo -e "${GREEN}Использование: $0 [--verbose] [--dry-run]${NC}"
    echo -e "${GREEN}  --verbose: Включить подробное логирование для отладки.${NC}"
    echo -e "${GREEN}  --dry-run: Имитировать выполнение скрипта без внесения изменений.${NC}"
    exit 0
}

# Функция для проверки и завершения работающего процесса executor
kill_running_executor() {
    local pid
    pid=$(pgrep -f "./executor")

    if [ -n "$pid" ]; then
        if $DRY_RUN; then
            echo -e "${GREEN}[Dry-run] Завершил бы работающий процесс executor (PID: $pid)${NC}"
        else
            echo -e "${ORANGE}⚙️ Найден запущенный процесс executor. Завершение процесса...${NC}"
            kill "$pid"
            sleep 2
            echo -e "${GREEN}✅ Процесс executor успешно завершен.${NC}"
        fi
    else
        echo -e "${BLUE}ℹ️ Запущенных процессов executor не найдено.${NC}"
    fi
}

# Функция для установки jq, если он отсутствует
install_jq_if_needed() {
    if ! command -v jq &>/dev/null; then
        echo -e "${ORANGE}📦 jq требуется для обработки JSON. Установка jq...${NC}"
        
        # Detect OS and install jq
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y jq
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install jq  # macOS
        elif [[ "$OSTYPE" == "alpine"* ]]; then
            apk add jq      # Alpine Linux
        else
            echo -e "${RED}❌ Не удалось установить jq. Пожалуйста, установите его вручную и попробуйте снова.${NC}"
            echo -e "${ORANGE}Установите jq через менеджер пакетов вашей системы.${NC}"
            exit 1
        fi

        # Verify installation
        if command -v jq &>/dev/null; then
            echo -e "${GREEN}✅ jq успешно установлен.${NC}"
        else
            echo -e "${RED}❌ Не удалось установить jq. Пожалуйста, установите его вручную и попробуйте снова.${NC}"
            exit 1
        fi
    fi
}

# Разбор аргументов командной строки
VERBOSE=false
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --verbose)
            VERBOSE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Неизвестный аргумент: $arg${NC}"
            usage
            ;;
    esac
done

# Установка jq
install_jq_if_needed

# Включение подробного режима, если запрошено
if $VERBOSE; then
    set -x
fi

# Сообщение о режиме dry-run
if $DRY_RUN; then
    echo -e "${ORANGE}Режим dry-run включен. Изменения не будут внесены.${NC}"
	sleep 1
fi

# Функция для запроса пользовательского ввода
ask_for_input() {
    local prompt="$1"
    local input

    read -p "$prompt: " input
    echo "$input"
}

# Функция для проверки значения газа
validate_gas_value() {
    local gas_value="$1"
    
    # Check if the input is an integer
    if [[ ! "$gas_value" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}⛽ Введите значение газа (должно быть целым числом от 100 до 20000)${NC}"
        return 1
    fi

    # Check if the gas value is within the allowed range
    if (( gas_value < 100 || gas_value > 20000 )); then
        echo -e "${RED}❌ Ошибка: Значение газа должно быть от 100 до 20000.${NC}"
        return 1
    fi

    return 0
}

parse_rpc_input() {
    local input="$1"
    local -a endpoints
    IFS=',' read -ra endpoints <<< "$input"
    printf '['
    for ((i=0; i<${#endpoints[@]}; i++)); do
        endpoint=$(echo "${endpoints[$i]}" | xargs)  # Trim whitespace
        printf '"%s"' "$endpoint"
        [[ $i -ne $((${#endpoints[@]}-1)) ]] && printf ','
    done
    printf ']'
}

# Устанавливаем русскую локализацию
LANG_CODE="ru"
MSG_VERSION_CHOICE="🧪 Выберите версию для установки:"
MSG_LATEST_OPTION="1) 🚀 Последняя версия"
MSG_SPECIFIC_OPTION="2) 📌 Конкретная версия"
MSG_ENTER_VERSION="📝 Введите номер версии, которую вы хотите установить (например, v0.51.0):"
MSG_INVALID_VERSION_CHOICE="⚠️ Неверный выбор. Пожалуйста, введите 1 или 2"
MSG_INVALID_VERSION_FORMAT="⚠️ Неверный формат версии. Должно быть как v0.51.0"
MSG_CLEANUP="🧹 Очистка предыдущих установок..."
MSG_DOWNLOAD="📥 Загрузка последнего релиза..."
MSG_EXTRACT="📦 Распаковка архива..."
MSG_INVALID_INPUT="⚠️ Неверный ввод. Пожалуйста, введите 'api' или 'rpc'."
MSG_PRIVATE_KEY="🔑 Введите ваш приватный ключ кошелька"
MSG_GAS_VALUE="⛽ Введите значение газа (должно быть целым числом от 100 до 20000)"
MSG_INVALID_GAS="❌ Ошибка: Значение газа должно быть от 100 до 20000."
MSG_NODE_TYPE="🖥️ Вы хотите запустить API-узел или RPC-узел? (api/rpc)"
MSG_RPC_ENDPOINTS="🔌 Хотите добавить пользовательские RPC-точки? (y/n)"
MSG_THANKS="💫 Установка ноды T3RN успешно завершена!"
MSG_L1RN_RPC="📋 Доступные L1RN RPC endpoints:"
MSG_SELECT_L1RN="🔢 Введите номера L1RN RPC endpoints для включения (через запятую, например, 1,2):"
MSG_INVALID_SELECTION="⚠️ Неверный выбор: %s. Пропускаем."
MSG_OUT_OF_RANGE="⚠️ Индекс %s вне диапазона. Пропускаем."
MSG_NO_SELECTION="⚠️ Нет допустимых выборов. Пожалуйста, выберите хотя бы один endpoint."
MSG_ALCHEMY_API_KEY="🔑 Введите ваш Alchemy API ключ:"
MSG_CREATE_DIR="📁 Создание и переход в директорию t3rn..."
MSG_DOWNLOAD_COMPLETE="✅ Загрузка завершена."
MSG_NAVIGATE_BINARY="🔍 Переход к расположению бинарного файла executor..."
MSG_COLLECTED_INPUTS="📊 Собранные данные и настройки:"
MSG_NODE_TYPE_LABEL="🏷️ Тип узла:"
MSG_ALCHEMY_API_KEY_LABEL="🔑 Ключ Alchemy API:"
MSG_GAS_VALUE_LABEL="⛽ Значение газа:"
MSG_RPC_ENDPOINTS_LABEL="🌐 Активные сети и RPC-точки:"
MSG_WALLET_PRIVATE_KEY_LABEL="🔐 Приватный ключ кошелька:"
MSG_FAILED_CREATE_DIR="❌ Не удалось создать или перейти в директорию t3rn. Выход."
MSG_FAILED_FETCH_TAG="❌ Не удалось получить последний тег релиза. Проверьте подключение к интернету и попробуйте снова."
MSG_FAILED_DOWNLOAD="❌ Не удалось загрузить последний релиз. Проверьте URL и попробуйте снова."
MSG_FAILED_EXTRACT="❌ Не удалось извлечь архив. Проверьте файл и попробуйте снова."
MSG_FAILED_NAVIGATE="❌ Не удалось перейти к расположению бинарного файла executor. Выход."
MSG_DELETE_T3RN_DIR="🗑️ Удаление существующей директории t3rn..."
MSG_DELETE_EXECUTOR_DIR="🗑️ Удаление существующей директории executor..."
MSG_DELETE_TAR_GZ="🗑️ Удаление ранее загруженных tar.gz файлов..."
MSG_EXTRACTION_COMPLETE="✅ Архив успешно извлечен."
MSG_RUNNING_NODE="▶️ Запуск узла..."
MSG_DRY_RUN_DELETE="🔍 [Dry-run] Существующие директории t3rn и executor будут удалены."
MSG_DRY_RUN_CREATE_DIR="🔍 [Dry-run] Будет создана и открыта директория t3rn."
MSG_DRY_RUN_NAVIGATE="🔍 [Dry-run] Будет выполнен переход к расположению бинарного файла executor."
MSG_DRY_RUN_RUN_NODE="🔍 [Dry-run] Узел будет запущен."
MSG_ENTER_CUSTOM_RPC="🔌 Введите пользовательские RPC-точки:"
MSG_ARBT_RPC="🔌 Arbitrum Sepolia RPC-точки (по умолчанию: $DEFAULT_RPC_ENDPOINTS_ARBT)"
MSG_BSSP_RPC="🔌 Base Sepolia RPC-точки (по умолчанию: $DEFAULT_RPC_ENDPOINTS_BSSP)"
MSG_BLSS_RPC="🔌 Blast Sepolia RPC-точки (по умолчанию: $DEFAULT_RPC_ENDPOINTS_BLSS)"
MSG_OPSP_RPC="🔌 Optimism Sepolia RPC-точки (по умолчанию: $DEFAULT_RPC_ENDPOINTS_OPSP)"
MSG_AVAILABLE_NETWORKS="🌍 Доступные сети:"
MSG_ARBT_DESC="🔷 ARBT = arbitrum-sepolia"
MSG_BSSP_DESC="🔷 BAST = base-sepolia"
MSG_OPSP_DESC="🔷 OPST = optimism-sepolia"
MSG_BLSS_DESC="🔷 BLST = blast-sepolia"
MSG_L2RN_ALWAYS_ENABLED="✅ L2RN всегда включен."
MSG_ENTER_NETWORKS="🌐 Введите сети, которые хотите активировать (через запятую, например: ARBT,BAST,OPST,BLST или нажмите Enter/введите 'all' для всех):"
MSG_INVALID_NETWORK="⚠️ Неверная сеть: %s. Пожалуйста, введите корректные сети."
MSG_KILLING_EXECUTOR="⚙️ Найден запущенный процесс executor. Завершение процесса..."
MSG_EXECUTOR_KILLED="✅ Процесс executor успешно завершен."
MSG_NO_EXECUTOR_RUNNING="ℹ️ Запущенных процессов executor не найдено."
MSG_CHECKING_EXECUTOR="🔍 === Проверка запущенных процессов executor ==="
MSG_KILLING_EXECUTOR="⚙️ Обнаружен запущенный процесс executor. Останавливаем для предотвращения конфликтов..."
MSG_EXECUTOR_KILLED="✅ Старый процесс executor успешно остановлен."
MSG_NO_EXECUTOR_RUNNING="✅ Запущенных процессов executor не обнаружено - можно продолжать."
MSG_WARNING="⚠️ ПРЕДУПРЕЖДЕНИЕ: ЕСЛИ ВЫ ДЕЛИТЕСЬ СКРИНШОТАМИ ЭТОГО СКРИПТА ИЗ-ЗА ОШИБКИ, УБЕДИТЕСЬ, ЧТО ВАШИ ПРИВАТНЫЕ КЛЮЧИ И КЛЮЧ ALCHEMY API НЕ ВИДНЫ! В ПРОТИВНОМ СЛУЧАЕ ВЫ МОЖЕТЕ ПОТЕРЯТЬ ВСЕ СВОИ АКТИВЫ В КОШЕЛЬКЕ ИЛИ РАСКРЫТЬ ДОСТУП К API! ⚠️"
MSG_JQ_REQUIRED="📦 jq требуется для обработки JSON. Установка jq..."
MSG_JQ_INSTALL_FAILED="❌ Не удалось установить jq. Пожалуйста, установите его вручную и попробуйте снова."
MSG_JQ_INSTALL_SUCCESS="✅ jq успешно установлен."
MSG_NODE_TYPE_OPTIONS="🔄 Выберите тип узла:"
MSG_API_MODE="1️⃣ API Узел - Прямая отправка транзакций через API"
MSG_ALCHEMY_MODE="2️⃣ Alchemy RPC - Использование RPC endpoints от Alchemy (требуется API-ключ)"
MSG_CUSTOM_MODE="3️⃣ Кастомный RPC - Использование публичных/пользовательских RPC endpoints (Alchemy не требуется)"
MSG_API_MODE_DESC="🚀 Режим API: Прямая отправка транзакций включена"
MSG_ALCHEMY_MODE_DESC="🔌 Режим Alchemy: Используются RPC endpoints от Alchemy"
MSG_CUSTOM_MODE_DESC="🛠️ Режим кастомного RPC: Используются публичные/пользовательские endpoints"
MSG_SELECT_NODE_TYPE="🔢 Введите ваш выбор (1/2/3): "
MSG_INVALID_NODE_TYPE="⚠️ Неверный выбор типа узла. Пожалуйста, введите 1, 2 или 3."

# Step 0: Clean up previous installations
echo -e "${GREEN}$MSG_CLEANUP${NC}"
if $DRY_RUN; then
    echo -e "${ORANGE}$MSG_DRY_RUN_DELETE${NC}"
	sleep 1
else
    if [ -d "t3rn" ]; then
        echo -e "${ORANGE}$MSG_DELETE_T3RN_DIR${NC}"
        rm -rf t3rn
    fi
	
	sleep 1

    if [ -d "executor" ]; then
        echo -e "${ORANGE}$MSG_DELETE_EXECUTOR_DIR${NC}"
        rm -rf executor
    fi
	
	sleep 1
	
    if ls executor-linux-*.tar.gz 1> /dev/null 2>&1; then
        echo -e "${ORANGE}$MSG_DELETE_TAR_GZ${NC}"
        rm -f executor-linux-*.tar.gz
    fi
	
	sleep 1
fi

# Step 1: Create and navigate to t3rn directory
echo -e "${ORANGE}$MSG_CREATE_DIR${NC}"
if $DRY_RUN; then
    echo -e "${GREEN}$MSG_DRY_RUN_CREATE_DIR${NC}"
else
    mkdir -p t3rn
    cd t3rn || { echo -e "${RED}$MSG_FAILED_CREATE_DIR${NC}"; exit 1; }
fi

# Step 2.5: Version selection
echo -e "${GREEN}${MSG_VERSION_CHOICE}${NC}"
echo -e " ${ORANGE}${MSG_LATEST_OPTION}${NC}"
echo -e " ${ORANGE}${MSG_SPECIFIC_OPTION}${NC}"

while true; do
    read -p "$(echo -e "${GREEN}${MSG_SELECT_NODE_TYPE}${NC}")" VERSION_CHOICE
    
    case $VERSION_CHOICE in
        1)
            LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
            [ -z "$LATEST_TAG" ] && { echo -e "${RED}$MSG_FAILED_FETCH_TAG${NC}"; exit 1; }
            break
            ;;
        2)
            while true; do
                echo -e "${GREEN}${MSG_ENTER_VERSION}${NC}"
                read LATEST_TAG
                [[ "$LATEST_TAG" =~ ^v[0-9]+\.[0-9]+(\.[0-9]+)?$ ]] && break
                echo -e "${RED}${MSG_INVALID_VERSION_FORMAT}${NC}"
            done
            break
            ;;
        *)
            echo -e "${RED}${MSG_INVALID_VERSION_CHOICE}${NC}"
            ;;
    esac
done

# Step 2: Download the latest release
DOWNLOAD_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_TAG/executor-linux-$LATEST_TAG.tar.gz"
echo -e "${GREEN}$MSG_DOWNLOAD${NC}"
wget --progress=bar:force:noscroll "$DOWNLOAD_URL" -O "executor-linux-$LATEST_TAG.tar.gz"
if [ $? -ne 0 ]; then
    echo "${RED}$MSG_FAILED_DOWNLOAD${NC}"
	sleep 2
    exit 1
fi
echo -e "${GREEN}$MSG_DOWNLOAD_COMPLETE${NC}"
sleep 1

# Step 3: Extract the archive
echo -e "${ORANGE}$MSG_EXTRACT${NC}"
# extract_archive "executor-linux-$LATEST_TAG.tar.gz"
tar -xvzf "executor-linux-$LATEST_TAG.tar.gz"
if [ $? -ne 0 ]; then
    echo -e "${RED}$MSG_FAILED_EXTRACT${NC}"
	sleep 2
    exit 1
fi

echo -e "${GREEN}$MSG_EXTRACTION_COMPLETE${NC}"
sleep 1

# Step 4: Navigate to the executor binary location
echo -e "${ORANGE}$MSG_NAVIGATE_BINARY${NC}"
if $DRY_RUN; then
    echo -e "${GREEN}$MSG_DRY_RUN_NAVIGATE${NC}"
	sleep 1
else
    mkdir -p executor/executor/bin
    cd executor/executor/bin || { echo -e "${RED}$MSG_FAILED_NAVIGATE${NC}"; exit 1; }
	sleep 1
fi

# Ask if the user wants to run an API node or RPC node
echo -e "${GREEN}$MSG_NODE_TYPE_OPTIONS${NC}"
echo -e " ${ORANGE}${MSG_API_MODE}${NC}"
echo -e " ${ORANGE}${MSG_ALCHEMY_MODE}${NC}"
echo -e " ${ORANGE}${MSG_CUSTOM_MODE}${NC}"

while true; do
    read -p "$(echo -e "${GREEN}${MSG_SELECT_NODE_TYPE}${NC}")" NODE_TYPE_CHOICE
    
    case $NODE_TYPE_CHOICE in
        1)
            NODE_TYPE="api"
            echo -e "${GREEN}${MSG_API_MODE_DESC}${NC}"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=true
            break
            ;;
        2)
            NODE_TYPE="alchemy-rpc"
            echo -e "${GREEN}${MSG_ALCHEMY_MODE_DESC}${NC}"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
            break
            ;;
        3)
            NODE_TYPE="custom-rpc"
            echo -e "${GREEN}${MSG_CUSTOM_MODE_DESC}${NC}"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
            break
            ;;
        *)
            echo -e "${RED}${MSG_INVALID_NODE_TYPE}${NC}"
            ;;
    esac
done

# Ask for wallet private key (masked input)
echo -e "${GREEN}$MSG_PRIVATE_KEY${NC}"
WALLET_PRIVATE_KEY=$(ask_for_input "")

# Ask for Alchemy API key (masked input, if RPC node is selected)
if [[ "$NODE_TYPE" == "alchemy-rpc" ]]; then
    echo -e "${GREEN}$MSG_ALCHEMY_API_KEY${NC}"
    ALCHEMY_API_KEY=$(ask_for_input "")
elif [[ "$NODE_TYPE" == "custom-rpc" ]]; then
    echo -e "${ORANGE}${MSG_CUSTOM_RPC_WARNING}${NC}"
    sleep 2
fi

# Ask for gas value and validate it
while true; do
	echo -e "${GREEN}$MSG_GAS_VALUE${NC} "
    read GAS_VALUE
    if [[ "$GAS_VALUE" =~ ^[0-9]+$ ]] && (( GAS_VALUE >= 100 && GAS_VALUE <= 20000 )); then
        break
    else
        echo -e "${RED}$MSG_INVALID_GAS${NC}"
    fi
done

#Конфигурация RPC эндпоинтов
configure_rpc_endpoints() {
    case $NODE_TYPE in
        "alchemy-rpc")
            echo -e "${GREEN}⚙️ Добавление Alchemy endpoints...${NC}"
            RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq \
                --arg arbt "https://arb-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
                --arg bast "https://base-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
                --arg opst "https://opt-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
                --arg blst "https://blast-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
                '.arbt += [$arbt] | .bast += [$bast] | .opst += [$opst] | .blst += [$blst]')
            ;;

        "custom-rpc")
            echo -e "${GREEN}⚙️ Использование только пользовательских RPC endpoints...${NC}"
            RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq 'del(.arbt, .bast, .opst, .blst)')
            ;;
    esac
}

# Выполнение конфигурации
configure_rpc_endpoints

# Установка окружения узла
export ENVIRONMENT=testnet

# Настройки логирования
export LOG_LEVEL=debug
export LOG_PRETTY=false

# Обработка ставок, заказов и требований
export EXECUTOR_PROCESS_BIDS_ENABLED=true
export EXECUTOR_PROCESS_ORDERS_ENABLED=true
export EXECUTOR_PROCESS_CLAIMS_ENABLED=true

# Настройка параметров API в зависимости от типа узла
if [[ "$NODE_TYPE" == "api" ]]; then
    # Автоматическое включение настроек API для API узлов
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
    export EXECUTOR_PROCESS_ORDERS_API_ENABLED=true
else
    # Автоматическое отключение настроек API для RPC узлов
    export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
    export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
fi

# RPC эндпоинты по умолчанию
DEFAULT_RPC_ENDPOINTS_JSON='{
  "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
  "arbt": ["https://arbitrum-sepolia.drpc.org"],
  "bast": ["https://base-sepolia-rpc.publicnode.com"],
  "blst": ["https://sepolia.blast.io"],
  "opst": ["https://sepolia.optimism.io"],
  "unit": ["https://unichain-sepolia.drpc.org"]
}'

# Инициализация RPC_ENDPOINTS_JSON значениями по умолчанию
RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"

# Извлечение эндпоинтов по умолчанию из JSON
DEFAULT_RPC_ENDPOINTS_ARBT=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.arbt[0]')
DEFAULT_RPC_ENDPOINTS_BSSP=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.bast[0]')
DEFAULT_RPC_ENDPOINTS_BLSS=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.blst[0]')
DEFAULT_RPC_ENDPOINTS_OPSP=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.opst[0]')
DEFAULT_RPC_ENDPOINTS_UNIT=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.unit[0]')
DEFAULT_RPC_ENDPOINTS_L2RN=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.l2rn[0]')


# Спрашиваем, хочет ли пользователь добавить пользовательские RPC эндпоинты или использовать стандартные
echo -e "${GREEN}$MSG_RPC_ENDPOINTS: ${NC}" 
read CUSTOM_RPC

if [[ "$CUSTOM_RPC" =~ ^[Yy]$ ]]; then
    echo -e "${ORANGE}$MSG_ENTER_CUSTOM_RPC${NC}"
    
    # Определение сетей и их описаний
    declare -A rpc_map=(
        ["arbt"]="Arbitrum Sepolia"
        ["bast"]="Base Sepolia"
        ["blst"]="Blast Sepolia"
        ["opst"]="Optimism Sepolia"
        ["unit"]="Unichain Sepolia"
        ["l2rn"]="L2RN"
    )

    # Формирование JSON с RPC эндпоинтами
    RPC_ENDPOINTS_JSON="{"
    for network in "${!rpc_map[@]}"; do
        echo -e "${GREEN}🔌 Введите RPC-точки для ${rpc_map[$network]} (через запятую):${NC}"
        read -p "> " endpoints
        if [ -n "$endpoints" ]; then
            RPC_ENDPOINTS_JSON+="\"$network\": $(parse_rpc_input "$endpoints"),"
        else
            default_value=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -c ".$network")
            RPC_ENDPOINTS_JSON+="\"$network\": $default_value,"
        fi
    done
    RPC_ENDPOINTS_JSON="${RPC_ENDPOINTS_JSON%,}}"
else
    RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"
fi

# Проверка структуры JSON
if ! jq empty <<< "$RPC_ENDPOINTS_JSON"; then
    echo -e "${RED}❌ Неверный JSON. Используем значения по умолчанию.${NC}"
    RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"
fi

# Минификация JSON
export RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)

# Формирование финального RPC_ENDPOINTS_L1RN и добавление его
SELECTED_URLS=()
for i in "${VALID_INDICES[@]}"; do
    SELECTED_URLS+=("${L1RN_RPC_OPTIONS[$i]}")
done

# Присвоение значений по умолчанию или пользовательского выбора
if [ ${#SELECTED_URLS[@]} -eq 0 ]; then
    RPC_ENDPOINTS_L1RN="https://brn.calderarpc.com/http,https://brn.rpc.caldera.xyz/"
else
    RPC_ENDPOINTS_L1RN=$(IFS=,; echo "${SELECTED_URLS[*]}")
fi

# Настройка RPC эндпоинтов в зависимости от типа узла
if [[ "$NODE_TYPE" == "rpc" ]]; then
  echo -e "${GREEN}🔄 Добавление Alchemy RPC endpoints...${NC}"
  
  # Безопасное объединение Alchemy эндпоинтов с существующими
  if ! RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq \
    --arg arbt "https://arb-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
    --arg bast "https://base-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
    --arg opst "https://opt-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
    --arg blst "https://blast-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
    --arg unit "https://unichain-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
    '.arbt = (.arbt + [$arbt]) |
     .bast = (.bast + [$bast]) |
     .opst = (.opst + [$opst]) |
     .blst = (.blst + [$blst]) |
     .unit = (.unit + [$unit])' ); then
    echo -e "${RED}❌ Не удалось добавить Alchemy endpoints. Неверная структура JSON.${NC}"
    exit 1
fi

  # Проверка финального JSON
  if ! echo "$RPC_ENDPOINTS_JSON" | jq empty; then
    echo -e "${RED}❌ Неверная структура JSON после изменений:${NC}"
    echo "$RPC_ENDPOINTS_JSON"
    exit 1
  fi
fi

# Минификация JSON с проверкой
if ! RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .); then
  echo -e "${RED}❌ Не удалось минифицировать JSON структуру RPC endpoints:${NC}"
  echo "$RPC_ENDPOINTS_JSON"
  exit 1
fi
export RPC_ENDPOINTS

# Настройка приватного ключа
export PRIVATE_KEY_LOCAL=$WALLET_PRIVATE_KEY
RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)
export RPC_ENDPOINTS="$RPC_ENDPOINTS_JSON"

# Выбор сетей для активации
echo -e "${GREEN}$MSG_AVAILABLE_NETWORKS${NC}"
echo -e "${ORANGE}$MSG_ARBT_DESC${NC}"
echo -e "${ORANGE}$MSG_BSSP_DESC${NC}"
echo -e "${ORANGE}$MSG_BLSS_DESC${NC}"
echo -e "${ORANGE}$MSG_OPSP_DESC${NC}"
echo -e "${ORANGE}🔷 UNIT = unichain-sepolia${NC}"
echo -e "${RED}$MSG_L2RN_ALWAYS_ENABLED${NC}"

ENABLED_NETWORKS="l2rn"  # l2rn is now always enabled as base layer
while true; do
    read -p "$(echo -e "${GREEN}🌐 Введите сети для активации (через запятую):\n[ARBT, BAST, BLST, OPST, UNIT] или 'all' для всех:${NC} ")" USER_NETWORKS
    if [[ -z "$USER_NETWORKS" || "$USER_NETWORKS" =~ ^[Aa][Ll][Ll]$ ]]; then
        ENABLED_NETWORKS="$ENABLED_NETWORKS,arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,unichain-sepolia"
        break
    else
        IFS=',' read -r -a networks <<< "$USER_NETWORKS"
        valid=true
        for network in "${networks[@]}"; do
            case "$network" in
                ARBT)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,arbitrum-sepolia"
                    ;;
                BAST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,base-sepolia"
                    ;;
                BLST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,blast-sepolia"
                    ;;
                OPST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,optimism-sepolia"
                    ;;
                UNIT)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,unichain-sepolia"
                    ;;
                *)
                    echo -e "${RED}⚠️ Неверная сеть: $network. Допустимые варианты: ARBT, BAST, BLST, OPST, UNIT${NC}"
                    valid=false
                    break
                    ;;
            esac
        done
        $valid && break
    fi
done
export ENABLED_NETWORKS

# Export RPC endpoints
export RPC_ENDPOINTS_ARBT
export RPC_ENDPOINTS_BSSP
export RPC_ENDPOINTS_BLSS
export RPC_ENDPOINTS_OPSP
export RPC_ENDPOINTS_L1RN
export EXECUTOR_MAX_L3_GAS_PRICE=$GAS_VALUE

# Display the collected inputs and settings (for verification)
echo -e "${GREEN}$MSG_COLLECTED_INPUTS${NC}"
echo -e "${ORANGE}$MSG_NODE_TYPE_LABEL $NODE_TYPE${NC}"
if [[ "$NODE_TYPE" == "rpc" ]]; then
    # Mask the API key for display
    MASKED_API_KEY="${ALCHEMY_API_KEY:0:6}******${ALCHEMY_API_KEY: -6}"
    echo -e "${ORANGE}$MSG_ALCHEMY_API_KEY_LABEL${NC} ${BLUE}$MASKED_API_KEY${NC}"
fi

# Mask the private key for display
MASKED_PRIVATE_KEY="${WALLET_PRIVATE_KEY:0:6}******${WALLET_PRIVATE_KEY: -6}"
echo -e "${ORANGE}$MSG_WALLET_PRIVATE_KEY_LABEL${NC} ${BLUE}$MASKED_PRIVATE_KEY${NC}"
echo -e "${ORANGE}$MSG_GAS_VALUE_LABEL${NC} ${BLUE}$GAS_VALUE${NC}"
echo -e "${ORANGE}📡 EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API:${NC} ${BLUE}$EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API${NC}"
echo -e "${ORANGE}📡 EXECUTOR_PROCESS_ORDERS_API_ENABLED:${NC} ${BLUE}$EXECUTOR_PROCESS_ORDERS_API_ENABLED${NC}"
echo -e "${ORANGE}🌐 NODE_ENV:${NC} ${BLUE}$NODE_ENV${NC}"
echo -e "${ORANGE}🔍 LOG_LEVEL:${NC} ${BLUE}$LOG_LEVEL${NC}"
echo -e "${ORANGE}🎨 LOG_PRETTY:${NC} ${BLUE}$LOG_PRETTY${NC}"
echo -e "${ORANGE}💼 EXECUTOR_PROCESS_BIDS_ENABLED:${NC} ${BLUE}$EXECUTOR_PROCESS_BIDS_ENABLED${NC}"
echo -e "${ORANGE}📋 EXECUTOR_PROCESS_ORDERS_ENABLED:${NC} ${BLUE}$EXECUTOR_PROCESS_ORDERS_ENABLED${NC}"
echo -e "${ORANGE}🧾 EXECUTOR_PROCESS_CLAIMS_ENABLED:${NC} ${BLUE}$EXECUTOR_PROCESS_CLAIMS_ENABLED${NC}"
echo -e "${GREEN}$MSG_RPC_ENDPOINTS_LABEL${NC}"

# Check which networks are enabled and display their RPC endpoints
if [[ "$ENABLED_NETWORKS" == *"arbitrum-sepolia"* ]]; then
    echo -e "${ORANGE}🔵 ARBT:${NC} ${BLUE}$RPC_ENDPOINTS_ARBT${NC}"
fi
if [[ "$ENABLED_NETWORKS" == *"base-sepolia"* ]]; then
    echo -e "${ORANGE}🔵 BSSP:${NC} ${BLUE}$RPC_ENDPOINTS_BSSP${NC}"
fi
if [[ "$ENABLED_NETWORKS" == *"blast-sepolia"* ]]; then
    echo -e "${ORANGE}🔵 BLSS:${NC} ${BLUE}$RPC_ENDPOINTS_BLSS${NC}"
fi
if [[ "$ENABLED_NETWORKS" == *"optimism-sepolia"* ]]; then
    echo -e "${ORANGE}🔵 OPSP:${NC} ${BLUE}$RPC_ENDPOINTS_OPSP${NC}"
fi
if [[ "$ENABLED_NETWORKS" == *"l1rn"* ]]; then
    echo -e "${ORANGE}🔵 L1RN:${NC} ${BLUE}$RPC_ENDPOINTS_L1RN${NC}"
fi
if [[ "$ENABLED_NETWORKS" == *"blast-sepolia"* ]]; then
    echo -e "${ORANGE}🔵 BLST:${NC} ${BLUE}$RPC_ENDPOINTS_BLSS${NC}"
fi
if [[ "$ENABLED_NETWORKS" == *"unichain-sepolia"* ]]; then
    echo -e "${ORANGE}🔵 UNIT:${NC} ${BLUE}$RPC_ENDPOINTS_UNIT${NC}"
fi

# Отображение предупреждения о безопасности
echo -e "${RED}$MSG_WARNING${NC}"
sleep 3

# Шаг 5: Продолжение установки или других шагов настройки
echo -e "${GREEN}$MSG_THANKS${NC}"
sleep 3

if $DRY_RUN; then
    echo -e "${GREEN}$MSG_DRY_RUN_RUN_NODE${NC}"
else
    echo -e "\n${ORANGE}$MSG_CHECKING_EXECUTOR${NC}"
    kill_running_executor
    sleep 1

    echo -e "${BLUE}$MSG_RUNNING_NODE${NC}"
    ./executor
fi

# Функция для запуска работающей ноды
start_node() {
    echo -e "\n${BOLD}${BLUE}🚀 Запуск ноды T3RN...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}🔍 Проверка установленной ноды...${NC}"
    
    # Проверка наличия файла executor
    if [ ! -f "$HOME/t3rn/executor/executor/bin/executor" ]; then
        error_message "Нода не установлена. Сначала выполните установку."
        return 1
    fi
    success_message "Нода найдена"
    
    echo -e "${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка работающих экземпляров...${NC}"
    kill_running_executor
    success_message "Подготовка к запуску завершена"
    
    echo -e "${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}▶️ Запуск ноды...${NC}"
    cd "$HOME/t3rn/executor/executor/bin"
    ./executor &
    success_message "Нода запущена в фоновом режиме"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода T3RN успешно запущена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для обновления ноды
update_node() {
    echo -e "\n${BOLD}${BLUE}⬆️ Обновление ноды T3RN...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/5${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка работающих экземпляров...${NC}"
    kill_running_executor
    success_message "Все экземпляры остановлены"
    
    echo -e "${WHITE}[${CYAN}2/5${WHITE}] ${GREEN}➜ ${WHITE}🧹 Очистка предыдущей установки...${NC}"
    if [ -d "$HOME/t3rn" ]; then
        rm -rf "$HOME/t3rn"
        success_message "Предыдущая установка удалена"
    else
        info_message "Предыдущая установка не найдена"
    fi
    
    echo -e "${WHITE}[${CYAN}3/5${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка последней версии...${NC}"
    mkdir -p "$HOME/t3rn"
    cd "$HOME/t3rn"
    LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    if [ -z "$LATEST_TAG" ]; then
        error_message "Не удалось получить последний тег релиза. Проверьте подключение к интернету."
        return 1
    fi
    
    DOWNLOAD_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_TAG/executor-linux-$LATEST_TAG.tar.gz"
    wget --progress=bar:force:noscroll "$DOWNLOAD_URL" -O "executor-linux-$LATEST_TAG.tar.gz"
    if [ $? -ne 0 ]; then
        error_message "Не удалось загрузить последний релиз. Проверьте URL и попробуйте снова."
        return 1
    fi
    success_message "Загрузка завершена"
    
    echo -e "${WHITE}[${CYAN}4/5${WHITE}] ${GREEN}➜ ${WHITE}📦 Распаковка архива...${NC}"
    tar -xvzf "executor-linux-$LATEST_TAG.tar.gz"
    if [ $? -ne 0 ]; then
        error_message "Не удалось извлечь архив. Проверьте файл и попробуйте снова."
        return 1
    fi
    success_message "Архив распакован"
    
    echo -e "${WHITE}[${CYAN}5/5${WHITE}] ${GREEN}➜ ${WHITE}✅ Завершение обновления...${NC}"
    mkdir -p executor/executor/bin
    cd executor/executor/bin
    chmod +x executor
    success_message "Исполняемый файл настроен"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода T3RN успешно обновлена до версии $LATEST_TAG!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для проверки логов
check_logs() {
    echo -e "\n${BOLD}${BLUE}📋 Просмотр логов ноды T3RN...${NC}\n"
    
    LOG_FILE="$HOME/t3rn/setup.log"
    if [ -f "$LOG_FILE" ]; then
        echo -e "${CYAN}Последние 50 строк лога:${NC}\n"
        tail -n 50 "$LOG_FILE"
    else
        error_message "Файл лога не найден"
    fi
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Для просмотра полного лога используйте:${NC}"
    echo -e "${CYAN}cat $HOME/t3rn/setup.log${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для проверки статуса ноды
check_status() {
    echo -e "\n${BOLD}${BLUE}🔍 Проверка статуса ноды T3RN...${NC}\n"
    
    # Проверка наличия запущенного процесса
    PID=$(pgrep -f "./executor")
    
    if [ -n "$PID" ]; then
        success_message "Нода активна (PID: $PID)"
        echo -e "${CYAN}Время работы:${NC}"
        ps -p $PID -o etime=
    else
        warning_message "Нода не запущена"
    fi
    
    # Проверка наличия установленных файлов
    if [ -f "$HOME/t3rn/executor/executor/bin/executor" ]; then
        success_message "Нода установлена"
    else
        warning_message "Файлы ноды не найдены. Возможно, нода не установлена."
    fi
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Для запуска ноды используйте опцию 2 в главном меню${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для удаления ноды
remove_node() {
    echo -e "\n${BOLD}${RED}⚠️ Удаление ноды T3RN...${NC}\n"
    
    echo -e "${RED}Вы уверены, что хотите удалить ноду T3RN? (y/n)${NC}"
    read -p "➜ " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка работающих экземпляров...${NC}"
        kill_running_executor
        success_message "Все экземпляры остановлены"
        
        echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов...${NC}"
        if [ -d "$HOME/t3rn" ]; then
            rm -rf "$HOME/t3rn"
            success_message "Директория ноды удалена"
        else
            info_message "Директория ноды не найдена"
        fi
        
        if [ -d "$HOME/executor" ]; then
            rm -rf "$HOME/executor"
            success_message "Дополнительные файлы ноды удалены"
        fi
        
        echo -e "\n${GREEN}✅ Нода T3RN успешно удалена!${NC}\n"
    else
        info_message "Удаление отменено"
    fi
}

# Функция для установки полной ноды с параметрами
setup_node() {
    # Переносим оригинальную функциональность скрипта сюда
    echo -e "\n${BOLD}${BLUE}🛠️ Установка ноды T3RN...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/6${WHITE}] ${GREEN}➜ ${WHITE}🧹 Очистка предыдущих установок...${NC}"
    if [ -d "$HOME/t3rn" ]; then
        rm -rf "$HOME/t3rn"
    fi
    
    if [ -d "$HOME/executor" ]; then
        rm -rf "$HOME/executor"
    fi
    
    if ls executor-linux-*.tar.gz 1> /dev/null 2>&1; then
        rm -f executor-linux-*.tar.gz
    fi
    success_message "Предыдущие установки очищены"
    
    echo -e "${WHITE}[${CYAN}2/6${WHITE}] ${GREEN}➜ ${WHITE}📁 Создание директории...${NC}"
    mkdir -p "$HOME/t3rn"
    cd "$HOME/t3rn" || { 
        error_message "Не удалось создать или перейти в директорию t3rn"
        return 1
    }
    success_message "Директория создана"
    
    echo -e "${WHITE}[${CYAN}3/6${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка последней версии...${NC}"
    LATEST_TAG=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
    if [ -z "$LATEST_TAG" ]; then
        error_message "Не удалось получить последний тег релиза. Проверьте подключение к интернету."
        return 1
    }
    
    DOWNLOAD_URL="https://github.com/t3rn/executor-release/releases/download/$LATEST_TAG/executor-linux-$LATEST_TAG.tar.gz"
    wget --progress=bar:force:noscroll "$DOWNLOAD_URL" -O "executor-linux-$LATEST_TAG.tar.gz"
    if [ $? -ne 0 ]; then
        error_message "Не удалось загрузить последний релиз. Проверьте URL и попробуйте снова."
        return 1
    }
    success_message "Загрузка завершена"
    
    echo -e "${WHITE}[${CYAN}4/6${WHITE}] ${GREEN}➜ ${WHITE}📦 Распаковка архива...${NC}"
    tar -xvzf "executor-linux-$LATEST_TAG.tar.gz"
    if [ $? -ne 0 ]; then
        error_message "Не удалось извлечь архив. Проверьте файл и попробуйте снова."
        return 1
    fi
    success_message "Архив распакован"
    
    echo -e "${WHITE}[${CYAN}5/6${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Настройка ноды...${NC}"
    mkdir -p executor/executor/bin
    cd executor/executor/bin || {
        error_message "Не удалось перейти к расположению бинарного файла executor"
        return 1
    }
    chmod +x executor
    
    # Здесь вызываем оригинальную функцию для настройки ноды
    configure_node
    success_message "Настройка завершена"
    
    echo -e "${WHITE}[${CYAN}6/6${WHITE}] ${GREEN}➜ ${WHITE}▶️ Запуск ноды...${NC}"
    ./executor &
    success_message "Нода запущена в фоновом режиме"
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода T3RN успешно установлена и запущена!${NC}"
    echo -e "${CYAN}Версия: ${LATEST_TAG}${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для настройки ноды (используется при установке)
configure_node() {
    # Используем существующий код для конфигурации ноды
    
    # Выбор типа узла
    info_message "Выберите тип узла:"
    echo -e " ${ORANGE}1) API Узел - Прямая отправка транзакций через API${NC}"
    echo -e " ${ORANGE}2) Alchemy RPC - Использование RPC endpoints от Alchemy${NC}"
    echo -e " ${ORANGE}3) Кастомный RPC - Использование публичных/пользовательских RPC endpoints${NC}"
    
    read -p "$(echo -e "${GREEN}Введите ваш выбор (1/2/3): ${NC}")" NODE_TYPE_CHOICE
    
    case $NODE_TYPE_CHOICE in
        1)
            NODE_TYPE="api"
            success_message "Выбран API узел"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=true
            ;;
        2)
            NODE_TYPE="alchemy-rpc"
            success_message "Выбран Alchemy RPC узел"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
            ;;
        3)
            NODE_TYPE="custom-rpc"
            success_message "Выбран кастомный RPC узел"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=false
            ;;
        *)
            error_message "Неверный выбор типа узла. Выбран API узел по умолчанию."
            NODE_TYPE="api"
            export EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=true
            export EXECUTOR_PROCESS_ORDERS_API_ENABLED=true
            ;;
    esac
    
    # Запрос приватного ключа кошелька
    info_message "Введите ваш приватный ключ кошелька:"
    read -p "➜ " WALLET_PRIVATE_KEY
    success_message "Приватный ключ сохранен"
    
    # Запрос Alchemy API ключа, если выбран Alchemy RPC узел
    if [[ "$NODE_TYPE" == "alchemy-rpc" ]]; then
        info_message "Введите ваш Alchemy API ключ:"
        read -p "➜ " ALCHEMY_API_KEY
        success_message "Alchemy API ключ сохранен"
    fi
    
    # Запрос значения газа
    info_message "Введите значение газа (должно быть целым числом от 100 до 20000):"
    while true; do
        read -p "➜ " GAS_VALUE
        if [[ "$GAS_VALUE" =~ ^[0-9]+$ ]] && (( GAS_VALUE >= 100 && GAS_VALUE <= 20000 )); then
            success_message "Значение газа установлено: $GAS_VALUE"
            break
        else
            error_message "Ошибка: Значение газа должно быть от 100 до 20000."
        fi
    done
    
    # Настройка окружения узла
    export ENVIRONMENT=testnet
    export LOG_LEVEL=debug
    export LOG_PRETTY=false
    export EXECUTOR_PROCESS_BIDS_ENABLED=true
    export EXECUTOR_PROCESS_ORDERS_ENABLED=true
    export EXECUTOR_PROCESS_CLAIMS_ENABLED=true
    export PRIVATE_KEY_LOCAL=$WALLET_PRIVATE_KEY
    export EXECUTOR_MAX_L3_GAS_PRICE=$GAS_VALUE
    
    # Выбор сетей для активации
    info_message "Доступные сети:"
    echo -e "${ORANGE}🔷 ARBT = arbitrum-sepolia${NC}"
    echo -e "${ORANGE}🔷 BAST = base-sepolia${NC}"
    echo -e "${ORANGE}🔷 BLST = blast-sepolia${NC}"
    echo -e "${ORANGE}🔷 OPST = optimism-sepolia${NC}"
    echo -e "${ORANGE}🔷 UNIT = unichain-sepolia${NC}"
    echo -e "${RED}✅ L2RN всегда включен.${NC}"
    
    ENABLED_NETWORKS="l2rn"  # l2rn всегда включен
    read -p "$(echo -e "${GREEN}Введите сети для активации через запятую \n[ARBT, BAST, BLST, OPST, UNIT] или 'all' для всех: ${NC}")" USER_NETWORKS
    
    if [[ -z "$USER_NETWORKS" || "$USER_NETWORKS" =~ ^[Aa][Ll][Ll]$ ]]; then
        ENABLED_NETWORKS="$ENABLED_NETWORKS,arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,unichain-sepolia"
        success_message "Выбраны все сети"
    else
        IFS=',' read -r -a networks <<< "$USER_NETWORKS"
        for network in "${networks[@]}"; do
            case "$network" in
                ARBT)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,arbitrum-sepolia"
                    ;;
                BAST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,base-sepolia"
                    ;;
                BLST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,blast-sepolia"
                    ;;
                OPST)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,optimism-sepolia"
                    ;;
                UNIT)
                    ENABLED_NETWORKS="$ENABLED_NETWORKS,unichain-sepolia"
                    ;;
                *)
                    warning_message "Неверная сеть: $network. Пропускаем."
                    ;;
            esac
        done
    fi
    export ENABLED_NETWORKS
    success_message "Настройка сетей завершена"
    
    # Настройка RPC эндпоинтов
    # RPC эндпоинты по умолчанию
    DEFAULT_RPC_ENDPOINTS_JSON='{
      "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
      "arbt": ["https://arbitrum-sepolia.drpc.org"],
      "bast": ["https://base-sepolia-rpc.publicnode.com"],
      "blst": ["https://sepolia.blast.io"],
      "opst": ["https://sepolia.optimism.io"],
      "unit": ["https://unichain-sepolia.drpc.org"]
    }'
    
    # Инициализация RPC_ENDPOINTS_JSON значениями по умолчанию
    RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"
    
    # Если выбран Alchemy RPC, добавляем Alchemy эндпоинты
    if [[ "$NODE_TYPE" == "alchemy-rpc" ]]; then
        info_message "Добавление Alchemy RPC endpoints..."
        RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq \
            --arg arbt "https://arb-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
            --arg bast "https://base-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
            --arg opst "https://opt-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
            --arg blst "https://blast-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
            --arg unit "https://unichain-sepolia.g.alchemy.com/v2/$ALCHEMY_API_KEY" \
            '.arbt = (.arbt + [$arbt]) |
             .bast = (.bast + [$bast]) |
             .opst = (.opst + [$opst]) |
             .blst = (.blst + [$blst]) |
             .unit = (.unit + [$unit])')
    fi
    
    # Минификация JSON
    export RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)
    success_message "Настройка RPC эндпоинтов завершена"
    
    # Вывод настроек
    info_message "Собранные данные и настройки:"
    echo -e "${ORANGE}🏷️ Тип узла:${NC} ${BLUE}$NODE_TYPE${NC}"
    echo -e "${ORANGE}⛽ Значение газа:${NC} ${BLUE}$GAS_VALUE${NC}"
    echo -e "${ORANGE}🌐 Активные сети:${NC} ${BLUE}$ENABLED_NETWORKS${NC}"
}

# Функция для управления RPC
manage_rpc() {
    echo -e "\n${BOLD}${BLUE}🔌 Управление RPC для ноды T3RN...${NC}\n"
    
    # Проверка наличия установленной ноды
    if [ ! -f "$HOME/t3rn/executor/executor/bin/executor" ]; then
        error_message "Нода не установлена. Сначала выполните установку."
        return 1
    fi
    
    # Подменю для работы с RPC
    echo -e "${BOLD}${BLUE}Выберите действие:${NC}\n"
    echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}📊 Просмотр текущих RPC endpoints${NC}"
    echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}✏️ Изменение одного RPC endpoint${NC}"
    echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}📝 Изменение всех RPC endpoints${NC}"
    echo -e "${WHITE}[${CYAN}4${WHITE}] ${GREEN}➜ ${WHITE}🔄 Сбросить RPC на значения по умолчанию${NC}"
    echo -e "${WHITE}[${CYAN}5${WHITE}] ${GREEN}➜ ${WHITE}🔙 Вернуться в главное меню${NC}\n"
    
    read -p "$(echo -e "${GREEN}Введите номер действия [1-5]:${NC} ")" rpc_choice
    
    # RPC эндпоинты по умолчанию (для сброса)
    DEFAULT_RPC_ENDPOINTS_JSON='{
      "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
      "arbt": ["https://arbitrum-sepolia.drpc.org"],
      "bast": ["https://base-sepolia-rpc.publicnode.com"],
      "blst": ["https://sepolia.blast.io"],
      "opst": ["https://sepolia.optimism.io"],
      "unit": ["https://unichain-sepolia.drpc.org"]
    }'
    
    # Переменная для хранения RPC конфигурации
    RPC_CONFIG_FILE="$HOME/t3rn/rpc_config.json"
    
    # Функция для отображения RPC в формате таблицы
    display_rpc_table() {
        local rpc_json="$1"
        
        # Вывод заголовка таблицы
        echo -e "\n${BOLD}${BLUE}┌──────────────┬─────────────────────┬──────────────────────────────────────────────────────────┐${NC}"
        echo -e "${BOLD}${BLUE}│ ${WHITE}Код сети     ${BLUE}│ ${WHITE}Название сети        ${BLUE}│ ${WHITE}RPC Endpoint                                           ${BLUE}│${NC}"
        echo -e "${BOLD}${BLUE}├──────────────┼─────────────────────┼──────────────────────────────────────────────────────────┤${NC}"
        
        # Определение сетей и их описаний
        local networks=("l2rn" "arbt" "bast" "blst" "opst" "unit")
        local network_names=("L2RN" "Arbitrum Sepolia" "Base Sepolia" "Blast Sepolia" "Optimism Sepolia" "Unichain Sepolia")
        
        # Вывод данных по каждой сети
        for i in "${!networks[@]}"; do
            local network="${networks[$i]}"
            local network_name="${network_names[$i]}"
            
            # Получаем текущий RPC для отображения
            local current_rpc=$(echo "$rpc_json" | jq -r ".$network // [] | join(\", \")")
            
            # Если RPC слишком длинный, обрезаем его для отображения
            local display_rpc="$current_rpc"
            if [ ${#display_rpc} -gt 60 ]; then
                display_rpc="${display_rpc:0:57}..."
            fi
            
            # Форматируем сеть и имя сети для выравнивания
            local net_code=$(printf "%-12s" "$network")
            local net_name=$(printf "%-19s" "$network_name")
            
            # Вывод строки таблицы
            echo -e "${BOLD}${BLUE}│ ${CYAN}$net_code ${BLUE}│ ${WHITE}$net_name ${BLUE}│ ${YELLOW}${display_rpc}${BLUE}$(printf "%$((60 - ${#display_rpc}))s")│${NC}"
        done
        
        # Вывод нижней границы таблицы
        echo -e "${BOLD}${BLUE}└──────────────┴─────────────────────┴──────────────────────────────────────────────────────────┘${NC}"
    }
    
    case $rpc_choice in
        1)
            echo -e "\n${BOLD}${BLUE}📊 Текущие RPC endpoints:${NC}"
            
            # Если файл конфигурации существует, показываем его содержимое
            if [ -f "$RPC_CONFIG_FILE" ]; then
                local RPC_ENDPOINTS_JSON=$(cat "$RPC_CONFIG_FILE")
                display_rpc_table "$RPC_ENDPOINTS_JSON"
            else
                echo -e "${YELLOW}⚠️ Конфигурационный файл RPC не найден. Отображаем стандартные эндпоинты:${NC}"
                display_rpc_table "$DEFAULT_RPC_ENDPOINTS_JSON"
            fi
            ;;
        2)
            echo -e "\n${BOLD}${BLUE}✏️ Изменение одного RPC endpoint${NC}\n"
            
            # Загружаем текущие настройки или используем дефолтные
            if [ -f "$RPC_CONFIG_FILE" ]; then
                RPC_ENDPOINTS_JSON=$(cat "$RPC_CONFIG_FILE")
            else
                RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"
            fi
            
            # Отображаем текущую конфигурацию
            display_rpc_table "$RPC_ENDPOINTS_JSON"
            
            # Запрашиваем у пользователя, какую сеть изменить
            echo -e "\n${CYAN}Введите код сети для изменения RPC (l2rn, arbt, bast, blst, opst, unit):${NC}"
            read -p "➜ " network_code
            
            # Проверяем, существует ли такая сеть
            if ! echo "$RPC_ENDPOINTS_JSON" | jq -e ".$network_code" > /dev/null 2>&1; then
                error_message "Сеть с кодом '$network_code' не найдена"
                return 1
            fi
            
            # Получаем информацию о выбранной сети и текущем RPC
            current_rpc=$(echo "$RPC_ENDPOINTS_JSON" | jq -r ".$network_code | join(\", \")")
            
            # Получаем описание сети
            network_descriptions=("L2RN" "Arbitrum Sepolia" "Base Sepolia" "Blast Sepolia" "Optimism Sepolia" "Unichain Sepolia")
            network_codes=("l2rn" "arbt" "bast" "blst" "opst" "unit")
            
            network_desc=""
            for i in "${!network_codes[@]}"; do
                if [ "${network_codes[$i]}" = "$network_code" ]; then
                    network_desc="${network_descriptions[$i]}"
                    break
                fi
            done
            
            # Отображаем текущие настройки для выбранной сети
            echo -e "\n${CYAN}Текущий RPC для ${BOLD}${WHITE}$network_desc ($network_code)${NC}${CYAN}:${NC}\n${YELLOW}$current_rpc${NC}"
            
            # Запрашиваем новое значение RPC
            echo -e "\n${GREEN}Введите новый RPC endpoint${NC} ${YELLOW}(или оставьте пустым для отмены)${NC}:"
            read -p "➜ " new_rpc
            
            if [ -n "$new_rpc" ]; then
                # Обновляем JSON с новым RPC
                RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq --arg network "$network_code" --arg endpoint "$new_rpc" \
                    '.[$network] = [$endpoint]')
                
                # Сохраняем обновленный JSON
                echo "$RPC_ENDPOINTS_JSON" > "$RPC_CONFIG_FILE"
                
                success_message "RPC для $network_desc ($network_code) обновлен на: $new_rpc"
                
                # Показываем обновленную таблицу
                echo -e "\n${CYAN}Обновленная конфигурация RPC:${NC}"
                display_rpc_table "$RPC_ENDPOINTS_JSON"
                
                # Спрашиваем о перезапуске ноды
                echo -e "\n${YELLOW}⚠️ Для применения изменений нужно перезапустить ноду.${NC}"
                echo -e "${GREEN}Хотите перезапустить ноду сейчас? (y/n)${NC}"
                read -p "➜ " restart_node
                
                if [[ "$restart_node" =~ ^[Yy]$ ]]; then
                    kill_running_executor
                    success_message "Нода остановлена. Подготовка к запуску с новыми RPC..."
                    
                    # Экспортируем переменную окружения для executor
                    export RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)
                    
                    # Запускаем ноду с новыми настройками
                    cd "$HOME/t3rn/executor/executor/bin"
                    ./executor &
                    success_message "Нода перезапущена с новыми RPC настройками"
                fi
            else
                info_message "Операция отменена, RPC не изменен"
            fi
            ;;
        3)
            echo -e "\n${BOLD}${BLUE}📝 Изменение всех RPC endpoints${NC}\n"
            
            # Загружаем текущие настройки или используем дефолтные
            if [ -f "$RPC_CONFIG_FILE" ]; then
                RPC_ENDPOINTS_JSON=$(cat "$RPC_CONFIG_FILE")
            else
                RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"
            fi
            
            # Отображаем текущую конфигурацию
            display_rpc_table "$RPC_ENDPOINTS_JSON"
            
            # Получаем информацию о доступных сетях
            networks=(l2rn arbt bast blst opst unit)
            network_names=("L2RN" "Arbitrum Sepolia" "Base Sepolia" "Blast Sepolia" "Optimism Sepolia" "Unichain Sepolia")
            
            # Обновляем RPC для каждой сети
            for i in "${!networks[@]}"; do
                network="${networks[$i]}"
                network_name="${network_names[$i]}"
                
                # Получаем текущий RPC для отображения
                current_rpc=$(echo "$RPC_ENDPOINTS_JSON" | jq -r ".$network | join(\", \")")
                
                echo -e "\n${CYAN}Текущий RPC для ${BOLD}${WHITE}$network_name ($network)${NC}${CYAN}:${NC} ${YELLOW}$current_rpc${NC}"
                echo -e "${GREEN}Введите новый RPC${NC} ${YELLOW}(или оставьте пустым для сохранения текущего)${NC}:"
                read -p "➜ " new_endpoint
                
                if [ -n "$new_endpoint" ]; then
                    # Обновляем JSON с новым RPC
                    RPC_ENDPOINTS_JSON=$(echo "$RPC_ENDPOINTS_JSON" | jq --arg network "$network" --arg endpoint "$new_endpoint" \
                        '.[$network] = [$endpoint]')
                    success_message "RPC для $network_name обновлен"
                else
                    info_message "RPC для $network_name оставлен без изменений"
                fi
            done
            
            # Сохраняем обновленный JSON
            echo "$RPC_ENDPOINTS_JSON" > "$RPC_CONFIG_FILE"
            success_message "Конфигурация RPC сохранена"
            
            # Показываем обновленную таблицу
            echo -e "\n${CYAN}Обновленная конфигурация RPC:${NC}"
            display_rpc_table "$RPC_ENDPOINTS_JSON"
            
            # Спрашиваем о перезапуске ноды
            echo -e "\n${YELLOW}⚠️ Для применения изменений нужно перезапустить ноду.${NC}"
            echo -e "${GREEN}Хотите перезапустить ноду сейчас? (y/n)${NC}"
            read -p "➜ " restart_node
            
            if [[ "$restart_node" =~ ^[Yy]$ ]]; then
                kill_running_executor
                success_message "Нода остановлена. Подготовка к запуску с новыми RPC..."
                
                # Экспортируем переменную окружения для executor
                export RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)
                
                # Запускаем ноду с новыми настройками
                cd "$HOME/t3rn/executor/executor/bin"
                ./executor &
                success_message "Нода перезапущена с новыми RPC настройками"
            fi
            ;;
        4)
            echo -e "\n${BOLD}${BLUE}🔄 Сброс RPC на значения по умолчанию${NC}\n"
            
            # Показываем текущие настройки
            if [ -f "$RPC_CONFIG_FILE" ]; then
                echo -e "${CYAN}Текущие настройки RPC:${NC}"
                display_rpc_table "$(cat "$RPC_CONFIG_FILE")"
            fi
            
            echo -e "\n${CYAN}Настройки RPC по умолчанию:${NC}"
            display_rpc_table "$DEFAULT_RPC_ENDPOINTS_JSON"
            
            echo -e "\n${YELLOW}⚠️ Вы уверены, что хотите сбросить все RPC настройки на значения по умолчанию? (y/n)${NC}"
            read -p "➜ " confirm_reset
            
            if [[ "$confirm_reset" =~ ^[Yy]$ ]]; then
                echo "$DEFAULT_RPC_ENDPOINTS_JSON" > "$RPC_CONFIG_FILE"
                success_message "RPC настройки сброшены на значения по умолчанию"
                
                # Спрашиваем о перезапуске ноды
                echo -e "${YELLOW}⚠️ Для применения изменений нужно перезапустить ноду.${NC}"
                echo -e "${GREEN}Хотите перезапустить ноду сейчас? (y/n)${NC}"
                read -p "➜ " restart_node
                
                if [[ "$restart_node" =~ ^[Yy]$ ]]; then
                    kill_running_executor
                    success_message "Нода остановлена. Подготовка к запуску с дефолтными RPC..."
                    
                    # Экспортируем переменную окружения для executor
                    export RPC_ENDPOINTS=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -c .)
                    
                    # Запускаем ноду с новыми настройками
                    cd "$HOME/t3rn/executor/executor/bin"
                    ./executor &
                    success_message "Нода перезапущена с дефолтными RPC настройками"
                fi
            else
                info_message "Сброс настроек отменен"
            fi
            ;;
        5)
            info_message "Возвращаемся в главное меню"
            return 0
            ;;
        *)
            error_message "Неверный выбор. Пожалуйста, введите номер от 1 до 5."
            ;;
    esac
}

# Функция для установки конкретной версии ноды
install_specific_version() {
    echo -e "\n${BOLD}${BLUE}⏮️ Установка конкретной версии ноды T3RN...${NC}\n"
    
    # Получаем список доступных версий с GitHub API
    echo -e "${WHITE}[${CYAN}1/4${WHITE}] ${GREEN}➜ ${WHITE}🔍 Получение списка доступных версий...${NC}"
    RELEASES=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases)
    
    if [ -z "$RELEASES" ] || [ "$RELEASES" = "[]" ]; then
        error_message "Не удалось получить список релизов. Проверьте подключение к интернету."
        return 1
    fi
    
    # Выводим список доступных версий (последние 10)
    echo -e "\n${CYAN}Доступные версии ноды T3RN:${NC}\n"
    
    # Используем jq для извлечения имен тегов (версий) и дат релизов
    TAGS=()
    echo "$RELEASES" | jq -r '.[] | "\(.tag_name) - \(.published_at | fromdateiso8601 | strftime("%d-%m-%Y"))"' | head -10 | nl -w2 -s') '
    
    # Сохраняем теги в массив для последующего выбора
    mapfile -t TAGS < <(echo "$RELEASES" | jq -r '.[].tag_name' | head -10)
    
    # Запрашиваем у пользователя выбор версии
    echo -e "\n${GREEN}Введите номер версии для установки (1-${#TAGS[@]}):${NC}"
    read -p "➜ " version_choice
    
    # Проверка корректности ввода
    if ! [[ "$version_choice" =~ ^[0-9]+$ ]] || [ "$version_choice" -lt 1 ] || [ "$version_choice" -gt "${#TAGS[@]}" ]; then
        error_message "Неверный выбор. Пожалуйста, введите номер от 1 до ${#TAGS[@]}."
        return 1
    fi
    
    # Выбранная версия
    SELECTED_TAG="${TAGS[$version_choice-1]}"
    success_message "Выбрана версия: $SELECTED_TAG"
    
    echo -e "${WHITE}[${CYAN}2/4${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка работающих экземпляров...${NC}"
    kill_running_executor
    success_message "Подготовка к установке завершена"
    
    echo -e "${WHITE}[${CYAN}3/4${WHITE}] ${GREEN}➜ ${WHITE}🧹 Очистка предыдущей установки...${NC}"
    if [ -d "$HOME/t3rn" ]; then
        rm -rf "$HOME/t3rn"
    fi
    if [ -d "$HOME/executor" ]; then
        rm -rf "$HOME/executor"
    fi
    if ls executor-linux-*.tar.gz 1> /dev/null 2>&1; then
        rm -f executor-linux-*.tar.gz
    fi
    success_message "Предыдущая установка очищена"
    
    echo -e "${WHITE}[${CYAN}4/4${WHITE}] ${GREEN}➜ ${WHITE}📥 Установка версии $SELECTED_TAG...${NC}"
    
    # Создаем директорию и загружаем выбранную версию
    mkdir -p "$HOME/t3rn"
    cd "$HOME/t3rn"
    
    DOWNLOAD_URL="https://github.com/t3rn/executor-release/releases/download/$SELECTED_TAG/executor-linux-$SELECTED_TAG.tar.gz"
    wget --progress=bar:force:noscroll "$DOWNLOAD_URL" -O "executor-linux-$SELECTED_TAG.tar.gz"
    
    if [ $? -ne 0 ]; then
        error_message "Не удалось загрузить выбранную версию. Проверьте URL и попробуйте снова."
        return 1
    fi
    
    # Распаковываем архив
    tar -xvzf "executor-linux-$SELECTED_TAG.tar.gz"
    if [ $? -ne 0 ]; then
        error_message "Не удалось извлечь архив. Проверьте файл и попробуйте снова."
        return 1
    fi
    
    # Подготавливаем исполняемый файл
    mkdir -p executor/executor/bin
    cd executor/executor/bin || {
        error_message "Не удалось перейти к расположению бинарного файла executor."
        return 1
    }
    chmod +x executor
    
    # Настройка ноды
    echo -e "\n${CYAN}Теперь нужно настроить ноду.${NC}"
    configure_node
    
    # Запуск ноды
    echo -e "\n${GREEN}🚀 Запуск ноды версии $SELECTED_TAG...${NC}"
    ./executor &
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода T3RN версии $SELECTED_TAG успешно установлена и запущена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Основной цикл программы
main() {
    while true; do
        clear
        # Отображение логотипа
        curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
        
        print_menu
        echo -e "${BOLD}${BLUE}📝 Введите номер действия [1-9]:${NC} "
        read -p "➜ " choice
        
        case $choice in
            1)
                setup_node
                ;;
            2)
                start_node
                ;;
            3)
                update_node
                ;;
            4)
                check_logs
                ;;
            5)
                check_status
                ;;
            6)
                manage_rpc
                ;;
            7)
                install_specific_version
                ;;
            8)
                remove_node
                ;;
            9)
                echo -e "\n${GREEN}👋 До свидания!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}❌ Ошибка: Неверный выбор! Пожалуйста, введите номер от 1 до 9.${NC}\n"
                ;;
        esac
        
        if [ "$choice" != "4" ]; then
            echo -e "\nНажмите Enter, чтобы вернуться в меню..."
            read
        fi
    done
}

# Запуск основного цикла, если скрипт запущен напрямую
# или выполнение функций из командной строки, если переданы аргументы
if [[ $# -eq 0 ]]; then
    main
else
    # Разбор аргументов командной строки
    VERBOSE=false
    DRY_RUN=false
    for arg in "$@"; do
        case "$arg" in
            --verbose)
                VERBOSE=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --help)
                usage
                ;;
            *)
                echo -e "${RED}Неизвестный аргумент: $arg${NC}"
                usage
                ;;
        esac
    done
    
    # Установка jq
    install_jq_if_needed
    
    # Включение подробного режима, если запрошено
    if $VERBOSE; then
        set -x
    fi
    
    # Сообщение о режиме dry-run
    if $DRY_RUN; then
        echo -e "${ORANGE}Режим dry-run включен. Изменения не будут внесены.${NC}"
    fi
    
    # Запуск установки
    setup_node
fi
