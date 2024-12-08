#!/bin/bash

# Определение цветов
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Функция для проверки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ошибка: $1${NC}"
        exit 1
    fi
}

# Функция для проверки зависимостей
check_dependencies() {
    local deps=("curl" "wget")
    for dep in "${deps[@]}"; do
        if ! command -v $dep &> /dev/null; then
            echo -e "${YELLOW}Установка $dep...${NC}"
            sudo apt update
            sudo apt install $dep -y
            check_error "Не удалось установить $dep"
        fi
    done
}

# Баннер
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Установка Node Exporter            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Проверка зависимостей
log "Проверка зависимостей..."
check_dependencies

# Загрузка логотипа
log "Загрузка логотипа..."
curl -s https://raw.githubusercontent.com/Mozgiii9/NodeRunnerScripts/refs/heads/main/logo.sh | bash

# Получение последней версии node_exporter
log "Получение последней версии node_exporter..."
VERSION=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep 'tag_name' | cut -d\" -f4 | cut -c2-)
check_error "Не удалось получить версию node_exporter"

# Определение операционной системы
log "Определение системы..."
if [[ "$(uname -s)" == "Linux" ]]; then
    OS="linux"
elif [[ "$(uname -s)" == "Darwin" ]]; then
    OS="darwin"
else
    echo -e "${RED}Неподдерживаемая операционная система!${NC}"
    exit 1
fi

# Определение архитектуры
if [[ "$(uname -m)" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$(uname -m)" == "aarch64" ]]; then
    ARCH="arm64"
else
    echo -e "${RED}Неподдерживаемая архитектура!${NC}"
    exit 1
fi

# Скачивание и установка node_exporter
log "Скачивание node_exporter v${VERSION}..."
wget -q --show-progress https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.${OS}-${ARCH}.tar.gz
check_error "Не удалось скачать node_exporter"

log "Распаковка..."
tar xf node_exporter-${VERSION}.${OS}-${ARCH}.tar.gz
check_error "Не удалось распаковать архив"

rm node_exporter-${VERSION}.${OS}-${ARCH}.tar.gz
sudo mv node_exporter-${VERSION}.${OS}-${ARCH} node_exporter
chmod +x $HOME/node_exporter/node_exporter
sudo mv $HOME/node_exporter/node_exporter /usr/bin
rm -Rf $HOME/node_exporter/

# Создание systemd сервиса
log "Создание systemd сервиса..."
sudo tee /etc/systemd/system/exporterd.service > /dev/null <<EOF
[Unit]
Description=Node Exporter Service
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=/usr/bin/node_exporter
Restart=always
RestartSec=3
LimitNOFILE=65535
NoNewPrivileges=true
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Запуск сервиса
log "Настройка и запуск сервиса..."
sudo systemctl daemon-reload
sudo systemctl enable exporterd
sudo systemctl start exporterd
check_error "Не удалось запустить сервис"

# Проверка статуса
log "Проверка статуса сервиса..."
if systemctl is-active --quiet exporterd; then
    echo -e "${GREEN}Node Exporter успешно установлен и запущен!${NC}"
    echo -e "${YELLOW}Версия:${NC} ${VERSION}"
    echo -e "${YELLOW}Порт:${NC} 9100"
    echo -e "${YELLOW}Метрики доступны по адресу:${NC} http://localhost:9100/metrics"
else
    echo -e "${RED}Ошибка при запуске сервиса!${NC}"
    exit 1
fi
