pipeline {
    agent any

    parameters {
        choice(
            name: 'ENV',
            choices: ['dev', 'qa', 'prod'],
            description: 'Select the environment'
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
        TF_DIR     = "terraform"
    }

    stages {

        stage('Set IMAGE_URI') {
            steps {
                script {
                    // Evaluate BUILD_NUMBER at runtime
                    env.IMAGE_TAG = "${BUILD_NUMBER}"
                    env.IMAGE_URI = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
                }
            }
        }

        stage('Checkout Code') {
            steps {
                git branch: 'development',
                    credentialsId: 'jenkins-ssh',
                    url: 'git@github.com:brahmaji99/Hackathon_repo.git'
            }
        }

        stage('Docker Build & Scan') {
            steps {
                sh """
                docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                    aquasec/trivy:latest image --exit-code 1 --severity CRITICAL,HIGH ${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('ECR Login & Push') {
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_REGION} \
                    | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                docker tag ${ECR_REPO}:${IMAGE_TAG} ${IMAGE_URI}
                docker push ${IMAGE_URI}
                """
            }
        }

        // ---------------- Terraform Stages ----------------

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh """
                    terraform init -reconfigure \
                        -backend-config="bucket=my-terraform-state-bucket" \
                        -backend-config="region=${AWS_REGION}" \
                        -backend-config="key=ecs/${ENV}/terraform.tfstate" \
                        -backend-config="dynamodb_table=terraform-lock"
                    """
                }
            }
        }

        stage('Terraform Workspace') {
            steps {
                dir("${TF_DIR}") {
                    sh """
                    terraform workspace select ${ENV} || terraform workspace new ${ENV}
                    terraform workspace show
                    """
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh """
                    terraform plan -input=false \
                        -var="ecr_image_uri=${IMAGE_URI}" \
                        -var="env=${ENV}"
                    """
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir("${TF_DIR}") {
                    sh """
                    terraform apply -auto-approve -input=false \
                        -var="ecr_image_uri=${IMAGE_URI}" \
                        -var="env=${ENV}"
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Deployment successful for ${ENV}"
        }
        failure {
            echo "Deployment failed for ${ENV}"
        }
    }
}
