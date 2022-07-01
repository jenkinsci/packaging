def jobProperties = [
  buildDiscarder(logRotator(numToKeepStr: '50', artifactNumToKeepStr: '5')),
  disableConcurrentBuilds(abortPrevious: true)
]

if (env.BRANCH_IS_PRIMARY) {
  jobProperties << pipelineTriggers([cron('@weekly')]) // Run at least weekly on the primary branch to assure we test recent releases
}

properties(jobProperties)

podTemplate(yaml: readTrusted('KubernetesPod.yaml'), workingDir: '/home/jenkins/agent') {
  nodeWithTimeout(POD_LABEL) {
    withEnv([
      "BUILDENV=${WORKSPACE}/env/test.mk",
      "BRANDING_DIR=${WORKSPACE}/branding",
      "BRAND=${WORKSPACE}/branding/jenkins.mk",
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
        sh 'make package && python3 -m pytest bin --junitxml target/junit.xml'
        junit 'target/junit.xml'
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
      ansiColor('xterm') {
        sh '''
            cat /proc/cpuinfo
            cat /proc/meminfo
            python3 -m venv venv
            . venv/bin/activate
            pip install -U pip wheel
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
