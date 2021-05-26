#!/usr/bin/env bash

# Stop on error.
set -e

# shellcheck disable=SC1091
source env.sh

# Install required dependencies.
echo "${YELLOW}You need to have $(join ',' "${DEPS[@]}") installed on your device."
read -rp "Do you want us to install them for you ? (y/n)${RESET}" answer
case "$answer" in
    yes|YES|y|Y|Yes)
        # install required tools
        echo "Installing or upgrading required tools..."
        eval "$PKG_MANAGER_ENV" "$PKG_MANAGER" "$PKG_MANAGER_UPDATE"
        for pkg in "${DEPS[@]}"; do
            install_or_upgrade "$pkg"
        done
        ;;
    *)
        echo "Skipping install or upgrade of required tools"
        for pkg in "${DEPS[@]}"; do
            check_presence "$pkg"
        done
        ;;
esac
echo

# Create default directories.
mkdir -p "$DEFAULT_GPG_HOMEDIR"
chmod 700 "$DEFAULT_GPG_HOMEDIR"

# Backup GPG agent configuration in default GPG homedir, if it exists.
backup_conf "$DEFAULT_GPG_AGENT_CONF"

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

# Whatever our GPG homedir, we replace pinentry-curses with pinentry-tty, so that we can automate entering User and Admin PINs.
GPG_AGENT_CONF=$GPG_HOMEDIR/gpg-agent.conf
cat << EOF > "$GPG_AGENT_CONF"
pinentry-program $PINENTRY
EOF

# Backup GPG configuration in default GPG homedir, if it exists.
backup_conf "$DEFAULT_GPG_CONF"

# https://csrc.nist.rip/groups/STM/cmvp/documents/140-1/140crt/140crt1130.pdf
# https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-131Ar2.pdf
# Specify crypto algorithms that will be used
# Note: the goal is to favor algorithms:
# - without known vulnerabilties
# - with a long key and block sizes
GPG_CONF=$GPG_HOMEDIR/gpg.conf
cat << EOF > "$GPG_CONF"
disable-pubkey-algo ELG
disable-pubkey-algo DSA
disable-cipher-algo 3DES
disable-cipher-algo BLOWFISH
disable-cipher-algo CAMELLIA256
disable-cipher-algo CAMELLIA128
disable-cipher-algo CAMELLIA192
disable-cipher-algo CAST5
disable-cipher-algo IDEA
disable-cipher-algo TWOFISH
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256 SHA224
personal-compress-preferences BZIP2 ZLIB ZIP Uncompressed
default-preference-list AES256 AES192 AES SHA512 SHA384 SHA256 SHA224 BZIP2 ZLIB ZIP Uncompressed
EOF

# Overwrite default GPG agent configuration with our own.
# We want to replace the pinentry-tty with the pinentry-mac.
cat << EOF > "$DEFAULT_GPG_AGENT_CONF"
# https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
pinentry-program /usr/local/bin/pinentry-mac
# For usability while balancing security, cache User PIN for at most a day.
default-cache-ttl 86400
max-cache-ttl 86400
EOF

# Configure scdaemon.
./scdaemon.sh
echo "YubiKey status:"
# shellcheck disable=SC2153
$GPG --card-status
echo

# We don't need to ask the user about whether they want to sign their git commits with GPG,
# because presumably they wouldn't bother running this script otherwise.
$GPG --import "$1"
./git.sh
echo

# Authenticating over SSH with their GPG authentication subkey OTOH is a different story.
read -rp "${YELLOW}Do you also want to use GPG on your YubiKey to authenticate over SSH? (y/n)${RESET}" answer
case "$answer" in
    yes|YES|y|Y|Yes)
        echo "Configuring SSH to use GPG authentication subkey..."
        ./ssh.sh
        ;;
    *)
        echo "Skipping using GPG authentication subkey for SSH."
esac
echo

echo "All done! Enjoy reusing your YubiKey on your new computer."
