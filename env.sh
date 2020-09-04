#!/bin/bash

# Shared environment variables.

export GIT="$(which git)"
export GPG="$(which gpg)"
export GPG_AGENT="$(which gpg-agent)"
export GPGCONF="$(which gpgconf)"
export YKMAN="$(which ykman)"

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

# Functions.

# Backup GPG agent configuration in default GPG homedir, if it exists.
function backup_default_gpg_agent_conf {
    if [[ -e $DEFAULT_GPG_AGENT_CONF ]]
    then
        DEFAULT_GPG_AGENT_CONF_BACKUP=$DEFAULT_GPG_AGENT_CONF.$(date +%s)
        if [[ -e $DEFAULT_GPG_AGENT_CONF_BACKUP ]]
        then
            echo "Unlikely for $DEFAULT_GPG_AGENT_CONF_BACKUP to exist!"
            exit 4
        else
            echo "Backing up $DEFAULT_GPG_AGENT_CONF to $DEFAULT_GPG_AGENT_CONF_BACKUP"
            mv "$DEFAULT_GPG_AGENT_CONF" "$DEFAULT_GPG_AGENT_CONF_BACKUP"
        fi
    else
        echo "$DEFAULT_GPG_AGENT_CONF doesn't exist"
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
