#!/bin/bash

# VPS autosetup

PINK='\033[1;95m'
NC='\033[0m'

if [ "$(id -u)" != "0" ]; then
   echo "${PINK}### Этот скрипт должен быть запущен от root ###${NC}" 1>&2
   exit 1
fi                                                                                          
apt update
apt upgrade
apt install mc git curl wget iptables-persistent chkrootkit rkhunter rsyslog ranger htop tcpdump net-tools nmap dnsutils jq sudo

# Включаем unattended-upgrades

echo "${PINK}### Включение Unattended Upgrades ###${NC}"
apt update && apt install -y unattended-upgrades
echo 'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades
sed -i 's|//\s*"${distro_id}:${distro_codename}-security";|"${distro_id}:${distro_codename}-security";|' /etc/apt/apt.conf.d/50unattended-upgrades
echo "${PINK}### Автообновления включены ###${NC}"

# Включаем BBR, отключаем IPv6
                                                                          
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sh -c 'echo "
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
" >> /etc/sysctl.conf'
sysctl -p
echo "${PINK}### Если вы видите ошибку, откройте /etc/sysctl.conf и измените eth0 на ваш интерфейс из ifconfig ###${NC}"
read -r

# Включаем автоматическую перезагрузку в 4:20 утра каждый понедельник

(crontab -l 2>/dev/null; echo "20 4 * * 1 /sbin/reboot") | crontab -
echo "${PINK}### Добавлена перезагрузка в 4:20 каждый понедельник ###${NC}"

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
echo "${PINK}### fail2ban настроен: бан на 12 часов спустя 5 попыток за 15 минут ###${NC}"

# Добавляем пользователя sudo
                                                                   
read -p "${PINK}### Введите имя пользователя: ###${NC}" username
adduser --gecos "" $username
usermod -aG sudo $username
echo "${PINK}### Пользователь $username создан и добавлен в sudo ###${NC}"

# Включаем логгирование sudo
                                        
echo "${PINK}### В следующем файле добавьте строку 'Defaults logfile=/var/log/sudo.log, log_input, log_output'"
read -r -p "${PINK}### Окей, я скопировал её и готов ###${NC}"
sudo visudo

# Для AmneziaVPN self-hosted

read -p "${PINK}### Вы разворачиваете AmneziaVPN self-hosted? Y/n: ###${NC}" -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "$username ALL=(ALL) NOPASSWD: ALL" | sudo EDITOR='tee' visudo -f /etc/sudoers.d/$username-nopasswd
    echo "${PINK}### sudo-операции для $username НЕ БУДУТ ТРЕБОВАТЬ ПАРОЛЬ ###${NC}"
else
    echo "${PINK}### sudo-операции для $username будут происходить как обычно ###${NC}"
fi

# Отключаем вход через root

sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh
echo "${PINK}### Вход под root отключен ###${NC}"

echo "${PINK}=======================================================================================${NC}"
echo "${PINK}### ВНИМАТЕЛЬНО ПРОЧТИТЕ: сейчас вам нужно открыть терминал на своём компьютере ${NC}"
echo "${PINK}### И создать ssh-ключ для входа на сервер следующей командой: ${NC}"
echo "${PINK}### ssh-keygen -t ed25519 -C "имяключа" -f ~/.ssh/имяключа ${NC}"
echo "${PINK}### Загрузите ключ на сервер (команда для Linux): ${NC}"
echo "${PINK}### ssh-copy-id -i ~/.ssh/имяключа.pub логин@IP.сервера ${NC}"
echo "${PINK}### Команда для Windows: ${NC}"
echo "${PINK}### cat ~/.ssh/id_ed25519.pub | ssh логин@IP.сервера" mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys" ${NC}"
echo "${PINK}### Попробуйте подключиться к вашему серверу при помощи этого ключа: ${NC}"
echo "${PINK}### ssh -i ~/.ssh/имяключа логин@IP.сервера ${NC}"
echo "${PINK}### ТОЛЬКО ЕСЛИ ВХОД УСПЕШЕН, нажмите здесь Enter для ОТКЛЮЧЕНИЯ ВХОДА В SSH ПО ПАРОЛЮ ${NC}"
echo "${PINK}=======================================================================================${NC}"
read -r
grep -r PasswordAuthentication /etc/ssh -l | xargs -n 1 sed -i -e "/PasswordAuthentication /c\PasswordAuthentication no"
echo "${PINK}### Вход по паролю отключён ###${NC}"

# Смена SSH-порта

read -p "${PINK}### Введите новый SSH порт: ###${NC}" port
sed -i "s/^#Port.*/Port $port/" /etc/ssh/sshd_config
sed -i "s/^Port.*/Port $port/" /etc/ssh/sshd_config
grep -q "^Port" /etc/ssh/sshd_config || echo "Port $port" >> /etc/ssh/sshd_config
systemctl restart ssh
echo "${PINK}### SSH порт изменен на $port ###${NC}"

# Настройка iptables и блокировка IP-адресов РКН

echo "${PINK}### Настройка iptables ###${NC}"
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

echo "${PINK}### Настройка iptables завершена ###${NC}"

# Добавляем 2 Гб подкачки для самых дешёвых VPS с 1 Гб RAM

swapfile="/swapfile"
if [ -f "$swapfile" ]; then
    echo "${PINK}### Swap файл уже существует ###${NC}"
    exit 1
fi
dd if=/dev/zero of=$swapfile bs=1M count=2048
chmod 600 $swapfile
mkswap $swapfile
swapon $swapfile
echo "$swapfile none swap sw 0 0" >> /etc/fstab
echo "${PINK}### Создан swap файл 2GB и активирован ###${NC}"
                           
# Смотрим GeoIP
                
wget -O ipregion.sh https://ipregion.vrnt.xyz
chmod +x ipregion.sh
./ipregion.sh

# Аудит безопасности
                                       
curl -O https://raw.githubusercontent.com/vernu/vps-audit/main/vps-audit.sh
chmod +x vps-audit.sh
sudo ./vps-audit.sh
