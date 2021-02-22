#!/usr/bin/env bash
set -euo pipefail
unset CDPATH; cd "$( dirname "${BASH_SOURCE[0]}" )"; cd "$(pwd -P)"

source config.sh
set -x
cd ..

# TZ for cron / logs
sudo timedatectl set-timezone "$ADMIN_TIMEZONE"
timedatectl

# Sysadmin prefs, LGSM deps, Restic deps
hash wget curl htop iotop jq tree tmux bzip2 2>/dev/null || (
	sudo apt update
	sudo apt install -y wget curl htop iotop jq tree tmux bzip2
)

# Restic
wget -O restic.bz2 "$RESTIC_DOWNLOAD_URL"
bzip2 -d restic.bz2
chmod +x ./restic
./restic self-update
./restic init

#
# https://docs.linuxgsm.com/requirements/gamedig
#

curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt update
sudo apt install -y nodejs
sudo npm install gamedig -g

#
# https://linuxgsm.com/lgsm/vhserver/
#

sudo dpkg --add-architecture i386
sudo apt update

# 20.10 notes:
#
# Swapping python3 over python-is-python2
#
# lib32gcc1 not found; apt claims lib32gcc-s1 replaces it
#
# libsdl2-2.0-0      silences an SDL warning and allegedly makes server startup faster
# https://github.com/ValveSoftware/steam-for-linux/issues/7036
#
# libsdl2-2.0-0:i386 was needed by LGSM and some 32-bit components
#
sudo apt install -y curl wget file tar bzip2 gzip unzip bsdmainutils python3 util-linux ca-certificates binutils bc jq tmux netcat lib32gcc-s1 lib32stdc++6 steamcmd libsdl2-2.0-0 libsdl2-2.0-0:i386

# Dedicated box, don't care about users
# adduser vhserver
# su - vhserver
whoami

wget -O linuxgsm.sh https://linuxgsm.sh
chmod +x linuxgsm.sh
bash linuxgsm.sh vhserver

./vhserver install

#
# Configure & run
#

configFile="lgsm/config-lgsm/vhserver/vhserver.cfg"

echo ""                                   >> "$configFile"
echo "servername=\"$servername\""         >> "$configFile"
echo "serverpassword=\"$serverpassword\"" >> "$configFile"
echo "port=\"$port\""                     >> "$configFile"
echo "postalert=\"$postalert\""           >> "$configFile"
echo "discordalert=\"$discordalert\""     >> "$configFile"
echo "discordwebhook=\"$discordwebhook\"" >> "$configFile"

# Linux default state folder is ~/.config/unity3d/IronGate/Valheim​
#
# Default from LGSM:
# startparameters="-name '${servername}' -password ${serverpassword} -port ${port} -world ${gameworld} -public ${public} -savedir /vagrant/state"
#
echo "startparameters=\"-name '\${servername}' -password \${serverpassword} -port \${port} -world \${gameworld} -public \${public} -savedir $PWD/state\"" >> "$configFile"

./vhserver start


#
# Server admin
#

echo "Waiting for server to create state directory..."

while [ ! -f state/adminlist.txt ]; do sleep 5; done

sleep 5 # For good measure
echo "$ADMIN_ID" >> state/adminlist.txt

#
# Backup
#

echo "Waiting 2 minutes for server gen state to settle..."
sleep 120
./admin/backup.sh "initial"


#
# Cron jobs
#

# This probably clobbers other cron entries.

crontab << EOF
# Check health every 5 mins
# */5 * * * * "$PWD/vhserver" monitor > /dev/null 2>&1

# Check for game updates every 30 mins
# Will alert but take no action
20,40 * * * * "$PWD/vhserver" check-update > /dev/null 2>&1

# Back up the server at 7am every day
0 7 * * * "$PWD/admin/backup.sh" daily > /dev/null 2>&1

# Check for LGSM updates at 8am on Monday
# 0 8 * * 1 "$PWD/vhserver" update-lgsm > /dev/null 2>&1
EOF

crontab -l
systemctl status cron

echo ""
echo "Complete."
