test.crt: test.key test.csr apple.conf
	openssl x509 -in test.csr -out test.crt -req -signkey test.key -days 36500 -extfile apple.conf -extensions extensions

test.pkcs12: test.key test.crt
	openssl pkcs12 -export -inkey test.key -in test.crt -out test.pkcs12 -password pass:s3cr3t

# generate keychain file to go through the signing process
test.keychain: test.pkcs12
	@rm $@ 2>&1 > /dev/null || true
	security create-keychain -p s3cr3t `pwd`/test.keychain
	security import test.pkcs12 -k `pwd`/test.keychain -t agg -f pkcs12 -A -P s3cr3t

