#!/bin/bash

# Скрипт для проброса всего трафика через proxychains на Ubuntu 22.04

# Проверка на root права
if [ "$EUID" -ne 0 ]; then
  echo "Этот скрипт требует прав суперпользователя (root)."
  echo "Пожалуйста, запустите с sudo: sudo $0"
  exit 1
fi

# Проверка установлен ли proxychains
if ! command -v proxychains4 &> /dev/null; then
    echo "Proxychains не установлен. Устанавливаем..."
    apt update
    apt install -y proxychains4
    if [ $? -ne 0 ]; then
        echo "Ошибка установки proxychains. Проверьте подключение к интернету и права доступа."
        exit 1
    fi
    echo "Proxychains успешно установлен."
else
    echo "Proxychains уже установлен."
fi

# Функция для настройки iptables для проброса всего трафика через proxychains
setup_traffic_forwarding() {
    local proxy_type=$1
    local proxy_ip=$2
    local proxy_port=$3
    local proxy_user=$4
    local proxy_pass=$5
    local local_port=$6
    local excluded_ips=$7
    
    # Создаем резервную копию оригинального конфига
    cp /etc/proxychains4.conf /etc/proxychains4.conf.backup
    
    # Настраиваем proxychains
    cat > /etc/proxychains4.conf << EOF
# proxychains.conf VER 4.x
#
# Проксификация всего трафика через заданный прокси

# Строгий режим - если прокси не работает, соединение прерывается
strict_chain

# Проксификация DNS запросов
proxy_dns

# Таймауты для TCP соединений
tcp_read_time_out 15000
tcp_connect_time_out 8000

# Локальные подсети не проксируются
localnet 127.0.0.0/255.0.0.0
localnet 10.0.0.0/255.0.0.0
localnet 172.16.0.0/255.240.0.0
localnet 192.168.0.0/255.255.0.0

# Список прокси-серверов:
[ProxyList]
EOF

# Добавляем прокси с учетом логина и пароля, если они указаны
if [ -n "$proxy_user" ] && [ -n "$proxy_pass" ]; then
    echo "$proxy_type $proxy_ip $proxy_port $proxy_user $proxy_pass" >> /etc/proxychains4.conf
else
    echo "$proxy_type $proxy_ip $proxy_port" >> /etc/proxychains4.conf
fi
EOF

    echo "Конфигурация proxychains обновлена."
    
    # Сбрасываем правила iptables
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    
    # Разрешаем локальный трафик
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Разрешаем установленные соединения
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Исключаем определенные IP из проксирования
    if [ -n "$excluded_ips" ]; then
        IFS=',' read -ra IPS <<< "$excluded_ips"
        for ip in "${IPS[@]}"; do
            iptables -t nat -A OUTPUT -d $ip -j RETURN
        done
    fi
    
    # Направляем весь TCP трафик через прокси
    iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port $local_port
    
    # Сохраняем правила iptables
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
    else
        echo "Установка netfilter-persistent для сохранения правил iptables..."
        apt install -y iptables-persistent
        netfilter-persistent save
    fi
    
    # Создаем скрипт для восстановления соединения после перезагрузки
    cat > /usr/local/bin/restore-proxy-connection.sh << EOF
#!/bin/bash
# Скрипт восстановления правил iptables для проксирования
sleep 10
iptables -t nat -A OUTPUT -p tcp -j REDIRECT --to-port $local_port
EOF
    chmod +x /usr/local/bin/restore-proxy-connection.sh
    
    # Создаем сервис для восстановления соединения
    cat > /etc/systemd/system/restore-proxy-connection.service << EOF
[Unit]
Description=Restore Proxy Connection Rules
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restore-proxy-connection.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable restore-proxy-connection.service
    
    # Создаем сервис для автозапуска прокси-сервера
    cat > /etc/systemd/system/proxychains-redirect.service << EOF
[Unit]
Description=Proxychains Traffic Redirector
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/proxychains4 -f /etc/proxychains4.conf /usr/bin/socat TCP4-LISTEN:$local_port,fork,reuseaddr TCP4:$proxy_ip:$proxy_port
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    # Устанавливаем socat если он не установлен
    if ! command -v socat &> /dev/null; then
        echo "Устанавливаем socat..."
        apt install -y socat
    fi
    
    # Активируем и запускаем сервис
    systemctl daemon-reload
    systemctl enable proxychains-redirect.service
    systemctl start proxychains-redirect.service
    
    echo "Весь трафик сервера теперь проходит через $proxy_type прокси $proxy_ip:$proxy_port"
    echo "Локальный порт перенаправления: $local_port"
    echo "Исключенные IP: $excluded_ips"
    echo ""
    echo "Текущая конфигурация:"
    cat /etc/proxychains4.conf
    echo ""
    echo "Статус службы перенаправления:"
    systemctl status proxychains-redirect.service
}

# Запрос параметров
read -p "Тип прокси (http, socks4, socks5): " proxy_type
read -p "IP адрес прокси: " proxy_ip
read -p "Порт прокси: " proxy_port
read -p "Имя пользователя прокси (оставьте пустым, если не требуется): " proxy_user
read -p "Пароль для прокси (оставьте пустым, если не требуется): " proxy_pass
read -p "Локальный порт для перенаправления (например, 9050): " local_port
read -p "Исключенные IP (через запятую, например 8.8.8.8,1.1.1.1): " excluded_ips

# Запускаем настройку проброса трафика
setup_traffic_forwarding "$proxy_type" "$proxy_ip" "$proxy_port" "$proxy_user" "$proxy_pass" "$local_port" "$excluded_ips"

echo ""
echo "Для проверки работы прокси выполните:"
echo "curl -s https://ifconfig.me"
echo ""
echo "Для восстановления настроек выполните:"
echo "systemctl stop proxychains-redirect.service"
echo "systemctl disable proxychains-redirect.service"
echo "systemctl disable restore-proxy-connection.service"
echo "iptables -F && iptables -t nat -F"
echo "cp /etc/proxychains4.conf.backup /etc/proxychains4.conf"
echo ""
echo "ВАЖНО: Скрипт настроен так, чтобы соединение не прерывалось"
echo "Если вы хотите проверить работу прокси, выполните в другой сессии:"
echo "curl -s https://ifconfig.me"
