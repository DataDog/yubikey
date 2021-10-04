#!/usr/bin/env bash

# Stop on error.
set -e

source env.sh
source realname-and-email.sh

# Determine whether to set globally or locally.
OLD_PWD="$(pwd)"
if [[ -z "$1" ]]
then
    echo "Signing git commits & tags ${GREEN}${BOLD}GLOBALLY${RESET}"
    SCOPE="--global"
else
    echo "Signing git commits & tags ${GREEN}${BOLD}LOCALLY${RESET}: $1"
    SCOPE="--local"
    cd "$1"


source lib/git_conf.sh
cd "$OLD_PWD"

# Export GPG public key to GitHub.
echo "Exporting your GPG public key to GitHub."
$GPG --armor --export "$KEYID" | $CLIP $CLIP_ARGS
echo "It has been copied to your clipboard."
echo "${YELLOW}You may now add it to GitHub: https://github.com/settings/gpg/new${RESET}"
echo "${GREEN}Opening GitHub...${RESET}"
open "https://github.com/settings/gpg/new"
echo

# Turn on notifications.
source lib/notifications.sh $SCOPE
echo "${GREEN}Enjoy signing your git commits with your YubiKey!${RESET}"
