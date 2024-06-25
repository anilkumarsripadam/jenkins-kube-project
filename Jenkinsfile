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
        JAVA_HOME = '/usr/local/openjdk-11' // Adjust according to the JDK version used in your Docker image
    }

    stages {
        stage('Git Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Git-token', url: 'https://github.com/anilkumarsripadam/jenkins-kube-project.git']])
            }
        }
        stage('Maven Build') {
            steps {
                container('maven') {
                    sh 'mvn clean install'
                }
            }
        }
        // Add other stages as per your pipeline configuration
    }
}
