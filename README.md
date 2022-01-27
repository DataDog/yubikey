# YubiKey at Datadog

- [Summary](#summary)
- [Estimated burden and prerequisites](#estimated-burden-and-prerequisites)
- [U2F](#u2f)
- [GPG](#gpg)
- [git](#git)
- [SSH](#ssh)
- [Reset](#reset)
- [Troubleshooting](#troubleshooting)
- [Optional](#optional)
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

You will need macOS with [Homebrew](https://brew.sh/) / Ubuntu / Archlinux, a password manager, and a
[YubiKey 5](https://www.yubico.com/products/yubikey-hardware/).

## U2F

**STRONGLY recommended:** configure U2F for
[GitHub](https://help.github.com/articles/configuring-two-factor-authentication/#configuring-two-factor-authentication-using-fido-u2f)
and
[Google](https://support.yubico.com/hc/en-us/articles/360013717460-Using-Your-YubiKey-with-Google).

## GPG

**Please read and follow all of the instructions carefully.**

```bash
$ ./gpg.sh
```

(Protip: set `TEMPDIR=1` when preparing YubiKey for someone else to avoid
polluting your default GPG homedir.)

## git

**STRONGLY RECOMMENDED:** signing your git commits and tags.

You **must** first set up [GPG](#gpg).

Then, to sign git commits and tags for a _particular_ repository:

```bash
$ ./git.sh /path/to/git/repository
```

Or, to sign git commits and tags for _all_ repositories:

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

Go [here](docs/troubleshooting.md) for troubleshooting common issues such as unblocking a blocked card, error when pulling or pushing with git over SSH, and rebasing with git.

## Optional

Go [here](docs/optional.md) for support on optional bits such as configuring a computer to use an already configured YubiKey, signing for different git repositories with different keys, Keybase, VMware Fusion, and Docker Content Trust.

## References

1. [YubiKey Handbook](https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/)

2. [A Git Horror Story: Repository Integrity With Signed Commits](https://mikegerwitz.com/papers/git-horror-story)

3. [Welp, there go my Git signatures](http://karl.kornel.us/2017/10/welp-there-go-my-git-signatures/)

4. [[Bitcoin-development] PSA: Please sign your git commits](https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2014-May/005877.html)
