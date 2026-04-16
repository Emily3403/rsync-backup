#!/usr/bin/env bash

# User config
SOURCES=(~/./Documents/)
BACKUPS_TO_KEEP=60 # Two months of daily backups

# Config for script
TARGET="incremental"
TODAY=$(date --iso-8601)
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
HOME_DIR="/var/services/homes/emily"

set -e

# First check if the last backup failed. If so, we propage the error.
if [ "$1" != "" ]; then
    echo "Force flag detected. Doing the update now!"
elif [ "$(sed -n '1p' bi.out)" != 'true' ]; then
    echo "[ERROR] the backup logs indicate that there is an error. Doing it anyway :o"

elif [ "$(date -d "7 hours ago" --iso-8601)" != "$TODAY" ]; then
    echo "[ERROR] it is too early in the morning to do a backup. (0:00 - 7:00)"
    exit 1
else
    echo $'[Info]  Everything is clear: starting backup normally. \n'
fi

exit_and_write_to_file() {
    rm -f "$SCRIPT_DIR/bi.out"
    echo "[ERROR] This operation failed. I am exiting!"
    echo "false" > "$SCRIPT_DIR/bi.out"
    echo "$TODAY" >> "$SCRIPT_DIR/bi.out"

    # Maybe notify i3blocks
    if [ "$XDG_CURRENT_DESKTOP" = "i3" ]; then
        pkill -SIGRTMIN+12 i3blocks
    fi

    exit 1
}

exit_normal() {
    rm -f "$SCRIPT_DIR/bi.out"

    echo "true" > "$SCRIPT_DIR"/bi.out
    echo "$TODAY" >> "$SCRIPT_DIR"/bi.out

    # Maybe notify i3blocks
    if [ "$XDG_CURRENT_DESKTOP" = "i3" ]; then
        pkill -SIGRTMIN+12 i3blocks
    fi

    exit 0
}


echo "[Info]  Starting the Backup ..."

rsync -e 'ssh' --info=progress2 --copy-links                     \
    --one-file-system --exclude-from "$SCRIPT_DIR/exclude.txt" \
        --link-dest "/var/services/homes/emily/test-backup/last" \
    -ahR "${SOURCES[@]}" "nas:test-backup/$TODAY"     ||
        exit_and_write_to_file

echo $'\n[Debug] linking `last` to the current backup ...'
ssh nas "ln -nsf ~/test-backup/$TODAY ~/test-backup/last" || exit_and_write_to_file

echo $'\n[Info]  Succeeded in doing the backup. Have a nice day ^^'

exit_normal
