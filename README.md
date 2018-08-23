# How to use Yubikey for gpg, git, ssh, Docker Content Trust, VMware Fusion, and more

## Table of contents

* [Summary](#summary)
* [Estimated burden](#estimated-burden)
* [GPG](#gpg)
* [SSH](#ssh)
* [U2F](#u2f)
* [Keybase](#keybase)
* [VMware Fusion](#vmware-fusion)
* [Docker Content Trust](#docker-content-trust)
* [Why disable Yubikey OTP?](#why-disable-yubikey-otp)
* [Troubleshooting](#troubleshooting)
* [TODO](#todo)
* [Acknowledgements](#acknowledgements)
* [References](#references)

## Summary

GPG is useful for authenticating yourself over SSH and / or GPG-signing your git commits / tags. However, without hardware like the [Yubikey](https://www.yubico.com/products/yubikey-hardware/), you would typically keep your GPG private subkeys in "plain view" on your machine, even if encrypted. That is, attackers who personally target [[1](https://www.kennethreitz.org/essays/on-cybersecurity-and-being-targeted), [2](https://bitcoingold.org/critical-warning-nov-26/), [3](https://panic.com/blog/stolen-source-code/), [4](https://www.fox-it.com/en/insights/blogs/blog/fox-hit-cyber-attack/)] you can compromise your machine can exfiltrate your (encrypted) private key, and your passphrase, in order to pretend to be you.

Instead, this setup lets you store your private subkeys on your Yubikey. Actually, it gives you much stronger guarantees: you *cannot* authenticate over SSH and / or sign GPG commits / tags *without*: (1) your Yubikey plugged in and operational, (2) your Yubikey PIN, and (3) touching your Yubikey. So, even if there is malware trying to get you to sign, encrypt, or authenticate something, you would almost certainly notice, because your Yubikey will flash, asking for your attention. (There is the "[time of check to time of use](https://en.wikipedia.org/wiki/Time_of_check_to_time_of_use)" issue, but that is out of our scope.)

## Estimated burden

<s>About 2-3 hours.</s>

Automated GPG setup with Yubikey should now take a few minutes.

## GPG

```bash
$ ./mac.sh
```

## SSH

TODO

## U2F

Optional: configure U2F for GitHub and Google.

1. [https://help.github.com/articles/configuring-two-factor-authentication-via-fido-u2f/](https://help.github.com/articles/configuring-two-factor-authentication-via-fido-u2f/)

2. [https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/](https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/)

3. Why is this optional? Because an evil maid attack gives you access to U2F-enabled services. Should not be required for people who travel with Yubikey in laptop. In any case, it's a race between the user and the attacker anyway.

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

## Why disable Yubikey OTP?

Yubikey OTPs are vulnerable to replay attacks. To first understand the attack scenario, one must understand how the OTPs are generated Source and full explanation [here](https://developers.yubico.com/OTP/OTPs_Explained.html).

1. When a OTP is generated by the Yubikey, it outputs a 44 character value.

    1. Ex: **cccjgjgkhcbb**irdrfdnlnghhfgrtnnlgedjlftrbdeut

    2. The first 12 characters represent the public ID of the Yubikey and remain constant. The remaining 32 characters represent a unique token that includes **a counter**.

        1. The counter part is the most important piece of why one should disable OTP.

2. When the user submits the OTP to an IDP:

    1. The IdP validates the unique ID is associated with the user account.

    2. The IdP decrypts the token with a pre-shared AES key, proving that the user is who they say they are.

    3. The IdP then check the counter to ensure it is greater than the last token **they are aware of**.

    4. The IdP updates the counter so that this token and all previous tokens cannot be replayed.

Attack Scenarios:

1. **Scenario 1 - Fake IdP**

    1. An attacker sets up a fake IdP.

    2. Attacker directs a benign user to this fake IdP.

    3. The user uses the OTP to authenticate to the fake IdP.

    4. The attacker can now replay this token because it’s counter will be greater than the one known to the legitimate IdP.

2. **Scenario 2 - Malicious or Compromised IdP**

    1. Prerequisite: The IdP is compromised by an attacker or the IdP has malicious intentions:

    2. The IdP can capture the most recently used token and replay it on any other IdP the Yubikey device is associated with. Furthermore, this token is valid on **ALL** other IdPs until a newer token has been used to increment the counter in the IdPs database.

3. **Scenario 3 - Yubispam**

    1. It is not uncommon for the user to accidentally share an OTP token by pressing the Yubikey. This assumes the default short click is configured for OTP on Yubikey.

    2. A malicious user sees the OTP and can use this OTP token on **ALL** associated IdPs until a newer token has been used to increment the counter in the IdPs database.

## Troubleshooting

* If you are blocked out of using GPG because you entered your PIN wrong too many times (3x by default), **don’t panic**: just [follow the instructions](https://github.com/ruimarinho/yubikey-handbook/blob/master/openpgp/troubleshooting/gpg-failed-to-sign-the-data.md) here.

* If you suddenly start getting `Permission denied (publickey)`, verify that `ssh-agent` is not running. If `ssh-agent` is running, kill the process. If the error persists, use the kludge in Table 5.

* If you are having issues failing to make connections, you still need to have `ssh-agent` running along with `gpg-agent`: `eval $(ssh-agent -s)`

## TODO

1. Automate, automate, automate as much as possible (e.g., using `bash` and `expect` scripts).

2. Instructions for revoking and / or replacing keys.

3. [Solving the PGP Revocation Problem with OpenTimestamps for Git Commits](https://petertodd.org/2016/opentimestamps-git-integration).

4. Procedures for recovering from key compromise / theft / loss.

5. [Setup NFC 2FA](https://ocramius.github.io/blog/yubikey-for-ssh-gpg-git-and-local-login/) (downside: would not work out-of-the-box on iPhones as yet).

6. [Setup PAM authentication](https://ocramius.github.io/blog/yubikey-for-ssh-gpg-git-and-local-login/) (downside: can get locked out of laptop).

## Acknowledgements

I developed this guide while working at [Datadog](https://www.datadoghq.com/), in order to use it in various product security efforts. Thanks to Jules Denardou (Datadog), Cara Marie (Datadog), Cody Lee (Datadog), and Santiago Torres-Arias (NYU) who helped me to test these instructions. Thanks to Justin Massey (Datadog) for contributing the [section on disabling Yubikey OTP](#why-disable-yubikey-otp).

## References

1. [https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/](https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/)

2. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e)

3. [https://medium.com/@ahawkins/securing-my-digital-life-gpg-yubikey-ssh-on-macos-5f115cb01266](https://medium.com/@ahawkins/securing-my-digital-life-gpg-yubikey-ssh-on-macos-5f115cb01266)

4. [https://ocramius.github.io/blog/yubikey-for-ssh-gpg-git-and-local-login/](https://ocramius.github.io/blog/yubikey-for-ssh-gpg-git-and-local-login/)

5. [https://blog.eleven-labs.com/en/openpgp-secret-keys-yubikey-part-2/](https://blog.eleven-labs.com/en/openpgp-secret-keys-yubikey-part-2/)

6. [https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/](https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/)

7. [https://mikegerwitz.com/papers/git-horror-story](https://mikegerwitz.com/papers/git-horror-story)

8. [http://karl.kornel.us/2017/10/welp-there-go-my-git-signatures/](http://karl.kornel.us/2017/10/welp-there-go-my-git-signatures/)

9. [https://petertodd.org/2016/opentimestamps-git-integration](https://petertodd.org/2016/opentimestamps-git-integration)

10. [https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2014-May/005877.html](https://lists.linuxfoundation.org/pipermail/bitcoin-dev/2014-May/005877.html)
