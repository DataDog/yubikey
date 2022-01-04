#!/usr/bin/env bash

function configure_shell {
    case $(basename "$SHELL") in
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
            RC_SSH_CONF="set -gx SSH_AUTH_SOCK \${HOME}/.gnupg/S.gpg-agent.ssh"
        else
            RC_SSH_CONF="export SSH_AUTH_SOCK=\${HOME}/.gnupg/S.gpg-agent.ssh"
        fi
    fi
    echo "$RC_SSH_CONF" >> "$config_file"
    eval "$RC_SSH_CONF"
    if [[ "$SSH_AUTH_SOCK" != "${HOME}/.gnupg/S.gpg-agent.ssh" ]]; then
        echo "Failed to configure SSH_AUTH_SOCK in $config_file"
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
# put set +e before trying running the gpg agent as it can be already running according to the OS and return != 0
set +e
$GPG_AGENT --daemon
set -e
if [[ -f "$SSH_ENV" ]]; then
    rm -f "$SSH_ENV"
fi

configure_shell
