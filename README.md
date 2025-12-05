# Native package script for Jenkins

This repository contains scripts for packaging `jenkins.war` into various platform-specific native packages.
The following platforms are currently supported:

  * Windows MSI: `msi/`
  * RedHat/CentOS RPM: `rpm/`
  * Debian/Ubuntu DEB: `deb/`
  * OpenSUSE RPM: `suse/`

# Pre-requisites
Running the main package script requires a Linux environment (currently Ubuntu, see [JENKINS-27744](https://issues.jenkins-ci.org/browse/JENKINS-27744).)
Run `make setup` to install (most of the) necessary tools.  Alternatively you can manually install the following onto a base install of Ubuntu:
* make
* unzip
* devscripts
* debhelper
* rpm
* expect
* createrepo-c
* ruby
  * net-sftp  (`gem install net-sftp`)
* maven
* java

You also need a Jenkins instance with [dist-fork plugin](https://wiki.jenkins-ci.org/display/JENKINS/DistFork+Plugin)
installed. URL of this Jenkins can be fed into `make` via the `JENKINS_URL` variable.
This Jenkins needs to have a Windows build agent that has [WiX Toolset](http://wixtoolset.org/) (currently 3.5), msbuild, [cygwin](https://www.cygwin.com/) and .net 2.0. This build agent is used to build MSI packages, which
can be only built on Windows.

You'll also need a `jenkins.war` file that you are packaging, which comes from the release process.
The location of this file is set via the `WAR` variable.

Remark:

A docker image is available to run following script

[![logo](https://img.shields.io/docker/pulls/jenkinsciinfra/packaging?label=jenkinsciinfra%2Fpackaging&logo=docker&logoColor=white)](https://hub.docker.com/r/jenkinsciinfra/packaging)

Run `docker-compose run --rm packaging bash` to get a shell in the official Docker image for this repository.

# Generating packages
Run `./prep.sh` to perform the preparatory actions of downloading the WAR and importing the GPG key.
Run `make package` to build all the native packages.
At minimum, you have to specify the `WAR` variable that points to the war file to be packaged and the `BRAND` variable that points to the branding file for licensing, artifact names, and package descriptions.
If a branding file is not provided, the branding/test.mk file is used with the artifact names and package descriptions it provides.
You will probably need to pass in the build environment and credentials.

For example:
```shell
make package BRAND=./branding/jenkins.mk BUILDENV=./env/test.mk CREDENTIAL=./credentials/test.mk
```

Packages will be placed into `target/` directory.
See the definition of the `package` goal for how to build individual packages selectively.

# Running functional tests

The functional tests require Python 3 and Docker.
Having built the packages as described above, run the functional tests with:

```shell
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
molecule test
deactivate
```

# Publishing packages
This repository contains scripts for copying packages over to a remote web server to publish them.
Run `make publish` to publish all native packages.

See the definition of the `publish` goal for individual package publishment.

## Running local tests
These tests install packages from a web server where they are published. So if you want to
run tests prior to publishing them, you need to create a temporary web server that you can mess up.

The default branding & environment (`branding/test.mk` and `env/test.mk`) are designed to support
this scenario. To make local testing work, you also need to have `/etc/hosts` entry that maps
`test.pkg.jenkins.io` hostname to `127.0.0.1`, and your computer has to be running ssh that
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
these branding parameters are referenced via `@@NAME@@` and get substituted by `bin/branding.py`.
To escape a string normally like @@VALUE@@, add an additional two @@ symbols as a prefix: @@@@VALUE@@.

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
