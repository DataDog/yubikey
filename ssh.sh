#!/bin/bash

# Stop on error.
set -e

source env.sh

if ! grep -q "enable-ssh-support" "$DEFAULT_GPG_AGENT_CONF"; then
    # enable ssh support
    echo "enable-ssh-support" >> "$DEFAULT_GPG_AGENT_CONF"
fi
# NOTE: Kill existing SSH and GPG agents, and start GPG agent manually (with SSH
# support added above) to maximize odds of picking up SSH key.
killall ssh-agent || echo "ssh-agent was not running."
$GPGCONF --kill all
$GPG_AGENT --daemon
if [[ -f "$SSH_ENV" ]]; then
    rm -f "$SSH_ENV"
fi

# fish
if [[ -f "${HOME}/.config/fish/config.fish" ]]; then
    echo "fish shell configuration detected"
    if ! [[ $(cat "${HOME}/.config/fish/config.fish") =~ "gpg-agent.ssh" ]]; then
        echo 'set -gx SSH_AUTH_SOCK ${HOME}/.gnupg/S.gpg-agent.ssh' >> "${HOME}/.config/fish/config.fish"
    fi
    source ${HOME}/.config/fish/config.fish
fi

# zsh
if [[ -f "${HOME}/.zshrc" ]]; then
    echo "zshell configuration detected"
    if ! [[ $(cat "${HOME}/.zshrc") =~ "gpg-agent.ssh" ]]; then
        echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> "${HOME}/.zshrc"
    fi
    set +e
    source "${HOME}/.zshrc" > /dev/null 2>&1
    set -e
fi

# bash
if [[ -f "${HOME}/.bash_profile" ]]; then
    echo "bash configuration detected"
    if ! [[ $(cat "${HOME}/.bash_profile") =~ "gpg-agent.ssh" ]]; then
        echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> "${HOME}/.bash_profile"
    fi
    source "${HOME}/.bash_profile" > /dev/null 2>&1
fi

if [[ -f "${HOME}/.profile" ]]; then
    echo "profile configuration detected"
    set +e
    if ! [[ $(cat "${HOME}/.profile") =~ "gpg-agent.ssh" ]]; then
        echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> "${HOME}/.profile" 2> /dev/null
    fi
    source "${HOME}/.profile"
    set -e
fi

ssh-add -L

# Export SSH key derived from GPG authentication subkey.
KEYID=$(get_keyid $DEFAULT_GPG_HOMEDIR)
SSH_PUBKEY=$KEYID.ssh.pub
echo "Exporting your SSH public key to $SSH_PUBKEY"
ssh-add -L | grep -iF 'cardno' > $SSH_PUBKEY
cat $SSH_PUBKEY | pbcopy
echo "It has also been copied to your clipboard."
echo "You may now add it to GitHub: https://github.com/settings/ssh/new"
echo "Opening GitHub..."
open "https://github.com/settings/ssh/new"
echo "Please save a copy in your password manager."
read -p "Have you done this? "
echo "Great."
echo ""
