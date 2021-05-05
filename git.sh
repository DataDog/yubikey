#!/usr/bin/env bash

# Stop on error.
set -e

source env.sh
source realname-and-email.sh

# Determine whether to set globally or locally.
if [[ -z "$1" ]]
then
    echo "Signing git commits & tags ${GREEN}${BOLD}GLOBALLY${RESET}"
    SCOPE="--global"
else
    echo "Signing git commits & tags ${GREEN}${BOLD}LOCALLY${RESET}: $1"
    SCOPE="--local"
    cd "$1"
fi

# Set git name and email.
echo "Setting your git-config user.name..."
$GIT config $SCOPE user.name "$REALNAME"
echo "Setting your git-config user.email..."
$GIT config $SCOPE user.email "$EMAIL"

# Ask user whether all git commits and tags should be signed.
KEYID=$(get_keyid "$DEFAULT_GPG_HOMEDIR")
echo "Setting git to use this GPG key."
echo "Also, turning on signing of all commits and tags by default."
# Tell git to use this GPG key.
$GIT config $SCOPE user.signingkey "$KEYID"
# Also, turn on signing commits and tags by default.
$GIT config $SCOPE commit.gpgsign true
$GIT config $SCOPE tag.forceSignAnnotated true
echo

# Export GPG public key to GitHub.
echo "Exporting your GPG public key to GitHub."
$GPG --armor --export "$KEYID" | $CLIP $CLIP_ARGS
echo "It has been copied to your clipboard."
echo "${YELLOW}You may now add it to GitHub: https://github.com/settings/gpg/new${RESET}"
echo "${GREEN}Opening GitHub...${RESET}"
open "https://github.com/settings/gpg/new"
echo

# Turn on notifications.
./notifications.sh
echo "${GREEN}Enjoy signing your git commits with your YubiKey!${RESET}"
