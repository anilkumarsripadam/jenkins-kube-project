pipeline {
    agent {
        kubernetes {
            label 'docker-agent'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: maven
    image: maven:3.8.5-openjdk-11
    command:
    - cat
    tty: true
  - name: docker
    image: docker:20.10.7
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
"""
        }
    }

    environment {
        REMOTE_SERVER = '10.21.34.232'
        SSH_USER = 'anil'
        SSH_CREDENTIALS_ID = 'ssh-key' // Jenkins credentials ID for SSH private key
        DOCKER_REGISTRY_CREDENTIALS = 'docker-registry-auth' // Jenkins credentials ID for Docker registry
        DOCKER_REGISTRY_URL = 'https://hub.docker.com/repositories/anilkumar9993'
        DOCKER_IMAGE_NAME = 'jenkins-sonar'
    }

    stages {
        stage('Git Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Git-token', url: 'https://github.com/anilkumarsripadam/jenkins-kube-project.git']])
            }
        }
        stage('Maven test') {
            steps {
                container('maven') {
                    sh 'mvn test'
                }
            }
        }
        stage('Integration Testing') {
            steps {
                container('maven') {
                    sh 'mvn verify -DskipUnitTests'
                }
            }
        }
        stage('Maven Build') {
            steps {
                container('maven') {
                    sh 'mvn clean install'
                }
            }
        }
        stage('Static Code Analysis') {
            steps {
                container('maven') {
                    withSonarQubeEnv('sonar-secret') {
                        sh 'mvn clean package sonar:sonar'
                    }
                }
            }
        }
        stage('Quality Gate') {
            steps {
                container('maven') {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-secret'
                }
            }
        }
        stage('Upload WAR File to Nexus') {
            steps {
                container('maven') {
                    script {
                        def readPomVersion = readMavenPom file: 'pom.xml'
                        def version = readPomVersion.version
                        def artifactPath = "target/ci-cd-${version}.jar"
                        def nexusRepo = readPomVersion.version.endsWith('SNAPSHOT') ? "spring-boot-snapshot" : "spring-boot-release"
                        nexusArtifactUploader artifacts: [
                            [artifactId: 'ci-cd', classifier: '', file: artifactPath, type: 'jar']
                        ],
                        credentialsId: 'nexus-auth',
                        groupId: 'com.example',
                        nexusUrl: '10.21.34.152:8081',
                        nexusVersion: 'nexus3',
                        protocol: 'http',
                        repository: nexusRepo,
                        version: "${version}"
                    }
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    script {
                        def readPomVersion = readMavenPom file: 'pom.xml'
                        def version = readPomVersion.version
                        def dockerImage = "${DOCKER_REGISTRY_URL}/${DOCKER_IMAGE_NAME}:${version}"
                        sh "docker build -t ${dockerImage} ."
                    }
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                container('docker') {
                    script {
                        def readPomVersion = readMavenPom file: 'pom.xml'
                        def version = readPomVersion.version
                        def dockerImage = "${DOCKER_REGISTRY_URL}/${DOCKER_IMAGE_NAME}:${version}"
                        withDockerRegistry([ credentialsId: DOCKER_REGISTRY_CREDENTIALS, url: DOCKER_REGISTRY_URL ]) {
                            sh "docker push ${dockerImage}"
                        }
                    }
                }
            }
        }
    }
}
