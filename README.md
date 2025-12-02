# vps_autosetup
The script automatically performs some basic configuration for your VPS such as:
- Enabling: unattended-upgrades, BBR, auto reboot (once a week), sudo logging, 2Gb swap; 
- Add sudo user, create & upload ssh-key (only Linux commands), change SSH port;
- Disabling: IPv6, root login, password authentication;
- Configuring iptables (read this section carefully);
- Show ipregion (by https://ipregion.vrnt.xyz);
- Show vps-audit (by https://github.com/vernu/vps-audit).

## Requirements:
- Debian Linux on your VPS (or Ubuntu, but Debian is preferable)

## Download:

```bash
curl -o vps_autosetup.sh https://raw.githubusercontent.com/vrzdrb/vps_autosetup/main/vps_autosetup.sh
```
or

```bash
wget https://raw.githubusercontent.com/vrzdrb/vps_autosetup/main/vps_autosetup.sh
```

## Run from root:
```bash
chmod +x vps_autosetup.sh
./vps_autosetup.sh
```
