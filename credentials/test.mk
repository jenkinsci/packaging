# Contains bogus GPG keys just so that we can go through the whole motion of signing bits
# For actual use, you need your own keys. see README.md

CREDENTIAL_DIR:=$(abspath $(dir $(lastword $(MAKEFILE_LIST))))/

export GPG_KEYRING :=${CREDENTIAL_DIR}test.gpg
export GPG_PUBLIC_KEY :=${CREDENTIAL_DIR}test.ascii.key
export GPG_SECRET_KEYRING :=${CREDENTIAL_DIR}test.secret.gpg
# file that contains GPG passphrase
export GPG_PASSPHRASE_FILE:=$(CREDENTIAL_DIR)test.gpg.password.txt
