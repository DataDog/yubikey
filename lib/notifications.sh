#!/usr/bin/env bash

# Look if the file is sourced or directly called. if not source env.sh
# https://stackoverflow.com/a/2684300
[[ ${BASH_SOURCE[0]} != "$0" ]] || source env.sh

# Honour git.sh setting or set to --global by default
# Besides you can specify --local when directly called
SCOPE=${1:---global}
echo "Turning on notifications for signing git commits & tags ${GREEN}${BOLD}${SCOPE//--/}ly${RESET}"

set -e

# Create a bin directory where user has write access
mkdir -p "$USER_BIN_DIR"

echo "Deploying the notifications script"
sed -E -e 's/%%NOTIFICATION_NOTIFY%%/'"$NOTIFICATION_NOTIFY"'/' bin/gpg-sign-notify > "$NOTIFICATION_SCRIPT_PATH"
chmod u+x "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}The notifications script has been deployed${RESET}"

$GIT config "$SCOPE" --add gpg.program "$NOTIFICATION_SCRIPT_PATH"
echo "${GREEN}Notifications have been set up in git${RESET}"
