#!/bin/bash

# Проверка на root
if [ "$(id -u)" != "0" ]; then
   echo "Этот скрипт должен быть запущен от root" 1>&2
   exit 1
fi

# Прерывание при ошибке
set -e

# Яркий голубой
echo -e "\e[96m$1\e[0m"

# Яркий розовый
echo -e "\e[38;5;213m$1\e[0m"

echo -e " \e[96m███████╗██╗   ██╗███████╗    ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗
██╔════╝╚██╗ ██╔╝██╔════╝    ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
███████╗ ╚████╔╝ ███████╗    ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  
╚════██║  ╚██╔╝  ╚════██║    ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  
███████║   ██║   ███████║    ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗
╚══════╝   ╚═╝   ╚══════╝     ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝\e[0m"

apt update && apt upgrade -y

echo -e "\e[38;5;213m██████╗ ███╗   ██╗███████╗
██╔══██╗████╗  ██║██╔════╝
██║  ██║██╔██╗ ██║███████╗
██║  ██║██║╚██╗██║╚════██║
██████╔╝██║ ╚████║███████║
╚═════╝ ╚═╝  ╚═══╝╚══════╝\e[0m"
                          
apt install systemd-resolved -y

tee /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=1.1.1.1 8.8.8.8 8.8.4.4
#FallbackDNS=
Domains=~.
DNSSEC=yes
DNSOverTLS=yes
EOF

systemctl enable systemd-resolved.service
systemctl start systemd-resolved.service
systemctl restart systemd-resolved.service

echo -e "\e[96m████████╗ ██████╗  ██████╗ ██╗     ███████╗
╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
   ██║   ██║   ██║██║   ██║██║     ███████╗
   ██║   ██║   ██║██║   ██║██║     ╚════██║
   ██║   ╚██████╔╝╚██████╔╝███████╗███████║
   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝\e[0m"

apt install unattended-upgrades sudo mc ufw chkrootkit micro htop tcpdump net-tools dnsutils jq iftop nethogs bmon -y

echo -e "\e[38;5;213m██╗   ██╗███╗   ██╗ █████╗ ████████╗████████╗███████╗███╗   ██╗██████╗ ███████╗██████╗ 
██║   ██║████╗  ██║██╔══██╗╚══██╔══╝╚══██╔══╝██╔════╝████╗  ██║██╔══██╗██╔════╝██╔══██╗
██║   ██║██╔██╗ ██║███████║   ██║      ██║   █████╗  ██╔██╗ ██║██║  ██║█████╗  ██║  ██║
██║   ██║██║╚██╗██║██╔══██║   ██║      ██║   ██╔══╝  ██║╚██╗██║██║  ██║██╔══╝  ██║  ██║
╚██████╔╝██║ ╚████║██║  ██║   ██║      ██║   ███████╗██║ ╚████║██████╔╝███████╗██████╔╝
 ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═════╝\e[0m"
                                                                                       
echo 'Unattended-Upgrade::Mail "root";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades
systemctl restart unattended-upgrades

echo -e "\e[96m██████╗ ██████╗ ██████╗     ██╗██████╗ ██╗   ██╗ ██████╗ 
██╔══██╗██╔══██╗██╔══██╗    ██║██╔══██╗██║   ██║██╔════╝ 
██████╔╝██████╔╝██████╔╝    ██║██████╔╝██║   ██║███████╗ 
██╔══██╗██╔══██╗██╔══██╗    ██║██╔═══╝ ╚██╗ ██╔╝██╔═══██╗
██████╔╝██████╔╝██║  ██║    ██║██║      ╚████╔╝ ╚██████╔╝
╚═════╝ ╚═════╝ ╚═╝  ╚═╝    ╚═╝╚═╝       ╚═══╝   ╚═════╝\e[0m"

if ! grep -q "net.core.default_qdisc = fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv4.tcp_congestion_control = bbr" /etc/sysctl.conf; then
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf; then
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf; then
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv6.conf.lo.disable_ipv6 = 1" /etc/sysctl.conf; then
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
fi

sysctl -p

echo -e "\e[38;5;213m██████╗ ███████╗██████╗  ██████╗  ██████╗ ████████╗
██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝
██████╔╝█████╗  ██████╔╝██║   ██║██║   ██║   ██║   
██╔══██╗██╔══╝  ██╔══██╗██║   ██║██║   ██║   ██║   
██║  ██║███████╗██████╔╝╚██████╔╝╚██████╔╝   ██║   
╚═╝  ╚═╝╚══════╝╚═════╝  ╚═════╝  ╚═════╝    ╚═╝\e[0m"

timedatectl set-timezone Europe/Moscow
echo "20 2 * * 1 /sbin/reboot" | tee -a /var/spool/cron/crontabs/root >/dev/null

echo -e "\e[96m███████╗███████╗██╗  ██╗
██╔════╝██╔════╝██║  ██║
███████╗███████╗███████║
╚════██║╚════██║██╔══██║
███████║███████║██║  ██║
╚══════╝╚══════╝╚═╝  ╚═╝\e[0m"

IP=$(curl -s --max-time 5 ifconfig.me)

echo -e "\e[38;5;213m=======================================================================================
ВНИМАТЕЛЬНО ПРОЧТИТЕ: сейчас вам нужно открыть терминал на своём компьютере
И создать ssh-ключ для входа на сервер следующей командой:\e[0m"

echo -e "\e[96mssh-keygen -t ed25519\e[0m"

echo -e "\e[38;5;213mЗагрузите ключ на сервер (команда для Linux):\e[0m"
echo -e "\e[96mssh-copy-id -i имяключа.pub root@$IP\e[0m"

echo -e "\e[38;5;213mКоманда для Windows:\e[0m"
echo -e "\e[96mcat id_ed25519.pub | ssh root@$IP mkdir -p && cat >> ~/.ssh/authorized_keys\e[0m"

echo -e "\e[38;5;213mПопробуйте подключиться к вашему серверу при помощи этого ключа:\e[0m"
echo -e "\e[96mssh -i имяключа root@$IP\e[0m"

echo -e "\e[38;5;213mТОЛЬКО ЕСЛИ ВХОД УСПЕШЕН, нажмите здесь Enter для ОТКЛЮЧЕНИЯ ВХОДА В SSH ПО ПАРОЛЮ\e[0m"
echo -e "\e[38;5;213m=======================================================================================\e[0m

read -r

SSHD_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG="/etc/ssh/ssh_config"
if [ ! -f "$SSHD_CONFIG" ]; then
    echo "Ошибка: Файл $SSHD_CONFIG не найден"
    exit 1
fi

BACKUP_FILE="/etc/ssh/sshd_config.backup_$(date +%Y%m%d_%H%M%S)"
cp "$SSHD_CONFIG" "$BACKUP_FILE"
echo "Создана резервная копия: $BACKUP_FILE"

if grep -q "^PubkeyAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
fi

if grep -q "^PasswordAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
else
    echo "PasswordAuthentication no" >> "$SSHD_CONFIG"
fi

if grep -q "^GSSAPIAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^GSSAPIAuthentication.*/GSSAPIAuthentication no/' "$SSHD_CONFIG"
else
    echo "GSSAPIAuthentication no" >> "$SSHD_CONFIG"
fi

if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin prohibit-password" >> "$SSHD_CONFIG"
fi

if grep -q "^GSSAPIAuthentication" "$SSH_CONFIG"; then
    sed -i 's/^GSSAPIAuthentication.*/GSSAPIAuthentication no/' "$SSH_CONFIG"
else
    echo "GSSAPIAuthentication no" >> "$SSH_CONFIG"
fi

echo "Проверка конфигурации SSH..."
if sshd -t -f "$SSHD_CONFIG"; then
    echo "Конфигурация SSH корректна"
else
    echo "Ошибка в конфигурации SSH! Восстанавливаем из резервной копии..."
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    echo "Конфигурация восстановлена из резервной копии"
    exit 1
fi

mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/99-security-settings.conf << 'EOF'
Port 22
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
GSSAPIAuthentication no
Protocol 2
X11Forwarding no
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300
ClientAliveCountMax 2
UseDNS no
ChallengeResponseAuthentication no
KerberosAuthentication no
EOF

echo ""
read -p "Введите новый SSH порт:" port
echo ""

chmod 600 ~/.ssh/authorized_keys

sed -i "s/^#Port.*/Port $port/" /etc/ssh/sshd_config.d/99-security-settings.conf
sed -i "s/^Port.*/Port $port/" /etc/ssh/sshd_config.d/99-security-settings.conf
grep -q "^Port" /etc/ssh/sshd_config.d/99-security-settings.conf || echo "Port $port" >> /etc/ssh/sshd_config.d/99-security-settings.conf

if systemctl restart sshd; then
    echo "Служба SSH перезапущена через sshd"
else
    systemctl restart ssh
    echo "Служба SSH перезапущена через ssh"
fi

echo -e "\e[96m SSH порт изменен на $port\e[0m"

echo -e "\e[96m██╗   ██╗███████╗██╗    ██╗
██║   ██║██╔════╝██║    ██║
██║   ██║█████╗  ██║ █╗ ██║
██║   ██║██╔══╝  ██║███╗██║
╚██████╔╝██║     ╚███╔███╔╝
 ╚═════╝ ╚═╝      ╚══╝╚══╝ 
                           \e[0m"
                           

IP4_REGEX="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
IP4=$(ip route get 8.8.8.8 2>/dev/null | grep -Po -- 'src \K\S*')

if [[ ! $IP4 =~ $IP4_REGEX ]]; then
    IP4=$(curl -s --max-time 5 ipinfo.io/ip 2>/dev/null)
fi

if [[ ! $IP4 =~ $IP4_REGEX ]]; then
  echo "Не удалось получить внешний IP."
  return 1
fi

BLOCK_ZONE_IP=$(echo ${IP4} | cut -d '.' -f 1-3).0/22
ufw --force reset
ufw limit $port/tcp comment 'SSH'
ufw allow 443/tcp comment 'WEB'
ufw insert 1 deny from "$BLOCK_ZONE_IP"
ufw --force enable

# Смотрим GeoIP 
wget -O ipregion.sh https://ipregion.vrnt.xyz
chmod +x ipregion.sh
./ipregion.sh
read -r

#Cмотрим IPQuality
bash <(curl -sL https://Check.Place) -EI
read -r

 
# Смотрим bench.sh
curl -Lso- bench.sh | bash
read -r

# Минимальный аудит безопасности
curl -O https://raw.githubusercontent.com/vernu/vps-audit/main/vps-audit.sh
chmod +x vps-audit.sh
sudo ./vps-audit.sh
read -r

echo -e "\e[38;5;213m███████╗██╗    ██╗ █████╗ ██████╗ 
██╔════╝██║    ██║██╔══██╗██╔══██╗
███████╗██║ █╗ ██║███████║██████╔╝
╚════██║██║███╗██║██╔══██║██╔═══╝ 
███████║╚███╔███╔╝██║  ██║██║     
╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     
                                  \e[0m"

swapfile="/swapfile"
if [ -f "$swapfile" ]; then
    echo "Swap файл уже существует"
    exit 1
fi
dd if=/dev/zero of=$swapfile bs=1M count=1024
chmod 600 $swapfile
mkswap $swapfile
swapon $swapfile
echo "$swapfile none swap sw 0 0" >> /etc/fstab

echo ""
echo "1Гб подкачки создан и активирован"
echo ""
