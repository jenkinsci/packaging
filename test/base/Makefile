
%.box: Makefile %.sh
	vagrant up $*
	@rm $@ 2>&1 > /dev/null || true
	vagrant package --output $@

#%.publish: %.box
#	rsync -avz $*.box www-data@boxes.jenkins-ci.org:/var/www/boxes.jenkins-ci.org/jenkins-test-$*.box
