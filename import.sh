#!/usr/bin/env bash

# Stop on error.
set -e

# shellcheck disable=SC1091
source env.sh
source lib/install.sh

# Figure out whether we need to write GPG keys to a tempdir.
# This is useful when you need to generate keys for someone else w/o adding to your own keystore.
if [[ -z "$TEMPDIR" ]]
then
  GPG_HOMEDIR=$DEFAULT_GPG_HOMEDIR
  echo "Using *default* GPG homedir: $GPG_HOMEDIR"
else
  GPG_HOMEDIR=$(mktemp -d)
  echo "Using *temp* GPG homedir: $GPG_HOMEDIR"
fi
echo

source lib/gpg_conf.sh
source lib/gpg_agent_conf.sh

# Configure scdaemon.
source lib/scdaemon.sh
echo "YubiKey status:"
$GPG --card-status
echo

# Import the GPG public key.
echo "Importing your GPG public key..."
$GPG --import "$1"
echo "Importing your GPG private key..."
$GPG --import "$2"
echo
echo -e "5\ny\n" | $GPG --no-tty --command-fd 0 --edit-key "$3" trust

read -rp "${YELLOW}Do you also want to use GPG on your YubiKey to sign git commits? (y/n)${RESET}" answer
case "$answer" in
    yes|YES|y|Y|Yes)
        echo "Configuring git to use GPG signing subkey..."
        source lib/git_conf.sh
        ;;
    *)
        echo "Skipping signing git commits."
esac
echo

# Authenticating over SSH with their GPG authentication subkey OTOH is a different story.
read -rp "${YELLOW}Do you also want to use GPG on your YubiKey to authenticate over SSH? (y/n)${RESET}" answer
case "$answer" in
    yes|YES|y|Y|Yes)
        echo "Configuring SSH to use GPG authentication subkey..."
        source lib/ssh_conf.sh
        ;;
    *)
        echo "Skipping using GPG authentication subkey for SSH."
esac
echo

echo "All done! Enjoy reusing your YubiKey on your new computer."
