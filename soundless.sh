#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

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

# Функция установки зависимостей
install_dependencies() {
    info_message "Установка необходимых пакетов..."
    sudo apt update
    sudo apt install -y git
    success_message "Зависимости установлены"
}

# Функция для установки или обновления Rust
setup_rust() {
    echo -e "${WHITE}[${CYAN}1/2${WHITE}] ${GREEN}➜ ${WHITE}🔧 Настройка Rust...${NC}"
    
    if ! command -v rustc &> /dev/null; then
        info_message "Установка Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
        success_message "Rust установлен"
    else
        info_message "Обновление Rust..."
        rustup update
        source $HOME/.cargo/env
        success_message "Rust обновлен"
    fi
}

# Функция для установки Soundness Layer
install_soundness() {
    echo -e "${WHITE}[${CYAN}2/2${WHITE}] ${GREEN}➜ ${WHITE}📥 Установка Soundness Layer...${NC}"
    info_message "Загрузка и установка Soundness Layer..."
    curl -sSL https://raw.githubusercontent.com/soundnesslabs/soundness-layer/main/soundnessup/install | bash
    source ~/.bashrc
    success_message "Soundness Layer установлен"
}

# Очистка экрана
clear

# Отображение логотипа и заголовка
echo -e "\n${BOLD}${WHITE}╔════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${WHITE}║     🚀 SOUNDLESS LAYER INSTALLER       ║${NC}"
echo -e "${BOLD}${WHITE}╚════════════════════════════════════════╝${NC}\n"

# Основная часть скрипта
echo -e "\n${BOLD}${BLUE}⚡ Установка Soundness Layer...${NC}\n"

# Установка зависимостей
install_dependencies

# Настройка Rust
setup_rust

# Установка Soundness Layer
install_soundness

echo -e "\n${PURPLE}═════════════════════════════════════════════${NC}"
echo -e "${GREEN}✨ Soundness Layer успешно установлен!${NC}"
echo -e "${PURPLE}═════════════════════════════════════════════${NC}\n"
