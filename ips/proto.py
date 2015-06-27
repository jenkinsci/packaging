@@LICENSE_TEXT_COMMENTED@@


# definition of the IPS package.
# see https://wikis.oracle.com/display/IpsBestPractices/Producing+and+Maintaining+Packages for more about this

import builder;

# IPS can't do SNAPSHOT
version = builder.props['version']
if version.endswith("-SNAPSHOT"):
    version = version[:-9];

pkg = builder.build_pkg(name="jenkins", version=version+",0-0")
pkg.update({
    "attributes"    : { 
        "pkg.summary" : "Jenkins", 
        "pkg.description" : "Extensible continuous integration system",
    }
})


# restart_fmri instructs IPS to reload the manifest
pkg.addfile("/usr/local/bin/jenkins.war",{"file":"./target/jenkins.war"})
pkg.addfile("/var/svc/manifest/application/jenkins.xml",{"file":"../ips/jenkins.xml","restart_fmri":"svc:/system/manifest-import:default"})
# this is the Hudson home directory
pkg.mkdirs("/var/lib/jenkins")

# TODO: register SMF when the feature is available?
# see http://www.pauloswald.com/article/29/hudson-solaris-smf-manifest
# see http://blogs.sun.com/wittyman/entry/postgresql_packages_from_ips_repository
