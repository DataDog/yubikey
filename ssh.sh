#!/usr/bin/env bash

# Stop on error.
set -e

source env.sh

# Sets gpg-agent for SSH_AUTH_SOCK in the user's profile & environment
echo "${GREEN}Setting the GPG agent for SSH_AUTH_SOCK to handle SSH actions${RESET}"
echo "${YELLOW}This includes git actions like pushing and pulling from Github${RESET}"
echo "${YELLOW}If this breaks your workflow, edit your profile to remove it${RESET}"
echo "${YELLOW}And please open a ticket to let us know: https://github.com/DataDog/yubikey${RESET}"
source lib/ssh_conf.sh

# Export SSH key derived from GPG authentication subkey.
KEYID=$(get_keyid "$DEFAULT_GPG_HOMEDIR")
SSH_PUBKEY=$KEYID.ssh.pub
echo "${YELLOW}Exporting your SSH public key to ${SSH_PUBKEY}${RESET}"
ssh-add -L | grep -iF 'cardno' > "$SSH_PUBKEY"
cat "$SSH_PUBKEY" | $CLIP $CLIP_ARGS
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
