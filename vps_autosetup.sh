#!/bin/bash

# Проверка на root
if [ "$(id -u)" != "0" ]; then
   echo "Этот скрипт должен быть запущен от root" 1>&2
   exit 1
fi

# Прерывание при ошибке
set -e

# Цвета
PURPLE='\e[38;5;213m'
CYAN='\e[96m'
GREEN='\e[92m'
YELLOW='\e[93m'
RED='\e[91m'
NC='\e[0m' # No Color

# Функция для отображения заголовка
show_header() {
    clear
    echo -e "${PURPLE}  _    ______  _____                __                  __             ${NC}"
    echo -e "${PURPLE} | |  / / __ \/ ___/   ____ ___  __/ /_____  ________  / /___  ______  ${NC}"
    echo -e "${PURPLE} | | / / /_/ /\__ \   / __ '/ / / / __/ __ \/ ___/ _ \/ __/ / / / __ \ ${NC}"
    echo -e "${PURPLE} | |/ / ____/___/ /  / /_/ / /_/ / /_/ /_/ (__  )  __/ /_/ /_/ / /_/ / ${NC}"
    echo -e "${PURPLE} |___/_/    /____/   \__,_/\__,_/\__/\____/____/\___/\__/\__,_/ .___/  ${NC}"
    echo -e "${PURPLE}                                                             /_/       ${NC}"
    echo ""
    echo -e "${CYAN}                 автоматизация разорвёт цепи рабства${NC}"
    echo ""
}

# Функция для отображения меню
show_menu() {
    show_header
    echo -e "${PURPLE}1.${NC} ${CYAN}Обновление и настройки сети${NC}"
    echo -e "${PURPLE}2.${NC} ${CYAN}Создание пользователя${NC}"
    echo -e "${PURPLE}3.${NC} ${CYAN}Настройки SSH${NC}"
    echo -e "${PURPLE}4.${NC} ${CYAN}Настройки UFW${NC}"
    echo -e "${PURPLE}5.${NC} ${CYAN}Запретить РКН (UFW)${NC}"
    echo -e "${PURPLE}6.${NC} ${CYAN}Добавить подкачку${NC}"
    echo -e "${PURPLE}7.${NC} ${CYAN}IPRegion${NC}"
    echo -e "${PURPLE}8.${NC} ${CYAN}IPQuality${NC}"
    echo -e "${PURPLE}9.${NC} ${CYAN}bench.sh${NC}"
    echo -e "${PURPLE}10.${NC} ${CYAN}VPS Audit${NC}"
    echo -e "${PURPLE}11.${NC} ${CYAN}Включить логгирование sudo${NC}"
    echo -e "${PURPLE}12.${NC} ${CYAN}Установить политику паролей${NC}"
    echo -e "${PURPLE}13.${NC} ${CYAN}Fail2Ban${NC}"
    echo -e "${PURPLE}0.${NC} ${CYAN}Выход${NC}"
    echo ""
    echo -ne "${CYAN}Выберите пункт меню: ${NC}"
}


