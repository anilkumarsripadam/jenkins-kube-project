pipeline {

    agent any

    stages{

        stage('Git Checkout'){

            steps{
                git branch: 'main', url: 'https://github.com/anilkumarsripadam/spring-boot-nexus-sonar.git'
            } 
        }
        stage('Maven Test'){

            steps{
                sh 'mvn test' 
            } 
        }
        stage('Integration testing'){
            steps{
                sh 'mvn verify -DskipUnitTests'
            }
        }
        stage('maven build'){
            steps{
                sh 'mvn clean install'
            }
        }
        stage('static code analysis'){
            steps{
                script{
                withSonarQubeEnv(credentialsId: 'sonar-secret-txt') {
                sh 'mvn clean package sonar:sonar'
                  }
                }
            }

        }
        stage('Quality Gate'){
            steps{
                script{
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-secret-txt'
                }
            }
        }
        stage('upload war filr to nexus'){
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
                    credentialsId: 'Nexus-auth', 
                    groupId: 'com.example', 
                    nexusUrl: '3.85.27.149:8081', 
                    nexusVersion: 'nexus3', 
                    protocol: 'http', 
                    repository: nexusRepo, 
                    version: "${readPomVersion.version}"
                }
            }
        }
        stage('docker image build'){
            steps{
                script{
                    sh 'docker image build -t $JOB_NAME:v1.$BUILD_ID .'
                    sh 'docker image tag $JOB_NAME:v1.$BUILD_ID anilkumar9993/$JOB_NAME:v1.$BUILD_ID'
                    sh 'docker image tag $JOB_NAME:v1.$BUILD_ID anilkumar9993/$JOB_NAME:latest'
                }
            }
        }
        stage('Docker image push'){
            steps{
                script{
                    withCredentials([string(credentialsId: 'docker_token', variable: 'docker_token')]){
                        sh 'echo ${docker_token}'
                        sh 'docker login -u anilkumar9993 -p ${docker_token}'
                        sh 'docker image push anilkumar9993/$JOB_NAME:v1.$BUILD_ID'
                        sh 'docker image push anilkumar9993/$JOB_NAME:latest'
                    }
                }
            }
        }
    }
}
