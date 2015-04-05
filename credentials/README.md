# Code-signing credentials
Different platforms want private keys and certificates in different formats.
To correctly sign all the supported formats, you need your keys in the following format:
 
* Code-signing key and certificate in PKCS12 format for Windows
* OS X keychain file that contains a valid installer signing certificate issued from Apple.
  This requires you to be a member of the Mac Developer Program. Create a separate keychain,
  add your code signing key and certificate, and use this keychain file.
* TODO: gpg key for Linux

`test.mk` contains the variable definitions to point to those files. 