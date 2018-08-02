#!/bin/bash

# Stop on error.
set -e

# install required tools
echo "Installing required tools..."
dnf install expect gnupg2 yubikey-manager
echo ""

echo "Yubikey status:"
gpg2 --card-status
echo ""

# reset yubikey openPGP applet
echo "RESETTING THE OPENGPG APPLET ON YOUR YUBIKEY!!!"
ykman openpgp reset
echo ""

# Warn user about generating Yubikey PUK and PIN.
# https://stackoverflow.com/a/1885534
read -p "Have you used your password manager to generate and save 8 random digits for your Yubikey Admin PIN aka PUK? [yY] "

if [[ $REPLY =~ ^[Yy]$ ]]
then
  # do dangerous stuff
  echo "Please note that the Yubikey Admin PIN or PUK is 12345678 by default."
  echo ""

  read -p "Have you used your password manager to generate and save 8 random digits for your Yubikey (change / user) PIN? [yY] "

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    echo "Please note that the Yubikey (change / user) PIN is 123456 by default."
    echo ""

    # drive yubikey setup
    # in my experience, you have to kill all GPG daemons to get things working
    gpgconf --kill all
    ./mac-expect.sh
    echo ""

    echo "Yubikey status:"
    gpg2 --card-status

    echo "GPG public key export:"
    gpg2 --armor --export
  else
    echo "Please use your password manager to generate and save 8 random digits for your Yubikey (change / user) PIN. "
    exit -2
  fi
else
  echo "Please use your password manager to generate and save 8 random digits for your Yubikey Admin PIN aka PUK."
  exit -1
fi

