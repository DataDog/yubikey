#!/bin/bash

# Shared environment variables.

# Use Homebrew binaries.
HOMEBREW_PREFIX=$(brew --prefix)
HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
export GIT=$HOMEBREW_BIN/git
export GPG=$HOMEBREW_BIN/gpg
export GPG_AGENT=$HOMEBREW_BIN/gpg-agent
export GPGCONF=$HOMEBREW_BIN/gpgconf
export YKMAN=$HOMEBREW_BIN/ykman

# Colors galore.
BOLD=$(tput bold)
export BOLD
RED=$(tput setaf 1)
export RED
RESET=$(tput sgr0) # Reset text
export RESET

# SSH.
export SSH_ENV="$HOME/.ssh/environment"

# Folders and files.
DEFAULT_GPG_HOMEDIR=$HOME/.gnupg
DEFAULT_GPG_AGENT_CONF=$DEFAULT_GPG_HOMEDIR/gpg-agent.conf
DEFAULT_GPG_CONF=$DEFAULT_GPG_HOMEDIR/gpg.conf

# Functions.

# Backup configuration in default GPG homedir, if it exists.
function backup_conf {
    local conf
    local conf_backup
    conf="$1"

    if [[ -e "$conf" ]]
    then
        conf_backup=$conf.$(date +%s)
        if [[ -e $conf_backup ]]
        then
            echo "Unlikely for $conf_backup to exist!"
            exit 4
        else
            echo "Backing up $conf to $conf_backup"
            mv "$conf" "$conf_backup"
        fi
    else
        echo "$conf doesn't exist"
    fi
}

# Get the GPG keyid using the given homedir.
function get_keyid {
    $GPG --homedir="$1" --card-status | grep 'Signature key' | cut -f2 -d: | tr -d ' '
}

function vercomp {
    if [[ $1 == "$2" ]]
    then
        return 0
    fi
    local IFS=.
    # shellcheck disable=SC2206
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
