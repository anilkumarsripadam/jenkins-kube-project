pipeline {
    agent any
    environment {
        DOCKER_CREDENTIALS_ID = 'Docker-auth' // Jenkins credentials ID for Docker Hub
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
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-secret'
                }
            }
        }
        stage('Upload WAR File to Nexus') {
            steps {
                script {
                    def readPomVersion = readMavenPom file: 'pom.xml'
                    def version = readPomVersion.version
                    def artifactPath = "target/ci-cd-${version}.jar"
                    def nexusRepo = readPomVersion.version.endsWith('SNAPSHOT') ? "spring-boot-snapshot" : "spring-boot-release"
                    nexusArtifactUploader artifacts: [
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
        stage('Docker Build') {
            steps {
                script {
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
