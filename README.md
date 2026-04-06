# VPS autosetup
<img width="649" height="347" alt="preview" src="https://github.com/user-attachments/assets/44679186-9798-4fe7-9b43-ce9be2ca452f" />

Скрипт позволяет быстро произвести базовую настройку VPS-сервера:
- Установить минимальный набор программ (sudo mc ufw chkrootkit micro htop tcpdump net-tools dnsutils jq iftop nethogs bmon);
- Включить: unattended-upgrades, BBR, авто-перезагрузку (раз в неделю), 1Гб подкачки для дешёвых VPS с 1Гб RAM; 
- Создать и загрузить ssh-ключ, изменить SSH порт;
- Отключить: IPv6, вход по паролю;
- Настроить UFW (в том числе на блокировку ботов РКН);
- Посмотреть ipregion (by https://ipregion.vrnt.xyz);
- Посмотреть IPQuality (by https://Check.Place);
- Посмотреть vps-audit (by https://github.com/vernu/vps-audit).

## Проверено на:
- Debian 12+
- Ubuntu 24.04+

## Загрузка (запускать под root):
```bash
curl -o vps_autosetup.sh https://raw.githubusercontent.com/vrzdrb/vps_autosetup/main/vps_autosetup.sh
chmod +x vps_autosetup.sh
./vps_autosetup.sh
```
