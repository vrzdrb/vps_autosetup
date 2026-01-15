#!/bin/bash


# Проверка на root

if [ "$(id -u)" != "0" ]; then
   echo "Этот скрипт должен быть запущен от root" 1>&2
   exit 1
fi


# Прерывание при ошибке

set -e


# Обновление системы

echo "Обновление"                                                                                          
apt update
apt upgrade


# Шифрование DNS
echo ""
echo ""
echo "Настройки DNS..."
echo ""
echo ""

tee /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=1.1.1.1 8.8.8.8 8.8.4.4
#FallbackDNS=
Domains=~.
DNSSEC=yes
DNSOverTLS=yes
EOF
systemctl restart systemd-resolved.service

echo ""
echo ""
echo "Настройки DNS применены"
echo ""
echo ""

# Базовый набор программ
echo ""
echo ""
echo "Установка базового ПО"
echo ""
echo ""
apt install sudo mc ufw chkrootkit rkhunter micro htop tcpdump net-tools dnsutils jq ranger
echo ""
echo ""
echo "Установка завершена"
echo ""
echo ""


# Включаем unattended-upgrades
echo ""
echo ""
echo "Включаем unattended-upgrades"
echo ""
echo ""
echo 'Unattended-Upgrade::Mail "root";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades
systemctl restart unattended-upgrades
echo ""
echo ""
echo "unattended-upgrades включены"
echo ""
echo ""

# Включаем BBR, отключаем IPv6
echo ""
echo ""
echo "Включаем BBR, отключаем IPv6"
echo ""
echo ""

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

echo ""
echo ""
echo "BBR включен, IPv6 отключен"
echo ""
echo ""

# Включаем автоматическую перезагрузку в 4:20 утра каждый понедельник
echo ""
echo ""
echo "Включаем автоматическую перезагрузку"
echo ""
echo ""

(crontab -l 2>/dev/null; echo "20 4 * * 1 /sbin/reboot") | crontab -

echo ""
echo ""
echo "Добавлена перезагрузка в 4:20 каждый понедельник"
echo ""
echo ""

# Добавляем пользователя sudo                                                  
echo ""
echo ""
read -p "Введите имя нового пользователя sudo:" username
echo ""
echo ""
adduser --gecos "" $username
usermod -aG sudo $username
echo ""
echo ""
echo "Пользователь $username создан и добавлен в sudo"
echo ""
echo ""

# Включаем логгирование sudo                            
echo ""
echo ""
echo "В следующем файле добавьте строку 'Defaults logfile=/var/log/sudo.log, log_input, log_output'"
echo ""
echo ""
read -r -p "Окей, я скопировал её и готов"
sudo visudo


# Для AmneziaVPN self-hosted
echo ""
echo ""
read -p "Вы разворачиваете AmneziaVPN self-hosted? Y/n:" -r
echo ""
echo ""
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "В следующем диалоговом окне вместо $username пишите root"
else
    echo "Ок"
fi


# Настройка безопасности SSH:
echo ""
echo ""
echo "======================================================================================="
echo "ВНИМАТЕЛЬНО ПРОЧТИТЕ: сейчас вам нужно открыть терминал на своём компьютере"
echo "И создать ssh-ключ для входа на сервер следующей командой:"
echo "ssh-keygen -t ed25519 -C "имяключа" -f ~/.ssh/имяключа"
echo ""
echo "Загрузите ключ на сервер (команда для Linux):"
echo "ssh-copy-id -i ~/.ssh/имяключа.pub $username@IP.сервера"
echo ""
echo "Команда для Windows:"
echo "cat ~/.ssh/id_ed25519.pub | ssh $username@IP.сервера mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
echo ""
echo "Попробуйте подключиться к вашему серверу при помощи этого ключа: "
echo "ssh -i ~/.ssh/имяключа $username@IP.сервера "
echo ""
echo "ТОЛЬКО ЕСЛИ ВХОД УСПЕШЕН, нажмите здесь Enter для ОТКЛЮЧЕНИЯ ВХОДА В SSH ПО ПАРОЛЮ "
echo "======================================================================================="
read -r
echo ""
echo ""
echo "Применяем настройки безопасности SSH"
echo ""
echo ""

SSHD_CONFIG="/etc/ssh/sshd_config"
SSH_CONFIG="/etc/ssh/ssh_config"
if [ ! -f "$SSHD_CONFIG" ]; then
    echo "Ошибка: Файл $SSHD_CONFIG не найден"
    exit 1
fi

BACKUP_FILE="/etc/ssh/sshd_config.backup_$(date +%Y%m%d_%H%M%S)"
cp "$SSHD_CONFIG" "$BACKUP_FILE"
echo "Создана резервная копия: $BACKUP_FILE"

rm /etc/ssh/sshd_config.d/50-cloud-init.conf

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
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin no" >> "$SSHD_CONFIG"
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
PermitRootLogin no
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
echo ""
echo "Настройки безопасности SSH применены"
echo ""
echo ""
echo "Смена SSH-порта"
echo ""
echo ""
read -p "Введите новый SSH порт:" port
echo ""
echo ""

sed -i "s/^#Port.*/Port $port/" /etc/ssh/sshd_config.d/99-security-settings.conf
sed -i "s/^Port.*/Port $port/" /etc/ssh/sshd_config.d/99-security-settings.conf
grep -q "^Port" /etc/ssh/sshd_config.d/99-security-settings.conf || echo "Port $port" >> /etc/ssh/sshd_config.d/99-security-settings.conf

echo ""
echo ""
echo "Перезапуск службы SSH..."
echo ""
echo ""
if systemctl restart sshd; then
    echo "Служба SSH перезапущена через sshd"
else
    systemctl restart ssh
    echo "Служба SSH перезапущена через ssh"
fi

echo ""
echo ""
echo "SSH порт изменен на $port"
echo ""
echo ""

# Настройка ufw и блокировка IP-адресов РКН
echo ""
echo ""
echo "Базовая настройка ufw"
echo ""
echo ""

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

echo ""
echo ""
echo "Базовая настройка ufw прошла успешно"
echo ""
echo ""
echo "Блокировка IP-адресов РКН"
echo ""
echo ""
cat > add_blacklist.sh << 'EOF'
wget -O blacklist.txt https://raw.githubusercontent.com/C24Be/AS_Network_List/main/blacklists/blacklist.txt
if [[ ! -f blacklist.txt ]]; then
   echo "Файл blacklist.txt не найден!"
   exit 1
fi
while read -r subnet; do
    ufw deny from "$subnet"
done < blacklist.txt
ufw status
EOF
chmod +x add_blacklist.sh
echo "Запускаем add_blacklist.sh..."
./add_blacklist.sh
if ! crontab -l 2>/dev/null | grep -q "add_blacklist.sh"; then
    (crontab -l 2>/dev/null; echo "0 5 * * * $(pwd)/add_blacklist.sh") | crontab -
    echo "Задание добавлено в crontab для ежедневного выполнения в 5:00 утра"
else
    echo "Задание уже существует в crontab"
fi

echo "Настройка ufw под РКН завершена!"


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

# Добавляем 1 Гб подкачки для самых дешёвых VPS с 1 Гб RAM
echo ""
echo ""
echo "Добавляем 1Гб подкачки"
echo ""
echo ""

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
echo ""
echo "1Гб подкачки создан и активирован"
echo ""
echo ""
