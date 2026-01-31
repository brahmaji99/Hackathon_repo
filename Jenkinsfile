pipeline {
  agent any

  parameters {
    choice(
      name: 'ENV',
      choices: ['dev', 'prod'],
      description: 'Select environment'
    )
    string(
      name: 'IMAGE_TAG',
      defaultValue: 'latest',
      description: 'Docker image tag'
    )
  }

  environment {
    AWS_REGION = "eu-north-1"
    ACCOUNT_ID = "206716568967"
    ECR_REPO   = "nginx-welcome"
    IMAGE_TAG = "${BUILD_NUMBER}"
    IMAGE_URI  = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
    TF_DIR     = "terraform"
  }

  stages {

     stage('Checkout Code') {
            steps {
                git branch: 'development',
                    credentialsId: 'jenkins-ssh',
                    url: 'git@github.com:brahmaji99/Hackathon_repo.git'
            }
    }

    stage('Docker Build') {
      steps {
        sh '''
          docker build -t ${ECR_REPO}:${IMAGE_TAG} .
        '''
      }
    }

    stage('Trivy Image Scan') {
            steps {
                script {
                echo "Running Trivy scan inside Docker..."
                sh '''
                    docker run --rm \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:latest image --exit-code 1 --severity CRITICAL,HIGH ${ECR_REPO}:${IMAGE_TAG}
                '''
                }
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

    stage('Push Image to ECR') {
      steps {
        sh '''
          docker tag ${ECR_REPO}:${IMAGE_TAG} ${IMAGE_URI}
          docker push ${IMAGE_URI}
        '''
      }
    }

    stage('Terraform Init') {
    steps {
        sh """
          terraform init -reconfigure \
            -backend-config="key=ecs/dev/terraform.tfstate"
        """
      }
    }



    stage('Select Terraform Workspace') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            terraform workspace select ${ENV} || terraform workspace new ${ENV}
          '''
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            terraform plan \
              -var="ecr_image_uri=${IMAGE_URI}"
          '''
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        dir("${TF_DIR}") {
          sh '''
            terraform apply -auto-approve \
              -var="ecr_image_uri=${IMAGE_URI}"
          '''
        }
      }
    }
  }

  post {
    success {
      echo "Deployment successful for ${ENV}"
    }
    failure {
      echo "Deployment failed"
    }
  }
}
