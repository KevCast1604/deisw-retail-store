pipeline {
    agent any

    environment {
        // Docker Hub configuration
        DOCKER_USER = 'kevcast1604'
        DOCKER_IMAGE = 'retail-store-u202318814'
        DOCKER_CREDENTIALS_ID = 'docker-hub-credentials'
        
        // SonarQube Server configuration name in Jenkins
        SONAR_SERVER_NAME = 'SonarQube'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Compile & Validate') {
            steps {
                echo 'Compiling the application and running Checkstyle validations...'
                sh 'chmod +x mvnw'
                sh './mvnw clean compile checkstyle:check'
            }
        }

        stage('Unit Tests & Coverage') {
            steps {
                echo 'Running unit tests and generating JaCoCo coverage reports...'
                sh './mvnw test'
            }
        }

        stage('SonarQube Static Analysis') {
            steps {
                echo 'Running static analysis with SonarQube...'
                withSonarQubeEnv("${env.SONAR_SERVER_NAME}") {
                    sh './mvnw sonar:sonar'
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo 'Checking SonarQube Quality Gate...'
                // If you do not have webhooks configured in SonarQube, you can comment out this stage
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker Image...'
                sh "docker build -t ${env.DOCKER_USER}/${env.DOCKER_IMAGE}:${env.BUILD_NUMBER} -t ${env.DOCKER_USER}/${env.DOCKER_IMAGE}:latest ."
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Logging in to Docker Hub and pushing image...'
                withCredentials([usernamePassword(credentialsId: "${env.DOCKER_CREDENTIALS_ID}", passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USER')]) {
                    sh 'echo "$DOCKER_HUB_PASSWORD" | docker login -u "$DOCKER_HUB_USER" --password-stdin'
                    sh "docker push ${env.DOCKER_USER}/${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}"
                    sh "docker push ${env.DOCKER_USER}/${env.DOCKER_IMAGE}:latest"
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution finished.'
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Please check the logs.'
        }
    }
}
