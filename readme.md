# Valheim Admin

Simple admin scripts for managing a Valheim server using [LinuxGSM](https://linuxgsm.com/lgsm/vhserver).

Nothing fancy. Assumes Ubuntu 20.10, Discord, and Restic.

## Prep

1. Record your [Steam ID](https://steamcommunity.com/sharedfiles/filedetails/?id=209000244). Specifically, the SteamID64, which is a large integer with no other characters.

1. Run `timedatectl list-timezones` and choose one.

1. Get a [discord webhook](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks).

1. Decide where [restic backups](https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html#) will go (cloud, disk, etc).<br/>I'm using Backblaze because it's trivial to set up & free out to 10 GB.

## Configure

```sh
git clone https://github.com/kofalt/valheim-admin

cd valheim-admin
cp admin/config.example admin/config.sh

# Fill in the values recorded above
nano admin/config.sh
```

## Run

```sh
# Install
admin/setup.sh

# Console output
tail -n 100 -f log/console/vhserver-console.log

# Server report
./vhserver details

# Cron report
crontab -l
systemctl status cron
```

## Administration

LGSM's included backup strategy is tarballs. This uses Restic instead.

Defaults to a daily shutdown & backup at 7am, and an update check (alert only) twice an hour.

You could more fully automate the server, check `crontab -e` for some disabled examples.

Also check the LGSM and Restic manuals for commands, flags, etc.
