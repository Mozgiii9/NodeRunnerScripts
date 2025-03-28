#!/bin/bash

# Определение цветов для более информативного вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
ORANGE='\033[0;38;5;208m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Создаем директорию для логов
mkdir -p "$HOME/t3rn"

# Определяем пути к файлам логов
SETUP_LOG="$HOME/t3rn/setup.log"
NODE_LOG="$HOME/t3rn/node.log"

# Инициализируем лог-файл установки, если он не существует
if [ ! -f "$SETUP_LOG" ]; then
    touch "$SETUP_LOG"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Инициализация лог-файла установки" >> "$SETUP_LOG"
fi

# Инициализируем лог-файл ноды, если он не существует
if [ ! -f "$NODE_LOG" ]; then
    touch "$NODE_LOG"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Инициализация лог-файла ноды" >> "$NODE_LOG"
fi

# Создаем функцию для логирования в файл без вывода на экран
log_to_file() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $message" >> "$SETUP_LOG"
}

# Функция для отображения успешных сообщений
success_message() {
    echo -e "${GREEN}[✅] $1${NC}"
    log_to_file "[SUCCESS] $1"
}

# Функция для отображения информационных сообщений
info_message() {
    echo -e "${CYAN}[ℹ️] $1${NC}"
    log_to_file "[INFO] $1"
}

# Функция для отображения ошибок
error_message() {
    echo -e "${RED}[❌] $1${NC}"
    log_to_file "[ERROR] $1"
}

# Функция для отображения предупреждений
warning_message() {
    echo -e "${YELLOW}[⚠️] $1${NC}"
    log_to_file "[WARNING] $1"
}

# Очистка экрана
clear

# Функция для отображения локального ASCII логотипа
display_logo() {
    echo -e "${CYAN}"
    echo -e "    ███╗   ██╗ ██████╗ ██████╗ ███████╗██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗  "
    echo -e "    ████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗ "
    echo -e "    ██╔██╗ ██║██║   ██║██║  ██║█████╗  ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝ "
    echo -e "    ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗ "
    echo -e "    ██║ ╚████║╚██████╔╝██████╔╝███████╗██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║ "
    echo -e "    ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ "
    echo -e "${NC}"
    echo -e "${BOLD}${BLUE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║             T3RN NODE MANAGER             ║${NC}"
    echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════╝${NC}"
    echo -e ""
}

# Функция для отображения меню
print_menu() {
    echo -e "${BOLD}${ORANGE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${ORANGE}║             🌟 МЕНЮ T3RN 🌟              ║${NC}"
    echo -e "${BOLD}${ORANGE}╚══════════════════════════════════════════╝${NC}"
    echo -e "${BOLD}${WHITE}1.${NC} ${BLUE}Установка ноды${NC}"
    echo -e "${BOLD}${WHITE}2.${NC} ${BLUE}Установка конкретной версии${NC}"
    echo -e "${BOLD}${WHITE}3.${NC} ${BLUE}Проверка логов${NC}"
    echo -e "${BOLD}${WHITE}4.${NC} ${BLUE}Управление RPC${NC}"
    echo -e "${BOLD}${WHITE}5.${NC} ${BLUE}Управление газом${NC}"
    echo -e "${BOLD}${WHITE}6.${NC} ${BLUE}Обновление ноды${NC}"
    echo -e "${BOLD}${WHITE}7.${NC} ${BLUE}Удаление ноды${NC}"
    echo -e "${BOLD}${WHITE}8.${NC} ${BLUE}Выход${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Введите номер опции:${NC}"
}

# Log file for debugging
LOG_FILE="$HOME/t3rn/setup.log"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
# Отключаем глобальное перенаправление
# exec > >(tee -a "$LOG_FILE") 2>&1

# RPC эндпоинты по умолчанию - определяем глобально
DEFAULT_RPC_ENDPOINTS_JSON='{
  "l2rn": ["https://b2n.rpc.caldera.xyz/http"],
  "arbt": ["https://arbitrum-sepolia.drpc.org"],
  "bast": ["https://base-sepolia-rpc.publicnode.com"],
  "blst": ["https://sepolia.blast.io"],
  "opst": ["https://sepolia.optimism.io"],
  "unit": ["https://unichain-sepolia.drpc.org"]
}'

# Извлечение эндпоинтов по умолчанию из JSON
DEFAULT_RPC_ENDPOINTS_ARBT=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.arbt[0]')
DEFAULT_RPC_ENDPOINTS_BSSP=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.bast[0]')
DEFAULT_RPC_ENDPOINTS_BLSS=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.blst[0]')
DEFAULT_RPC_ENDPOINTS_OPSP=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.opst[0]')
DEFAULT_RPC_ENDPOINTS_UNIT=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.unit[0]')
DEFAULT_RPC_ENDPOINTS_L2RN=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -r '.l2rn[0]')

echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${WHITE}║           🚀 T3RN NODE SETUP           ║${NC}"
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

