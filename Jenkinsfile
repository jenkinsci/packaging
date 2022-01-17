pipeline {
  agent {
    kubernetes {
      yamlFile 'KubernetesPod.yaml'
      workingDir '/home/jenkins/agent'
    }
  }

  options {
    disableConcurrentBuilds(abortPrevious: true)
    buildDiscarder logRotator(numToKeepStr: '5') // Retain only last 5 builds to reduce space requirements
    timeout(time: 1, unit: 'HOURS')
  }

  environment {
    BUILDENV = "${WORKSPACE}/env/test.mk"
    BRANDING_DIR = "${WORKSPACE}/branding"
    BRAND = "${WORKSPACE}/branding/test.mk"
    GPG_FILE = "${WORKSPACE}/credentials/sandbox.gpg"
    GPG_KEYNAME = 'Bogus Test'
    GPG_PASSPHRASE = 's3cr3t'
    GPG_PASSPHRASE_FILE = "${WORKSPACE}/credentials/test.gpg.password.txt"
    WAR = "${WORKSPACE}/jenkins.war"
    MSI = "${WORKSPACE}/jenkins.msi"
    RELEASELINE = '-experimental'
  }

  stages {
    stage('Prep') {
      steps {
        checkout scm
        sh './prep.sh'
      }
    }
    stage('Build') {
      steps {
        sh 'make war deb rpm suse'
      }
      post {
        success {
          archiveArtifacts 'target/debian/*.deb, target/rpm/*.rpm, target/suse/*.rpm'
        }
      }
    }
  }
}
