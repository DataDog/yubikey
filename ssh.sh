#!/usr/bin/env bash

# Stop on error.
set -e

source env.sh

source lib/ssh_conf.sh

# Export SSH key derived from GPG authentication subkey.
KEYID=$(get_keyid "$DEFAULT_GPG_HOMEDIR")
SSH_PUBKEY=$KEYID.ssh.pub
echo "${YELLOW}Exporting your SSH public key to ${SSH_PUBKEY}${RESET}"
ssh-add -L | grep -iF 'cardno' > "$SSH_PUBKEY"
echo "$SSH_PUBKEY" | $CLIP $CLIP_ARGS
echo "It has also been copied to your clipboard."
echo "${YELLOW}You may now add it to GitHub: https://github.com/settings/ssh/new${RESET}"
echo "${GREEN}Opening GitHub...${RESET}"
$OPEN "https://github.com/settings/ssh/new"
echo "${YELLOW}Please save a copy in your password manager.${RESET}"
read -rp "${YELLOW}Have you done this? ${RESET}"
echo "Great."
echo
echo "You will need to ${GREEN}${BOLD}enter your PIN (once a day)${RESET}, and ${GREEN}${BOLD}touch your YubiKey everytime${RESET} in order to use SSH."
echo
echo "Enjoy authenticating over SSH with your YubiKey at Datadog!"
