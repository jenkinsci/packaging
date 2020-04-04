pipeline {
    agent {
        label 'docker'
    }
    stages {
        stage("Test") {
            steps {
                sh './do-mwaite'
            }
            post {
                always {
                    junit 'results/TEST*.xml'
                }
            }
        }
    }
}
