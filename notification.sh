#!/usr/bin/env bash

source env.sh

set -e

echo "Deploying the notifcation script"
echo -e "$NOTIFICATION_CMD" > "$NOTIFICATION_SCRIPT_PATH"
chmod u+x "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}The notification script is deployed${RESET}"

$GIT config --global --add gpg.program "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}The notifcation is set up in git${RESET}"
echo "${GREEN}Enjoy your yubikey${RESET}"
