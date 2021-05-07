#!/usr/bin/env bash

# Look if the file is sourced or directly called. if not source env.sh
# https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
[[ $_ != $0 ]] || source env.sh

set -e

echo "Deploying the notification script"
echo -e "$NOTIFICATION_CMD" > "$NOTIFICATION_SCRIPT_PATH"
chmod u+x "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}The notification script has been deployed${RESET}"

$GIT config --global --add gpg.program "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}Notifications have been set up in git${RESET}"
