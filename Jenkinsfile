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
                    def appName = 'sring-app' // Replace with your app name
                    def dockerImage = "${appName}:${env.BUILD_NUMBER}"
                    sh "docker build -t ${dockerImage} ."
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'docker-secret', variable: 'Docker-hub-login')]) {
                        def appName = 'spring-app' // Replace with your app name
                        def dockerImage = "anilkumar9993/${appName}:${env.BUILD_NUMBER}"
                        sh 'docker login -u anilkumar9993 -p "$Docker_hub_login"'
                        sh "docker push ${dockerImage}"
                    }
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    def appName = 'spring-app' // Replace with your app name
                    def dockerImage = "${appName}:${env.BUILD_NUMBER}"

                    // Substitute the Docker image in the deployment.yaml
                    sh """
                    sed -i 's|<IMAGE>|${dockerImage}|g' deployment.yaml
                    kubectl apply -f deployment.yaml
                    kubectl rollout status deployment/${appName}
                    """
                }
            }
        }
    }
}
