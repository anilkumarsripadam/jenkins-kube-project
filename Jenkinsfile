pipeline {
    agent any
        docker { image 'docker:stable' }
    environment {
        DOCKER_CREDENTIALS_ID = 'docker_token' // Jenkins credentials ID for Docker Hub
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
        stage('git check-out'){
            steps{
                git branch: 'main', url: 'https://github.com/anilkumarsripadam/jenkins-kube-project.git'  // Replace with your repository

            }
        }
        stage('docker build'){
            steps{
                script{
                    def imageName = "anilkumar9993/${JOB_NAME}"
                    def imageTag = "v1.${BUILD_ID}"
                    def latestTag = "latest"

                    docker.withRegistry('https://registry.hub.docker.com', "${DOCKER_CREDENTIALS_ID}") {
                        def customImage = docker.build("${imageName}:${imageTag}")
                        customImage.push()
                        customImage.push(latestTag)
                    }    
                }
            }
        }
    }
}