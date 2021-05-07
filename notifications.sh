#!/usr/bin/env bash

# Look if the file is sourced or directly called. if not source env.sh
# https://stackoverflow.com/a/2684300
[[ ${BASH_SOURCE[0]} != "$0" ]] || source env.sh

# Honour git.sh setting or set to --global by default
# Besides you can specify --local when directly called
SCOPE=${1:---global}
echo "Notifying the signature of git commits & tags ${GREEN}${BOLD}${SCOPE}${RESET}"

set -e

echo "Deploying the notification script"
echo -e "$NOTIFICATION_CMD" > "$NOTIFICATION_SCRIPT_PATH"
chmod u+x "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}The notification script has been deployed${RESET}"

$GIT config "$SCOPE" --add gpg.program "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}Notifications have been set up in git${RESET}"
