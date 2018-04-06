# How to use Yubikey for gpg, git, ssh, Docker Content Trust, VMware Fusion, and more

## Table of contents

* [Summary](#summary)
* [Estimated burden](#estimated-burden)
* [Instructions](#instructions)
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

About 2-3 hours.

## Instructions

1. **Install Homebrew.**

2. **Install GPG and other preliminaries.**

    1. `brew install gnupg hopenpgp-tools pinentry-mac ykman yubico-piv-tool`

3. **Check the card status.**

    1. Don’t worry even if it says it supports only 3 RSA 2048-bit subkeys. We found that we could actually install 3 RSA 4096-bit subkeys (depending on the Yubikey model).

    2. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#insert-yubikey](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#insert-yubikey)

4. **Change card PINs and metadata.**

    1. [Since we won’t be using it here, turn off OTP](https://github.com/liyanchang/yubikey-setup/tree/edd0b7fc6b5e588c8897961ce8f5f85aa868ff1d#turn-off-otp---aka-the-random-letters-when-you-accidentally-touch-it).  Disabling it is recommended: see the explanation [here](#why-disable-yubikey-otp).

    2. [https://developers.yubico.com/PIV/Introduction/Admin_access.html](https://developers.yubico.com/PIV/Introduction/Admin_access.html)

    3. [https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/editing-metadata.html](https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/editing-metadata.html)

    4. [https://developers.yubico.com/PGP/Card_edit.html](https://developers.yubico.com/PGP/Card_edit.html)

    5. Optional: set management key (but not PIN and PUK) via yubico-piv-tool ([https://developers.yubico.com/PIV/Guides/Device_setup.html](https://developers.yubico.com/PIV/Guides/Device_setup.html))

    6. Set the user and admin PINs.

    7. Optional: You might want to also set the unblock and reset PINs.

    8. [You might want to force asking for the PIN every time you sign](https://www.andreagrandi.it/tag/yubikey.html). See the `forcesig` option in `gpg`.

    9. Useful reset in case things go wrong: [https://developers.yubico.com/ykneo-openpgp/ResetApplet.html](https://developers.yubico.com/ykneo-openpgp/ResetApplet.html)

    10. Looks like anyone can reset your card if they have physical access, or can compromise your machine, which is undesirable. At least you can recover from your key backup later. (Ask Yubico about this.) In the meantime, I am told that standard industry practice is to use two Yubikeys, with one serving as backup in case the other fails.

    11. Store these PINs in an offline safe.

5. **Configure GPG.**

    1. See Table 1. (How future-proof are these recommendations?)

    2. [https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/#install-the-right-tools](https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/#install-the-right-tools)

    3. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#create-configuration](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#create-configuration)

<blockquote>

    # Some random stuff to check later
    use-agent
    charset utf-8
    fixed-list-mode

    # Avoid information leaked
    no-emit-version
    no-comments
    export-options export-minimal

    # Displays the long format of the ID of the keys and their fingerprints
    keyid-format 0xlong
    with-fingerprint

    # Displays the validity of the keys
    list-options show-uid-validity
    verify-options show-uid-validity

    # Limits the algorithms used
    personal-cipher-preferences AES256
    personal-digest-preferences SHA512
    default-preference-list SHA512 SHA384 SHA256 RIPEMD160 AES256 TWOFISH BLOWFISH ZLIB BZIP2 ZIP Uncompressed

    cipher-algo AES256
    digest-algo SHA512
    cert-digest-algo SHA512
    compress-algo ZLIB

    disable-cipher-algo 3DES
    weak-digest SHA1

    s2k-cipher-algo AES256
    s2k-digest-algo SHA512
    s2k-mode 3
    s2k-count 65011712

</blockquote>

**Table 1**: `~/.gnupg/gpg.conf`.

6. **Create temporary working directory for GPG.**

    1. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#create-temporary-working-directory-for-gpg](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#create-temporary-working-directory-for-gpg)

7. **Create the master key.**

    1. [Choose a long but memorable passphrase](https://www.gnupg.org/faq/gnupg-faq.html#strong_passphrase).

    2. Make sure it has only the ability to [Certify](https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/#creating-the-master-key).

    3. Make sure it expires (perhaps in a few years).

    4. Set reminder to renew key.

    5. Commit passphrase to memory and / or offline storage.

8. **Cache the key ID (for convenience).**

    1. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#save-key-id](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#save-key-id)

9. **Create subkeys.**

    1. Make sure you know which key size your Yubikey can accommodate (see Step 3).

    2. Create a [subkey](https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/#creating-subkeys) for only each of the following capabilities: Sign, Encrypt, Authenticate.

    3. The passphrase is the same as for the master key (see Step 7i).

    4. Make sure it expires (perhaps in 1 year).

    5. Set reminder(s) to renew subkeys.

10. **Check your list of secret keys.**

    1. `gpg --export $KEYID | hokey lint`

    2. > The output will display any problems with your key in red text. If everything is green, your key passes each of the tests. If it is red, your key has failed one of the tests.

    3. > hokey may warn (orange text) about cross certification for the authentication key. GPG's Signing Subkey Cross-Certification documentation has more detail on cross certification, and gpg v2.2.1 notes "subkey does not sign and so does not need to be cross-certified".

    4. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#check-your-work](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#check-your-work)

11. **Create a revocation certificate (in case master key is compromised).**

    1. `gpg --output $GNUPGHOME/openpgp-revocs.d/$KEYID.rev --gen-revoke $KEYID`

    2. `less $GNUPGHOME/openpgp-revocs.d/$KEYID.rev`

12. **Export public key.**

    1. `gpg --export --armor $KEYID > $GNUPGHOME/$KEYID.pub.asc`

    2. `less $GNUPGHOME/$KEYID.pub.asc`

13. **Import public key.**

    1. `gpg --import < $GNUPGHOME/$KEYID.pub.asc`

    2. Copy this public key elsewhere for future reference.

14. **Export private master key.**

    1. `gpg --export-secret-keys --armor $KEYID > $GNUPGHOME/$KEYID.priv.asc`

    2. `less $GNUPGHOME/$KEYID.priv.asc`

15. **Export private subkeys.**

    1. `gpg --export-secret-subkeys --armor $KEYID > $GNUPGHOME/$KEYID.sub_priv.asc`

    2. The passphrase is the same as for the master key (see Step 8a).

    3. `less $GNUPGHOME/$KEYID.sub_priv.asc`

16. **Backup everything unto offline encrypted image.**

    1. Choose a good password.

    2. `hdiutil create /tmp/encrypted-gpg-backup.dmg -encryption -volname "gpg-backup" -fs APFS -srcfolder $GNUPGHOME`

    3. Move encrypted image unto offline storage.

    4. Commit password to memory and / or offline storage.

    5. Securely delete `$GNUPGHOME` (which is not straightforward on SSDs).

17. **Delete private keys from memory.**

    1. `gpg --delete-secret-key $KEYID`

    2. `gpg --list-secret-keys`

18. **Restore private subkeys to memory.**

    1. `gpg --import $GNUPGHOME/$KEYID.sub_priv.asc`

    2. `gpg --list-secret-keys`

19. **Move private subkeys onto Yubikey.**

    1. `gpg --expert --edit-key $KEYID`

    2. [https://blog.eleven-labs.com/en/openpgp-secret-keys-yubikey-part-2/?#export-the-keys-to-the-yubikey](https://blog.eleven-labs.com/en/openpgp-secret-keys-yubikey-part-2/#export-the-keys-to-the-yubikey)

    3. If Yubikey complains about `"gpg: selecting openpgp failed: Operation not supported by device"`, just unplug and replug Yubikey, then try again.

    4. Use the ADMIN PIN from Step 4iii.

    5. Make sure you put the right types of subkeys in the right slots!

    6. `gpg --keyid-format LONG --list-secret-keys`

    7. `gpg --card-status`

<blockquote>

    Reader ...........: Yubico Yubikey 4 OTP U2F CCID
    Application ID ...: [redacted]
    Version ..........: 2.1
    Manufacturer .....: Yubico
    Serial number ....: [redacted]
    Name of cardholder: Trishank Karthik Kuppusamy
    Language prefs ...: en
    Sex ..............: male
    URL of public key : [not set]
    Login data .......: [redacted]
    Signature PIN ....: forced
    Key attributes ...: rsa4096 rsa4096 rsa4096
    Max. PIN lengths .: 127 127 127
    PIN retry counter : 3 3 3
    Signature counter : 0
    Signature key ....: 6E7A C369 F3FD 6B74 D89F  3EA5 B4AF 1C9C 7351 8187
          created ....: 2017-11-05 21:47:07
    Encryption key....: 4DFE E3D7 AF94 C6B4 DB96  CF0B 97BF BA5F 949E 66BB
          created ....: 2017-11-05 21:46:19
    Authentication key: 02CB F034 EED6 99A6 6EB8  686A 6543 5A46 D929 EAB8
          created ....: 2017-11-05 21:47:43
    General key info..: sub  rsa4096/B4AF1C9C73518187 2017-11-05 Trishank Karthik Kuppusamy [redacted]
    sec#  rsa4096/B9D5EC8FD089F227  created: 2017-11-05  expires: 2021-11-04
    ssb>  rsa4096/97BFBA5F949E66BB  created: 2017-11-05  expires: 2018-11-05
                                    card-no: [redacted]
    ssb>  rsa4096/B4AF1C9C73518187  created: 2017-11-05  expires: 2018-11-05
                                    card-no: [redacted]
    ssb>  rsa4096/65435A46D929EAB8  created: 2017-11-05  expires: 2018-11-05
                                    card-no: [redacted]

</blockquote>

**Table 2**: `gpg --card-status`.

20. **Set trust for the master key.**

    1. It looks like we have to import our public key here again for whatever reason (see Step 13). It also looks like this step needs to be done after reboot for permanent effect.

    2. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#trust-master-key](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#trust-master-key)

21. **Enable touch protection.**

    1. Use the ADMIN PIN from Step 4iii.

    2. [https://developers.yubico.com/yubikey-manager/](https://developers.yubico.com/yubikey-manager/)

    3. `ykman openpgp touch aut on`

    4. `ykman openpgp touch enc on`

    5. `ykman openpgp touch sig on`

22. **Set up SSH agent.**

    1. Configure `gpg-agent` as in Table 3.

    2. Add the lines in Table 4a to your `bash` profile.

    3. Add the lines in Table 4b to the bottom of your `bashrc` or `zshrc`.

<blockquote>

    # https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#update-configuration
    # https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/authenticating-ssh-with-gpg.html
    enable-ssh-support
    pinentry-program /usr/local/bin/pinentry-mac
    default-cache-ttl 600
    max-cache-ttl 7200

</blockquote>

**Table 3**: `~/.gnupg/gpg-agent.conf`.

<blockquote>

    export "GPG_TTY=$(tty)"
    export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"

</blockquote>

**Table 4a**: `~/.bash_profile`.

<blockquote>

    export SSH_ENV="${HOME}/.ssh/environment"

    start_ssh_agent() {
        echo "Initialising new SSH agent..."
        ssh-agent -s | sed 's/^echo/#echo/' > ${SSH_ENV}
        echo succeeded
        chmod 600 ${SSH_ENV}
        . ${SSH_ENV} > /dev/null
        ssh-add -k;
    }

    # Source SSH settings, if applicable
    load_ssh_session() {
        if [ -f "${SSH_ENV}" ]; then
            . ${SSH_ENV} > /dev/null
            #ps ${SSH_AGENT_PID} doesn't work under cywgin
            ps aux ${SSH_AGENT_PID} | grep 'ssh-agent -s$' > /dev/null || {
                start_ssh_agent;
            }
        else
            start_ssh_agent;
        fi
    }

    load_ssh_session

</blockquote>

**Table 4b**: `~/.bashrc`.

23. **Test the keys.**

    1. Start a new `bash` shell.

    2. `echo "$(uname -a)" | gpg --encrypt --sign --armor --default-key B9D5EC8FD089F227 --recipient B4AF1C9C73518187 | gpg --decrypt --armor`

    3. Use the USER PIN from Step 4iii.

    4. Make sure to touch your Yubikey (see Step 21).

    5. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#verifying-signature](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#verifying-signature)

24. **Kill running GPG agents and restart them.**

    1. `gpgconf --kill all`

25. **Upload SSH public key to GitHub.**

    1. `ssh-add -L | grep -iF 'cardno' | pbcopy`

    2. [https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)

26. **Test GitHub SSH.**

    1. `ssh -T -vvv git@github.com`

    2. Use the USER PIN from Step 4iii.

    3. Make sure to touch your Yubikey (see Step 21).

27. **Upload GPG public key to GitHub.**

    1. `gpg --armor --export B9D5EC8FD089F227 | pbcopy`

    2. [https://help.github.com/articles/adding-a-new-gpg-key-to-your-github-account/](https://help.github.com/articles/adding-a-new-gpg-key-to-your-github-account/)

28. **Configure and test Git signing.**

    1. [https://git-scm.com/book/id/v2/Git-Tools-Signing-Your-Work](https://git-scm.com/book/id/v2/Git-Tools-Signing-Your-Work)

    2. `git config --global user.signingkey B9D5EC8FD089F227`

    3. `git config --global commit.gpgsign true`

    4. [`git config --global tag.forceSignAnnotated true`](https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/git-signing/signing-tags.html)

    5. [https://help.github.com/articles/signing-commits-using-gpg/](https://help.github.com/articles/signing-commits-using-gpg/)

    6. Use the USER PIN from Step 4iii.

    7. Make sure to touch your Yubikey (see Step 21).

29. **Optional: configure U2F for GitHub and Google.**

    1. [https://help.github.com/articles/configuring-two-factor-authentication-via-fido-u2f/](https://help.github.com/articles/configuring-two-factor-authentication-via-fido-u2f/)

    2. [https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/](https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/)

    3. Why is this optional? Because an evil maid attack gives you access to U2F-enabled services. Should not be required for people who travel with Yubikey in laptop. In any case, it's a race between the user and the attacker anyway.

30. **Optional: verify public key on Keybase.**

    1. You can now do this using the command-line option, with only `curl` and `gpg`, and without installing any Keybase app, or uploading an encrypted copy of your private key. For example, see [my profile](https://keybase.io/trishankdatadog).

31. **Reboot.**

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
