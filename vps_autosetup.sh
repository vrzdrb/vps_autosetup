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

echo "Настройки DNS..."

tee /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=1.1.1.1 8.8.8.8 8.8.4.4
#FallbackDNS=
Domains=~.
DNSSEC=yes
DNSOverTLS=yes
EOF
systemctl restart systemd-resolved.service

echo "Настройки DNS применены"


# Базовый набор программ

echo "Установка базового ПО"
apt install sudo mc git ufw chkrootkit rkhunter rsyslog micro htop tcpdump net-tools dnsutils jq docker
echo "Установка завершена"


# Включаем unattended-upgrades

echo "Включаем unattended-upgrades"

echo 'Unattended-Upgrade::Mail "root";' >> /etc/apt/apt.conf.d/50unattended-upgrades
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades
systemctl restart unattended-upgrades

echo "unattended-upgrades включены"


# Включаем BBR, отключаем IPv6

echo "Включаем BBR, отключаем IPv6"

if ! grep -q "net.core.default_qdisc = fq" /etc/sysctl.conf; then
    echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv4.tcp_congestion_control = bbr" /etc/sysctl.conf; then
    echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
fi

sh -c 'echo "
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
" >> /etc/sysctl.conf'

sysctl -p

echo "BBR включен, IPv6 отключен"

# Включаем автоматическую перезагрузку в 4:20 утра каждый понедельник

(crontab -l 2>/dev/null; echo "20 4 * * 1 /sbin/reboot") | crontab -

echo "Добавлена перезагрузка в 4:20 каждый понедельник"


# Устанавливаем и настраиваем Fail2Ban

echo "Настройка fail2ban"

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
    echo "В следующем диалоговом окне вместо $username пишите root"
else
    echo "Ок"
fi


# Настройка безопасности SSH:

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

echo "Применяем настройки безопасности SSH"

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

systemctl restart sshd

echo "Настройки безопасности SSH применены"
echo "Смена SSH-порта"

read -p "Введите новый SSH порт:" port
sed -i "s/^#Port.*/Port $port/" /etc/ssh/sshd_config.d/99-security-settings.conf
sed -i "s/^Port.*/Port $port/" /etc/ssh/sshd_config.d/99-security-settings.conf
grep -q "^Port" /etc/ssh/sshd_config.d/99-security-settings.conf || echo "Port $port" >> /etc/ssh/sshd_config.d/99-security-settings.conf

systemctl restart ssh

echo "SSH порт изменен на $port"


# Настройка ufw и блокировка IP-адресов РКН

echo "Базовая настройка ufw"

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

echo "Базовая настройка ufw прошла успешно"
echo "Блокировка IP-адресов РКН"

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


# Добавляем 2 Гб подкачки для самых дешёвых VPS с 1 Гб RAM

echo "Добавляем 2Гб подкачки"

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

echo "2Гб подкачки созданы и активированы"
               
                           
# Смотрим GeoIP
                
wget -O ipregion.sh https://ipregion.vrnt.xyz
chmod +x ipregion.sh
./ipregion.sh


# Минимальный аудит безопасности
                                       
curl -O https://raw.githubusercontent.com/vernu/vps-audit/main/vps-audit.sh
chmod +x vps-audit.sh
sudo ./vps-audit.sh
