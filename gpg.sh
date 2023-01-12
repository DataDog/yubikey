#!/usr/bin/env bash

# Stop on error.
set -e

# shellcheck disable=SC1091
source env.sh
source lib/install.sh

# Get full name and email address.
# shellcheck disable=SC1091
source realname-and-email.sh

# Get comment to distinguish between keys.
COMMENT="GPG on YubiKey for Datadog"
echo "${YELLOW}What is a comment you would like to use to distinguish this key?"
read -rp "Comment (press Enter to accept '$COMMENT'): ${RESET}" input
COMMENT=${input:-$COMMENT}
echo

# Generate some information for the user.
USER_PIN=$(python3 -S -c "import random; print(random.SystemRandom().randrange(10**7,10**8))")
ADMIN_PIN=$(python3 -S -c "import random; print(random.SystemRandom().randrange(10**7,10**8))")
SERIAL=$($YKMAN info | grep 'Serial number:' | cut -f2 -d: | tr -d ' ')

# Set some parameters based on whether FIPS key or not.
DEVICE_TYPE=$($YKMAN info | grep 'Device type:' | cut -f2 -d: | awk '{$1=$1;print}')
echo "YubiKey device type: $DEVICE_TYPE"
if [[ "$DEVICE_TYPE" == *"YubiKey"*"FIPS"* ]]; then
  echo "Which appears to be a FIPS key"
  YUBIKEY_FIPS=true
  # YubiKey FIPS supports at most RSA-3072 on-card key generation, which should
  # be good until at least 2030 according to NIST:
  # https://csrc.nist.gov/CSRC/media/projects/cryptographic-module-validation-program/documents/security-policies/140sp3204.pdf
  # https://www.keylength.com/en/compare/
  KEY_LENGTH=3072
else
  echo "Which does not appear to be a FIPS key"
  YUBIKEY_FIPS=false
  KEY_LENGTH=4096
fi
# Activate cache policy if possible (when firmware version equal or superior to 5.2.3
# https://github.com/Yubico/yubikey-manager/issues/277#issuecomment-529805540
FIRMWARE_VERSION=$($YKMAN info | grep 'Firmware version:' | cut -f2 -d: | awk '{$1=$1;print}')
set +e
vercomp "$FIRMWARE_VERSION" 5.2.3
if [[ "$?" -eq 2 ]] || [[ "$YUBIKEY_FIPS" == "true" ]]; then
  echo "Setting touch policy to on"
  TOUCH_POLICY=on
else
  echo "Setting touch policy to cached"
  TOUCH_POLICY=cached
fi
set -e
echo

source lib/tree.sh

# Update scdaemon.conf
source lib/scdaemon.sh

# Show card information to user so they can be sure they are wiping right key
# NOTE: explicitly check against default GPG homedir to make sure we are not wiping something critical...
echo "YubiKey status:"
# shellcheck disable=SC2153
$GPG --card-status
echo

# Reset YubiKey openPGP applet
echo "${YELLOW}RESETTING THE OPENGPG APPLET ON YOUR YUBIKEY!!!"
$YKMAN openpgp reset
echo "${RESET}"

# Whatever our GPG homedir, we replace pinentry-curses with pinentry-tty, so that we can automate entering User and Admin PINs.
GPG_AGENT_CONF=$GPG_HOMEDIR/gpg-agent.conf
cat << EOF > "$GPG_AGENT_CONF"
pinentry-program $PINENTRY_SETUP
EOF

source lib/gpg_conf.sh
# force locale to prevent expect script from breaking on non-english systems.
old_locale="${LC_ALL}"
export LC_ALL=en_US.UTF-8

# drive yubikey setup
# but right before, kill all GPG daemons to make sure things work reliably
$GPGCONF --homedir="$GPG_HOMEDIR" --kill all
# The script failed to run when GPG_TTY != '' so we ensure it's empty before the expect script.
# https://gnupg.org/documentation/manuals/gnupg/Common-Problems.html
GPG_TTY="" ./expects/"expect-${OS}.sh" "$TOUCH_POLICY" "$ADMIN_PIN" "$GPG_HOMEDIR" "$USER_PIN" "$KEY_LENGTH" "$REALNAME" "$EMAIL" "$COMMENT"
echo

# restore initial locale value
export LC_ALL="${old_locale}"

source lib/gpg_agent_conf.sh

# restart GPG daemons to pick up pinentry-mac
$GPGCONF --kill all

