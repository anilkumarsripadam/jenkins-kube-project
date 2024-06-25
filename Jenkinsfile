pipeline {
    agent any

    stages {
        stage('Git Checkout') {
            steps {
                checkout scmGit(branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[credentialsId: 'Git-token', url: 'https://github.com/anilkumarsripadam/jenkins-kube-project.git']])
            }
        }
        stage('Maven test') {
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
        stage('Upload WAR file to Nexus') {
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
                    nexusUrl: '10.21.34.152:8081',
                    nexusVersion: 'nexus3',
                    protocol: 'http',
                    repository: nexusRepo,
                    version: "${readPomVersion.version}"
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    def appName = 'spring-app' // Replace with your app name
                    def dockerImage = "${appName}:${env.BUILD_NUMBER}"
                    sh "docker build -t ${dockerImage} ."
                    sh "docker tag ${dockerImage} anilkumar9993/${dockerImage}"
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-registry-auth') {
                        def appName = 'spring-app'
                        def dockerImage = docker.image("anilkumar9993/${appName}:${env.BUILD_NUMBER}")
                        dockerImage.push()
                    }
                }
            }
        }
        stage('kubernets-deployment'){
            steps{
                script{
                    def appName = 'spring-app'
                    def dockerImage = "anilkumar9993/${appName}:${env.BUILD_NUMBER}"
                    writeFile file: 'k8s-deployment.yaml', text: """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${appName}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${appName}
  template:
    metadata:
      labels:
        app: ${appName}
    spec:
      containers:
      - name: ${appName}
        image: ${dockerImage}
        ports:
        - containerPort: 8080

---

apiVersion: v1
kind: Service
metadata:
  name: ${appName}
spec:
  selector:
    app: ${appName}
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${appName}-ingress
spec:
  rules:
  - host: ${appName}.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${appName}
            port:
              number: 80
"""
                    sh 'kubectl apply -f k8s-deployment.yaml'
                }
            }    
        }
    }
}
