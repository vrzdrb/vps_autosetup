#!/bin/bash

# VPS autosetup

if [ "$(id -u)" != "0" ]; then
   echo "Этот скрипт должен быть запущен от root" 1>&2
   exit 1
fi

echo "Обновление"                                                                                          
apt update
apt upgrade

echo "Установка базовых программ"
apt install sudo mc git iptables-persistent chkrootkit rkhunter rsyslog micro htop tcpdump net-tools dnsutils jq

# Включаем unattended-upgrades

echo "Включение Unattended Upgrades"
apt update && apt install -y unattended-upgrades
echo 'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades
sed -i 's|//\s*"${distro_id}:${distro_codename}-security";|"${distro_id}:${distro_codename}-security";|' /etc/apt/apt.conf.d/50unattended-upgrades
echo "Автообновления включены"

# Включаем BBR, отключаем IPv6
                                                                          
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sh -c 'echo "
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
" >> /etc/sysctl.conf'
sysctl -p
echo "Если вы видите ошибку, откройте /etc/sysctl.conf и измените eth0 на ваш интерфейс из ifconfig"
read -r

# Включаем автоматическую перезагрузку в 4:20 утра каждый понедельник

(crontab -l 2>/dev/null; echo "20 4 * * 1 /sbin/reboot") | crontab -
echo "Добавлена перезагрузка в 4:20 каждый понедельник"

# Устанавливаем и настраиваем Fail2Ban

apt update && apt install -y fail2ban
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 43200
findtime = 900
maxretry = 5

[sshd]
enabled = true
EOF
systemctl enable fail2ban && systemctl start fail2ban
echo "fail2ban настроен: бан на 12 часов спустя 5 попыток за 15 минут"

# Добавляем пользователя sudo
                                                                   
read -p "Введите имя нового пользователя sudo:" username
adduser --gecos "" $username
usermod -aG sudo $username
echo "Пользователь $username создан и добавлен в sudo"

# Включаем логгирование sudo
                                        
echo "В следующем файле добавьте строку 'Defaults logfile=/var/log/sudo.log, log_input, log_output'"
read -r -p "Окей, я скопировал её и готов"
sudo visudo

# Для AmneziaVPN self-hosted

read -p "Вы разворачиваете AmneziaVPN self-hosted? Y/n:" -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "$username ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee' visudo -f /etc/sudoers.d/$username-nopasswd
    echo "sudo-операции для $username НЕ БУДУТ ТРЕБОВАТЬ ПАРОЛЬ"
else
    echo "sudo-операции для $username будут происходить как обычно"
fi

# Отключаем вход через root

sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh
echo "Вход под root отключен"

echo "======================================================================================="
echo "ВНИМАТЕЛЬНО ПРОЧТИТЕ: сейчас вам нужно открыть терминал на своём компьютере"
echo "И создать ssh-ключ для входа на сервер следующей командой:"
echo "ssh-keygen -t ed25519 -C "имяключа" -f ~/.ssh/имяключа"
echo "Загрузите ключ на сервер (команда для Linux):"
echo "ssh-copy-id -i ~/.ssh/имяключа.pub логин@IP.сервера"
echo "Команда для Windows:"
echo "cat ~/.ssh/id_ed25519.pub | ssh логин@IP.сервера mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
echo "Попробуйте подключиться к вашему серверу при помощи этого ключа: "
echo "ssh -i ~/.ssh/имяключа логин@IP.сервера "
echo "ТОЛЬКО ЕСЛИ ВХОД УСПЕШЕН, нажмите здесь Enter для ОТКЛЮЧЕНИЯ ВХОДА В SSH ПО ПАРОЛЮ "
echo "======================================================================================="
read -r
grep -r PasswordAuthentication /etc/ssh -l | xargs -n 1 sed -i -e "/PasswordAuthentication /c\PasswordAuthentication no"
echo "Вход по паролю отключён"

# Смена SSH-порта

read -p "Введите новый SSH порт:" port
sed -i "s/^#Port.*/Port $port/" /etc/ssh/sshd_config
sed -i "s/^Port.*/Port $port/" /etc/ssh/sshd_config
grep -q "^Port" /etc/ssh/sshd_config || echo "Port $port" >> /etc/ssh/sshd_config
systemctl restart ssh
echo "SSH порт изменен на $port"

# Настройка iptables и блокировка IP-адресов РКН

echo "Настройка iptables"
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport $port -j ACCEPT 
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -P INPUT DROP
iptables -D INPUT -p tcp --dport 22 -j ACCEPT
iptables-save > /etc/network/iptables.rules

git clone https://github.com/freemedia-tech/iptables-rugov-block.git
cd iptables-rugov-block
./install.sh

echo "Настройка iptables завершена"

# Добавляем 2 Гб подкачки для самых дешёвых VPS с 1 Гб RAM

swapfile="/swapfile"
if [ -f "$swapfile" ]; then
    echo "Swap файл уже существует"
    exit 1
fi
dd if=/dev/zero of=$swapfile bs=1M count=2048
chmod 600 $swapfile
mkswap $swapfile
swapon $swapfile
echo "$swapfile none swap sw 0 0" >> /etc/fstab
echo "Создан swap файл 2GB и активирован"
                           
# Смотрим GeoIP
                
wget -O ipregion.sh https://ipregion.vrnt.xyz
chmod +x ipregion.sh
./ipregion.sh

# Аудит безопасности
                                       
curl -O https://raw.githubusercontent.com/vernu/vps-audit/main/vps-audit.sh
chmod +x vps-audit.sh
sudo ./vps-audit.sh