# 1. Обновление и настройки сети
setup_network_and_updates() {
    echo -e "${CYAN}Обновление пакетов и настройка сети...${NC}"
    apt update && apt upgrade -y
    apt install systemd-resolved -y
    tee /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=1.1.1.1 8.8.8.8 1.0.0.1 8.8.4.4
#FallbackDNS=9.9.9.9
Domains=~.
DNSSEC=yes
DNSOverTLS=yes
EOF
    
    systemctl enable systemd-resolved.service
    systemctl start systemd-resolved.service
    systemctl restart systemd-resolved.service

    echo -e "${CYAN}Установка дополнительных пакетов...${NC}"
    apt install unattended-upgrades sudo mc ufw micro htop jq -y
    echo 'Unattended-Upgrade::Mail "root";' >> /etc/apt/apt.conf.d/50unattended-upgrades
    echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
    dpkg-reconfigure -f noninteractive unattended-upgrades
    systemctl restart unattended-upgrades

    echo -e "${CYAN}Настройка BBR и отключение IPv6...${NC}"
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

    echo -e "${CYAN}Настройка часового пояса и перезагрузки по крону...${NC}"
    timedatectl set-timezone Europe/Moscow
    echo "20 2 * * 1 /sbin/reboot" | tee -a /var/spool/cron/crontabs/root >/dev/null
    
    echo -e "${GREEN}✓ Обновление и настройки сети завершены!${NC}"
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 2. Создание пользователя
create_user() {
    echo -e "${CYAN}Создание нового пользователя...${NC}"
    echo -ne "${CYAN}Введите имя пользователя: ${NC}"
    read -r username
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}Пользователь $username уже существует!${NC}"
    else
        useradd -m -s /bin/bash "$username"
        echo -ne "${CYAN}Задайте пароль для пользователя $username: ${NC}"
        passwd "$username"
        
        usermod -aG sudo "$username"
        echo -e "${GREEN}✓ Пользователь $username успешно создан и добавлен в группу sudo${NC}"
    fi
    
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 3. Настройки SSH
setup_ssh() {
    echo -e "${CYAN}Настройка SSH...${NC}"
    echo -ne "${CYAN}Введите имя созданного пользователя (НЕ ROOT): ${NC}"
    read -r username
    IP=$(curl -s --max-time 5 ifconfig.me)
    
    echo -e "${PURPLE}=======================================================================================${NC}"
    echo -e "${PURPLE}ВНИМАТЕЛЬНО ПРОЧТИТЕ: сейчас вам нужно открыть терминал на своём компьютере${NC}"
    echo -e "${PURPLE}И создать ssh-ключ для входа на сервер следующей командой:${NC}"
    echo -e "${CYAN}ssh-keygen -t ed25519${NC}"
    echo ""
    echo -e "${PURPLE}Загрузите ключ на сервер (команда для Linux):${NC}"
    echo -e "${CYAN}ssh-copy-id -i имяключа.pub $username@$IP${NC}"
    echo ""
    echo -e "${PURPLE}Команда для Windows:${NC}"
    echo -e "${CYAN}cat id_ed25519.pub | ssh $username@$IP mkdir -p && cat >> ~/.ssh/authorized_keys${NC}"
    echo ""
    echo -e "${PURPLE}Попробуйте подключиться к вашему серверу при помощи этого ключа:${NC}"
    echo -e "${CYAN}ssh -i имяключа $username@$IP${NC}"
    echo ""
    echo -e "${PURPLE}ТОЛЬКО ЕСЛИ ВХОД УСПЕШЕН, нажмите здесь Enter для ОТКЛЮЧЕНИЯ ВХОДА В SSH ПО ПАРОЛЮ${NC}"
    echo -e "${PURPLE}=======================================================================================${NC}"
    read -r
    
    SSHD_CONFIG="/etc/ssh/sshd_config"
    SSH_CONFIG="/etc/ssh/ssh_config"
    
    if [ ! -f "$SSHD_CONFIG" ]; then
        echo -e "${RED}Ошибка: Файл $SSHD_CONFIG не найден${NC}"
        return 1
    fi
    
    BACKUP_FILE="/etc/ssh/sshd_config.backup_$(date +%Y%m%d_%H%M%S)"
    cp "$SSHD_CONFIG" "$BACKUP_FILE"
    echo -e "${GREEN}Создана резервная копия: $BACKUP_FILE${NC}"
    
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
    
    if sshd -t -f "$SSHD_CONFIG"; then
        echo -e "${GREEN}Конфигурация SSH корректна${NC}"
    else
        echo -e "${RED}Ошибка в конфигурации SSH! Восстанавливаем из резервной копии...${NC}"
        cp "$BACKUP_FILE" "$SSHD_CONFIG"
        echo -e "${GREEN}Конфигурация восстановлена из резервной копии${NC}"
        return 1
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
    read -p "$(echo -e ${CYAN}Введите новый SSH порт: ${NC})" port
    echo ""
    
    chmod 600 /home/$username/.ssh/authorized_keys
    
    sed -i "s/^#Port.*/Port $port/" /etc/ssh/sshd_config.d/99-security-settings.conf
    sed -i "s/^Port.*/Port $port/" /etc/ssh/sshd_config.d/99-security-settings.conf
    grep -q "^Port" /etc/ssh/sshd_config.d/99-security-settings.conf || echo "Port $port" >> /etc/ssh/sshd_config.d/99-security-settings.conf
    
    if systemctl restart sshd; then
        echo -e "${GREEN}Служба SSH перезапущена через sshd${NC}"
    else
        systemctl restart ssh
        echo -e "${GREEN}Служба SSH перезапущена через ssh${NC}"
    fi
    
    echo -e "${GREEN}✓ SSH порт изменен на $port${NC}"
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 4. Настройки UFW
setup_ufw() {
    echo -e "${CYAN}Настройка UFW...${NC}"

    echo ""
    read -p "$(echo -e ${CYAN}Введите ваш SSH порт: ${NC})" port
    echo ""
    
    IP4_REGEX="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
    IP4=$(ip route get 8.8.8.8 2>/dev/null | grep -Po -- 'src \K\S*')
    
    if [[ ! $IP4 =~ $IP4_REGEX ]]; then
        IP4=$(curl -s --max-time 5 ipinfo.io/ip 2>/dev/null)
    fi
    
    if [[ ! $IP4 =~ $IP4_REGEX ]]; then
        echo -e "${RED}Не удалось получить внешний IP.${NC}"
        return 1
    fi
    
    BLOCK_ZONE_IP=$(echo ${IP4} | cut -d '.' -f 1-3).0/22
    ufw --force reset
    ufw limit $port/tcp comment 'SSH'
    ufw allow 443/tcp comment 'WEB'
    ufw insert 1 deny from "$BLOCK_ZONE_IP"
    ufw --force enable
    
    echo -e "${GREEN}✓ Настройки UFW завершены!${NC}"
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 5. Запретить РКН (UFW)
block_rkn() {
    echo -e "${CYAN}Блокировка IP-адресов РКН...${NC}"
    
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
    echo -e "${GREEN}Запускаем add_blacklist.sh...${NC}"
    ./add_blacklist.sh
    
    if ! crontab -l 2>/dev/null | grep -q "add_blacklist.sh"; then
        (crontab -l 2>/dev/null; echo "0 3 * * * $(pwd)/add_blacklist.sh") | crontab -
        echo -e "${GREEN}Задание добавлено в crontab для ежедневного выполнения в 5:00 утра${NC}"
    else
        echo -e "${YELLOW}Задание уже существует в crontab${NC}"
    fi
    
    echo -e "${GREEN}✓ Настройка ufw под РКН завершена!${NC}"
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 6. Добавить подкачку
add_swap() {
    echo -e "${CYAN}Добавление swap файла...${NC}"
    
    swapfile="/swapfile"
    if [ -f "$swapfile" ]; then
        echo -e "${YELLOW}Swap файл уже существует${NC}"
    else
        dd if=/dev/zero of=$swapfile bs=1M count=1024
        chmod 600 $swapfile
        mkswap $swapfile
        swapon $swapfile
        echo "$swapfile none swap sw 0 0" >> /etc/fstab
        echo -e "${GREEN}✓ 1Гб подкачки создан и активирован${NC}"
    fi
    
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 7. IPRegion
run_ipregion() {
    echo -e "${CYAN}Запуск IPRegion...${NC}"
    
    wget -O ipregion.sh https://ipregion.vrnt.xyz
    chmod +x ipregion.sh
    ./ipregion.sh
    
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 8. IPQuality
run_ipquality() {
    echo -e "${CYAN}Запуск IPQuality...${NC}"
    
    bash <(curl -sL https://Check.Place) -EI
    
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 9. bench.sh
run_bench() {
    echo -e "${CYAN}Запуск bench.sh...${NC}"
    
    curl -Lso- bench.sh | bash
    
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

# 10. VPS Audit
run_vps_audit() {
    echo -e "${CYAN}Запуск VPS Audit...${NC}"
    
    curl -O https://raw.githubusercontent.com/vernu/vps-audit/main/vps-audit.sh
    chmod +x vps-audit.sh
    ./vps-audit.sh
    
    echo -e "${YELLOW}Нажмите Enter для возврата в меню...${NC}"
    read -r
}

#!/bin/bash

# 11. sudo logging
enable_sudo_logging() {
    local sudoers_file="/etc/sudoers"
    sudo sed -i '/Defaults logfile/d' "$sudoers_file"
    echo 'Defaults logfile="/var/log/sudo.log"' | sudo tee -a "$sudoers_file" > /dev/null
    if sudo visudo -cf "$sudoers_file"; then
        echo "[OK] Sudo logging enabled. Logs will be in /var/log/sudo.log"
        read -r
    else
        echo "[ERROR] Failed to configure sudo logging"
        read -r
    fi
}

# 12. Password policy
configure_password_policy() {
    local pam_file="/etc/pam.d/common-password"
    local pwquality_conf="/etc/security/pwquality.conf"
    sudo apt-get install -y libpam-pwquality
    sudo sed -i '/pam_pwquality.so/d' "$pam_file"
    echo 'password requisite pam_pwquality.so retry=3 minlen=12 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 enforce_for_root' \
        | sudo tee -a "$pam_file" > /dev/null
    sudo bash -c "cat > $pwquality_conf" <<EOF
minlen = 12
ucredit = -1
lcredit = -1
dcredit = -1
ocredit = -1
EOF

    echo "[OK] Password policy configured in PAM and pwquality.conf"
    read -r
}

# 13. Fail2ban 
install_fail2ban() {
    sudo apt-get update
    sudo apt-get install -y fail2ban
    echo "=== Fail2ban interactive setup ==="
    read -p "Введите максимальное число неудачных попыток (maxretry) [по умолчанию 5]: " maxretry
    maxretry=${maxretry:-5}

    read -p "Введите время блокировки в секундах (bantime) [по умолчанию 600]: " bantime
    bantime=${bantime:-600}

    read -p "Введите время окна для подсчёта попыток в секундах (findtime) [по умолчанию 300]: " findtime
    findtime=${findtime:-300}

    read -p "Введите список игнорируемых IP (через пробел) [по умолчанию 127.0.0.1/8]: " ignoreip
    ignoreip=${ignoreip:-127.0.0.1/8}
    local jail_file="/etc/fail2ban/jail.local"
    sudo bash -c "cat > $jail_file" <<EOF
[DEFAULT]
ignoreip = $ignoreip
bantime  = $bantime
findtime = $findtime
maxretry = $maxretry

[sshd]
enabled = true
EOF

    sudo systemctl enable fail2ban
    sudo systemctl restart fail2ban
    echo "[OK] Fail2ban установлен и настроен. Конфиг: $jail_file"
    read -r
}

# Главный цикл
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            setup_network_and_updates
            ;;
        2)
            create_user
            ;;
        3)
            setup_ssh
            ;;
        4)
            setup_ufw
            ;;
        5)
            block_rkn
            ;;
        6)
            add_swap
            ;;
        7)
            run_ipregion
            ;;
        8)
            run_ipquality
            ;;
        9)
            run_bench
            ;;
        10)
            run_vps_audit
            ;;
        11)
            enable_sudo_logging
            ;;
        12)
            configure_password_policy
            ;;
        13)
            install_fail2ban
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор! Пожалуйста, выберите пункт от 0 до 9${NC}"
            sleep 2
            ;;
    esac
done

