#!/bin/bash

# Stop on error.
set -e

echo "Welcome! This program will automatically generate GPG keys on your Yubikey."
echo "If you ever run into problems, just press Ctrl-C, and rerun this program again."
echo ""

# install required tools
echo "Installing required tools, please try a full upgrade with 'brew upgrade --force'"
echo "of the problematic packages if something goes wrong, then try again."
brew install --force expect gnupg pinentry-mac ykman
echo ""

# 1-2. Get full name and email address.
source realname-and-email.sh

# Support only these YubiKey types.
YUBIKEY_VERSION=$($YKMAN info | grep 'Device type:' | cut -f2 -d: | awk '{print $2}')
if [[ $YUBIKEY_VERSION != "5C" ]]
then
  echo "Sorry, but we do not support your YubiKey type."
  exit 1
fi

# 3. Comment.
comment="GPG on Yubikey for Datadog"
echo "What is a comment you would like to use to distinguish this key?"
read -p "Comment (press Enter to accept '$comment'): " input
comment=${input:-$comment}
echo ""

# Generate some information for the user.

echo "There are two important random numbers for the Yubikey you MUST keep safely."
echo "See https://developers.yubico.com/yubikey-piv-manager/PIN_and_Management_Key.html"
echo ""

# 1. PIN
PIN=$(python -S -c "import random; print(random.SystemRandom().randrange(10**7,10**8))")
echo "The first number is the PIN."
echo "The PIN is used during normal operation to authorize an action such as creating a digital signature for any of the loaded certificates."
echo ""
echo "***********************************************************"
echo "Default PIN code: 123456"
echo "New PIN code: $PIN"
echo "***********************************************************"
echo ""
echo "Please save this new PIN immediately in your password manager."
read -p "Have you done this? "
echo "Great. Now, remember, the first time you are asked for the PIN, please enter: 123456"
echo "After that, you will be asked to set a new PIN. Enter: $PIN"
echo ""

# 2. PUK
PUK=$(python -S -c "import random; print(random.SystemRandom().randrange(10**7,10**8))")
echo "The second number is the Admin PIN, aka PUK."
echo "The Admin PIN can be used to reset the PIN if it is ever lost or becomes blocked after the maximum number of incorrect attempts."
echo ""
echo "***********************************************************"
echo "Default Admin PIN code: 12345678"
echo "New Admin PIN code: $PUK"
echo "***********************************************************"
echo ""
echo "Please save this new Admin PIN immediately in your password manager."
read -p "Have you done this? "
echo "Great. Now, remember, the first time you are asked for the Admin PIN, please enter: 12345678"
echo "After that, you will be asked to set a new Admin PIN. Enter: $PUK"
echo ""

# setup pinentry-mac
mkdir -p ~/.gnupg
cat << EOF > ~/.gnupg/gpg-agent.conf
# https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
pinentry-program /usr/local/bin/pinentry-mac
# For usability while balancing security, cache PIN for at most a day.
default-cache-ttl 86400
max-cache-ttl 86400
EOF

# restart GPG daemons to pick up pinentry-mac
$GPGCONF --kill all

# show card information to user so they can be sure they are wiping right key
echo "Yubikey status:"
$GPG --card-status
echo ""

# reset yubikey openPGP applet
echo "RESETTING THE OPENGPG APPLET ON YOUR YUBIKEY!!!"
$YKMAN openpgp reset
echo ""

# force locale to prevent expect script from breaking on non-english systems.
old_locale="${LC_ALL}"
export LC_ALL=en_US.UTF-8

# drive yubikey setup
# but right before, kill all GPG daemons to make sure things work reliably
$GPGCONF --kill all
./expect.sh "$realname" "$email" "$comment"
echo ""

# restore initial locale value
export LC_ALL="${old_locale}"

# Export GPG public key.
keyid=$($GPG --card-status | grep 'sec>' | awk '{print $2}' | cut -f2 -d/)
echo "Exporting your GPG public key to $keyid.gpg.pub."
$GPG --armor --export $keyid > $keyid.gpg.pub
$GPG --armor --export $keyid | pbcopy
echo "Please save a copy in your password manager."
read -p "Have you done this? "
echo "There is NO off-card backup of your private / secret keys."
echo "So if your Yubikey is damaged, lost, or stolen, then you must rotate your GPG keys out-of-band."
echo ""

# Ask user to save revocation certificate before deleting it.
fingerprint=$($GPG --card-status | grep 'Signature key' | cut -f2 -d: | tr -d ' ')
cat ~/.gnupg/openpgp-revocs.d/$fingerprint.rev | pbcopy
echo "Your revocation certificate is at ~/.gnupg/openpgp-revocs.d/$fingerprint.rev"
echo "It has been copied to your clipboard."
echo "Please save a copy in your password manager before we delete it off disk."
read -p "Have you done this? "
rm ~/.gnupg/openpgp-revocs.d/$fingerprint.rev
echo "Great. Deleted this revocation certificate from disk."
# NOTE: EMPTY clipboard after this.
pbcopy < /dev/null
echo ""

# Final reminders.
echo "Finally, remember that your keys will not expire until 10 years from now."
echo "You will need to enter your PIN (once a day), and touch your Yubikey everytime in order to sign any message with this GPG key."
echo ""
echo "************************************************************"
echo "Your PIN is: $PIN"
echo "Your Admin PIN, aka PUK is: $PUK"
echo "************************************************************"
echo ""
echo "Enjoy using your Yubikey at Datadog!"
