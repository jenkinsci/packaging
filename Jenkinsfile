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

nodeWithTimeout('docker') {
  stage('Test') {
    checkout scm
    unstash 'results'
    infra.withDockerCredentials {
      sh '''
          python3 -m venv venv
          source venv/bin/activate
          pip install -r requirements.txt
          molecule test
          deactivate
          '''.stripIndent()
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
