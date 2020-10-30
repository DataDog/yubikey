#!/bin/bash

# Stop on error.
set -e

source env.sh
source realname-and-email.sh

# Set git name and email.
echo "Setting your git-config global user.name..."
$GIT config --global user.name "$REALNAME"
echo "Setting your git-config global user.email..."
$GIT config --global user.email "$EMAIL"

# Ask user whether all git commits and tags should be signed.
KEYID=$(get_keyid "$DEFAULT_GPG_HOMEDIR")
echo "Setting git to use this GPG key globally."
echo "Also, turning on signing of all commits and tags by default."
# Tell git to use this GPG key.
$GIT config --global user.signingkey "$KEYID"
# Also, turn on signing commits and tags by default.
$GIT config --global commit.gpgsign true
$GIT config --global tag.forceSignAnnotated true
echo

# Export GPG public key to GitHub.
echo "Exporting your GPG public key to GitHub."
$GPG --armor --export "$KEYID" | pbcopy
echo "It has been copied to your clipboard."
echo "You may now add it to GitHub: https://github.com/settings/gpg/new"
echo "Opening GitHub..."
open "https://github.com/settings/gpg/new"
echo
