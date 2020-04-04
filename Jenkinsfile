pipeline {
    agent {
        label 'docker'
    }
    stages {
        stage("Test") {
            steps {
                sh 'make docker.test'
            }
            post {
                always {
                    junit 'results/TEST*.xml'
                }
            }
        }
    }
}