# Функция для управления RPC
manage_rpc() {
    local return_to_main=false
    
    while [ "$return_to_main" = false ]; do
        clear
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
        
        # Переменная для хранения RPC конфигурации
        RPC_CONFIG_FILE="$HOME/t3rn/rpc_config.json"
        
        # Функция для отображения RPC в формате таблицы
        display_rpc_table() {
            local rpc_json="$1"
            
            # Определяем сети и их описания
            local networks=("l2rn" "arbt" "bast" "blst" "opst" "unit")
            local network_names=("L2RN" "Arbitrum Sepolia" "Base Sepolia" "Blast Sepolia" "Optimism Sepolia" "Unichain Sepolia")
            
            # Устанавливаем фиксированную ширину колонок
            local col1_width=15  # Код сети
            local col2_width=25  # Название сети
            local col3_width=70  # RPC Endpoint
            
            # Выводим заголовок
            echo -e "\n${CYAN}📊 Текущие RPC endpoints:${NC}"
            
            # Верхняя граница таблицы
            echo -e "${BOLD}${BLUE}┌───────────────┬─────────────────────────┬──────────────────────────────────────────────────────────────────┐${NC}"
            
            # Заголовки колонок
            echo -e "${BOLD}${BLUE}│${WHITE} Код сети      ${BLUE}│${WHITE} Название сети           ${BLUE}│${WHITE} RPC Endpoint                                                   ${BLUE}│${NC}"
            
            # Разделитель после заголовков
            echo -e "${BOLD}${BLUE}├───────────────┼─────────────────────────┼──────────────────────────────────────────────────────────────────┤${NC}"
            
            # Вывод строк с данными
            for i in "${!networks[@]}"; do
                local network="${networks[$i]}"
                local network_name="${network_names[$i]}"
                
                # Получаем текущий RPC для отображения
                local current_rpc=$(echo "$rpc_json" | jq -r ".$network // [] | join(\", \")")
                
                # Если RPC слишком длинный, обрезаем его для отображения
                local display_rpc="$current_rpc"
                if [ ${#display_rpc} -gt $((col3_width-5)) ]; then
                    display_rpc="${display_rpc:0:$((col3_width-8))}..."
                fi
                
                # Форматируем вывод строки данных
                echo -e "${BOLD}${BLUE}│${CYAN} $(printf "%-13s" "$network")${BLUE}│${WHITE} $(printf "%-23s" "$network_name")${BLUE}│${YELLOW} $(printf "%-68s" "$display_rpc")${BLUE}│${NC}"
            done
            
            # Выводим нижнюю границу таблицы
            echo -e "${BOLD}${BLUE}└───────────────┴─────────────────────────┴──────────────────────────────────────────────────────────────────┘${NC}"
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
                
                # Ожидаем нажатия Enter перед возвратом в меню RPC
                echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню RPC...${NC}"
                read -s
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
                    sleep 2
                    continue
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
                        
                        # Проверяем доступность порта 9090
                        check_and_free_port
                        if [ $? -ne 0 ]; then
                            echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню RPC...${NC}"
                            read -s
                            continue
                        fi
                        
                        # Экспортируем переменную окружения для executor
                        export RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)
                        
                        # Запускаем ноду с новыми настройками
                        cd "$HOME/t3rn/executor/executor/bin"
                        ./executor > "$HOME/t3rn/node.log" 2>&1 &
                        local NODE_PID=$!
                        
                        # Проверяем, запустилась ли нода успешно
                        sleep 3
                        if ps -p $NODE_PID > /dev/null; then
                            success_message "Нода перезапущена с новыми RPC настройками (PID: $NODE_PID)"
                        else
                            error_message "Возникла ошибка при запуске ноды. Проверьте логи для дополнительной информации."
                        fi
                    fi
                else
                    info_message "Операция отменена, RPC не изменен"
                fi
                
                # Ожидаем нажатия Enter перед возвратом в меню RPC
                echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню RPC...${NC}"
                read -s
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
                    
                    # Проверяем доступность порта 9090
                    check_and_free_port
                    if [ $? -ne 0 ]; then
                        echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню RPC...${NC}"
                        read -s
                        continue
                    fi
                    
                    # Экспортируем переменную окружения для executor
                    export RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)
                    
                    # Запускаем ноду с новыми настройками
                    cd "$HOME/t3rn/executor/executor/bin"
                    ./executor > "$HOME/t3rn/node.log" 2>&1 &
                    local NODE_PID=$!
                    
                    # Проверяем, запустилась ли нода успешно
                    sleep 3
                    if ps -p $NODE_PID > /dev/null; then
                        success_message "Нода перезапущена с новыми RPC настройками (PID: $NODE_PID)"
                    else
                        error_message "Возникла ошибка при запуске ноды. Проверьте логи для дополнительной информации."
                    fi
                fi
                
                # Ожидаем нажатия Enter перед возвратом в меню RPC
                echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню RPC...${NC}"
                read -s
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
                        
                        # Проверяем доступность порта 9090
                        check_and_free_port
                        if [ $? -ne 0 ]; then
                            echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню RPC...${NC}"
                            read -s
                            continue
                        fi
                        
                        # Экспортируем переменную окружения для executor
                        export RPC_ENDPOINTS=$(echo "$DEFAULT_RPC_ENDPOINTS_JSON" | jq -c .)
                        
                        # Запускаем ноду с новыми настройками
                        cd "$HOME/t3rn/executor/executor/bin"
                        ./executor > "$HOME/t3rn/node.log" 2>&1 &
                        local NODE_PID=$!
                        
                        # Проверяем, запустилась ли нода успешно
                        sleep 3
                        if ps -p $NODE_PID > /dev/null; then
                            success_message "Нода перезапущена с дефолтными RPC настройками (PID: $NODE_PID)"
                        else
                            error_message "Возникла ошибка при запуске ноды. Проверьте логи для дополнительной информации."
                        fi
                    fi
                else
                    info_message "Сброс настроек отменен"
                fi
                
                # Ожидаем нажатия Enter перед возвратом в меню RPC
                echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню RPC...${NC}"
                read -s
                ;;
            5)
                info_message "Возвращаемся в главное меню"
                return_to_main=true
                ;;
            *)
                error_message "Неверный выбор. Пожалуйста, введите номер от 1 до 5."
                sleep 2
            ;;
    esac
