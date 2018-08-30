# How to use Yubikey for gpg, git, ssh, Docker Content Trust, VMware Fusion, and more

## Table of contents

* [Summary](#summary)
* [Estimated burden and prerequisites](#estimated-burden-and-prerequisites)
* [GPG, git, and ssh](#gpg-git-and-ssh)
* [U2F](#u2f)
* [Keybase](#keybase)
* [VMware Fusion](#vmware-fusion)
* [Docker Content Trust](#docker-content-trust)
* [Troubleshooting](#troubleshooting)
* [TODO](#todo)
* [Acknowledgements](#acknowledgements)
* [References](#references)

## Summary

GPG is useful for authenticating yourself over SSH and / or GPG-signing your git commits / tags. However, without hardware like the [Yubikey](https://www.yubico.com/products/yubikey-hardware/), you would typically keep your GPG private subkeys in "plain view" on your machine, even if encrypted. That is, attackers who personally target [[1](https://www.kennethreitz.org/essays/on-cybersecurity-and-being-targeted), [2](https://bitcoingold.org/critical-warning-nov-26/), [3](https://panic.com/blog/stolen-source-code/), [4](https://www.fox-it.com/en/insights/blogs/blog/fox-hit-cyber-attack/)] you can compromise your machine can exfiltrate your (encrypted) private key, and your passphrase, in order to pretend to be you.

Instead, this setup lets you store your private subkeys on your Yubikey. Actually, it gives you much stronger guarantees: you *cannot* authenticate over SSH and / or sign GPG commits / tags *without*: (1) your Yubikey plugged in and operational, (2) your Yubikey PIN, and (3) touching your Yubikey. So, even if there is malware trying to get you to sign, encrypt, or authenticate something, you would almost certainly notice, because your Yubikey will flash, asking for your attention. (There is the "[time of check to time of use](https://en.wikipedia.org/wiki/Time_of_check_to_time_of_use)" issue, but that is out of our scope.)

## Estimated burden and prerequisites

<s>About 2-3 hours.</s> Automated GPG setup with Yubikey should now take _a few minutes_.

You will need macOS, [Homebrew](https://brew.sh/), a password manager, and a [Yubikey 4](https://www.yubico.com/product/yubikey-4-series/).

## GPG, git, and SSH

```bash
$ ./mac.sh
```

*Please read and follow all of the instructions carefully.*

## U2F

Optional: configure U2F for GitHub and Google.

1. [https://help.github.com/articles/configuring-two-factor-authentication-via-fido-u2f/](https://help.github.com/articles/configuring-two-factor-authentication-via-fido-u2f/)

2. [https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/](https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/)

## Keybase

Optional: verify public key on Keybase.

1. You can now do this using the command-line option, with only `curl` and `gpg`, and without installing any Keybase app, or uploading an encrypted copy of your private key. For example, see [my profile](https://keybase.io/trishankdatadog).

## VMware Fusion

Optional: using Yubikey inside GNU/Linux running on VMware Fusion.

1. Shut down your VM, find its .vmx file, edit the file to the [add the following line](https://www.symantec.com/connect/blogs/enabling-hid-devices-such-usb-keyboards-barcode-scanners-vmware), and then reboot it: `usb.generic.allowHID = "TRUE"`

2. Connect your Yubikey to the VM once you have booted and logged in.

3. Install libraries for smart card:

    1. Ubuntu 17.10: `apt install scdaemon`

    2. Fedora 27: `dnf install pcsc-lite pcsc-lite-ccid`

4. Import your public key (see Step 13).

5. Set ultimate trust for your key (see Step 20).

6. Configure GPG (see Step 22).

7. Test the keys (see Step 23). On Fedora, make sure to replace `gpg` with `gpg2`.

8. Use the absolutely terrible kludge in Table 5 to make SSH work.

9. Spawn a new shell, and test GitHub SSH (see Step 26).

10. Test Git signing (see Step 28). On Fedora, make sure to replace `gpg` with `gpg2`: `git config --global gpg.program gpg2`

<blockquote>

    # gpg-ssh hack
    gpg-connect-agent killagent /bye
    eval $(gpg-agent --daemon --enable-ssh-support --sh)
    ssh-add -l

</blockquote>

**Table 5**: Add these lines to `~/.bashrc`.

## Docker Content Trust

Optional: using Yubikey to store the root role key for Docker Notary.

1. Assumption: you are running all of the following under [Fedora 27](#vmware-fusion).

2. Install prerequisites: `dnf install golang yubico-piv-tool`

3. Set [GOPATH](https://golang.org/doc/code.html#GOPATH) (make sure to update PATH too), and spawn a new `bash` shell.

4. Check out the Notary source code: `go get github.com/theupdateframework/notary`

5. Patch source code to [point to correct location of shared library on Fedora](https://github.com/theupdateframework/notary/pull/1286).

    1. `cd ~/go/src/go get github.com/theupdateframework/notary`

    2. `git pull https://github.com/trishankatdatadog/notary.git trishank_kuppusamy/fedora-pkcs11`

6. [Build and install](https://github.com/theupdateframework/notary/pull/1285) the Notary client: `go install -tags pkcs11 github.com/theupdateframework/notary/cmd/notary`

7. Add the lines in Table 6 to your `bash` profile, and spawn a new shell.

8. Try listing keys (there should be no signing keys as yet):

    1. `dockernotary key list -D`

    2. If you see the line `"DEBU[0000] Initialized PKCS11 library /usr/lib64/libykcs11.so.1 and started HSM session"`, then we are in business.

    3. Otherwise, if you see the line `"DEBU[0000] No yubikey found, using alternative key storage: found library /usr/lib64/libykcs11.so.1, but initialize error pkcs11: 0x6: CKR_FUNCTION_FAILED"`, then you probably need to `gpgconf --kill scdaemon` ([see this issue](https://github.com/theupdateframework/notary/issues/1006)), and try again.

9. Generate the root role key ([can be reused across multiple Docker repositories](https://github.com/theupdateframework/notary/blame/a41821feaf59a28c1d8f78799300d26f8bdf8b0d/docs/best_practices.md#L91-L95)), and export it to both Yubikey, and keep a copy on disk:

    1. Choose a strong passphrase.

    2. `dockernotary key generate -D`

    3. Commit passphrase to memory and / or offline storage.

    4. Try listing keys again, you should now see a copy of the same private key in two places (disk, and Yubikey).

    5. Backup private key in `~/.docker/trust/private/KEYID.key` unto offline, encrypted, long-term storage.

    6. [Securely delete](https://www.gnu.org/software/coreutils/manual/html_node/shred-invocation.html) this private key on disk.

    7. Now if you list the keys again, you should see the private key only on Yubikey.

10. Link the yubikey library so that the prebuilt docker client can find it: `sudo ln -s /usr/lib64/libykcs11.so.1 /usr/local/lib/libykcs11.so`

11. Later, when you want Docker to use the root role key on your Yubikey:

    1. When you push an image, you may have to kill `scdaemon` (in a separate shell) right after Docker pushes, but right before Docker uses the root role key on your Yubikey, and generates a new targets key for the repository.

    2. Use `docker -D` to find out exactly when to do this.

    3. This is annoying, but it works.

<blockquote>

    # docker notary stuff
    alias dockernotary="notary -s https://notary.docker.io -d ~/.docker/trust"
    # always be using content trust
    export DOCKER_CONTENT_TRUST=1

</blockquote>

**Table 6**: Add these lines to `~/.bashrc`.

## Troubleshooting

* If you are blocked out of using GPG because you entered your PIN wrong too many times (3x by default), **don’t panic**: just [follow the instructions](https://github.com/ruimarinho/yubikey-handbook/blob/master/openpgp/troubleshooting/gpg-failed-to-sign-the-data.md) here.

* If you suddenly start getting `Permission denied (publickey)`, verify that `ssh-agent` is not running. If `ssh-agent` is running, kill the process. If the error persists, use the kludge in Table 5.

* If you are having issues failing to make connections, you still need to have `ssh-agent` running along with `gpg-agent`: `eval $(ssh-agent -s)`

## TODO

1. Instructions for revoking and / or replacing keys.

2. Procedures for recovering from key compromise / theft / loss.

3. [Solving the PGP Revocation Problem with OpenTimestamps for Git Commits](https://petertodd.org/2016/opentimestamps-git-integration).

## Acknowledgements

I developed this guide while working at [Datadog](https://www.datadoghq.com/), in order to use it in various product security efforts. Thanks to Ayaz Badouraly, Arthur Bellal, Forrest Buff, Alex Charrier, Jules Denardou, Ivan DiLernia, Hippolyte Henry, David Huie, Yann Mahé, Cara Marie, Rishabh Moudgil, Maxime Mouial, Nicholas Muesch, Julien Muetton, Cody Lee, Ofek Lev, Thomas Renault, Pratik Guha Sarkar, and Santiago Torres-Arias (NYU), all of whom who were at Datadog (unless specified otherwise), and who helped me to test these instructions. Thanks to Justin Massey for contributing the section on disabling Yubikey OTP.

## References

1. [https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/](https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/)

2. [https://mikegerwitz.com/papers/git-horror-story](https://mikegerwitz.com/papers/git-horror-story)

3. [http://karl.kornel.us/2017/10/welp-there-go-my-git-signatures/](http://karl.kornel.us/2017/10/welp-there-go-my-git-signatures/)

4. [https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2014-May/005877.html](https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2014-May/005877.html)
