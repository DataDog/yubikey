#!/usr/bin/env bash

source env.sh

set -e

echo "Deploying the notification script"
echo -e "$NOTIFICATION_CMD" > "$NOTIFICATION_SCRIPT_PATH"
chmod u+x "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}The notification script has been deployed${RESET}"

$GIT config --global --add gpg.program "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}Notifications have been set up in git${RESET}"
