#!/bin/bash -ex
bin="$(dirname $0)"

sudo apt-get install apt-utils

ssh $PKGSERVER mkdir -p $DEBDIR/
rsync -avz "${DEB}" $PKGSERVER:$DEBDIR/

# build package index
# see http://wiki.debian.org/SecureApt for more details
rm -rf binary || true
mkdir binary > /dev/null 2>&1 || true
cp "${DEB}" binary
apt-ftparchive packages binary > binary/Packages
apt-ftparchive contents binary > binary/Contents

# merge the result
pushd binary
  mvn org.kohsuke:apt-ftparchive-merge:1.2:merge -Durl=$DEB_URL/binary/ -Dout=../merged
popd

cat merged/Packages > binary/Packages
cat merged/Packages | gzip -9c > binary/Packages.gz
cat merged/Packages | bzip2 > binary/Packages.bz2
cat merged/Packages | lzma > binary/Packages.lzma
cat merged/Contents | gzip -9c > binary/Contents.gz
apt-ftparchive -c debian/release.conf release  binary > binary/Release
# sign the release file
rm binary/Release.gpg || true
gpg --no-use-agent --passphrase-file ~/.gpg.passphrase -abs -o binary/Release.gpg binary/Release

# generate web index
$bin/gen.rb > $bin/contents/index.html
echo "#GENERATED" > $bin/contents/.htaccess
if $OSS_JENKINS; then
  sed -e "s/@RELEASELINE@/${RELEASELINE}/g" < $bin/htaccess >> $bin/contents/.htaccess
fi
cp binary/Packages.* binary/Release binary/Release.gpg binary/Contents.gz $bin/contents/binary

rsync -avz $bin/contents/ $PKGSERVER:$DEB_WEBDIR
