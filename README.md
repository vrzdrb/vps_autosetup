# VPS autosetup
<img width="652" height="446" alt="preview" src="https://github.com/user-attachments/assets/48755c3a-edfd-4e06-8e39-84903baa6640" />

Скрипт позволяет быстро произвести базовую настройку VPS-сервера:
- Установить минимальный набор программ (sudo mc ufw micro htop jq);
- Включить: unattended-upgrades, BBR, авто-перезагрузку (раз в неделю), 1Гб подкачки для дешёвых VPS с 1Гб RAM; 
- Создать и загрузить ssh-ключ, изменить SSH порт;
- Отключить: IPv6, вход по паролю;
- Настроить UFW (в том числе на блокировку ботов РКН);
- Посмотреть ipregion (by https://ipregion.vrnt.xyz);
- Посмотреть IPQuality (by https://Check.Place);
- Посмотреть vps-audit (by https://github.com/vernu/vps-audit).
- Включить логгирование sudo, политику паролей, установить и настроить fail2ban

## Проверено на:
- Debian 12+
- Ubuntu 24.04+

## Загрузка (запускать под root):
```bash
curl -o vps_autosetup.sh https://raw.githubusercontent.com/vrzdrb/vps_autosetup/main/vps_autosetup.sh
chmod +x vps_autosetup.sh
./vps_autosetup.sh
```
