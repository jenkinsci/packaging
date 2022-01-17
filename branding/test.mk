#
# Profile for testing release process
#
export RELEASELINE=

export PRODUCTNAME=Jenkins Test
export ARTIFACTNAME=jenkinstest
export CAMELARTIFACTNAME=JenkinsTest
export VENDOR=Jenkins Test project
export SUMMARY=Jenkins Automation Server (Test)
export PORT=7777

export MSI_PRODUCTCODE=e76baa9f-2bb2-49e5-b518-8a5b7d1cd084
export AUTHOR=Bogus user <bogus@example.org>
export LICENSE=MIT/X License, GPL/CDDL, ASL2
export HOMEPAGE=http://test.jenkins.io/
export CHANGELOG_PAGE=http://test.jenkins.io/changelog

export ORGANIZATION=example.org

# figure out the directory of this file
BRANDING_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

export DESCRIPTION_FILE=$(BRANDING_DIR)/description-file
export LICENSE_FILE=$(BRANDING_DIR)/license-mit
