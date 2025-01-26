#!/bin/bash

# Отображение логотипа
echo "Загрузка анимации.."
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash
sleep 2

# Цвета для сообщений
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Функция для отображения успешных сообщений
success_message() {
    echo -e "${GREEN}[✅] $1${NC}"
}

# Функция для отображения информационных сообщений
info_message() {
    echo -e "${CYAN}[ℹ️] $1...${NC}"
}

# Функция для отображения сообщений об ошибках
error_message() {
    echo -e "${RED}[❌] $1${NC}"
}

# Функция импорта существующего keystore
import_keystore() {
    local import_choice
    
    read -p "Хотите импортировать существующий keystore? (y/n): " import_choice
    
    if [[ "$import_choice" == "y" ]]; then
        mkdir -p "$HOME/privasea/config"
        
        while true; do
            read -p "Введите полный путь к файлу keystore: " KEYSTORE_PATH
            
            if [[ ! -f "$KEYSTORE_PATH" ]]; then
                error_message "Файл keystore не найден по указанному пути"
                read -p "Хотите попробовать снова? (y/n): " retry_choice
                
                if [[ "$retry_choice" != "y" ]]; then
                    return 1
                fi
                continue
            fi
            
            if [[ ! "$KEYSTORE_PATH" =~ UTC-- ]]; then
                error_message "Неверный формат файла keystore"
                read -p "Хотите попробовать снова? (y/n): " retry_choice
                
                if [[ "$retry_choice" != "y" ]]; then
                    return 1
                fi
                continue
            fi
            
            if cp "$KEYSTORE_PATH" "$HOME/privasea/config/wallet_keystore"; then
                success_message "Keystore успешно импортирован в $HOME/privasea/config/wallet_keystore"
                return 0
            else
                error_message "Не удалось скопировать файл keystore"
                return 1
            fi
        done
    fi
    
    return 0
}

# Очистка экрана
clear
echo -e "${CYAN}========================================"
echo "   🚀 Установка Privasea Acceleration Node"
echo -e "========================================${NC}\n"

# Шаг 1: Проверка установки Docker
if ! command -v docker &>/dev/null; then
    info_message "Docker не найден, начинаем установку"
    
    sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    sudo apt update && sudo apt install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker

    success_message "Docker успешно установлен и запущен"
else
    success_message "Docker уже установлен"
fi

echo ""

# Шаг 2: Загрузка Docker образа
info_message "Загрузка Docker образа"
if docker pull privasea/acceleration-node-beta:latest; then
    success_message "Docker образ успешно загружен"
else
    error_message "Не удалось загрузить Docker образ"
    exit 1
fi

echo ""

# Шаг 3: Создание директории конфигурации
info_message "Создание директории конфигурации"
if mkdir -p "$HOME/privasea/config"; then
    success_message "Директория конфигурации успешно создана"
else
    error_message "Не удалось создать директорию конфигурации"
    exit 1
fi

echo ""

# Шаг 4: Управление keystore
info_message "Управление keystore"
if [[ -f "$HOME/privasea/config/wallet_keystore" ]]; then
    info_message "Найден существующий keystore в директории конфигурации"
    
    PS3="Выберите действие: "
    options=("Заменить keystore" "Оставить существующий keystore")
    select opt in "${options[@]}"; do
        case $REPLY in
            1)
                rm "$HOME/privasea/config/wallet_keystore"
                PS3="Выберите действие: "
                options=("Сгенерировать новый keystore" "Импортировать keystore")
                select opt in "${options[@]}"; do
                    case $REPLY in
                        1)
                            info_message "Генерация нового keystore"
                            if docker run -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
                                success_message "Новый keystore успешно сгенерирован"
                            else
                                error_message "Не удалось сгенерировать новый keystore"
                                exit 1
                            fi
                            break
                            ;;
                        2)
                            import_keystore || exit 1
                            break
                            ;;
                        *)
                            error_message "Неверный выбор"
                            ;;
                    esac
                done
                break
                ;;
            2)
                info_message "Используем существующий keystore"
                break
                ;;
            *)
                error_message "Неверный выбор"
                ;;
        esac
    done
else
    PS3="Выберите действие: "
    options=("Сгенерировать новый keystore" "Импортировать keystore")
    select opt in "${options[@]}"; do
        case $REPLY in
            1)
                info_message "Генерация нового keystore"
                if docker run -it -v "$HOME/privasea/config:/app/config" privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
                    success_message "Новый keystore успешно сгенерирован"
                else
                    error_message "Не удалось сгенерировать новый keystore"
                    exit 1
                fi
                break
                ;;
            2)
                import_keystore || exit 1
                break
                ;;
            *)
                error_message "Неверный выбор"
                ;;
        esac
    done
fi

if [[ -n "$(ls "$HOME/privasea/config/UTC--"* 2>/dev/null)" ]]; then
    KEYSTORE_FILE=$(ls -t "$HOME/privasea/config/UTC--"* | head -n1)
    mv "$KEYSTORE_FILE" "$HOME/privasea/config/wallet_keystore"
fi

echo ""

# Шаг 5: Подтверждение запуска
read -p "Хотите продолжить и запустить ноду? (y/n): " choice
if [[ "$choice" != "y" ]]; then
    echo -e "${CYAN}Процесс прерван.${NC}"
    exit 0
fi

# Шаг 6: Запрос пароля keystore
info_message "Введите пароль для keystore (для доступа к ноде)"
read -s KEystorePassword
echo ""

# Шаг 7: Запуск Privasea Acceleration Node
read -p "Введите кастомный порт для запуска ноды (или нажмите Enter для автоматического выбора свободного порта): " custom_port

if [[ -z "$custom_port" ]]; then
    info_message "Поиск свободного порта..."
    while true; do
        custom_port=$(shuf -i 1024-65535 -n 1)
        if ! lsof -i:$custom_port &>/dev/null; then
            break
        fi
    done
    info_message "Свободный порт найден: $custom_port"
else
    info_message "Запуск Privasea Acceleration Node на порту $custom_port"
fi

if docker run -d -v "$HOME/privasea/config:/app/config" \
-e KEYSTORE_PASSWORD="$KEystorePassword" \
-p "$custom_port:8080" \
privasea/acceleration-node-beta:latest; then
    success_message "Нода успешно запущена на порту $custom_port"
else
    error_message "Не удалось запустить ноду"
    exit 1
fi

echo ""

# Финальный шаг: Отображение информации о завершении
echo -e "${GREEN}========================================"
echo "   ✨ Установка завершена успешно"
echo -e "========================================${NC}\n"
echo -e "${CYAN}📂 Файлы конфигурации находятся в:${NC} $HOME/privasea/config"
echo -e "${CYAN}🔑 Keystore сохранен как:${NC} wallet_keystore"
echo -e "${CYAN}🔐 Использованный пароль keystore:${NC} $KEystorePassword\n"
