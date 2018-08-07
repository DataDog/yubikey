#!/bin/bash

# Stop on error.
set -e

echo "Welcome! This program will automatically generate GPG keys on your Yubikey."
echo "If you ever run into problems, just press Ctrl-C, and rerun this program again."
echo ""

# Get some information from the user.

# 1. Real name.
echo "What is the real name you use on GitHub?"
read -p "Real name: " realname
echo ""

# 2. Email address.
echo "What is an email address you have registered with GitHub?"
read -p "Email: " email
echo ""

# Generate some information for the user.

echo "There are two important random numbers for the Yubikey you MUST keep safely."
echo "See https://developers.yubico.com/yubikey-piv-manager/PIN_and_Management_Key.html"
echo ""

# 1. PIN
PIN=$(python -S -c "import random; print random.SystemRandom().randrange(10**7,10**8)")
echo "The first number is the PIN."
echo "The PIN is used during normal operation to authorize an action such as creating a digital signature for any of the loaded certificates."
echo "The default PIN code is 123456."
echo "The new, random PIN code we have generated for you is: $PIN"
echo "Please save this new PIN immediately in your password manager."
read -p "Have you done this? "
echo "Great. Now, remember, the first time you are asked for the PIN, please enter: 123456"
echo "After that, you will be asked to set a new PIN. Enter: $PIN"
echo ""

# 2. PUK
PUK=$(python -S -c "import random; print random.SystemRandom().randrange(10**7,10**8)")
echo "The second number is the Admin PIN, aka PUK."
echo "The PUK can be used to reset the PIN if it is ever lost or becomes blocked after the maximum number of incorrect attempts."
echo "The default PUK code is 12345678."
echo "The new, random PUK code we have generated for you is: $PUK"
echo "Please save this new PUK immediately in your password manager."
read -p "Have you done this? "
echo "Great. Now, remember, the first time you are asked for the Admin PIN, please enter: 12345678"
echo "After that, you will be asked to set a new Admin PIN. Enter: $PUK"
echo ""

# install required tools
echo "Installing required tools..."
brew install --force expect gnupg pinentry-mac ykman
echo ""

# setup pinentry-mac
cat << EOF > ~/.gnupg/gpg-agent.conf
# https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#update-configuration
pinentry-program /usr/local/bin/pinentry-mac
default-cache-ttl 600
max-cache-ttl 7200
EOF

# restart GPG daemons to pick up pinentry-mac
gpgconf --kill all

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
./mac-expect.sh "$realname" "$email"
echo ""

# Tell git to use this GPG key.
echo "Setting git to use this GPG key globally."
keyid=$(gpg --list-keys --with-colons $email | awk -F: '/^pub:/ { print $5 }')
git config --global user.signingkey $keyid
echo ""

echo "Yubikey status:"
gpg --card-status
echo ""

echo "GPG public key export:"
gpg --armor --export $email
echo ""

gpg --armor --export $email | pbcopy
echo "A copy of this public key has also been copied to your clipboard."
echo "You may now add it to GitHub: https://help.github.com/articles/adding-a-new-gpg-key-to-your-github-account/"
echo ""
echo "There is NO off-card backup of your private / secret keys."
echo "So if your Yubikey is damaged, lost, or stolen, then you must rotate your GPG keys out-of-band."
echo ""
echo "Otherwise, remember that your keys will not expire until 4 years from now."
echo "You will need to touch your Yubikey in order to sign any message with this GPG key."
echo "Your new PIN is: $PIN"
echo "Your new Admin PIN, aka PUK is: $PUK"
echo "Good luck."
echo ""

