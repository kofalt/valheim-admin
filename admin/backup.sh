#!/usr/bin/env bash
set -euo pipefail
unset CDPATH; cd "$( dirname "${BASH_SOURCE[0]}" )"; cd "$(pwd -P)"

source config.sh
set -x
cd ..

tag="${1:-manual}"

./admin/discord.sh --text "Server halting for $tag backup in 30 seconds..."
sleep 30

./vhserver stop
sleep 1

result=0
./restic backup "$PWD"  --tag "$tag" || result=$?

sleep 1
./vhserver start

if [ "$result" -eq "0" ]; then
	./restic snapshots --host "$HOSTNAME" --path "$PWD" --quiet --compact --last | grep ':' | ./admin/discord-stdin.sh
else
	./admin/discord.sh --text "Backup ($tag) failed with code $result."
fi
