# Troubleshooting

- [Blocked card](#blocked-card)
- [Error with git pull/fetch or when using SSH](#error-with-git-pullfetch-or-when-using-ssh)
- [git rebase](#git-rebase)
- [No PyUSB backend detected](#no-pyusb-backend-detected)
- [Bad substitution](#bad-substitution)
- [Operation-not-supported-by-device-error](#operation-not-supported-by-device-error)

## Blocked card

If you are blocked out of using GPG because you entered your PIN wrong too
many times (3x by default), **don’t panic**: just [follow the
instructions](https://github.com/ruimarinho/yubikey-handbook/blob/master/openpgp/troubleshooting/gpg-failed-to-sign-the-data.md)
here. Make sure you enter your **Admin PIN** correctly within 3x, otherwise
your current keys are blocked, and you must reset your YubiKey to use new keys.

## Error with git pull/fetch or when using SSH

If you try to ssh or git pull/fetch and you have the following error:
```
sign_and_send_pubkey: signing failed: agent refused operation
```
You are probably mistyping your PIN. To verify it, you can:
```
gpg --card-edit
gpg/card> verify
...
PIN retry counter : 3 0 3 # if it is the right PIN
PIN retry counter : 2 0 3 # if it is a wrong PIN
...
```
If your PIN is wrong, try 123456, which is the default PIN.
If it still fails, reset your PIN:
```
gpg --card-edit
gpg/card> admin
gpg/card> passwd
gpg: OpenPGP card no. D2760001240102010006055532110000 detected

Your selection? 1
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? q
```

## git rebase

If you are using the FIPS model, you can perform signing operations for 15
seconds after touching your YubiKey before having to touch it again. When
running a large git rebase, you may have to touch your YubiKey multiple times.
If the rebase seems to hang and the YubiKey flashes, it means you need to touch
it again.

If you are still having issues when rebasing, you might consider using
the `--no-gpg-sign` flag as a [workaround](https://github.com/DataDog/yubikey/issues/19).

## No PyUSB backend detected

If you see the following error while running `./gpg.sh`:

```
Usage: ykman [OPTIONS] COMMAND [ARGS]...
Try "ykman -h" for help.

Error: No PyUSB backend detected!
```

Hit CTRL-C to exit the script (if the script has not already exited) and [reinstall](https://github.com/Yubico/yubikey-manager/issues/185#issuecomment-446379356) `libsub`, then try again: `brew reinstall libusb`

## Bad substitution

If you see the following error while running `./gpg.sh`:

```
OS detected is macos
Is it correct ? (y|N) Y
env.sh: line 34: ${OS,,}: bad substitution
```

Run `brew install bash`. The script is using a feature not that is not supported by the old macOS bash.

## Operation not supported by device error

This manifests as PIN Entry dialog prompting to insert the card in a perpetual loop.

You may also see:

```shell
gpg --card-status
gpg: selecting card failed: Operation not supported by device
gpg: OpenPGP card not available: Operation not supported by device
```

Run [./scdaemon.sh](../scdaemon.sh).