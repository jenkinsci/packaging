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
Export your public key & private key

    gpg --export             KEYID > test.gpg
    gpg --export --armor     KEYID > test.ascii.key
    gpg --export-secret-keys KEYID > test.secret.gpg

Verify the newly created keyring. Note that the keyring options must have some directory name parts in it, or else it's treated as they are in `~/.gnupg`

    gpg --no-default-keyring --keyring=./test.gpg --secret-keyring=./test.secret.gpg --list-keys
    gpg --no-default-keyring --keyring=./test.gpg --secret-keyring=./test.secret.gpg --list-secret-keys
