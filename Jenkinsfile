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
            stage('kubernetes deployment'){
                steps{
                    script{
                        def appName = 'spring-app'
                        def imageName = "anilkumar9993/${appName}:${env.BUILD_NUMBER}"
                        sh "sed -i 's|<IMAGE>|${imageName}|g' deployment.yaml"
                        withKubeConfig(caCertificate: 'LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJME1ETXhOakEzTkRNMU1sb1hEVE0wTURNeE5EQTNORE0xTWxvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTGx3CmVqMFlUanByL0R6U0pucGdLOHpPOWpOZXljUENQT2VKZ3FYTEp3Sk01MVBWQm1tSXlyL1hNVi9oMEQxY3grd2wKWVdiVDg5bm1xSjFySGhkOGVIZXQvQVJsRENRbHpXcGU3K2lacWtzSG9JMTRxaXB6SDVyWTY2UW1TaDg0WHViVApFdEFsMEp1V3VaNnhxWFY3eDF6TStMMytpaDNqMlFMWUNaT3VmTGdmM0IxY0trL2lsZC9zWS84bGdLVG5NQWJBCm1UZmlDZXg0Sk1NSlh2eWtzVmdjUmRaNXoxL2pFZ3c5TDl5a1lRRDVUdm1xWXRJS1hqU2xEUmFpSmQ4TFdzbmEKOXdvRDhJRzBJUUcwT2F6ek9HbUwwbHR1QjFydCtzT0NlS2lNZjdCTVQ5UTFDZDl3ZGM5NFF0ODB6dGQreXMxWQp0QTMzSE9lRGpKK3BDRXpSZW5rQ0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZCOW1Oa090cUwyVjJLbFBvWjVibTRuR1hMRjNNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBRmZHRk92NUNVVThZSFRnSklvagpUYmpqRzcvQ2F1ZzhLVWxpUFhPLzFmMVdBcHVrK0pXRHhsQjdWUWkwTUZVVlVTM2E1eDE4bnozOEx5WlBaQkpxCkFHZGZUdWFFR1htWWgwcDYzZ21iejRlc2xVUFhGU0dqcVBkMnZDd2QrbnJISXFBZ3pxK1V4b2wzL3JRa2grcmIKbCtEOFdPOWNyYlh3dVEyQVRkbFUzUXlPYVZreDJ3RWFiemVaS2ZKdXZEWC85cmlZUmxiSnpVZ3dicCswOTlIUwpwVXZSdmxiZVFNbmtTTityVjZtUFpqVUlObFlRVVJIS0ZoL1RYSXFtclhoTjUwN1B5QWFMZ2NnMzNFSjdRQ0s4CmRLWjlvL0d1dCtiNW84ak1uQlptWXNHVjNQQ0RTcDRIWWdsOXVsTnZUSEE2OUJhTkM1UmNtZW5iQ1k2QzdPSloKYUY4PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==', clusterName: 'cluster.local', contextName: 'kubernetes-admin@cluster.local', credentialsId: 'kube-secret', namespace: 'ops', restrictKubeConfigAccess: false, serverUrl: 'https://lb.kubesphere.local:6443') {
                        sh 'kubectl apply -f deployment.yaml'
                    }
                }
            }
        }
    }
}