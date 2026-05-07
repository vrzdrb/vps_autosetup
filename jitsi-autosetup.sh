#!/bin/bash

sudo apt update
sudo apt install gnupg2 nginx-full
sudo apt install apt-transport-https
sudo add-apt-repository universe
sudo apt update
read -p "Введите доменное имя (в формате meet.domain.com): " domain
if [ -z "$domain" ]; then
    echo "Ошибка: Домен не может быть пустым"
    exit 1
fi
read -p "Введите внешний (публичный) IPv4-адрес сервера: " ip
if [ -z "$ip" ]; then
    echo "Ошибка: IP-адрес не может быть пустым"
    exit 1
fi
if [[ ! $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo "Предупреждение: IP-адрес '$ip' не соответствует стандартному формату IPv4"
    echo "Продолжить? (y/n)"
    read -r answer
    if [[ ! $answer =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
echo "Установка hostname..."
sudo hostnamectl set-hostname "$domain"
if [ $? -eq 0 ]; then
    echo "✓ Hostname успешно установлен на: $domain"
else
    echo "✗ Ошибка при установке hostname"
    exit 1
fi
echo "Обновление /etc/hosts..."
if grep -q "^127.0.0.1.*$domain" /etc/hosts; then
    echo "Предупреждение: Запись для $domain уже существует в /etc/hosts"
    echo "Пропускаем добавление..."
else
    echo "127.0.0.1 localhost $ip $domain" | sudo tee -a /etc/hosts > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Строка успешно добавлена в /etc/hosts"
    else
        echo "✗ Ошибка при добавлении строки в /etc/hosts"
        exit 1
    fi
fi
echo "Новый hostname: $(hostname)"
sudo curl -sL https://prosody.im/files/prosody-debian-packages.key -o /usr/share/keyrings/prosody-debian-packages.key
echo "deb [signed-by=/usr/share/keyrings/prosody-debian-packages.key] http://packages.prosody.im/debian $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/prosody-debian-packages.list
sudo apt install lua5.2
curl -sL https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
sudo apt update
sudo ufw allow 80/tcp
sudo ufw allow 10000/udp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw reload
sudo apt install jitsi-meet
