#!/bin/bash

# Stop on error.
set -e

# https://stackoverflow.com/a/44348249
function install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade "$1"
  else
    HOMEBREW_NO_AUTO_UPDATE=1 brew install "$1"
  fi
}

echo "Welcome! This program will automatically generate GPG keys on your YubiKey."
echo "If you ever run into problems, just press Ctrl-C, and rerun this program again."
echo

# install required tools
echo "Installing or upgrading required tools..."
brew update
install_or_upgrade expect
install_or_upgrade git
install_or_upgrade gnupg
install_or_upgrade pinentry-mac
install_or_upgrade ykman
echo

# Get full name and email address.
source realname-and-email.sh

# Get comment to distinguish between keys.
COMMENT="GPG on YubiKey for Datadog"
echo "What is a comment you would like to use to distinguish this key?"
read -p "Comment (press Enter to accept '$COMMENT'): " input
COMMENT=${input:-$COMMENT}
echo

# Generate some information for the user.
PIN=$(python -S -c "import random; print(random.SystemRandom().randrange(10**7,10**8))")
PUK=$(python -S -c "import random; print(random.SystemRandom().randrange(10**7,10**8))")
SERIAL=$($YKMAN info | grep 'Serial number:' | cut -f2 -d: | tr -d ' ')

# Set some parameters based on whether FIPS key or not.
DEVICE_TYPE=$($YKMAN info | grep 'Device type:' | cut -f2 -d: | awk '{$1=$1;print}')
echo "YubiKey device type: $DEVICE_TYPE"
if [[ "$DEVICE_TYPE" == *"YubiKey FIPS"* ]]; then
  echo "Which appears to be a FIPS key"
  YUBIKEY_FIPS=true
  # YubiKey FIPS supports at most RSA-3072 on-card key generation, which should
  # be good until at least 2030 according to NIST:
  # https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp3204.pdf
  # https://www.keylength.com/en/compare/
  KEY_LENGTH=3072
  # It also does not appear to allow the very handy cached touch policy:
  # https://github.com/Yubico/yubikey-manager/issues/277
  TOUCH_POLICY=on
else
  echo "Which does not appear to be a FIPS key"
  YUBIKEY_FIPS=false
  KEY_LENGTH=4096
  TOUCH_POLICY=cached
fi
echo

# Show card information to user so they can be sure they are wiping right key
# NOTE: explicitly check against default GPG homedir to make sure we are not wiping something critical...
echo "YubiKey status:"
# NOTE: For some as yet unknown reason, we need to reload scdaemon when a brew update is done with SSH auth using GPG...
$GPGCONF --kill all
$GPG --card-status
echo

# Reset YubiKey openPGP applet
echo "RESETTING THE OPENGPG APPLET ON YOUR YUBIKEY!!!"
$YKMAN openpgp reset
echo

# Backup GPG agent configuration in default GPG homedir, if it exists.
backup_default_gpg_agent_conf

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

# Whatever our GPG homedir, we replace pinentry-curses with pinentry-tty, so that we can automate entering PIN and PUK.
GPG_AGENT_CONF=$GPG_HOMEDIR/gpg-agent.conf
cat << EOF > $GPG_AGENT_CONF
pinentry-program /usr/local/bin/pinentry-tty
EOF

# force locale to prevent expect script from breaking on non-english systems.
old_locale="${LC_ALL}"
export LC_ALL=en_US.UTF-8

# drive yubikey setup
# but right before, kill all GPG daemons to make sure things work reliably
$GPGCONF --homedir=$GPG_HOMEDIR --kill all
./expect.sh "$TOUCH_POLICY" "$PUK" "$GPG_HOMEDIR" "$PIN" "$KEY_LENGTH" "$REALNAME" "$EMAIL" "$COMMENT"
echo

# restore initial locale value
export LC_ALL="${old_locale}"

