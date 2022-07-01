# Code-signing credentials
Different platforms want private keys and certificates in different formats.
To correctly sign all the supported formats, you need your keys in the following format:
 
* Code-signing key and certificate in PKCS12 format for Windows
* OS X keychain file that contains a valid installer signing certificate issued from Apple.
  This requires you to be a member of the Mac Developer Program. Create a separate keychain,
  add your code signing key and certificate, and use this keychain file.
* GPG secret/public keypair in separate GPG public keyring and GPG secret keyring.  

`test.mk` contains the variable definitions to point to those files.

## Creating your own GPG key

Generate a new GPG key with `gpg --full-generate-key`:

* When asked what kind of key you want, select "(1) RSA and RSA (default)".
* When asked what key size you want, enter "4096" bits.
* When asked how long the key should be valid, enter "0" (key does not expire).
* When asked for your real name, enter "Bogus Test".
* When asked for your email address, enter "noreply@jenkins-ci.org".
* When asked for a comment, enter "This is test only key".
* When asked for the secret password, enter the password from `test.gpg.password.txt`.

Export your public key & private key

    gpg --export             KEYID > test.gpg
    gpg --export --armor     KEYID > test.ascii.key
    gpg --export-secret-keys KEYID > test.secret.gpg
    cat test.gpg >sandbox.gpg
    cat test.secret.gpg >>sandbox.gpg

Verify the newly created keyring. Note that the keyring options must have some directory name parts in it, or else it's treated as they are in `~/.gnupg`

    gpg --no-default-keyring --keyring=./test.gpg --secret-keyring=./test.secret.gpg --list-keys
    gpg --no-default-keyring --keyring=./test.gpg --secret-keyring=./test.secret.gpg --list-secret-keys
