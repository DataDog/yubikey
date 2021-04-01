#!/usr/bin/env bash

# Stop on error.
set -e

source env.sh

# https://stackoverflow.com/a/44348249
function install_or_upgrade {
    local pkg
    pkg="$1"
    if "$PKG_CHECK" "$PKG_CHECK_ARGS" "$pkg" >/dev/null; then
        eval "$PKG_MANAGER_ENV" "$PKG_MANAGER" "$PKG_MANAGER_UPGRADE" "$pkg"
    else
        eval "$PKG_MANAGER_ENV" "$PKG_MANAGER" "$PKG_MANAGER_INSTALL" "$pkg"
    fi
}

function check_presence {
    local pkg
    pkg="$1"
    if ! "$PKG_CHECK" "$PKG_CHECK_ARGS" "$pkg" >/dev/null 2>&1; then
        echo "$pkg is missing, please install it"
        return 1
    fi
}

echo "Welcome! This program will automatically generate GPG keys on your YubiKey."
echo "If you ever run into problems, just press Ctrl-C, and rerun this program again."
echo

echo "You need to have $(join ',' "${DEPS[@]}") installed on your device."
read -rp "Do you want us to install them for you ? (y/n)" answer
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

case $(${GPG} --version | head -n1 | cut -d" " -f3) in
    2.2.23|2.2.22)
        echo "Your version of gnupg has a bug that makes $0 fail"
        echo "Bugged version are 2.2.23 and 2.2.22"
        echo "Please use version < 2.2.22 or > 2.2.23"
        echo "See https://dev.gnupg.org/T5086 for more details"
        exit 1
        ;;
    *)
        ;;
esac

# Get full name and email address.
source realname-and-email.sh

# Get comment to distinguish between keys.
COMMENT="GPG on YubiKey for Datadog"
echo "What is a comment you would like to use to distinguish this key?"
read -rp "Comment (press Enter to accept '$COMMENT'): " input
COMMENT=${input:-$COMMENT}
echo

# Generate some information for the user.
USER_PIN=$(python -S -c "import random; print(random.SystemRandom().randrange(10**7,10**8))")
ADMIN_PIN=$(python -S -c "import random; print(random.SystemRandom().randrange(10**7,10**8))")
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

# force locale to prevent expect script from breaking on non-english systems.
old_locale="${LC_ALL}"
export LC_ALL=en_US.UTF-8

# drive yubikey setup
# but right before, kill all GPG daemons to make sure things work reliably
$GPGCONF --homedir="$GPG_HOMEDIR" --kill all
GPG_TTY="" ./expect.sh "$TOUCH_POLICY" "$ADMIN_PIN" "$GPG_HOMEDIR" "$USER_PIN" "$KEY_LENGTH" "$REALNAME" "$EMAIL" "$COMMENT"
echo

# restore initial locale value
export LC_ALL="${old_locale}"

# Overwrite default GPG agent configuration with our own.
# We want to replace the pinentry-tty with the pinentry-mac.
cat << EOF > "$DEFAULT_GPG_AGENT_CONF"
# https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
pinentry-program /usr/local/bin/pinentry-mac
# For usability while balancing security, cache User PIN for at most a day.
default-cache-ttl 86400
max-cache-ttl 86400
EOF

# restart GPG daemons to pick up pinentry-mac
$GPGCONF --kill all

echo "There are two important random numbers for the YubiKey you MUST keep safely."
echo "See https://developers.yubico.com/yubikey-piv-manager/PIN_and_Management_Key.html"
echo

echo "The first number is the User PIN."
echo "The User PIN is used during normal operation to authorize an action such as issuing a new GPG signature."
echo
echo "***********************************************************"
echo "New User PIN: $USER_PIN"
echo "***********************************************************"
echo
echo "Please save this new User PIN (copied to clipboard) immediately in your password manager."
echo "$USER_PIN" | $CLIP $CLIP_ARGS
read -rp "Have you done this? "
echo "Please also associate it with this YubiKey serial number (copied to clipboard): $SERIAL"
echo "$SERIAL" | $CLIP $CLIP_ARGS
read -rp "Have you done this? "
echo

echo "The second number is the Admin PIN."
echo "The Admin PIN can be used to reset the PIN if it is ever lost or becomes blocked after the maximum number of incorrect attempts."
echo
echo "***********************************************************"
echo "New Admin PIN: $ADMIN_PIN"
echo "***********************************************************"
echo
echo "Please save this new Admin PIN (copied to clipboard) immediately in your password manager."
echo "$ADMIN_PIN" | $CLIP $CLIP_ARGS
read -rp "Have you done this? "
echo "Please also associate it with this YubiKey serial number (copied to clipboard): $SERIAL"
echo "$SERIAL" | $CLIP $CLIP_ARGS
read -rp "Have you done this? "
echo

# Export GPG public key.
KEYID=$(get_keyid "$GPG_HOMEDIR")
BIN_GPG_PUBKEY=$KEYID.gpg.pub.bin
ASC_GPG_PUBKEY=$KEYID.gpg.pub.asc
echo "Exporting your binary GPG public key to $BIN_GPG_PUBKEY"
$GPG --homedir="$GPG_HOMEDIR" --export "$KEYID" > "$BIN_GPG_PUBKEY"
echo "Exporting your ASCII-armored GPG public key to $ASC_GPG_PUBKEY"
$GPG --homedir="$GPG_HOMEDIR" --armor --export "$KEYID" > "$ASC_GPG_PUBKEY"
echo "$ASC_GPG_PUBKEY" | $CLIP $CLIP_ARGS
echo "Please save a copy in your password manager."
read -rp "Have you done this? "
echo "There is NO off-card backup of your private / secret keys."
echo "So, if your YubiKey is damaged, lost, or stolen, then you must rotate your GPG keys out-of-band."
echo "You would also no longer be able to decrypt messages encrypted for this GPG key."
echo

# Ask user to save revocation certificate before deleting it.
REVOCATION_CERT=$GPG_HOMEDIR/openpgp-revocs.d/$KEYID.rev
echo "$REVOCATION_CERT" | $CLIP $CLIP_ARGS
echo "Your revocation certificate is at $REVOCATION_CERT"
echo "It has been copied to your clipboard."
echo "Please save a copy in your password manager before we delete it off disk."
read -rp "Have you done this? "
rm "$REVOCATION_CERT"
echo "Great. Deleted this revocation certificate from disk."
# NOTE: EMPTY clipboard after this.
$CLIP $CLIP_ARGS < /dev/null
echo

# Final reminders.
echo "Finally, remember that your keys will not expire until 10 years from now."
echo "You will need to ${RED}${BOLD}enter your User PIN (once a day)${RESET}, and ${RED}${BOLD}touch your YubiKey${RESET} in order to sign any message with this GPG key."
if [[ "$TOUCH_POLICY" == "on" ]]; then
  echo "You may wish to pass the --no-gpg-sign flag to git rebase."
else
  echo "Touch is cached for 15s on sign operations."
fi
echo "Enjoy using your YubiKey at Datadog!"
