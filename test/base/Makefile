
%.box: %.sh
	vagrant up $*
	@rm $@ 2>&1 > /dev/null || true
	vagrant package --output $@ $*

%.import: %.box
	vagrant box add --name kohsuke/$*-java $<

clean:
	vagrant destroy -f

#%.publish: %.box
#	rsync -avz $*.box www-data@boxes.jenkins-ci.org:/var/www/boxes.jenkins-ci.org/jenkins-test-$*.box
