// Full installer test flow, in one file
// You must parameterize the build with: 

// @stringparameter dockerLabel (node label for docker nodes)
// @stringparameter packagingBranch - branch to use in packaging build

// **ARTIFACTS URLS**
// Note: you can use an artifact archived in a Job build by an artifact:// URL
//  Ex: 'artifact://full/path/to/job/buildNr#artifact.ext'
// @stringparameter debfile URL to Debian package
// @stringparameter rpmfile URL to CentOS/RHEL RPM package
// @stringparameter susefile URL to SUSE RPM package
// @stringparameter testLibraryBranch branchname to load the installertests workflow lib from

// Optional build parameters
// @stringparameter (optional) port - port number to use in testing jenkins (default 8080)
// @stringparameter (optional) artifact (jenkins artifactname, defaults to 'jenkins')

// Basic parameters
String dockerLabel = 'ubuntu-ope01'
String packagingBranch = 'feature-docker-test-env-fixes'
String artifactname = (artifact == null ) ? 'jenkins' : artifact
String jenkinsPort = (port == null ) ? '8080' : "$port"

// Set up
String scriptPath = 'packaging-docker/installtests'
String checkCmd = "sudo $scriptPath/service-check.sh $artifactname $jenkinsPort"

// Core tests represent the basic supported linuxes, extended tests build out coverage further
def coreTests = []
def extendedTests = []
coreTests[0]=["sudo-ubuntu:14.04",  ["sudo $scriptPath/debian.sh installers/deb/*.deb", checkCmd]]
coreTests[1]=["sudo-centos:7",      ["sudo $scriptPath/centos.sh installers/rpm/*.rpm", checkCmd]]
coreTests[2]=["sudo-opensuse:13.2", ["sudo $scriptPath/suse.sh installers/suse/*.rpm", checkCmd]]
extendedTests[0]=["sudo-debian:wheezy", ["sudo $scriptPath/debian.sh installers/deb/*.deb", checkCmd]]
extendedTests[1]=["sudo-centos:6",      ["sudo $scriptPath/centos.sh installers/rpm/*.rpm", checkCmd]]
extendedTests[2]=["sudo-ubuntu:15.10",  ["sudo $scriptPath/debian.sh installers/deb/*.deb", checkCmd]]

node(dockerLabel) {
    stage "Load Lib"
    sh 'rm -rf workflowlib'
    dir ('workflowlib') {
        git branch: testLibraryBranch, url: 'https://github.com/jenkinsci/packaging.git'
        flow = load 'workflow/installertest.groovy'
    }
    

    stage 'Fetch Installer'
    flow.fetch_installers(debfile, rpmfile, susefile)
    
    sh 'rm -rf packaging-docker'
    dir('packaging-docker') {
      git branch: packagingBranch, url: 'https://github.com/jenkinsci/packaging.git'
    }
    
    // Build the sudo dockerfiles
    stage 'Build sudo dockerfiles'
    withEnv(['HOME='+pwd()]) {
        sh 'packaging-docker/docker/build-sudo-images.sh'
    }
    
    stage 'Run Installation Tests'
    String[] stepNames = ['install', 'servicecheck']
    flow.execute_install_testset(coreTests, stepNames)
    flow.execute_install_testset(extendedTests, stepNames)
}