#!/usr/bin/env bash

# Set git name and email.
echo "Setting your git-config user.name..."
$GIT config $SCOPE user.name "$REALNAME"
echo "Setting your git-config user.email..."
$GIT config $SCOPE user.email "$EMAIL"

# Ask user whether all git commits and tags should be signed.
KEYID=$(get_keyid "$DEFAULT_GPG_HOMEDIR")
echo "Setting git to use this GPG key."
echo "Also, turning on signing of all commits and tags by default."
# Tell git to use this GPG key.
$GIT config $SCOPE user.signingkey "$KEYID"
# Also, turn on signing commits and tags by default.
$GIT config $SCOPE commit.gpgsign true
$GIT config $SCOPE tag.forceSignAnnotated true
echo
