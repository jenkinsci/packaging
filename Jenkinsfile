pipeline {
    agent {
        label 'docker'
    }
    stages {
        stage("Test") {
            steps {
                sh 'git clean -xfd; make docker.test'
            }
            post {
                always {
                    junit 'results/TEST*.xml'
                }
            }
        }
    }
}
