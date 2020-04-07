//
// THIS FILE IS TO BE DELETED OR REPLACED BEFORE MERGE
//
pipeline {
    agent {
        label 'docker && !cloud' // Keep all builds inside markwaite.net to check 2.223
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
