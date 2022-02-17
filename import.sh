#!/usr/bin/env bash

# Stop on error.
set -e


function usage ()
{
    cat << EOF
Usage :  $0 [options] [--]

    Options:
    -h|--help     OPTIONAL Display this message
    -p|--public   REQUIRED Path to your public key on disk
    -i|--id       REQUIRED Key ID you are importing
EOF

}

if [[ $# -lt 1 ]]; then
    echo -e "Missing arguments\n"
    usage
    exit 1
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -p|--public)
            publickey_path="$2"
            shift 2
            ;;
        -i|--id)
            keyid="$2"
            shift 2
            ;;
        *)
            echo -e "ERROR: An unknown flag was passed: ${1}\n"
            usage
            ;;
    esac
done
if [[ -z "$publickey_path" ]] || [[ -z "$keyid" ]]; then
    usage
    exit 1
fi
if [[ ! -f "$publickey_path" ]] \
    || [[ "$(head -n 1 "$publickey_path")" != "-----BEGIN PGP PUBLIC KEY BLOCK-----" ]]; then
    echo "Public key $publickey_path is not GPG public key, exiting"
    exit 1
fi

# shellcheck disable=SC1091
source env.sh
source lib/install.sh
source lib/tree.sh
source lib/gpg_conf.sh
source lib/gpg_agent_conf.sh

# Configure scdaemon.
source lib/scdaemon.sh
echo "YubiKey status:"
# https://security.stackexchange.com/questions/108190/export-secret-key-after-yubikey-is-plugged-in
$GPG --card-status
echo

# Import the GPG public key.
echo "Importing your GPG public key..."
$GPG --import "$publickey_path"
echo
echo -e "5\ny\n" | $GPG --no-tty --command-fd 0 --edit-key "$keyid" trust

read -rp "${YELLOW}Do you also want to use GPG on your YubiKey to sign git commits? (y/n)${RESET}" answer
case "$answer" in
    yes|YES|y|Y|Yes)
        echo "Configuring git to use GPG signing subkey..."
        export SCOPE="--global"
        source lib/git_conf.sh
        source lib/notifications.sh $SCOPE
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
