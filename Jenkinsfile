    pipeline {
        agent any
    
        environment {
            // Configuración manual y persistente de Java 26 en el contenedor
            JAVA_HOME = '/var/jenkins_home/jdk26'
            PATH = "/var/jenkins_home/jdk26/bin:${env.PATH}"
    
            // Configuraciones de la imagen de Docker
            REGISTRY_USER = 'kevcast1604'
            IMAGE_NAME = 'retail-store-u202318814'
            TAG = "${env.BUILD_NUMBER}"
            
            // SonarQube Server configuration name in Jenkins
            SONAR_SERVER_NAME = 'MiSonarServer'
        }
    
        stages {
            stage('Prepare JDK 26') {
                steps {
                    echo 'Checking and preparing JDK 26 environment...'
                    sh '''
                    ARCH=$(uname -m)
                    echo "Detected container architecture: $ARCH"
                    
                    if [ "$ARCH" = "x86_64" ]; then
                        JDK_ARCH="x64"
                    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
                        JDK_ARCH="aarch64"
                    else
                        JDK_ARCH="x64"
                    fi
                    
                    if [ -f "/var/jenkins_home/jdk26/bin/java" ]; then
                        if ! /var/jenkins_home/jdk26/bin/java -version > /dev/null 2>&1; then
                            echo "Cached JDK 26 is incompatible with $ARCH. Removing..."
                            rm -rf /var/jenkins_home/jdk26
                        fi
                    fi
                    
                    if [ ! -d "/var/jenkins_home/jdk26" ] || [ ! -f "/var/jenkins_home/jdk26/bin/java" ]; then
                        echo "Downloading Eclipse Temurin JDK 26 for $JDK_ARCH..."
                        rm -rf /var/jenkins_home/jdk26
                        mkdir -p /var/jenkins_home/jdk26
                        curl -L "https://api.adoptium.net/v3/binary/latest/26/ga/linux/${JDK_ARCH}/jdk/hotspot/normal/eclipse" | tar -xz -C /var/jenkins_home/jdk26 --strip-components=1
                    fi
                    '''
                }
            }
    
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
                    timeout(time: 10, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
    
            stage('4. Construir y Publicar Imagen Docker') {
                steps {
                    // Nos autenticamos de forma segura en Docker Hub usando el ID de credenciales de Jenkins
                    withCredentials([usernamePassword(credentialsId: 'DOCKER_HUB_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        script {
                            echo "Iniciando sesión en Docker Hub..."
                            sh "echo '${DOCKER_PASS}' | docker login -u '${DOCKER_USER}' --password-stdin"
    
                            echo "Construyendo imagen optimizada AMD64..."
                            sh "docker buildx build --platform linux/amd64 -t ${env.REGISTRY_USER}/${env.IMAGE_NAME}:${env.TAG} -t ${env.REGISTRY_USER}/${env.IMAGE_NAME}:latest --push ."
                        }
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
