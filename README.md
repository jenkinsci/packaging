# Native package script for Jenkins
This repository contains scripts for packaging `jenkins.war` into various platform-specific native packages.
The following platforms are currently supported:

  * Windows MSI: `msi/`
  * RedHat/CentOS RPM: `rpm/`
  * Debian/Ubuntu DEB: `debian/`
  * OS X PKG: `osx/`
  * OpenSUSE RPM: `suse/`

# Pre-requisites
Running the main package script requires a Linux environment (currently Ubuntu, see [JENKINS-27744](https://issues.jenkins-ci.org/browse/JENKINS-27744).)
Run `make setup` to install necessary tools.

You also need a Jenkins instance with [dist-fork plugin](https://wiki.jenkins-ci.org/display/JENKINS/DistFork+Plugin)
installed. This Jenkins needs to have an OSX build agent that has PackageMaker, and Windows build agent whose
pre-requisites need to be clarified. These two build agents are used to build OSX and MSI packages, which
can be only built on native platforms.

You'll also need a `jenkins.war` file that you are packaging, which comes from the release process.

# Generating packages
Run `make package` to build all the native packages.
At minimum, you have to specify the `WAR` variable that points to the war file to be packaged.

Packages will be placed into `build/` directory.
See the definition of the `package` goal for how to build individual packages selectively.

# Deploying packages
This repository contains scripts for copying packages over to a remote web server to publish them.
Run `make deploy` to publish all native packages.

See the definition of the `deploy` goal for individual package deployment.

# Customizing
* `branding/` directory contains `*.mk` files controls the branding of the generated packages.
  You can create your own branding definition to customize the package generation process.
  See [branding readme](branding/README.md) for more details.

# TODO (mostly note to myself)
* Split resource templates to enable customization
* `OSS_JENKINS` switch must die, which means we need more pluggability