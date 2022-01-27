#!/usr/bin/env bash

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
