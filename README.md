# YubiKey at Datadog

Table of contents

- [Summary](#summary)
- [Estimated burden and prerequisites](#estimated-burden-and-prerequisites)
- [U2F](#u2f)
- [GPG](#gpg)
- [git](#git)
- [SSH](#ssh)
- [Reset](#reset)
- [Troubleshooting](#troubleshooting)
- [Optional](#optional)
- [TODO](#todo)
- [References](#references)

## Summary

GPG is useful for authenticating yourself over SSH and / or GPG-signing your
git commits / tags. However, without hardware like the
[YubiKey](https://www.yubico.com/products/yubikey-hardware/), you would
typically keep your GPG private subkeys in "plain view" on your machine, even
if encrypted. That is, attackers who personally target
[[1](https://www.kennethreitz.org/essays/on-cybersecurity-and-being-targeted),
[2](https://bitcoingold.org/critical-warning-nov-26/),
[3](https://panic.com/blog/stolen-source-code/),
[4](https://www.fox-it.com/en/insights/blogs/blog/fox-hit-cyber-attack/)] you
can compromise your machine can exfiltrate your (encrypted) private key, and
your passphrase, in order to pretend to be you.

Instead, this setup lets you store your private subkeys on your YubiKey.
Actually, it gives you much stronger guarantees: you *cannot* authenticate over
SSH and / or sign GPG commits / tags *without*: (1) your YubiKey plugged in and
operational, (2) your YubiKey PIN, and (3) touching your YubiKey. So, even if
there is malware trying to get you to sign, encrypt, or authenticate something,
you would almost certainly notice, because your YubiKey will flash, asking for
your attention. (There is the "[time of check to time of
use](https://en.wikipedia.org/wiki/Time_of_check_to_time_of_use)" issue,
but that is out of our scope.)

## Estimated burden and prerequisites

<s>About 2-3 hours.</s> 15 minutes could save you 15% or more on cybersecurity
insurance.

You will need macOS, [Homebrew](https://brew.sh/), a password manager, and a
[YubiKey 5](https://www.yubico.com/products/yubikey-hardware/).

## U2F

**STRONGLY recommended:** configure U2F for
[GitHub](https://help.github.com/articles/configuring-two-factor-authentication/#configuring-two-factor-authentication-using-fido-u2f)
and
[Google](https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/).

## GPG

**Please read and follow all of the instructions carefully.**

```bash
$ ./gpg.sh
```

(Protip: set `TEMPDIR=1` when preparing YubiKey for someone else to avoid
polluting your default GPG homedir.)

## git

**STRONGLY RECOMMENDED:** signing all your git commits across all repositories.

You **must** have first set up [GPG](#gpg). Then:

```bash
$ ./git.sh
```


## SSH

**NOT recommended** unless you plan to use your GPG authentication subkey as
your only SSH authentication key.

You **must** have first set up [GPG](#gpg). Then:

```bash
$ ./ssh.sh
```


## Reset

If you need to reset YubiKeys, you may use the following script. The script looks for every plugged YubiKey,
and shows a menu to reset one specific key, or all of them.
**Please read and follow all of the instructions carefully. YOU WILL NOT BE ABLE TO RETRIEVE KEYS/DATA FROM THE YUBIKEY AFTER COMPLETION.**

```bash
$ ./reset.sh
```

## Troubleshooting

### Blocked card

If you are blocked out of using GPG because you entered your PIN wrong too
many times (3x by default), **don’t panic**: just [follow the
instructions](https://github.com/ruimarinho/yubikey-handbook/blob/master/openpgp/troubleshooting/gpg-failed-to-sign-the-data.md)
here. Make sure you enter your **Admin PIN** correctly within 3x, otherwise
your current keys are blocked, and you must reset your YubiKey to use new keys.

### Error with git pull/fetch or when using SSH
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

### git rebase

If you are using the FIPS model, you can perform signing operations for 15
seconds after touching your YubiKey before having to touch it again. When
running a large git rebase, you may have to touch your YubiKey multiple times.
If the rebase seems to hang and the YubiKey flashes, it means you need to touch
it again.

If you are still having issues when rebasing, you might consider using
the `--no-gpg-sign` flag as a [workaround](https://github.com/DataDog/yubikey/issues/19).

### Error: No PyUSB backend detected!

If you see the following error while running `./gpg.sh`:

```
Usage: ykman [OPTIONS] COMMAND [ARGS]...
Try "ykman -h" for help.

Error: No PyUSB backend detected!
```

Hit CTRL-C to exit the script (if the script has not already exited) and reinstall libsub, then try again:

    `brew reinstall libusb`

## Optional

Go [here](docs/optional.md) for support on optional bits such as Keybase, VMware Fusion, Docker Content Trust, signing for different git repositories with different keys, and configuring a computer to use an already configured Yubikey.

## TODO

1. Instructions for revoking and / or replacing keys.

2. Procedures for recovering from key compromise / theft / loss.

## References

1. [https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/](https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/)

2. [https://mikegerwitz.com/papers/git-horror-story](https://mikegerwitz.com/papers/git-horror-story)

3. [http://karl.kornel.us/2017/10/welp-there-go-my-git-signatures/](http://karl.kornel.us/2017/10/welp-there-go-my-git-signatures/)

4. [https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2014-May/005877.html](https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2014-May/005877.html)
