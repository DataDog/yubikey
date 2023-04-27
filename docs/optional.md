# Optional

- [Configure another computer to use a configured YubiKey](#configure-another-computer-to-use-a-configured-yubikey)
- [Signing for different git repositories with different keys](#signing-for-different-git-repositories-with-different-keys)
- [Keybase](#keybase)
- [VMware Fusion](#vmware-fusion)
- [Docker Content Trust](#docker-content-trust)

## Configure another computer to use a configured YubiKey

You don't need to do anything extra if you have not set up GPG and SSH to your use YubiKey.

Otherwise, you need to:

On your previous computer:
1. Get the Yubikey GPG key ID by running `gpg --list-keys`, in the following example the key ID is `4E09860E71D948019BD426D5D099A306DBECDF1B`
![image](https://user-images.githubusercontent.com/4062883/148108677-ab3a04b4-8ef6-4ba0-b78e-ec9c127857e3.png)
2. Get a copy of your Yubikey GPG public key (this might have been backed up in your password manager) by running `gpg --export --armor key_id > /path/to/pubkey.asc`, so in our example it will be `gpg --export --armor 4E09860E71D948019BD426D5D099A306DBECDF1B > pubkey.asc`.
3. (Optional) Write your copy of your GPG public key stored in your password manager to disk if not already there (e.g., to `/path/to/pubkey.asc`).

On the new computer:
1. Get the pubkey.asc file on the disk by downloading it
2. Run [`./import.sh -p /path/to/pubkey.asc -i key_id`](../import.sh). In our example, `./import.sh -p ~/pubkey.asc -i 4E09860E71D948019BD426D5D099A306DBECDF1B`
3. You will be prompted several times:
    1. To install dependencies (required), type yes, and press enter
    2. To configure the Yubikey GPG key for commit signing (or not), type yes or no, and press enter
    3. To use the Yubikey GPG key for SSH connections (or not), type yes or no, and press enter

## Signing for different git repositories with different keys

The script can setup your Git installation so that all your commits and tags
will be signed by default with the key contained in the YubiKey. We
**strongly** recommend that you turn on this option. If you have done so,
please stop reading here.

Otherwise, one reason for declining this option may be that you wish to sign
for different repositories with different keys. There are a few ways to handle
this. Perhaps the simplest is to let the script assign the YubiKey to all git
repositories, and then use `git config --local` to override `user.signingkey`
for different repositories.

Alternatively, let us say you use your personal key for open source projects,
and the one in the YubiKey for Datadog proprietary code. One possible
solution is to setup git aliases. First, make sure signing is turned on
globally:

```sh
git config --global commit.gpgsign true
git config --global tag.forceSignAnnotated true
```

Then you can tell git to use a specific key by default, depending on which one
is the one you use the most:

```sh
git config --global user.signingkey <id_of_the_key_you_want_to_use_by_default>
```

You can alias the `commit` command to override the default key and use another
one to sign that specific commit:

```sh
git config --global alias.dd-commit '-c user.signingkey=<id_of_the_yubikey_key> commit'
git config --global alias.dd-tag '-c user.signingkey=<id_of_the_yubikey_key> tag'
```

With this setup, every time you do `git commit` or `git tag`, the default key
will be used while `git dd-commit` and `git dd-tag` will use the one in the
YubiKey.

## Keybase

Optional: verify public key on Keybase.  You can now do this using the
command-line option, with only `curl` and `gpg`, and without installing any
Keybase app, or uploading an encrypted copy of your private key. For example,
see this [profile](https://keybase.io/trishankdatadog).

If you have the [Keybase application](https://keybase.io/docs/the_app/install_macos)
installed, you can import your YubiKey public key like this:

```bash
$ keybase pgp select

# If you already have a primary Keybase public key, use the --multi flag to import another
$ keybase pgp select --multi
```

See `keybase pgp help select` for more detail.

## VMware Fusion

Optional: using YubiKey inside GNU/Linux running on VMware Fusion.

1. Shut down your VM, find its .vmx file, edit the file to the [add the
   following
   line](https://www.symantec.com/connect/blogs/enabling-hid-devices-such-usb-keyboards-barcode-scanners-vmware),
   and then reboot it: `usb.generic.allowHID = "TRUE"`

2. Connect your YubiKey to the VM once you have booted and logged in.

3. Install libraries for smart card:

    1. Ubuntu 17.10: `apt install scdaemon`

    2. Fedora 27: `dnf install pcsc-lite pcsc-lite-ccid`

4. Import your public key (see Step 13).

5. Set ultimate trust for your key (see Step 20).

6. Configure GPG (see Step 22).

7. Test the keys (see Step 23). On Fedora, make sure to replace `gpg` with
   `gpg2`.

8. Use the absolutely terrible kludge in Table 1 to make SSH work.

9. Spawn a new shell, and test GitHub SSH (see Step 26).

10. Test Git signing (see Step 28). On Fedora, make sure to replace `gpg` with
    `gpg2`: `git config --global gpg.program gpg2`

```sh
    # gpg-ssh hack
    gpg-connect-agent killagent /bye
    eval $(gpg-agent --daemon --enable-ssh-support --sh)
    ssh-add -l
```

**Table 1**: Add these lines to `~/.bashrc`.

## Docker Content Trust

Optional: using YubiKey to store the root role key for Docker Notary.

1. Assumption: you are running all of the following under [Fedora
   27](#vmware-fusion).

2. Install prerequisites: `dnf install golang yubico-piv-tool`

3. Set [GOPATH](https://golang.org/doc/code.html#GOPATH) (make sure to update
   PATH too), and spawn a new `bash` shell.

4. Check out the Notary source code: `go get
   github.com/theupdateframework/notary`

5. Patch source code to [point to correct location of shared library on
   Fedora](https://github.com/theupdateframework/notary/pull/1286).

    1. `cd ~/go/src/go get github.com/theupdateframework/notary`

    2. `git pull https://github.com/trishankatdatadog/notary.git trishank_kuppusamy/fedora-pkcs11`

6. [Build and install](https://github.com/theupdateframework/notary/pull/1285)
   the Notary client: `go install -tags pkcs11
   github.com/theupdateframework/notary/cmd/notary`

7. Add the lines in Table 2 to your `bash` profile, and spawn a new shell.

8. Try listing keys (there should be no signing keys as yet):

    1. `dockernotary key list -D`

    2. If you see the line `"DEBU[0000] Initialized PKCS11 library
       /usr/lib64/libykcs11.so.1 and started HSM session"`, then we are in
       business.

    3. Otherwise, if you see the line `"DEBU[0000] No yubikey found, using
       alternative key storage: found library /usr/lib64/libykcs11.so.1, but
       initialize error pkcs11: 0x6: CKR_FUNCTION_FAILED"`, then you probably
       need to `gpgconf --kill scdaemon` ([see this
           issue](https://github.com/theupdateframework/notary/issues/1006)),
       and try again.

9. Generate the root role key ([can be reused across multiple Docker
   repositories](https://github.com/theupdateframework/notary/blame/a41821feaf59a28c1d8f78799300d26f8bdf8b0d/docs/best_practices.md#L91-L95)),
and export it to both YubiKey, and keep a copy on disk:

    1. Choose a strong passphrase.

    2. `dockernotary key generate -D`

    3. Commit passphrase to memory and / or offline storage.

    4. Try listing keys again, you should now see a copy of the same private
       key in two places (disk, and YubiKey).

    5. Backup private key in `~/.docker/trust/private/KEYID.key` unto offline,
       encrypted, long-term storage.

    6. [Securely
       delete](https://www.gnu.org/software/coreutils/manual/html_node/shred-invocation.html)
       this private key on disk.

    7. Now if you list the keys again, you should see the private key only on
       YubiKey.

10. Link the yubikey library so that the prebuilt docker client can find it:
    `sudo ln -s /usr/lib64/libykcs11.so.1 /usr/local/lib/libykcs11.so`

11. Later, when you want Docker to use the root role key on your YubiKey:

    1. When you push an image, you may have to kill `scdaemon` (in a separate
       shell) right after Docker pushes, but right before Docker uses the root
    role key on your YubiKey, and generates a new targets key for the
    repository.

    2. Use `docker -D` to find out exactly when to do this.

    3. This is annoying, but it works.

```sh
    # docker notary stuff
    alias dockernotary="notary -s https://notary.docker.io -d ~/.docker/trust"
    # always be using content trust
    export DOCKER_CONTENT_TRUST=1
```

**Table 2**: Add these lines to `~/.bashrc`.