done

    return 0
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
        # Сохраняем файлы логов, если они существуют
        if [ -f "$HOME/t3rn/setup.log" ]; then
            cp "$HOME/t3rn/setup.log" "/tmp/t3rn_setup.log.backup"
        fi
        if [ -f "$HOME/t3rn/node.log" ]; then
            cp "$HOME/t3rn/node.log" "/tmp/t3rn_node.log.backup"
        fi
        # Сохраняем конфигурационный файл газа, если он существует
        if [ -f "$HOME/t3rn/gas_config.txt" ]; then
            cp "$HOME/t3rn/gas_config.txt" "/tmp/t3rn_gas_config.backup"
        fi
        # Сохраняем конфигурационный файл RPC, если он существует
        if [ -f "$HOME/t3rn/rpc_config.json" ]; then
            cp "$HOME/t3rn/rpc_config.json" "/tmp/t3rn_rpc_config.backup"
        fi
        
        rm -rf "$HOME/t3rn"
        
        # Создаем директорию заново и восстанавливаем логи и конфигурацию
        mkdir -p "$HOME/t3rn"
        if [ -f "/tmp/t3rn_setup.log.backup" ]; then
            cp "/tmp/t3rn_setup.log.backup" "$HOME/t3rn/setup.log"
        fi
        if [ -f "/tmp/t3rn_node.log.backup" ]; then
            cp "/tmp/t3rn_node.log.backup" "$HOME/t3rn/node.log"
        fi
        if [ -f "/tmp/t3rn_gas_config.backup" ]; then
            cp "/tmp/t3rn_gas_config.backup" "$HOME/t3rn/gas_config.txt"
        fi
        if [ -f "/tmp/t3rn_rpc_config.backup" ]; then
            cp "/tmp/t3rn_rpc_config.backup" "$HOME/t3rn/rpc_config.json"
        fi
    else
        mkdir -p "$HOME/t3rn"
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
    
    # Запуск ноды (автоматически)
    echo -e "\n${GREEN}🚀 Запуск ноды версии $SELECTED_TAG...${NC}"
    
    # Проверяем доступность порта 9090 перед запуском
    check_and_free_port
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Создаем файл для логов ноды, если он не существует
    NODE_LOG="$HOME/t3rn/node.log"
    touch "$NODE_LOG"
    
    # Запуск ноды в фоновом режиме с перенаправлением вывода в лог-файл
    ./executor > "$NODE_LOG" 2>&1 &
    local NODE_PID=$!
    
    # Проверяем, запустилась ли нода успешно
    sleep 3
    if ps -p $NODE_PID > /dev/null; then
        success_message "Нода версии $SELECTED_TAG запущена (PID: $NODE_PID)"
        success_message "Логи работы ноды сохраняются в: $NODE_LOG"
    else
        error_message "Возникла ошибка при запуске ноды. Проверьте логи для дополнительной информации."
        return 1
    fi
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода T3RN версии $SELECTED_TAG успешно установлена и запущена!${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для настройки ноды (используется при установке)
configure_node() {
    # Локальная переменная для хранения пути к файлу конфигурации газа
    local gas_config_file="$HOME/t3rn/gas_config.txt"
    
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
            # Сохраняем значение газа в файл конфигурации для будущего использования
            echo "$GAS_VALUE" > "$gas_config_file"
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
    # Инициализация RPC_ENDPOINTS_JSON значениями по умолчанию
    RPC_ENDPOINTS_JSON="$DEFAULT_RPC_ENDPOINTS_JSON"
    
    # Если выбран Alchemy RPC, добавляем Alchemy эндпоинты
if [[ "$NODE_TYPE" == "alchemy-rpc" ]]; then
        info_message "Добавление Alchemy RPC endpoints..."
        configure_rpc_endpoints
    fi
    
    # Минификация JSON и сохранение в файл конфигурации
    RPC_CONFIG_FILE="$HOME/t3rn/rpc_config.json"
    echo "$RPC_ENDPOINTS_JSON" > "$RPC_CONFIG_FILE"
    
    # Экспортируем переменную окружения для executor
    export RPC_ENDPOINTS=$(echo "$RPC_ENDPOINTS_JSON" | jq -c .)
    success_message "Настройка RPC эндпоинтов завершена"
    
    # Вывод настроек
    info_message "Собранные данные и настройки:"
    echo -e "${ORANGE}🏷️ Тип узла:${NC} ${BLUE}$NODE_TYPE${NC}"
    echo -e "${ORANGE}⛽ Значение газа:${NC} ${BLUE}$GAS_VALUE${NC}"
    echo -e "${ORANGE}🌐 Активные сети:${NC} ${BLUE}$ENABLED_NETWORKS${NC}"
}

# Функция для установки полной ноды с параметрами
setup_node() {
    # Переносим оригинальную функциональность скрипта сюда
    echo -e "\n${BOLD}${BLUE}🛠️ Установка ноды T3RN...${NC}\n"
    
    echo -e "${WHITE}[${CYAN}1/5${WHITE}] ${GREEN}➜ ${WHITE}🧹 Очистка предыдущих установок...${NC}"
    # Сначала проверяем и останавливаем ноду, если она запущена
    kill_running_executor
    
    if [ -d "$HOME/t3rn" ]; then
        # Сохраняем файлы логов, если они существуют
        if [ -f "$HOME/t3rn/setup.log" ]; then
            cp "$HOME/t3rn/setup.log" "/tmp/t3rn_setup.log.backup"
        fi
        if [ -f "$HOME/t3rn/node.log" ]; then
            cp "$HOME/t3rn/node.log" "/tmp/t3rn_node.log.backup"
        fi
        # Сохраняем конфигурационный файл газа, если он существует
        if [ -f "$HOME/t3rn/gas_config.txt" ]; then
            cp "$HOME/t3rn/gas_config.txt" "/tmp/t3rn_gas_config.backup"
        fi
        # Сохраняем конфигурационный файл RPC, если он существует
        if [ -f "$HOME/t3rn/rpc_config.json" ]; then
            cp "$HOME/t3rn/rpc_config.json" "/tmp/t3rn_rpc_config.backup"
        fi
        
        rm -rf "$HOME/t3rn"
        
        # Создаем директорию заново и восстанавливаем логи и конфигурацию
        mkdir -p "$HOME/t3rn"
        if [ -f "/tmp/t3rn_setup.log.backup" ]; then
            cp "/tmp/t3rn_setup.log.backup" "$HOME/t3rn/setup.log"
        fi
        if [ -f "/tmp/t3rn_node.log.backup" ]; then
            cp "/tmp/t3rn_node.log.backup" "$HOME/t3rn/node.log"
        fi
        if [ -f "/tmp/t3rn_gas_config.backup" ]; then
            cp "/tmp/t3rn_gas_config.backup" "$HOME/t3rn/gas_config.txt"
        fi
        if [ -f "/tmp/t3rn_rpc_config.backup" ]; then
            cp "/tmp/t3rn_rpc_config.backup" "$HOME/t3rn/rpc_config.json"
        fi
    else
        mkdir -p "$HOME/t3rn"
    fi
    
    if [ -d "$HOME/executor" ]; then
        rm -rf "$HOME/executor"
    fi
    
    if ls executor-linux-*.tar.gz 1> /dev/null 2>&1; then
        rm -f executor-linux-*.tar.gz
    fi
    success_message "Предыдущие установки очищены"
    
    echo -e "${WHITE}[${CYAN}2/5${WHITE}] ${GREEN}➜ ${WHITE}📥 Загрузка последней версии...${NC}"
    cd "$HOME/t3rn" || { 
        error_message "Не удалось перейти в директорию t3rn"
        return 1
    }
    
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
    
    echo -e "${WHITE}[${CYAN}3/5${WHITE}] ${GREEN}➜ ${WHITE}📦 Распаковка архива...${NC}"
    tar -xvzf "executor-linux-$LATEST_TAG.tar.gz"
    if [ $? -ne 0 ]; then
        error_message "Не удалось извлечь архив. Проверьте файл и попробуйте снова."
        return 1
    fi
    success_message "Архив распакован"
    
    echo -e "${WHITE}[${CYAN}4/5${WHITE}] ${GREEN}➜ ${WHITE}⚙️ Настройка ноды...${NC}"
    mkdir -p executor/executor/bin
    cd executor/executor/bin || {
        error_message "Не удалось перейти к расположению бинарного файла executor"
        return 1
    }
    chmod +x executor
    
    # Здесь вызываем функцию для настройки ноды
    configure_node
    success_message "Настройка завершена"
    
    echo -e "${WHITE}[${CYAN}5/5${WHITE}] ${GREEN}➜ ${WHITE}▶️ Запуск ноды...${NC}"
    
    # Проверяем доступность порта 9090 перед запуском
    check_and_free_port
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Создаем файл для логов ноды, если он не существует
    NODE_LOG="$HOME/t3rn/node.log"
    touch "$NODE_LOG"
    
    # Запуск ноды в фоновом режиме с перенаправлением вывода в лог-файл
    ./executor > "$NODE_LOG" 2>&1 &
    local NODE_PID=$!
    
    # Проверяем, запустилась ли нода успешно
    sleep 3
    if ps -p $NODE_PID > /dev/null; then
        success_message "Нода запущена в фоновом режиме (PID: $NODE_PID)"
        success_message "Логи работы ноды сохраняются в: $NODE_LOG"
    else
        error_message "Возникла ошибка при запуске ноды. Проверьте логи для дополнительной информации."
        return 1
    fi
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода T3RN успешно установлена и запущена!${NC}"
    echo -e "${CYAN}Версия: ${LATEST_TAG}${NC}"
    echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
}

# Функция для проверки и освобождения порта 9090
check_and_free_port() {
    echo -e "${WHITE}[${CYAN}*${WHITE}] ${GREEN}➜ ${WHITE}🔍 Проверка доступности порта 9090...${NC}"
    
    # Проверяем, занят ли порт 9090
    local port_pid=$(lsof -ti:9090)
    
    if [ -n "$port_pid" ]; then
        warning_message "Порт 9090 уже занят процессом с PID: $port_pid"
        echo -e "${ORANGE}Это может произойти, если предыдущая нода не была корректно остановлена.${NC}"
        echo -e "${YELLOW}Хотите освободить порт 9090, завершив процесс? (y/n)${NC}"
        read -p "➜ " free_port
        
        if [[ "$free_port" =~ ^[Yy]$ ]]; then
            echo -e "${ORANGE}Завершение процесса с PID: $port_pid...${NC}"
            kill -9 $port_pid
    sleep 2
            
            # Проверяем, освободился ли порт
            if lsof -ti:9090 > /dev/null; then
                error_message "Не удалось освободить порт 9090. Пожалуйста, перезагрузите сервер или освободите порт вручную."
                return 1
            else
                success_message "Порт 9090 успешно освобожден"
            fi
        else
            error_message "Порт 9090 занят. Запуск ноды невозможен. Перезагрузите сервер или освободите порт вручную."
            return 1
        fi
    else
        success_message "Порт 9090 свободен"
    fi
    
    return 0
}

# Функция для управления газом
manage_gas() {
    local return_to_main=false
    local gas_config_file="$HOME/t3rn/gas_config.txt"
    local current_gas_value
    
    while [ "$return_to_main" = false ]; do
        clear
        echo -e "\n${BOLD}${BLUE}⛽ Управление газом для ноды T3RN...${NC}\n"
        
        # Проверка наличия установленной ноды
        if [ ! -f "$HOME/t3rn/executor/executor/bin/executor" ]; then
            error_message "Нода не установлена. Сначала выполните установку."
            return 1
        fi
        
        # Получаем текущее значение газа из конфигурационного файла или из запущенной ноды
        if [ -f "$gas_config_file" ]; then
            current_gas_value=$(cat "$gas_config_file")
        else
            # Проверяем, запущена ли нода
            NODE_PID=$(pgrep -f "./executor")
            if [ -n "$NODE_PID" ]; then
                # Попытка определить значение газа из переменных окружения процесса
                if command -v pgrep > /dev/null && command -v xargs > /dev/null && command -v grep > /dev/null; then
                    gas_from_env=$(pgrep -f "./executor" | xargs -I{} grep -z "MAX_L3_GAS_PRICE" /proc/{}/environ 2>/dev/null | tr '\0' '\n' | grep "EXECUTOR_MAX_L3_GAS_PRICE" | cut -d= -f2)
                    if [ -n "$gas_from_env" ]; then
                        current_gas_value=$gas_from_env
                    else
                        current_gas_value="Не удалось определить"
                    fi
                else
                    current_gas_value="Не удалось определить"
                fi
            else
                current_gas_value="Нода не запущена"
            fi
        fi
        
        # Отображаем информацию
        echo -e "${BOLD}${WHITE}╔══════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${WHITE}║           ТЕКУЩЕЕ ЗНАЧЕНИЕ ГАЗА          ║${NC}"
        echo -e "${BOLD}${WHITE}╚══════════════════════════════════════════╝${NC}"
        
        echo -e "${CYAN}Текущее установленное значение газа:${NC} ${YELLOW}$current_gas_value${NC}\n"
        
        # Подменю для работы с газом
        echo -e "${BOLD}${BLUE}Выберите действие:${NC}\n"
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}🔄 Изменить значение газа${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🔙 Вернуться в главное меню${NC}\n"
        
        read -p "$(echo -e "${GREEN}Введите номер действия [1-2]:${NC} ")" gas_choice
        
        case $gas_choice in
            1)
                echo -e "\n${BOLD}${BLUE}🔄 Изменение значения газа${NC}\n"
                
                # Предупреждение о перезапуске ноды
                echo -e "${YELLOW}⚠️ Для применения нового значения газа потребуется перезапуск ноды.${NC}\n"
                
                # Запрашиваем новое значение газа
                echo -e "${CYAN}Введите новое значение газа (целое число от 100 до 20000):${NC}"
while true; do
                    read -p "➜ " new_gas_value
                    if [[ "$new_gas_value" =~ ^[0-9]+$ ]] && (( new_gas_value >= 100 && new_gas_value <= 20000 )); then
                        # Сохраняем новое значение газа
                        echo "$new_gas_value" > "$gas_config_file"
                        success_message "Значение газа установлено: $new_gas_value"
                        
                        # Спрашиваем о перезапуске ноды
                        echo -e "\n${YELLOW}⚠️ Для применения изменений нужно перезапустить ноду.${NC}"
                        echo -e "${GREEN}Хотите перезапустить ноду сейчас? (y/n)${NC}"
                        read -p "➜ " restart_node
                        
                        if [[ "$restart_node" =~ ^[Yy]$ ]]; then
                            kill_running_executor
                            success_message "Нода остановлена. Подготовка к запуску с новым значением газа..."
                            
                            # Проверяем доступность порта 9090
                            check_and_free_port
                            if [ $? -ne 0 ]; then
                                echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню газа...${NC}"
                                read -s
                                continue
                            fi
                            
                            # Экспортируем переменную окружения для executor
                            export EXECUTOR_MAX_L3_GAS_PRICE=$new_gas_value
                            
                            # Запускаем ноду с новыми настройками
                            cd "$HOME/t3rn/executor/executor/bin"
                            ./executor > "$HOME/t3rn/node.log" 2>&1 &
                            local NODE_PID=$!
                            
                            # Проверяем, запустилась ли нода успешно
                            sleep 3
                            if ps -p $NODE_PID > /dev/null; then
                                success_message "Нода перезапущена с новым значением газа (PID: $NODE_PID)"
                            else
                                error_message "Возникла ошибка при запуске ноды. Проверьте логи для дополнительной информации."
                            fi
                        fi
                        
        break
    else
                        error_message "Ошибка: Значение газа должно быть от 100 до 20000."
    fi
done

                echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню газа...${NC}"
                read -s
                ;;
                
            2)
                info_message "Возвращаемся в главное меню"
                return_to_main=true
                ;;
                
            *)
                error_message "Неверный выбор. Пожалуйста, введите 1 или 2."
                sleep 2
                ;;
        esac
    done
    
    return 0
}

