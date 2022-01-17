pipeline {
  agent {
    kubernetes {
      label 'package-linux'
      yamlFile 'KubernetesPod.yaml'
      workingDir '/home/jenkins/agent'
    }
  }

  options {
    disableConcurrentBuilds(abortPrevious: true)
    buildDiscarder logRotator(numToKeepStr: '5') // Retain only last 5 builds to reduce space requirements
  }

  environment {
    JENKINS_VERSION = 'latest'
    JENKINS_DOWNLOAD_URL= 'https://repo.jenkins-ci.org/releases/org/jenkins-ci/main/jenkins-war/'
    WAR = "${WORKSPACE}/target/war/jenkins.war"
    MSI = "${WORKSPACE}/target/msi/jenkins.msi"
    BRAND = "${WORKSPACE}/branding/common"
    ORGANIZATION = 'example.org'
    BUILDENV = "${WORKSPACE}/env/test.mk"
    CREDENTIAL = "${WORKSPACE}/credentials/test.mk"
    GPG_KEYNAME = 'test'
    GPG_KEYRING = "${WORKSPACE}/credentials/${GPG_KEYNAME}.gpg"
    GPG_SECRET_KEYRING = "${WORKSPACE}/credentials/${GPG_KEYNAME}.secret.gpg"
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
          archiveArtifacts 'target/war/*.war, target/debian/*.deb, target/rpm/*.rpm, target/suse/*.rpm'
        }
      }
    }
  }
}
