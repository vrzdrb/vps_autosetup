# VPS autosetup

Скрипт автоматически производит базовую настройку VPS-сервера:
- Устанавливает минимальный набор программ вроде midnight commander, ranger, micro, ufw;
- Включает: unattended-upgrades, BBR, авто-перезагрузку (раз в неделю), логгирование sudo, 1Гб подкачки для дешёвых VPS с 1Гб RAM; 
- Добавляет пользователя sudo, помогает создать и загрузить ssh-ключ, меняет SSH порт;
- Выключает: IPv6, вход по паролю;
- Настраивает UFW, в том числе добавляет IP-адреса РКН в чёрный список;
- Показывает вывод ipregion (by https://ipregion.vrnt.xyz);
- Показывает вывод IPQuality (by https://Check.Place);
- Показывает вывод bench.sh;
- Показывает вывод vps-audit (by https://github.com/vernu/vps-audit).

## Требования:
- Debian или Ubuntu (тестировался преимущественно на Debian 12/13)

## Загрузка (запускать под root):
```bash
curl -o vps_autosetup.sh https://raw.githubusercontent.com/vrzdrb/vps_autosetup/main/vps_autosetup.sh
chmod +x vps_autosetup.sh
./vps_autosetup.sh
```
Скрипт написан новичком для новичков, любые предложения по улучшению буду рад видеть в issues.
