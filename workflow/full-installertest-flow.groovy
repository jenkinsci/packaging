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


node(dockerLabel) {
    stage "Load Lib"
    sh 'rm -rf workflowlib'
    dir ('workflowlib') {
        git branch: packagingTestBranch, url: 'https://github.com/jenkinsci/packaging.git'
        flow = load 'workflow/installertest.groovy'
    }
}
// Run the real tests within docker node label
flow.fetchAndRunJenkinsInstallerTest(dockerLabel, rpmfile, susefile, debfile, 
    packagingTestBranch, artifactName, jenkinsPort)