# Overwrite default GPG agent configuration with our own.
# We want to replace the pinentry-tty with the pinentry-mac.
cat << EOF > $DEFAULT_GPG_AGENT_CONF
# https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
pinentry-program /usr/local/bin/pinentry-mac
# For usability while balancing security, cache PIN for at most a day.
default-cache-ttl 86400
max-cache-ttl 86400
EOF

# restart GPG daemons to pick up pinentry-mac
$GPGCONF --kill all

echo "There are two important random numbers for the YubiKey you MUST keep safely."
echo "See https://developers.yubico.com/yubikey-piv-manager/PIN_and_Management_Key.html"
echo

echo "The first number is the PIN."
echo "The PIN is used during normal operation to authorize an action such as creating a digital signature for any of the loaded certificates."
echo
echo "***********************************************************"
echo "New PIN code: $PIN"
echo "***********************************************************"
echo
echo "Please save this new PIN (copied to clipboard) immediately in your password manager."
echo $PIN | pbcopy
read -p "Have you done this? "
echo "Please also associate it with this YubiKey serial number (copied to clipboard): $SERIAL"
echo $SERIAL | pbcopy
read -p "Have you done this? "
echo

echo "The second number is the Admin PIN, aka PUK."
echo "The Admin PIN can be used to reset the PIN if it is ever lost or becomes blocked after the maximum number of incorrect attempts."
echo
echo "***********************************************************"
echo "New Admin PIN code: $PUK"
echo "***********************************************************"
echo
echo "Please save this new Admin PIN (copied to clipboard) immediately in your password manager."
echo $PUK | pbcopy
read -p "Have you done this? "
echo "Please also associate it with this YubiKey serial number (copied to clipboard): $SERIAL"
echo $SERIAL | pbcopy
read -p "Have you done this? "
echo

# Export GPG public key.
KEYID=$(get_keyid $GPG_HOMEDIR)
BIN_GPG_PUBKEY=$KEYID.gpg.pub.bin
ASC_GPG_PUBKEY=$KEYID.gpg.pub.asc
echo "Exporting your binary GPG public key to $BIN_GPG_PUBKEY"
$GPG --homedir=$GPG_HOMEDIR --export $KEYID > $BIN_GPG_PUBKEY
echo "Exporting your ASCII-armored GPG public key to $ASC_GPG_PUBKEY"
$GPG --homedir=$GPG_HOMEDIR --armor --export $KEYID > $ASC_GPG_PUBKEY
cat $ASC_GPG_PUBKEY | pbcopy
echo "Please save a copy in your password manager."
read -p "Have you done this? "
echo "There is NO off-card backup of your private / secret keys."
echo "So, if your YubiKey is damaged, lost, or stolen, then you must rotate your GPG keys out-of-band."
echo "You would also no longer be able to decrypt messages encrypted for this GPG key."
echo

# Ask user to save revocation certificate before deleting it.
REVOCATION_CERT=$GPG_HOMEDIR/openpgp-revocs.d/$KEYID.rev
cat $REVOCATION_CERT | pbcopy
echo "Your revocation certificate is at $REVOCATION_CERT"
echo "It has been copied to your clipboard."
echo "Please save a copy in your password manager before we delete it off disk."
read -p "Have you done this? "
rm $REVOCATION_CERT
echo "Great. Deleted this revocation certificate from disk."
# NOTE: EMPTY clipboard after this.
pbcopy < /dev/null
echo

# Final reminders.
echo "Finally, remember that your keys will not expire until 10 years from now."
echo "You will need to ${RED}${BOLD}enter your PIN (once a day)${RESET}, and ${RED}${BOLD}touch your YubiKey every time${RESET} in order to sign any message with this GPG key."
if [[ "$YUBIKEY_FIPS" == "true" ]]; then
  echo "You may wish to pass the --no-gpg-sign flag to git rebase."
else
  echo "Touch is cached for 15s on sign operations."
fi
echo "Enjoy using your YubiKey at Datadog!"
