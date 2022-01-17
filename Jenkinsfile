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
    WAR = "${WORKSPACE}/jenkins.war"
    MSI = "${WORKSPACE}/jenkins.msi"
    BRAND = "${WORKSPACE}/branding/test.mk"
    BUILDENV = "${WORKSPACE}/env/test.mk"
    CREDENTIAL = "${WORKSPACE}/credentials/test.mk"
    GPG_KEYNAME = 'Bogus Test'
    GPG_FILE = "${WORKSPACE}/credentials/sandbox.gpg"
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
