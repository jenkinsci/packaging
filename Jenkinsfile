properties([
  buildDiscarder(logRotator(numToKeepStr: '50', artifactNumToKeepStr: '5')),
  disableConcurrentBuilds(abortPrevious: true)
])

podTemplate(yaml: readTrusted('KubernetesPod.yaml'), workingDir: '/home/jenkins/agent') {
  nodeWithTimeout(POD_LABEL) {
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
        def results = '*.war, target/debian/*.deb, target/rpm/*.rpm, target/suse/*.rpm'
        stash includes: results, name: 'results'
        archiveArtifacts results
      }
    }
  }
}

nodeWithTimeout('azure && docker') {
  stage('Test') {
    checkout scm
    unstash 'results'
    infra.withDockerCredentials {
      sh 'sudo apt-get update && sudo apt-get install -y python3-docker python3-pip python3-venv python3-wheel' // TODO https://github.com/jenkins-infra/packer-images/pull/167
      ansiColor('xterm') {
        sh '''
            python3 -m venv venv
            . venv/bin/activate
            pip install -U pip
            pip install -r requirements.txt
            ANSIBLE_FORCE_COLOR=true molecule test
            deactivate
        '''.stripIndent()
      }
    }
  }
}

void nodeWithTimeout(String label, Closure body) {
  node(label) {
    timeout(time: 1, unit: 'HOURS') {
      body()
    }
  }
}
