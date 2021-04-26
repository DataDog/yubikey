#!/usr/bin/env bash

function which_flavour {
    if [[ -f /etc/os-release ]]; then
        detected="$(grep '^ID=' /etc/os-release | cut -d= -f2)"
    fi
    echo "$detected"
}

case "$OSTYPE" in
    darwin*)
        OS='macos'
        ;;
    linux*)
        OS=$(which_flavour)
        ;;
    *)
        OS="not detected"
        ;;
esac

echo "OS detected is $OS"

case $(echo "$OS" | tr "[:upper:]" "[:lower:]") in
    macos)
        PKG_MANAGER="brew"
        PKG_MANAGER_ENV=""
        PKG_MANAGER_INSTALL="install"
        PKG_MANAGER_UPDATE="update"
        PKG_MANAGER_UPGRADE="upgrade"
        PKG_CHECK="brew"
        PKG_CHECK_ARGS="list"
        HOMEBREW_PREFIX=$(brew --prefix)
        HOMEBREW_BIN=$HOMEBREW_PREFIX/bin
        GIT=$HOMEBREW_BIN/git
        GPG=$HOMEBREW_BIN/gpg
        GPG_AGENT=$HOMEBREW_BIN/gpg-agent
        GPGCONF=$HOMEBREW_BIN/gpgconf
        YKMAN=$HOMEBREW_BIN/ykman
        CLIP="pbcopy"
        CLIP_ARGS=""
        PINENTRY="/usr/local/bin/pinentry-tty"
        OPEN="open"
        DEPS=(
            "expect"
            "git"
            "gpg"
            "pinentry-mac"
            "ykman"
        )
        NOTIFICATION_CMD="osascript -e 'display notification \"Git wants to sign a commit!\" with title \"Click on your Yubikey\"'\ngpg \"\$@\""
        NOTIFICATION_SCRIPT_PATH="/usr/local/bin/yubinotif"
        SCDAEMON_CONF="disable-ccid\nreader-port \"Yubico YubiKey FIDO+CCID\""
        export HOMEBREW_NO_AUTO_UPDATE=1
        ;;
    ubuntu|debian)
        PKG_MANAGER="apt"
        PKG_MANAGER_ENV="sudo"
        PKG_MANAGER_INSTALL="install"
        PKG_MANAGER_UPDATE="update"
        PKG_MANAGER_UPGRADE="install"
        PKG_CHECK="apt"
        PKG_CHECK_ARGS="show"
        BIN_PATH="/usr/bin"
        GIT="${BIN_PATH}/git"
        GPG="${BIN_PATH}/gpg"
        GPG_AGENT="${BIN_PATH}/gpg-agent"
        GPGCONF="${BIN_PATH}/gpgconf"
        YKMAN="${BIN_PATH}/ykman"
        CLIP="${BIN_PATH}/xclip"
        CLIP_ARGS="-selection clipboard -i"
        PINENTRY="/usr/bin/pinentry-tty"
        OPEN="xdg-open"
        DEPS=(
            "expect"
            "git"
            "gpg"
            "pinentry-tty"
            "python"
            "scdaemon"
            "yubikey-manager"
            "xclip"
        )
        NOTIFICATION_CMD="notify-send 'Git wants to sign a commit!' 'Click on your Yubikey'\ngpg \"\$@\""
        NOTIFICATION_SCRIPT_PATH="/usr/local/bin/yubinotif"
        SCDAEMON_CONF=""
        sudo apt-add-repository ppa:yubico/stable
        ;;
    arch)
        PKG_MANAGER="pacman"
        PKG_MANAGER_ENV="sudo"
        PKG_MANAGER_INSTALL="-S"
        PKG_MANAGER_UPDATE="-Sy"
        PKG_MANAGER_UPGRADE="-S"
        PKG_CHECK="pacman"
        PKG_CHECK_ARGS="-Qi"
        BIN_PATH="/usr/bin"
        GIT="${BIN_PATH}/git"
        GPG="${BIN_PATH}/gpg"
        GPG_AGENT="${BIN_PATH}/gpg-agent"
        GPGCONF="${BIN_PATH}/gpgconf"
        YKMAN="${BIN_PATH}/ykman"
        CLIP="${BIN_PATH}/xclip"
        CLIP_ARGS="-selection clipboard -i"
        PINENTRY="/usr/bin/pinentry"
        OPEN="xdg-open"
        # shellcheck disable=SC2034
        DEPS=(
            "expect"
            "gnupg"
            "pinentry"
            "git"
            "yubikey-manager"
            "xclip"
            "pcsclite"
        )
        # shellcheck disable=SC2034
        NOTIFICATION_CMD="notify-send 'Git wants to sign a commit!' 'Click on your Yubikey'\ngpg \"\$@\""
        NOTIFICATION_SCRIPT_PATH="/usr/local/bin/yubinotif"
        # shellcheck disable=SC2034
        SCDAEMON_CONF=""
        ;;
    *)
        echo "Sorry, your OS is not supported"
        exit 1
esac

# Use Homebrew binaries.
export PKG_MANAGER
export PKG_MANAGER_ENV
export PKG_MANAGER_INSTALL
export PKG_MANAGER_UPDATE
export PKG_MANAGER_UPGRADE
export PKG_CHECK
export PKG_CHECK_ARGS
export GIT
export GPG
export GPG_AGENT
export GPGCONF
export YKMAN
export CLIP
export CLIP_ARGS
export OPEN
export PINENTRY
export NOTIFICATION_SCRIPT_PATH

# Colors galore.
BOLD=$(tput bold)
export BOLD
RED=$(tput setaf 1)
export RED
GREEN=$(tput setaf 2)
export GREEN
YELLOW=$(tput setaf 3)
export YELLOW
BLUE=$(tput setaf 4)
export BLUE
MAGENTA=$(tput setaf 5)
export MAGENTA
RESET=$(tput sgr0) # Reset text
export RESET

# SSH.
export SSH_ENV="$HOME/.ssh/environment"

# Folders and files.
export DEFAULT_GPG_HOMEDIR=$HOME/.gnupg
export DEFAULT_GPG_AGENT_CONF=$DEFAULT_GPG_HOMEDIR/gpg-agent.conf
export DEFAULT_GPG_CONF=$DEFAULT_GPG_HOMEDIR/gpg.conf
export DEFAULT_GPG_SCDAEMON_CONF=${DEFAULT_GPG_HOMEDIR}/scdaemon.conf

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

function join { local IFS="$1"; shift; echo "$*"; }
