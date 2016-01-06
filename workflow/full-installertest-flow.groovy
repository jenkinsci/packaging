// Full installer test flow, in one file
// You must parameterize the build with: 

// @stringparameter dockerLabel (node label for docker nodes) - MUST be set, otherwise it'll try to run on master...

// **ARTIFACTS URLS - REQUIRED**
// Note: you can use an artifact archived in a Job build by an artifact:// URL
//  Ex: 'artifact://full/path/to/job/buildNr#artifact.ext'
// @stringparameter debfile URL to Debian package
// @stringparameter rpmfile URL to CentOS/RHEL RPM package
// @stringparameter susefile URL to SUSE RPM package

// Optional build parameters
// @stringparameter (optional) packagingTestBranch - branch in packaging repo to use for the workflow 
//      & the installer tests. (defaults to master)
// @stringparameter (optional) jenkinsPort - port number to use in testing jenkins (defaults 8080)
// @stringparameter (optional) artifactName - (jenkins artifactname, defaults to 'jenkins')

// Basic parameters
String packagingTestBranch = (binding.hasVariable('packagingTestBranch')) ? packagingTestBranch : 'oss-dockerized-tests'
String artifactName = (binding.hasVariable('artifactName')) ? artifactName : 'jenkins'
String jenkinsPort = (binding.hasVariable('jenkinsPort')) ? jenkinsPort : '8080'

// Set up
String scriptPath = 'packaging-docker/installtests'
String checkCmd = "sudo $scriptPath/service-check.sh $artifactName $jenkinsPort"

// Core tests represent the basic supported linuxes, extended tests build out coverage further
def coreTests = []
def extendedTests = []
coreTests[0]=["sudo-ubuntu:14.04",  ["sudo $scriptPath/debian.sh installers/deb/*.deb", checkCmd]]
coreTests[1]=["sudo-centos:6",      ["sudo $scriptPath/centos.sh installers/rpm/*.rpm", checkCmd]]
coreTests[2]=["sudo-opensuse:13.2", ["sudo $scriptPath/suse.sh installers/suse/*.rpm", checkCmd]]
extendedTests[0]=["sudo-debian:wheezy", ["sudo $scriptPath/debian.sh installers/deb/*.deb", checkCmd]]
extendedTests[1]=["sudo-centos:7",      ["sudo $scriptPath/centos.sh installers/rpm/*.rpm", checkCmd]]
extendedTests[2]=["sudo-ubuntu:15.10",  ["sudo $scriptPath/debian.sh installers/deb/*.deb", checkCmd]]

node(dockerLabel) {
    stage "Load Lib"
    sh 'rm -rf workflowlib'
    dir ('workflowlib') {
        git branch: packagingTestBranch, url: 'https://github.com/jenkinsci/packaging.git'
        flow = load 'workflow/installertest.groovy'
    }
    

    stage 'Fetch Installer'
    flow.fetchInstallers(debfile, rpmfile, susefile)
    
    sh 'rm -rf packaging-docker'
    dir('packaging-docker') {
      git branch: packagingTestBranch, url: 'https://github.com/jenkinsci/packaging.git'
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