echo "There are two important random numbers for the YubiKey you MUST keep safely."
echo "See https://developers.yubico.com/yubikey-piv-manager/PIN_and_Management_Key.html"
echo

echo "The first number is the User PIN."
echo "The User PIN is used during normal operation to authorize an action such as issuing a new GPG signature."
echo "${GREEN}"
echo "***********************************************************"
echo "New User PIN: $USER_PIN"
echo "***********************************************************"
echo "${RESET}"
echo "${YELLOW}Please save this new User PIN (copied to clipboard) immediately in your password manager.${RESET}"
echo "$USER_PIN" | $CLIP $CLIP_ARGS
read -rp "${YELLOW}Have you done this?${RESET}"
echo "${YELLOW}Please also associate it with this YubiKey serial number (copied to clipboard): ${SERIAL}${RESET}"
echo "$SERIAL" | $CLIP $CLIP_ARGS
read -rp "${YELLOW}Have you done this? ${RESET}"
echo

echo "The second number is the Admin PIN."
echo "The Admin PIN can be used to reset the PIN if it is ever lost or becomes blocked after the maximum number of incorrect attempts."
echo "${GREEN}"
echo "***********************************************************"
echo "New Admin PIN: $ADMIN_PIN"
echo "***********************************************************"
echo "${RESET}"
echo "${YELLOW}Please save this new Admin PIN (copied to clipboard) immediately in your password manager.${RESET}"
echo "$ADMIN_PIN" | $CLIP $CLIP_ARGS
read -rp "${YELLOW}Have you done this? ${RESET}"
echo "${YELLOW}Please also associate it with this YubiKey serial number (copied to clipboard): ${SERIAL}${RESET}"
echo "$SERIAL" | $CLIP $CLIP_ARGS
read -rp "${YELLOW}Have you done this?${RESET}"
echo

# Export GPG public key.
KEYID=$(get_keyid "$GPG_HOMEDIR")
BIN_GPG_PUBKEY=$KEYID.gpg.pub.bin
ASC_GPG_PUBKEY=$KEYID.gpg.pub.asc
echo "${GREEN}Exporting your binary GPG public key to $(pwd)/${BIN_GPG_PUBKEY}${RESET}"
$GPG --homedir="$GPG_HOMEDIR" --export "$KEYID" > "$BIN_GPG_PUBKEY"
echo "${GREEN}Exporting your ASCII-armored GPG public key to $(pwd)/${ASC_GPG_PUBKEY}${RESET}"
$GPG --homedir="$GPG_HOMEDIR" --armor --export "$KEYID" > "$ASC_GPG_PUBKEY"
echo "$ASC_GPG_PUBKEY" | $CLIP $CLIP_ARGS
echo "${YELLOW}Please save a copy in your password manager.${RESET}"
read -rp "${YELLOW}Have you done this? ${RESET}"
echo "There is NO off-card backup of your private / secret keys."
echo "So, if your YubiKey is damaged, lost, or stolen, then you must rotate your GPG keys out-of-band."
echo "You would also no longer be able to decrypt messages encrypted for this GPG key."
echo

# Ask user to save revocation certificate before deleting it.
REVOCATION_CERT=$GPG_HOMEDIR/openpgp-revocs.d/$KEYID.rev
echo "$REVOCATION_CERT" | $CLIP $CLIP_ARGS
echo "${GREEN}Your revocation certificate is at ${REVOCATION_CERT}${RESET}"
echo "It has been copied to your clipboard."
echo "${YELLOW}Please save a copy in your password manager before we delete it off disk.${RESET}"
read -rp "${YELLOW}Have you done this? ${RESET}"
rm "$REVOCATION_CERT"
echo "Great. Deleted this revocation certificate from disk."
# NOTE: EMPTY clipboard after this.
$CLIP $CLIP_ARGS < /dev/null
echo

# Final reminders.
echo "Finally, remember that your keys will not ${GREEN}expire until 10 years from now.${RESET}"
echo "You will need to ${GREEN}${BOLD}enter your User PIN (once a day)${RESET}, and ${GREEN}${BOLD}touch your YubiKey${RESET} in order to sign any message with this GPG key."
if [[ "$TOUCH_POLICY" == "on" ]]; then
  echo "${YELLOW}You may wish to pass the --no-gpg-sign flag to git rebase.${RESET}"
else
  echo "Touch is cached for 15s on sign operations."
fi
echo "Enjoy using your YubiKey at Datadog!"