# Функция для настройки RPC эндпоинтов
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

# Функция для запуска ноды
start_node() {
    echo -e "\n${BOLD}${BLUE}▶️ Запуск ноды T3RN...${NC}\n"
    
    # Проверяем, существует ли исполняемый файл
    if [ ! -f "$HOME/t3rn/executor/executor/bin/executor" ]; then
        error_message "Исполняемый файл ноды не найден. Сначала установите ноду (опция 1)."
        return 1
    fi
    
    # Проверяем, не запущена ли уже нода
    NODE_PID=$(pgrep -f executor)
    if [ -n "$NODE_PID" ]; then
        echo -e "${YELLOW}⚠️ Нода уже запущена с PID: $NODE_PID${NC}"
        echo -e "${CYAN}Хотите остановить текущую ноду и запустить заново? (y/n)${NC}"
        read -p "➜ " restart_choice
        
        if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
            echo -e "${ORANGE}🛑 Останавливаем текущую ноду...${NC}"
            kill_running_executor
            sleep 2
        else
            info_message "Операция отменена. Нода продолжает работу."
            return 0
        fi
    fi
    
    # Переходим в директорию с исполняемым файлом
    cd "$HOME/t3rn/executor/executor/bin" || {
        error_message "Не удалось перейти в директорию с исполняемым файлом."
        return 1
    }
    
    # Проверяем доступность порта 9090 перед запуском
    check_and_free_port
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Создаем файл для логов ноды, если он не существует
    NODE_LOG="$HOME/t3rn/node.log"
    touch "$NODE_LOG"
    
    echo -e "${GREEN}🚀 Запускаем ноду T3RN...${NC}"
    
    # Создаем отдельную директорию для вывода и перенаправляем stderr в stdout в фоновом режиме
    mkdir -p "$HOME/t3rn/logs"
    
    # Запускаем ноду в фоновом режиме с перенаправлением вывода в лог-файл
    # и отключением вывода в терминал
    ./executor > "$NODE_LOG" 2>&1 &
    NODE_PID=$!
    
    # Проверяем, запустилась ли нода успешно
    sleep 3
    if ps -p $NODE_PID > /dev/null; then
        success_message "Нода успешно запущена (PID: $NODE_PID)"
        success_message "Логи работы ноды сохраняются в: $NODE_LOG"
    else
        error_message "Возникла ошибка при запуске ноды. Проверьте логи для дополнительной информации."
        return 1
    fi
    
    echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✨ Нода T3RN успешно запущена!${NC}"
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
    echo -e "${YELLOW}Для запуска ноды используйте опцию 3 в главном меню${NC}"
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
        # Сохраняем файлы логов, если они существуют
        if [ -f "$HOME/t3rn/setup.log" ]; then
            cp "$HOME/t3rn/setup.log" "/tmp/t3rn_setup.log.backup"
        fi
        if [ -f "$HOME/t3rn/node.log" ]; then
            cp "$HOME/t3rn/node.log" "/tmp/t3rn_node.log.backup"
        fi
        # Сохраняем конфигурационный файл газа, если он существует
        if [ -f "$HOME/t3rn/gas_config.txt" ]; then
            cp "$HOME/t3rn/gas_config.txt" "/tmp/t3rn_gas_config.backup"
        fi
        # Сохраняем конфигурационный файл RPC, если он существует
        if [ -f "$HOME/t3rn/rpc_config.json" ]; then
            cp "$HOME/t3rn/rpc_config.json" "/tmp/t3rn_rpc_config.backup"
        fi
        
        rm -rf "$HOME/t3rn"
        
        # Создаем директорию заново и восстанавливаем логи и конфигурацию
        mkdir -p "$HOME/t3rn"
        if [ -f "/tmp/t3rn_setup.log.backup" ]; then
            cp "/tmp/t3rn_setup.log.backup" "$HOME/t3rn/setup.log"
        fi
        if [ -f "/tmp/t3rn_node.log.backup" ]; then
            cp "/tmp/t3rn_node.log.backup" "$HOME/t3rn/node.log"
        fi
        if [ -f "/tmp/t3rn_gas_config.backup" ]; then
            cp "/tmp/t3rn_gas_config.backup" "$HOME/t3rn/gas_config.txt"
        fi
        if [ -f "/tmp/t3rn_rpc_config.backup" ]; then
            cp "/tmp/t3rn_rpc_config.backup" "$HOME/t3rn/rpc_config.json"
        fi
        
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

# Функция для удаления ноды
remove_node() {
    local return_to_main=false
    
    while [ "$return_to_main" = false ]; do
        clear
        echo -e "\n${BOLD}${RED}⚠️ Удаление ноды T3RN...${NC}\n"
        
        # Проверка наличия установленной ноды
        if [ ! -d "$HOME/t3rn" ] && [ ! -d "$HOME/executor" ]; then
            error_message "Нода не установлена. Нечего удалять."
            sleep 2
            return 1
        fi
        
        echo -e "${BOLD}${RED}Вы уверены, что хотите удалить ноду T3RN и все связанные с ней файлы?${NC}"
        echo -e "${YELLOW}Это действие невозможно отменить.${NC}\n"
        
        echo -e "${BOLD}${BLUE}Выберите действие:${NC}\n"
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${RED}➜ ${WHITE}🗑️ Удалить ноду и все файлы${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}🔙 Вернуться в главное меню${NC}\n"
        
        read -p "$(echo -e "${GREEN}Введите номер действия [1-2]:${NC} ")" confirm
        
        case $confirm in
            1)
                echo -e "\n${WHITE}[${CYAN}1/3${WHITE}] ${GREEN}➜ ${WHITE}🛑 Остановка и удаление всех процессов ноды...${NC}"
                
                # Находим все процессы, связанные с нодой и завершаем их
                NODE_PIDS=$(pgrep -f "executor")
                if [ -n "$NODE_PIDS" ]; then
                    for pid in $NODE_PIDS; do
                        echo -e "${ORANGE}Завершение процесса с PID: $pid...${NC}"
                        kill -9 $pid 2>/dev/null
                    done
                    sleep 2
                    
                    # Проверка на наличие оставшихся процессов
                    REMAINING_PIDS=$(pgrep -f "executor")
                    if [ -n "$REMAINING_PIDS" ]; then
                        warning_message "Некоторые процессы ноды не удалось завершить. Может потребоваться перезагрузка системы."
                    else
                        success_message "Все процессы ноды успешно остановлены"
                    fi
                else
                    info_message "Активных процессов ноды не обнаружено"
                fi
                
                echo -e "\n${WHITE}[${CYAN}2/3${WHITE}] ${GREEN}➜ ${WHITE}🗑️ Удаление файлов и директорий...${NC}"
                # Удаляем основную директорию ноды
                if [ -d "$HOME/t3rn" ]; then
                    rm -rf "$HOME/t3rn"
                    success_message "Директория $HOME/t3rn удалена"
                else
                    info_message "Директория $HOME/t3rn не найдена"
                fi
                
                # Удаляем дополнительные файлы, если они существуют
                if [ -d "$HOME/executor" ]; then
                    rm -rf "$HOME/executor"
                    success_message "Директория $HOME/executor удалена"
                else
                    info_message "Директория $HOME/executor не найдена"
                fi
                
                # Удаляем архивы, если они есть
                if ls "$HOME"/executor-linux-*.tar.gz 1> /dev/null 2>&1; then
                    rm -f "$HOME"/executor-linux-*.tar.gz
                    success_message "Архивы executor-linux-*.tar.gz удалены"
                fi
                
                echo -e "\n${WHITE}[${CYAN}3/3${WHITE}] ${GREEN}➜ ${WHITE}✅ Проверка завершения удаления...${NC}"
                # Финальная проверка
                if [ ! -d "$HOME/t3rn" ] && [ ! -d "$HOME/executor" ] && ! pgrep -f "executor" > /dev/null; then
                    echo -e "\n${GREEN}✅ Нода T3RN и все связанные с ней файлы успешно удалены!${NC}"
                else
                    warning_message "Некоторые компоненты ноды могли остаться в системе. Рекомендуется перезагрузка."
                fi
                
                echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в главное меню...${NC}"
                read -s
                return_to_main=true
                ;;
                
            2)
                info_message "Возвращаемся в главное меню"
                return_to_main=true
                ;;
                
            *)
                error_message "Неверный выбор. Пожалуйста, введите 1 или 2."
                sleep 2
                    ;;
            esac
        done
    
    return 0
}

