#!/bin/bash

# Stop on error.
set -e

echo "Welcome! This program will automatically generate GPG keys on your Yubikey."
echo "If you ever run into problems, just press Ctrl-C, and rerun this program again."
echo ""

# install required tools
echo "Installing required tools, please try a full upgrade with 'brew upgrade --force'"
echo "of the problematic packages if something goes wrong, then try again."
brew install --force expect git gnupg pinentry-mac ykman
echo ""

# Check for ROCA.
DEVICE_TYPE=$(ykman info | grep 'Device type:' | cut -f2 -d:)
FIRMWARE_VERSION=$(ykman info | grep 'Firmware version:' | cut -f2 -d:)
echo "Checking whether Yubikey suffers from ROCA vulnerability..."
./roca-check.py "$DEVICE_TYPE" "$FIRMWARE_VERSION"
echo ""

# Get some information from the user.

# Use the Homebrew git.
GIT=/usr/local/bin/git

# 1. Real name.
realname=$($GIT config --global --default '' --get user.name)
echo "What is the real name you use on GitHub?"
read -p "Real name (press Enter to accept '$realname'): " input

if [[ -z $realname ]]
then
  if [[ -z $input ]]
  then
    echo "No name found!"
    exit 1
  else
    realname=$input
    echo "Using given input: $realname"
    echo "Setting your git-config global user.name too..."
    $GIT config --global user.name $realname
  fi
else
  if [[ -z $input ]]
  then
    echo "Using given user.name: $realname"
  else
    realname=$input
    echo "Using given input: $realname"
  fi
fi

echo ""

# 2. Email address.
email=$($GIT config --global --default '' --get user.email)
echo "What is an email address you have registered with GitHub?"
read -p "Email (press Enter to accept '$email'): " input

if [[ -z $email ]]
then
  if [[ -z $input ]]
  then
    echo "No email found!"
    exit 1
  else
    email=$input
    echo "Using given input: $email"
    echo "Setting your git-config global user.email too..."
    $GIT config --global user.email $email
  fi
else
  if [[ -z $input ]]
  then
    echo "Using given user.email: $email"
  else
    email=$input
    echo "Using given input: $email"
  fi
fi

echo ""

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
enable-ssh-support
# For usability while balancing security, cache PIN for at most a day.
default-cache-ttl 86400
max-cache-ttl 86400
EOF

# enable SSH
echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> ~/.bash_profile
echo 'export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"' >> ~/.zshrc

# restart GPG daemons to pick up pinentry-mac
gpgconf --kill all

# show card information to user so they can be sure they are wiping right key
echo "Yubikey status:"
gpg --card-status
echo ""

# reset yubikey openPGP applet
echo "RESETTING THE OPENGPG APPLET ON YOUR YUBIKEY!!!"
ykman openpgp reset
echo ""

# drive yubikey setup
# but right before, kill all GPG daemons to make sure things work reliably
gpgconf --kill all
./expect.sh "$realname" "$email" "$comment"
echo ""

# Ask user whether all git commits and tags should be signed.
read -p "Do you want to set up git so that all commits and tags will be signed with this key (STRONGLY recommended)? [y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]
then
  echo "Setting git to use this GPG key globally."
  echo "Also, turning on signing of all commits and tags by default."
  keyid=$(gpg --card-status | grep 'sec>' | awk '{print $2}' | cut -f2 -d/)
  # Tell git to use this GPG key.
  $GIT config --global user.signingkey $keyid
  # Also, turn on signing commits and tags by default.
  $GIT config --global commit.gpgsign true
  $GIT config --global tag.forceSignAnnotated true
  echo ""
fi

# Export GPG public key.
echo "Exporting your GPG public key to $keyid.gpg.pub."
gpg --armor --export $keyid > $keyid.gpg.pub
gpg --armor --export $keyid | pbcopy
echo "It has also been copied to your clipboard."
echo "You may now add it to GitHub: https://github.com/settings/gpg/new"
echo "Opening Chrome ..."
open -a "/Applications/Google Chrome.app"/ "https://github.com/settings/gpg/new"
echo "Please save a copy in your password manager."
read -p "Have you done this? "
echo "There is NO off-card backup of your private / secret keys."
echo "So if your Yubikey is damaged, lost, or stolen, then you must rotate your GPG keys out-of-band."
echo ""

# Export SSH key derived from GPG authentication subkey.
echo "Exporting your SSH public key to $keyid.ssh.pub."
ssh-add -L | grep -iF 'cardno' > $keyid.ssh.pub
ssh-add -L | grep -iF 'cardno' | pbcopy
echo "It has also been copied to your clipboard."
echo "You may now add it to GitHub: https://github.com/settings/ssh/new"
echo "Opening Chrome ..."
open -a "/Applications/Google Chrome.app"/ "https://github.com/settings/ssh/new"
echo "Please save a copy in your password manager."
read -p "Have you done this? "
echo "Great."
echo ""

# Ask user to save revocation certificate before deleting it.
fingerprint=$(gpg --card-status | grep 'Signature key' | cut -f2 -d: | tr -d ' ')
cat ~/.gnupg/openpgp-revocs.d/$fingerprint.rev | pbcopy
echo "Your revocation certificate is at ~/.gnupg/openpgp-revocs.d/$fingerprint.rev"
echo "It has been copied to your clipboard."
echo "Please save a copy in your password manager before we delete it off disk."
read -p "Have you done this? "
rm ~/.gnupg/openpgp-revocs.d/$fingerprint.rev
echo "Great. Deleted this revocation certificate from disk."
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
