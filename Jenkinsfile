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
        stage('Maven test'){
            steps{
                script{
                    sh 'mvn test'
                }
            }
        }
        stage('intigration testing'){
            steps{
                script{
                    sh 'mvn verify -DskipUnitTests'
                }
            }
        }
        stage('maven build'){
            steps{
                script{
                    sh 'mvn clean install'
                }
            }
        }
        stage('static code analysis'){
            steps{
                script{
                    withSonarQubeEnv(credentialsId: 'sonar-secret'){
                        sh 'mvn clean package sonar:sonar'
                    }
                }
            }
        }
        stage('Quality Gate'){
            steps{
                script{
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-secret'
                }
            }
        }
        stage('upload war file to nexus'){
            steps{
                script{

                    def readPomVersion = readMavenPom file: 'pom.xml'
                    def version = readPomVersion.version
                    def artifactPath = "target/ci-cd-${version}.jar"
                    def nexusRepo = readPomVersion.version.endsWith('SNAPSHOT') ? "spring-boot-snapshot" : "sring-boot-release"
                    nexusArtifactUploader artifacts: 
                    [
                        [
                            artifactId: 'ci-cd', 
                            classifier: '', 
                            file: artifactPath, 
                            type: 'jar'
                        ]
                    ],
                    credentialsId: 'nexus-auth', 
                    groupId: 'com.example', 
                    nexusUrl: 'nexus:8081', 
                    nexusVersion: 'nexus3', 
                    protocol: 'http', 
                    repository: nexusRepo, 
                    version: "${readPomVersion.version}"
                }
            }
        }
        stage('SSH to Remote Server') {
            steps {
                script {
                    // Define SSH key file path (usually stored in Jenkins credentials)
                    def sshKey = credentials("${SSH_CREDENTIALS_ID}")

                    // Construct SSH command using SSH key file
                    def sshCommand = "ssh -i ${sshKey} ${SSH_USER}@${REMOTE_SERVER} 'ls -l'"
                    def sshOutput = sh(returnStdout: true, script: sshCommand).trim()

                    // Print the output of the SSH command
                    println "SSH Command Output:"
                    println sshOutput
                    }
                }
            }
        }
    }