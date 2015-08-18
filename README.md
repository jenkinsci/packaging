# Native package script for Jenkins
This repository contains scripts for packaging `jenkins.war` into various platform-specific native packages.
The following platforms are currently supported:

  * Windows MSI: `msi/`
  * RedHat/CentOS RPM: `rpm/`
  * Debian/Ubuntu DEB: `deb/`
  * OS X PKG: `osx/`
  * OpenSUSE RPM: `suse/`

# Pre-requisites
Running the main package script requires a Linux environment (currently Ubuntu, see [JENKINS-27744](https://issues.jenkins-ci.org/browse/JENKINS-27744).)
Run `make setup` to install necessary tools.  Alternatively you can manually install the following onto a base install of Ubuntu:
* make
* unzip
* devscripts
* debhelper
* rpm
* expect
* createrepo

You also need a Jenkins instance with [dist-fork plugin](https://wiki.jenkins-ci.org/display/JENKINS/DistFork+Plugin)
installed. URL of this Jenkins can be fed into `make` via the `JENKINS_URL` variable.
This Jenkins needs to have an OSX build agent that has PackageMaker, and Windows build agent whose
pre-requisites need to be clarified. These two build agents are used to build OSX and MSI packages, which
can be only built on native platforms.

You'll also need a `jenkins.war` file that you are packaging, which comes from the release process.
The location of this file is set via the `WAR` variable.

# Generating packages
Run `make package` to build all the native packages.
At minimum, you have to specify the `WAR` variable that points to the war file to be packaged and a branding file (for licensing and package descriptions). 
You will probably need to pass in the build environment and credentials.

For example:
```shell
make package BRAND=./branding/jenkins.mk BUILDENV=./env/test.mk CREDENTIAL=./credentials/test.mk
```

Packages will be placed into `target/` directory.
See the definition of the `package` goal for how to build individual packages selectively.

# Publishing packages
This repository contains scripts for copying packages over to a remote web server to publish them.
Run `make publish` to publish all native packages.

See the definition of the `publish` goal for individual package publishment.

# Running tests
Once packages are published, you can run tests to see if they install correctly.
Tests are written with VirtualBox + serverspec. You must have `vagrant-serverspec` plugin 1.0.1 or later.

Run `make test` to run all the tests. `test` goal doesn't declare dependency on `publish` goal,
so run `make publish test` if you need to rebuild packages.

To test just one package, `make FLAVOR.test` where FLAVOR is one of rpm, deb, or suse.

The installation of the package is often time consuming, and you can invoke it with `make FLAVOR.test.up`
Once you do that, you can just rerun serverspec tests with `make FLAVOR.test.run`. When all is done,
run `make FLAVOR.test.destroy` to terminate VirtualBox VMs.

## Running local tests
These tests install packages from a web server where they are published. So if you want to
run tests prior to publishing them, you need to create a temporary web server that you can mess up.

The default branding & environment (`branding/test.mk` and `env/test.mk`) are designed to support
this scenario. To make local testing work, you also need to have `/etc/hosts` entry that maps
`test.pkg.jenkins-ci.org` hostname to `127.0.0.1`, and your computer has to be running ssh that
lets you login as you.

Once you verified the above prerequisites, open another terminal and run `make test.local.setup`
This will run a docker container that acts as your throw-away package web server. When done, Ctrl+C
to kill it.

# Branding
`branding/` directory contains `*.mk` files that control the branding of the generated packages.
It also include text files which are used for large, branded text blocks (license and descriptions).
Specify the branding file via the `BRAND` variable.

You can create your own branding definition to customize the package generation process.
See [branding readme](branding/README.md) for more details. In the rest of the packaging script files,
these branding parameters are referenced via `@@NAME@@` and get substituted by `bin/branding.sh`

# Environment
`env/` directory contains `*.mk` files that control the environment into which
you publish packages.  Specify the environment file via the `BUILDENV` variable.

You can create your own environment definition to customize the package generation process.
See [environment readme](env/README.md) for more details.

# Credentials
`credentials/` directory contains `test.mk` file that controls the locations of code-signing keys,
their passwords, and certificates. Specify the credentials file via the `CREDENTIAL` variable.

For production use, you need to create your own credentials file. See [credentials readme](credentials/README.md)
for more details.

# TODO (mostly note to myself)
* Split resource templates to enable customization
