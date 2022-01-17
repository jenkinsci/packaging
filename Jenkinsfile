properties([
  buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '5')),
  disableConcurrentBuilds(abortPrevious: true)
])
podTemplate(yaml: readTrusted('KubernetesPod.yaml'), workingDir: '/home/jenkins/agent') {
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
        stage('Prep') {
          checkout scm
          sh './prep.sh'
        }
        stage('Build') {
          sh 'make war deb rpm suse'
        }
        archiveArtifacts 'target/debian/*.deb, target/rpm/*.rpm, target/suse/*.rpm'
      }
    }
  }
}