# Функция для проверки логов
check_logs() {
    # Сбрасываем все предыдущие ловушки
    trap - INT
    
    local return_to_main=false
    
    while [ "$return_to_main" = false ]; do
        clear
        echo -e "\n${BOLD}${BLUE}📋 Просмотр логов ноды T3RN...${NC}\n"
        
        # Проверка наличия установленной ноды
        if [ ! -f "$HOME/t3rn/executor/executor/bin/executor" ]; then
            error_message "Нода не установлена. Сначала выполните установку."
            sleep 2
            return 1
        fi
        
        # Устанавливаем пути к лог-файлам
        SETUP_LOG="$HOME/t3rn/setup.log"
        NODE_LOG="$HOME/t3rn/node.log"
        
        # Проверяем существование лог-файлов
        if [ ! -f "$SETUP_LOG" ] && [ ! -f "$NODE_LOG" ]; then
            error_message "Файлы логов не найдены"
            sleep 2
            return 1
        fi
    
        # Подменю для работы с логами
        echo -e "${BOLD}${BLUE}Выберите действие:${NC}\n"
        echo -e "${WHITE}[${CYAN}1${WHITE}] ${GREEN}➜ ${WHITE}📄 Просмотр логов установки и настройки${NC}"
        echo -e "${WHITE}[${CYAN}2${WHITE}] ${GREEN}➜ ${WHITE}📃 Просмотр логов работы ноды${NC}"
        echo -e "${WHITE}[${CYAN}3${WHITE}] ${GREEN}➜ ${WHITE}🔙 Вернуться в главное меню${NC}\n"
        
        read -p "$(echo -e "${GREEN}Введите номер действия [1-3]:${NC} ")" log_choice
        
        case $log_choice in
            1)
                if [ ! -f "$SETUP_LOG" ]; then
                    error_message "Файл логов установки не найден"
                    sleep 2
                    continue
                fi
                
                # Информация о возврате в меню
                echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}ℹ️ Чтобы вернуться в меню, нажмите CTRL+C${NC}"
                echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
                
                # Пауза перед показом логов
                echo -e "${CYAN}Начинаем просмотр логов установки через 5 секунд...${NC}"
                for i in {5..1}; do
                    echo -ne "${ORANGE}$i...${NC}"
                    sleep 1
                done
                echo -e "\n"
                
                echo -e "${CYAN}Последние 25 строк лога установки:${NC}\n"
                tail -n 25 "$SETUP_LOG"
                
                echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}Для просмотра полного лога используйте:${NC}"
                echo -e "${CYAN}cat $SETUP_LOG${NC}"
                echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
                
                # Спрашиваем, хочет ли пользователь продолжить мониторинг
                echo -e "${ORANGE}Хотите следить за обновлением логов установки? (y/n)${NC}"
                read -p "➜ " monitor_choice
                
                if [[ "$monitor_choice" =~ ^[Yy]$ ]]; then
                    echo -e "${ORANGE}Следим за обновлением логов. Для выхода нажмите CTRL+C...${NC}\n"
                    # Устанавливаем ловушку для возврата в меню логов при нажатии CTRL+C
                    watch_logs=true
                    trap 'watch_logs=false' INT
                    
                    # Используем цикл вместо простого tail -f для возможности выхода
                    while $watch_logs; do
                        # Читаем последние 10 строк с интервалом в 1 секунду
                        tail -n 10 "$SETUP_LOG"
                        sleep 1
                        # Очищаем экран только если все еще следим за логами
                        if $watch_logs; then
                            echo -e "\n${CYAN}--- Обновление логов (Нажмите CTRL+C для выхода) ---${NC}\n"
                        fi
                    done
                    # Сбрасываем ловушку и показываем сообщение
                    trap - INT
                    echo -e "\n${GREEN}Возвращаемся в меню логов...${NC}"
                    sleep 2
                fi
                ;;
                
            2)
                if [ ! -f "$NODE_LOG" ]; then
                    error_message "Файл логов работы ноды не найден"
                    sleep 2
                    continue
                fi
                
                # Информация о возврате в меню
                echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}ℹ️ Чтобы вернуться в меню, нажмите CTRL+C${NC}"
                echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
                
                # Пауза перед показом логов
                echo -e "${CYAN}Начинаем просмотр логов работы ноды через 5 секунд...${NC}"
                for i in {5..1}; do
                    echo -ne "${ORANGE}$i...${NC}"
                    sleep 1
                done
                echo -e "\n"
                
                echo -e "${CYAN}Последние 25 строк лога работы ноды:${NC}\n"
                tail -n 25 "$NODE_LOG"
                
                echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
                echo -e "${YELLOW}Для просмотра полного лога используйте:${NC}"
                echo -e "${CYAN}cat $NODE_LOG${NC}"
                echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
                
                # Спрашиваем, хочет ли пользователь продолжить мониторинг
                echo -e "${ORANGE}Хотите следить за обновлением логов работы ноды? (y/n)${NC}"
                read -p "➜ " monitor_choice
                
                if [[ "$monitor_choice" =~ ^[Yy]$ ]]; then
                    echo -e "${ORANGE}Следим за обновлением логов. Для выхода нажмите CTRL+C...${NC}\n"
                    # Устанавливаем ловушку для возврата в меню логов при нажатии CTRL+C
                    watch_logs=true
                    trap 'watch_logs=false' INT
                    
                    # Используем цикл вместо простого tail -f для возможности выхода
                    while $watch_logs; do
                        # Читаем последние 10 строк с интервалом в 1 секунду
                        tail -n 10 "$NODE_LOG"
                        sleep 1
                        # Очищаем экран только если все еще следим за логами
                        if $watch_logs; then
                            echo -e "\n${CYAN}--- Обновление логов (Нажмите CTRL+C для выхода) ---${NC}\n"
                        fi
                    done
                    # Сбрасываем ловушку и показываем сообщение
                    trap - INT
                    echo -e "\n${GREEN}Возвращаемся в меню логов...${NC}"
                    sleep 2
                fi
                ;;
                
            3)
                return_to_main=true
                ;;
                
            *)
                error_message "Неверный выбор. Пожалуйста, введите номер от 1 до 3."
                sleep 2
                ;;
        esac
    done
    
    return 0
}

# Основной цикл программы
main() {
    echo -e "${BLUE}${BOLD}T3RN Node Installer${NC}"
    echo -e "${ORANGE}================${NC}"
    
    while true; do
        clear
        display_logo
        print_menu
        
        read -p "➜ " choice
        
        case $choice in
            1)
                setup_node
                ;;
            2)
                install_specific_version
                ;;
            3)
                check_logs
                ;;
            4)
                manage_rpc
                ;;
            5)
                manage_gas
                ;;
            6)
                update_node
                ;;
            7)
                remove_node
                ;;
            8)
                echo -e "${GREEN}Выход из программы. До свидания!${NC}"
                break
                ;;
            *)
                error_message "Неверный выбор. Пожалуйста, выберите опцию от 1 до 8."
                ;;
        esac
        
        echo -e "\n${ORANGE}Нажмите Enter, чтобы вернуться в меню...${NC}"
        read -s
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
