#!/usr/bin/env bash
source env.sh

shopt -s extglob

confirm() {
    local msg

    msg="$1"

    echo "$msg"
    read -rn 3 answer
    case $answer in
        Yes|yes|Y|y|YES)
            echo
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

    for i in $(seq 1 2); do
        if ! $YKMAN --device "${serial}" otp delete "$i" -f >/dev/null 2>&1; then
            echo "Warning the slot $i didn't contain OTP configuration or an error happened"
        fi
    done
    $YKMAN --device "${serial}" oath reset -f
    $YKMAN --device "${serial}" openpgp reset -f
    $YKMAN --device "${serial}" piv reset -f
    $YKMAN --device "${serial}" fido reset
}

yubikeys=$($YKMAN list --serials)
select serial in all $yubikeys cancel; do
    echo "You chose $serial"
    case $serial in
        all)
            confirm "Are you sure you want to reset $yubikeys ? yes/no" || exit 0
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
            confirm "Are you sure you want to reset $serial ? yes/no" || exit 0
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


