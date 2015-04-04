# test.key/test.csr is a self-signed certificate for testing

# file that contains GPG passphrase
export GPG_PASSPHRASE_FILE:=$(shell echo ~/.gpg.passphrase)

export PKCS12_FILE:=$(CURDIR)/credentials/test.pkcs12
export PKCS12_PASSWORD_FILE:=$(CURDIR)/credentials/test.pkcs12.password.txt