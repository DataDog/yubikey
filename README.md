How to store private keys on a Yubikey

Author: Trishank K Kuppusamy
Date: Nov 2 2017

[[TOC]]

# Summary

GPG is useful for authenticating yourself over SSH and / or GPG-signing your git commits / tags. However, without hardware like the [Yubikey](https://www.yubico.com/products/yubikey-hardware/), you would typically keep your GPG private subkeys in "plain view" on your machine, even if encrypted. That is, attackers who personally target [[1](https://www.kennethreitz.org/essays/on-cybersecurity-and-being-targeted), [2](https://bitcoingold.org/critical-warning-nov-26/), [3](https://panic.com/blog/stolen-source-code/), [4](https://www.fox-it.com/en/insights/blogs/blog/fox-hit-cyber-attack/)] you can compromise your machine can exfiltrate your (encrypted) private key, and your passphrase, in order to pretend to be you.

Instead, this setup lets you store your private subkeys on your Yubikey. Actually, it gives you much stronger guarantees: you *cannot* authenticate over SSH and / or sign GPG commits / tags *without*: (1) your Yubikey plugged in and operational, (2) your Yubikey PIN, and (3) touching your Yubikey. So, even if there is malware trying to get you to sign, encrypt, or authenticate something, you would almost certainly notice, because your Yubikey will flash, asking for your attention. (There is the "[time of check to time of use](https://en.wikipedia.org/wiki/Time_of_check_to_time_of_use)" issue, but that is out of our scope.)

# Acknowledgements

I developed this guide while working at [Datadog](https://www.datadoghq.com/), in order to use it in various product security efforts. Thanks to Jules Denardou, Cara Marie, Cody Lee, and Santiago Torres-Arias who helped me to test these instructions. Thanks to Justin Massey for contributing the section on disabling OTP.

# Estimated burden

About 2 hours.

# Instructions

1. **Install Homebrew.**

2. **Install GPG and other preliminaries.**

    1. brew install gnupg hopenpgp-tools pinentry-mac ykman yubico-piv-tool

3. **Check the card status.**

    2. Don’t worry even if it says it supports only 3 RSA 2048-bit subkeys. We found that we could actually install 3 RSA 4096-bit subkeys.

    3. [[Consider using Ed25519 by default. GPG >= 2.1.0 supports it out-of-the-box.](https://www.google.com/url?q=https://www.gniibe.org/memo/software/gpg/keygen-25519.html&sa=D&ust=1516293904476000&usg=AFQjCNFfom7Juj5anIvf3hGAudUyEuh-7A) But probably best to go with what everyone supports (RSA).]

    4. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#insert-yubikey](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#insert-yubikey)

4. **Change card PINs and metadata.**

    5. [Since we won’t be using it here, turn off OTP](https://github.com/liyanchang/yubikey-setup/tree/edd0b7fc6b5e588c8897961ce8f5f85aa868ff1d#turn-off-otp---aka-the-random-letters-when-you-accidentally-touch-it).  Disabling it is recommended: see the explanation in the [lower part](#bookmark=id.btrorhs0mayd) of this document.

    6. [https://developers.yubico.com/PIV/Introduction/Admin_access.html](https://developers.yubico.com/PIV/Introduction/Admin_access.html)

    7. [https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/editing-metadata.html](https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/editing-metadata.html)

    8. [https://developers.yubico.com/PGP/Card_edit.html](https://developers.yubico.com/PGP/Card_edit.html)

    9. Optional: set Management key (but not PIN and PUK) via yubico-piv-tool ([https://developers.yubico.com/PIV/Guides/Device_setup.html](https://developers.yubico.com/PIV/Guides/Device_setup.html))

    10. Set the change and admin PINs.

    11. (Optional: You might want to also set the unblock and reset PINs.)

    12. (Optional: [You might want to force asking for the PIN every time you sign](https://www.andreagrandi.it/tag/yubikey.html).)

    13. Useful reset in case things go wrong: [https://developers.yubico.com/ykneo-openpgp/ResetApplet.html](https://developers.yubico.com/ykneo-openpgp/ResetApplet.html)

    14. [Looks like anyone can reset your card if they have physical access, or can compromise your machine, which is undesirable. At least you can recover from your key backup later. Ask Yubico about this. In the meantime, I am told that standard industry practice is to use two Yubikeys, with one serving as backup in case the other fails.]

    15. Store these PINs in an offline safe.

5. **Configure GPG.**

    16. See Table 1. [How future-proof are these recommendations?]

    17. [https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/#install-the-right-tools](https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/#install-the-right-tools)

    18. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#create-configuration](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#create-configuration)

<table>
  <tr>
    <td>
```
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
```
    </td>
  </tr>
</table>


**Table 1**: `~/.gnupg/gpg.conf`.

6. **Create temporary working directory for GPG.**

    19. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#create-temporary-working-directory-for-gpg](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#create-temporary-working-directory-for-gpg)

7. **Create the master key.**

    20. [Choose a long but memorable passphrase](https://www.gnupg.org/faq/gnupg-faq.html#strong_passphrase).

    21. Make sure it has only the ability to [Certify](https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/#creating-the-master-key).

    22. Make sure it expires (perhaps in a few years).

    23. Set reminder to renew key.

    24. Commit passphrase to memory and / or offline storage.

    25. [It might be much easier if we generate the keys on the Yubikey itself, and then export a backup. Upside: easier. Downside: key generation on hardware can be prone to bugs (see [the RoCA vulnerability](https://en.wikipedia.org/wiki/ROCA_vulnerability)).]

    26. [Here's [how to generate keys on Yubikeys itself](https://www.yubico.com/support/knowledge-base/categories/articles/use-yubikey-openpgp/#generateopenpgp). Either way, I STRONGLY recommend making an offline backup of your private keys (Steps 14-16).]

    27. [We should make this (on-hardware generation) the default for its ease of use, unless you are importing existing keys.]

8. **Cache the key ID (for convenience).**

    28. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#save-key-id](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#save-key-id)

9. **Create subkeys.**

    29. Make sure you know which key size your Yubikey can accommodate (see Step 3).

    30. Create a [subkey](https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1/#creating-subkeys) for only each of the following capabilities: Sign, Encrypt, Authenticate.

    31. The passphrase is the same as for the master key (see Step 8a).

    32. Make sure it expires (perhaps in 1 year).

    33. Set reminder(s) to renew subkeys.

10. **Check your list of secret keys.**

    34. `gpg --export $KEYID | hokey lint`

    35. "The output will display any problems with your key in red text. If everything is green, your key passes each of the tests. If it is red, your key has failed one of the tests."

    36. "hokey may warn (orange text) about cross certification for the authentication key. GPG's Signing Subkey Cross-Certification documentation has more detail on cross certification, and gpg v2.2.1 notes "subkey does not sign and so does not need to be cross-certified"."

    37. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#check-your-work](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#check-your-work)

11. **Create a revocation certificate (in case master key is compromised).**

    38. `gpg --output $GNUPGHOME/openpgp-revocs.d/$KEYID.rev --gen-revoke $KEYID`

    39. `less $GNUPGHOME/openpgp-revocs.d/$KEYID.rev`

12. **Export public key.**

    40. `gpg --export --armor $KEYID > $GNUPGHOME/$KEYID.pub.asc`

    41. `less $GNUPGHOME/$KEYID.pub.asc`

13. **Import public key.**

    42. `gpg --import < $GNUPGHOME/$KEYID.pub.asc`

    43. Copy this public key elsewhere for future reference.

14. **Export private master key.**

    44. `gpg --export-secret-keys --armor $KEYID > $GNUPGHOME/$KEYID.priv.asc`

    45. `less $GNUPGHOME/$KEYID.priv.asc`

15. **Export private subkeys.**

    46. `gpg --export-secret-subkeys --armor $KEYID > $GNUPGHOME/$KEYID.sub_priv.asc`

    47. The passphrase is the same as for the master key (see Step 8a).

    48. `less $GNUPGHOME/$KEYID.sub_priv.asc`

16. **Backup everything unto offline encrypted image.**

    49. Choose a good password.

    50. `hdiutil create /tmp/encrypted-gpg-backup.dmg -encryption -volname "gpg-backup" -fs APFS -srcfolder $GNUPGHOME`

    51. Move encrypted image unto offline storage.

    52. Commit password to memory and / or offline storage.

    53. Securely delete `$GNUPGHOME` (which is not straightforward on SSDs).

17. **Delete private keys from memory.**

    54. `gpg --delete-secret-key $KEYID`

    55. `gpg --list-secret-keys`

18. **Restore private subkeys to memory.**

    56. `gpg --import $GNUPGHOME/$KEYID.sub_priv.asc`

    57. `gpg --list-secret-keys`

19. **Move private subkeys onto Yubikey.**

    58. `gpg --expert --edit-key $KEYID`

    59. [https://blog.eleven-labs.com/en/openpgp-secret-keys-yubikey-part-2/?#export-the-keys-to-the-yubikey](https://blog.eleven-labs.com/en/openpgp-secret-keys-yubikey-part-2/#export-the-keys-to-the-yubikey)

    60. (If Yubikey complains about "gpg: selecting openpgp failed: Operation not supported by device", just unplug and replug Yubikey, then try again.)

    61. Use the ADMIN pin from Step 4b.

    62. Make sure you put the right types of subkeys in the right slots!

    63. `gpg --keyid-format LONG --list-secret-keys`

    64. `gpg --card-status`

<table>
  <tr>
    <td>
```
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
```
    </td>
  </tr>
</table>


**Table 2**: `gpg --card-status`.

20. **Set trust for the master key.**

    65. It looks like we have to import our public key here again for whatever reason (see Step 13). It also looks like this step needs to be done after reboot for permanent effect.

    66. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#trust-master-key](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#trust-master-key)

21. **Enable touch protection.**

    67. Use the ADMIN pin from Step 4b.

    68. [https://developers.yubico.com/yubikey-manager/](https://developers.yubico.com/yubikey-manager/)

    69. `ykman openpgp touch aut on`

    70. `ykman openpgp touch enc on`

    71. `ykman openpgp touch sig on`

22. **Set up SSH agent.**

    72. Configure `gpg-agent` as in Table 3.

    73. Add the lines in Table 4 to your bash profile.

<table>
  <tr>
    <td>
```
# https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#update-configuration
# https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/authenticating-ssh-with-gpg.html
enable-ssh-support
pinentry-program /usr/local/bin/pinentry-mac
default-cache-ttl 600
max-cache-ttl 7200</td>
```
  </tr>
</table>


**Table 3**: `~/.gnupg/gpg-agent.conf`.

<table>
  <tr>
    <td>
```
export "GPG_TTY=$(tty)"
export "SSH_AUTH_SOCK=${HOME}/.gnupg/S.gpg-agent.ssh"
```
    </td>
  </tr>
</table>


**Table 4**: `~/.bash_profile`.

23. **Test the keys.**

    74. Start a new bash shell.

    75. `echo "$(uname -a)" | gpg --encrypt --sign --armor --default-key B9D5EC8FD089F227 --recipient B4AF1C9C73518187 | gpg --decrypt --armor`

    76. Use the pin from Step 4b.

    77. Make sure to touch your Yubikey (see Step 21).

    78. [https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#verifying-signature](https://github.com/drduh/YubiKey-Guide/tree/ed1c2fdfa6300bdd6143d7e1877749f2f2fcab8e#verifying-signature)

24. **Kill running GPG agents and restart them.**

    79. `gpgconf --kill all`

25. **Upload SSH public key to GitHub.**

    80. `ssh-add -L | grep -iF 'cardno' | pbcopy`

    81. [https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)

26. **Test GitHub SSH.**

    82. `ssh -T -vvv git@github.com`

    83. Use the PIN from Step 4b.

    84. Make sure to touch your Yubikey (see Step 21).

27. **Upload GPG public key to GitHub.**

    85. `gpg --armor --export B9D5EC8FD089F227 | pbcopy`

    86. [https://help.github.com/articles/adding-a-new-gpg-key-to-your-github-account/](https://help.github.com/articles/adding-a-new-gpg-key-to-your-github-account/)

28. **Configure and t****est Git signing.**

    87. [https://git-scm.com/book/id/v2/Git-Tools-Signing-Your-Work](https://git-scm.com/book/id/v2/Git-Tools-Signing-Your-Work)

    88. `git config --global user.signingkey B9D5EC8FD089F227`

    89. `git config --global commit.gpgsign true`

    90. [git config --global tag.forceSignAnnotated true](https://ruimarinho.gitbooks.io/yubikey-handbook/content/openpgp/git-signing/signing-tags.html)

    91. [https://help.github.com/articles/signing-commits-using-gpg/](https://help.github.com/articles/signing-commits-using-gpg/)

    92. Use the PIN from Step 4b.

    93. Make sure to touch your Yubikey (see Step 21).

29. **Optional: configure U2F for GitHub and Google.**

    94. [https://help.github.com/articles/configuring-two-factor-authentication-via-fido-u2f/](https://help.github.com/articles/configuring-two-factor-authentication-via-fido-u2f/)

    95. [https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/](https://www.yubico.com/support/knowledge-base/categories/articles/how-to-use-your-yubikey-with-google/)

    96. (Why is this optional? Because an evil maid attack gives you access to U2F-enabled services. Should not be required for people who travel with Yubikey in laptop. In any case, it's a race between the user and the attacker anyway.)

30. **Reboot.**

# VMware Fusion

31. **Optional: using Yubikey inside GNU/Linux running on VMware Fusion.**

    97. Shut down your VM, find its .vmx file, edit the file to the [add the following line](https://www.symantec.com/connect/blogs/enabling-hid-devices-such-usb-keyboards-barcode-scanners-vmware), and then reboot it: `usb.generic.allowHID = "TRUE"`

    98. Connect your Yubikey to the VM once you have booted and logged in.

    99. Install libraries for smart card:

        1. Ubuntu 17.10: `apt install scdaemon`

        2. Fedora 27: `dnf install pcsc-lite pcsc-lite-ccid`

    100. Import your public key (see Step 13).

    101. Set ultimate trust for your key (see Step 20).

    102. Configure GPG (see Step 22).

    103. Test the keys (see Step 23).

        3. On Fedora, make sure to replace `gpg` with `gpg2`.

    104. Use the absolutely terrible kludge in Table 5 to make SSH work.

    105. Spawn a new shell, and test GitHub SSH (see Step 26).

    106. Test Git signing (see Step 28).

        4. On Fedora, make sure to replace `gpg` with `gpg2`: `git config --global gpg.program gpg2`

<table>
  <tr>
    <td>
```
# gpg-ssh hack
gpg-connect-agent killagent /bye
eval $(gpg-agent --daemon --enable-ssh-support --sh)
ssh-add -l
```
    </td>
  </tr>
</table>


**Table 5**: Add these lines to `~/.bashrc`.

# Docker Content Trust

32. **Optional: using Yubikey to store the root role key for Docker Notary.**

    107. Assumption: you are running all of the following under Fedora 27 (see Step 31).

    108. Install prerequisites:

        5. `dnf install golang yubico-piv-tool`

    109. Set [GOPATH](https://golang.org/doc/code.html#GOPATH) (make sure to update PATH too), and spawn a new bash shell.

    110. Check out the Notary source code:

        6. `go get github.com/theupdateframework/notary`

    111. Patch source code to [point to correct location of shared library on Fedora](https://github.com/theupdateframework/notary/pull/1286).

        7. `cd ~/go/src/go get github.com/theupdateframework/notary`

        8. `git pull https://github.com/trishankatdatadog/notary.git trishank_kuppusamy/fedora-pkcs11`

    112. [Build and install](https://github.com/theupdateframework/notary/pull/1285) the Notary client.

        9. `go install -tags pkcs11 github.com/theupdateframework/notary/cmd/notary`

    113. Add the lines in Table 6 to your bash profile, and spawn a new bash shell.

    114. Try listing keys (there should be no signing keys as yet):

        10. `dockernotary key list -D`

        11. If you see the line `"DEBU[0000] Initialized PKCS11 library /usr/lib64/libykcs11.so.1 and started HSM session"`, then we are in business.

        12. Otherwise, if you see the line `"DEBU[0000] No yubikey found, using alternative key storage: found library /usr/lib64/libykcs11.so.1, but initialize error pkcs11: 0x6: CKR_FUNCTION_FAILED"`, then you probably need to `gpgconf --kill scdaemon` ([see this issue](https://github.com/theupdateframework/notary/issues/1006)), and try again.

    115. Generate the root role key ([can be reused across multiple Docker repositories](https://github.com/theupdateframework/notary/blame/a41821feaf59a28c1d8f78799300d26f8bdf8b0d/docs/best_practices.md#L91-L95)), and export it to both Yubikey, and keep a copy on disk:

        13. Choose a strong passphrase.

        14. `dockernotary key generate -D`

        15. Commit passphrase to memory and / or offline storage.

        16. Try listing keys again, you should now see a copy of the same private key in two places (disk, and Yubikey).

        17. Backup private key in `~/.docker/trust/private/KEYID.key` unto offline, encrypted, long-term storage.

        18. [Securely delete](https://www.gnu.org/software/coreutils/manual/html_node/shred-invocation.html) this private key on disk.

        19. Now if you list the keys again, you should see the private key only on Yubikey.

    116. Link the yubikey library so that the prebuilt docker client can find it.

        20. `sudo ln -s /usr/lib64/libykcs11.so.1 /usr/local/lib/libykcs11.so`

    117. Later, when you want Docker to use the root role key on your Yubikey:

        21. When you push an image, you may have to kill `scdaemon` (in a separate shell) right after Docker pushes, but right before Docker uses the root role key on your Yubikey, and generates a new targets key for the repository.

        22. Use `docker -D` to find out exactly when to do this.

        23. This is annoying, but it works.

<table>
  <tr>
    <td>
```
# docker notary stuff
alias dockernotary="notary -s https://notary.docker.io -d ~/.docker/trust"
# always be using content trust
export DOCKER_CONTENT_TRUST=1
```
    </td>
  </tr>
</table>


**Table 6**: Add these lines to `~/.bashrc`.

# Why Disable OTP?

OTPs are vulnerable to replay attack. To first understand the attack scenario, one must understand how the OTPs are generated (Source and full explanation here: [https://developers.yubico.com/OTP/OTPs_Explained.html](https://developers.yubico.com/OTP/OTPs_Explained.html))

1. When a OTP is generated by the Yubikey, it outputs a 44 character value.

    1. Ex: `cccjgjgkhcbbirdrfdnlnghhfgrtnnlgedjlftrbdeut`

    2. The first 12 characters represent the public ID of the Yubikey and remain constant. The remaining 32 characters represent a unique token that includes **a counter**.

        1. The counter part is the most important piece of why one should disable OTP.

2. When the user submits the OTP to an IDP:

    3. The IdP validates the unique ID is associated with the user account.

    4. The IdP decrypts the token with a pre-shared AES key, proving that the user is who they say they are.

    5. The IdP then check the counter to ensure it is greater than the last token **they are aware of**.

    6. The IdP updates the counter so that this token and all previous tokens cannot be replayed.

Attack Scenarios:

1. Scenario 1 - Fake IdP

    1. An attacker sets up a fake IdP.

    2. Attacker directs a benign user to this fake IdP.

    3. The user uses the OTP to authenticate to the fake IdP.

    4. The attacker can now replay this token because it’s counter will be greater than the one known to the legitimate IdP.

2. Scenario 2 - Malicious or Compromised IdP

    5. Prerequisite: The IdP is compromised by an attacker or the IdP has malicious intentions:

    6. The IdP can capture the most recently used token and replay it on any other IdP the Yubikey device is associated with. Furthermore, this token is valid on **ALL** other IdPs until a newer token has been used to increment the counter in the IdPs database.

3. Scenario 3 - YubiSpam

    7. It is not uncommon for the user to accidentally share an OTP token by pressing the Yubikey. This assumes the default short click is configured for OTP on Yubikey.

    8. A malicious user sees the OTP and can use this OTP token on **ALL** associated IdPs until a newer token has been used to increment the counter in the IdPs database.

# TODO

1. Automate, automate, automate as much as possible (e.g., using bash and expect scripts).

2. Instructions for revoking and / or replacing keys.

3. [Solving the PGP Revocation Problem with OpenTimestamps for Git Commits](https://petertodd.org/2016/opentimestamps-git-integration).

4. Upload public key to Keybase.

5. Procedures for recovering from key compromise / theft / loss.

6. [Setup NFC 2FA](https://ocramius.github.io/blog/yubikey-for-ssh-gpg-git-and-local-login/) (downside: would not work out-of-the-box on iPhones as yet).

7. [Setup PAM authentication](https://ocramius.github.io/blog/yubikey-for-ssh-gpg-git-and-local-login/) (downside: can get locked out of laptop).

# Troubleshooting

* If you are blocked out of using GPG because you entered your PIN wrong too many times (3x by default), **don’t panic**: just [follow the instructions](https://github.com/ruimarinho/yubikey-handbook/blob/master/openpgp/troubleshooting/gpg-failed-to-sign-the-data.md) here.

* If you suddenly start getting `Permission denied (publickey)`, verify that `ssh-agent` is not running. If `ssh-agent` is running, kill the process. If the error persists, use the kludge in Table 5.

* If you are having issues failing to make connections, you still need to have `ssh-agent` running along with `gpg-agent`: `eval $(ssh-agent -s)`

# Changelog

* 2018-01-10: Make U2F optional for those (e.g., frequent flyers) worried about evil maid attack. Also turn off OTP.

* 2018-01-04: Added instructions on how to use Yubikey with Docker Notary (see Step 32).

# References

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
