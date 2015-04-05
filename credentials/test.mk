# Contains bogus keys and certificates just so that we can go through the whole motion of signing bits
# For actual use, you need your own keys and valid certificates. see README.md

CREDENTIAL_DIR:=$(dir $(lastword $(MAKEFILE_LIST)))

# file that contains GPG passphrase
export GPG_PASSPHRASE_FILE:=$(shell echo ~/.gpg.passphrase)

export PKCS12_FILE         :=$(CREDENTIAL_DIR)test.pkcs12
export PKCS12_PASSWORD_FILE:=$(CREDENTIAL_DIR)test.pkcs12.password.txt

export KEYCHAIN_FILE         :=${CREDENTIAL_DIR}test.keychain
export KEYCHAIN_PASSWORD_FILE:=${CREDENTIAL_DIR}test.keychain.password.txt