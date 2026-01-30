pipeline {
    agent any

    environment {
        AWS_REGION = "eu-north-1"
        ECR_REPO = "nginx-welcome"
        AWS_ACCOUNT_ID = "206716568967"
        IMAGE_TAG = "${BUILD_NUMBER}"
        ECR_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    credentialsId: 'jenkins-ssh',
                    url: 'git@github.com:brahmaji99/Hackathon_repo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                """
            }
        }

        stage('Trivy Image Scan') {
           steps {
                sh '''
                echo "Running Trivy scan..."
                trivy image \
                    --exit-code 1 \
                    --severity CRITICAL,HIGH \
                    ${ECR_REPO}:${IMAGE_TAG}
                '''
             }
        }

        stage('ECR Login') {
          steps {
            sh '''
                aws --version
                docker --version
                aws ecr get-login-password --region eu-north-1 \
                | docker login --username AWS --password-stdin 206716568967.dkr.ecr.eu-north-1.amazonaws.com
             '''
           }
       }

        stage('Tag Image') {
            steps {
                sh """
                docker tag ${ECR_REPO}:${IMAGE_TAG} \
                ${ECR_URI}/${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh """
                docker push ${ECR_URI}/${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }
    }

    post {
        success {
            echo "✅ Image pushed successfully: ${ECR_URI}/${ECR_REPO}:${IMAGE_TAG}"
        }
        failure {
            echo "❌ Pipeline failed"
        }
    }
}

