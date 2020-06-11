#!/usr/bin/env bash
shopt -s extglob

confirm() {
    local msg

    msg="$1"

    echo "$msg"
    read -srn 3 answer
    case $answer in
        Yes|yes|Y|y|YES)
            return 0
            ;;
        *)
            echo "Cancelling"
            return 1
    esac
}

reset_device() {
    local serial
    serial="$1"

    /usr/local/bin/ykman --device "$(serial)" otp delete 1 -f
    /usr/local/bin/ykman --device "$(serial)" otp delete 2 -f
    /usr/local/bin/ykman --device "$(serial)" oath reset -f
    /usr/local/bin/ykman --device "$(serial)" openpgp reset -f
    /usr/local/bin/ykman --device "$(serial)" piv reset -f
    /usr/local/bin/ykman --device "$(serial)" fido reset -f
}

# Don't have you personnal yubikey plugged in
# to run me `bash yubispam.sh`
yubikeys=$(/usr/local/bin/ykman list --serials)
select serial in all $yubikeys cancel; do
    echo "You choose $serial"
    case $serial in
        all)
            echo "Are you sure you want to reset $yubikeys ? yes/no"
            confirm || exit 0
            for yubikey in $yubikeys; do
                echo "Reset $yubikey"
                reset_device "$yubikey"
            done
            break
            ;;
        cancel)
            echo "Cancelled"
            break
            ;;
        +([0-9]))
            echo "Are you sure you want to reset $serial ? yes/no"
            confirm || exit 0
            echo "Reset $serial"
            reset_device "$serial"
            break
            ;;
        *)
            echo "Unexpected error, exiting"
            exit 1
            ;;
    esac
done


