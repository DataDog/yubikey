#!/bin/bash

# Stop on error.
set -e

source env.sh

configure_shell() {
    local config_file
    config_file="$1"

    echo "$(basename "$config_file") detected"
    if ! grep -q "gpg-agent.ssh" "$config_file"; then
        if [[ "$(basename "$config_file")" == "config.fish" ]]; then
            echo 'set -gx SSH_AUTH_SOCK ${HOME}/.gnupg/S.gpg-agent.ssh' >> "${config_file}"
        else
            echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> "${config_file}"
        fi
    fi
    # Avoid bad config file to force us to fail
    set +e
    source "${config_file}" > /dev/null 2>&1
    set -e
    if [[ "$SSH_AUTH_SOCK" != "${HOME}/.gnupg/S.gpg-agent.ssh" ]]; then
        echo "Failed to configure SSH_AUTH_SOCK into $config_file"
        return 1
    fi

}

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

case $(/usr/bin/basename "$SHELL") in
    bash)
        configuration_file="${HOME}/.bashrc"
        ;;
    zsh)
        configuration_file="${HOME}/.zshrc"
        ;;
    fish)
        configuration_file="${HOME}/.config/fish/config.fish"
        ;;
    *)
        configuration_file="${HOME}/.profile"
        ;;
esac
configure_shell "$configuration_file"


# Export SSH key derived from GPG authentication subkey.
KEYID=$(get_keyid "$DEFAULT_GPG_HOMEDIR")
SSH_PUBKEY=$KEYID.ssh.pub
echo "Exporting your SSH public key to $SSH_PUBKEY"
ssh-add -L | grep -iF 'cardno' > "$SSH_PUBKEY"
cat "$SSH_PUBKEY" | pbcopy
echo "It has also been copied to your clipboard."
echo "You may now add it to GitHub: https://github.com/settings/ssh/new"
echo "Opening GitHub..."
open "https://github.com/settings/ssh/new"
echo "Please save a copy in your password manager."
read -p "Have you done this? "
echo "Great."
echo ""

