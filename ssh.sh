#!/bin/bash

# Stop on error.
set -e

source env.sh

function configure_shell {
    case $(/usr/bin/basename "$SHELL") in
        bash)
            config_file="${HOME}/.bashrc"
            ;;
        zsh)
            config_file="${HOME}/.zshrc"
            ;;
        fish)
            config_file="${HOME}/.config/fish/config.fish"
            ;;
        *)
            config_file="${HOME}/.profile"
            ;;
    esac

    config_file_basename=$(basename "$config_file")
    echo "$config_file_basename detected"
    if ! grep -q "gpg-agent.ssh" "$config_file"; then
        if [[ "$config_file_basename" == "config.fish" ]]; then
            echo "set -gx SSH_AUTH_SOCK ${HOME}/.gnupg/S.gpg-agent.ssh" >> "${config_file}"
        else
            echo "export \"SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh\"" >> "${config_file}"
        fi
    fi
    # put set +e before sourcing the rc file just in case people have things that return 1 in it
    set +e
    # shellcheck disable=SC1090
    source "${config_file}" > /dev/null 2>&1
    set -e
    if [[ "$SSH_AUTH_SOCK" != "${HOME}/.gnupg/S.gpg-agent.ssh" ]]; then
        echo "Failed to configure SSH_AUTH_SOCK into $config_file"
        exit 1
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

configure_shell

# Export SSH key derived from GPG authentication subkey.
KEYID=$(get_keyid "$DEFAULT_GPG_HOMEDIR")
SSH_PUBKEY=$KEYID.ssh.pub
echo "Exporting your SSH public key to $SSH_PUBKEY"
ssh-add -L | grep -iF 'cardno' > "$SSH_PUBKEY"
echo "$SSH_PUBKEY" | pbcopy
echo "It has also been copied to your clipboard."
echo "You may now add it to GitHub: https://github.com/settings/ssh/new"
echo "Opening GitHub..."
open "https://github.com/settings/ssh/new"
echo "Please save a copy in your password manager."
read -pr "Have you done this? "
echo "Great."
echo
echo "You will need to ${RED}${BOLD}enter your PIN (once a day)${RESET}, and ${RED}${BOLD}touch your YubiKey everytime${RESET} in order to use SSH."
echo
echo "Enjoy using your YubiKey at Datadog!"
