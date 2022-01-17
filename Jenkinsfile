properties([
  buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '5')),
  disableConcurrentBuilds(abortPrevious: true)
])
podTemplate(yaml: readTrusted('PodTemplates.d/package-linux.yaml'), workingDir: '/home/jenkins/agent') {
  node(POD_LABEL) {
    timeout(time: 1, unit: 'HOURS') {
      withEnv([
        "BUILDENV=${WORKSPACE}/env/test.mk",
        "BRANDING_DIR=${WORKSPACE}/branding",
        "BRAND=${WORKSPACE}/branding/test.mk",
        "GPG_FILE=${WORKSPACE}/credentials/sandbox.gpg",
        "GPG_KEYNAME=Bogus Test",
        "GPG_PASSPHRASE=s3cr3t",
        "GPG_PASSPHRASE_FILE=${WORKSPACE}/credentials/test.gpg.password.txt",
        "WAR=${WORKSPACE}/jenkins.war",
        "MSI=${WORKSPACE}/jenkins.msi",
        "RELEASELINE=-experimental",
      ]) {
        stage('Preparation') {
          checkout scm
          sh './prep.sh'
        }
        stage('Build') {
          sh 'make package'
          sh 'python3 -m unittest discover -s bin'
        }
        stage('Results') {
          stash includes: 'jenkins.war', name: 'war'
          archiveArtifacts '*.war, target/debian/*.deb, target/rpm/*.rpm, target/suse/*.rpm'
        }
      }
    }
  }
}
podTemplate(yaml: readTrusted('PodTemplates.d/package-windows.yaml')) {
  node(POD_LABEL) {
    timeout(time: 1, unit: 'HOURS') {
      withEnv([
        "BUILDENV=${WORKSPACE}/env/test.mk",
        "BRANDING_DIR=${WORKSPACE}/branding",
        "BRAND=${WORKSPACE}/branding/test.mk",
        "GPG_FILE=${WORKSPACE}/credentials/sandbox.gpg",
        "GPG_KEYNAME=Bogus Test",
        "GPG_PASSPHRASE=s3cr3t",
        "GPG_PASSPHRASE_FILE=${WORKSPACE}/credentials/test.gpg.password.txt",
        "WAR=${WORKSPACE}/jenkins.war",
        "MSI=${WORKSPACE}/jenkins.msi",
        "RELEASELINE=-experimental",
      ]) {
        stage('Preparation') {
          checkout scm
          unstash 'war'
        }
        stage('Build') {
          container('dotnet') {
            powershell '''
                Get-ChildItem env:
                $env:WAR=(Resolve-Path .\\jenkins.war).Path
                & .\\make.ps1
                '''.stripIndent()
          }
        }
        stage('Results') {
          archiveArtifacts 'msi/build/bin/Release/en-US/*.msi'
        }
      }
    }
  }
}
