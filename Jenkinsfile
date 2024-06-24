pipeline {
    agent any

    environment {
        REMOTE_SERVER = '10.21.34.232'
        SSH_USER = 'anil'
        SSH_CREDENTIALS_ID = 'ssh-key' // Jenkins credentials ID for SSH private key
    }

    stages {
        stage('Git Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Git-token', url: 'https://github.com/anilkumarsripadam/jenkins-kube-project.git']])
            }
        }
        stage('Maven Test') {
            steps {
                script {
                    sh 'mvn test'
                }
            }
        }
        stage('Integration Testing') {
            steps {
                script {
                    sh 'mvn verify -DskipUnitTests'
                }
            }
        }
        stage('Maven Build') {
            steps {
                script {
                    sh 'mvn clean install'
                }
            }
        }
        stage('Static Code Analysis') {
            steps {
                script {
                    withSonarQubeEnv(credentialsId: 'sonar-secret') {
                        sh 'mvn clean package sonar:sonar'
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                script {
                    // Timeout of 1 minutes for waiting for the quality gate
                    timeout(time: 1, unit: 'MINUTES') {
                        def qg = waitForQualityGate abortPipeline: false, credentialsId: 'sonar-secret'
                        if (qg.status != 'OK' && qg.status != 'ERROR') {
                            // Skip further checks if the quality gate is pending or inconclusive
                            echo "Quality Gate status is ${qg.status}. Proceeding without approval."
                        } else if (qg.status == 'ERROR') {
                            error "Quality Gate failed with status: ${qg.status}"
                        }
                    }
                }
            }
        }
    }
}
