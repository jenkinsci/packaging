//
// THIS FILE IS TO BE DELETED OR REPLACED BEFORE MERGE
//
pipeline {
    agent {
        label 'docker && !cloud'
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
