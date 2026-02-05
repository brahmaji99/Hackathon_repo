pipeline {
    agent any

    parameters {
        choice(
            name: 'ENV',
            choices: ['dev', 'qa', 'prod'],
            description: 'Select the environment'
        )
        booleanParam(
            name: 'DESTROY',
            defaultValue: false,
            description: 'Destroy Terraform resources'
        )
        string(
            name: 'IMAGE_TAG',
            defaultValue: 'latest',
            description: 'Docker image tag'
        )
    }

    environment {
        AWS_REGION        = "eu-north-1"
        ACCOUNT_ID        = "206716568967"
        ECR_REPO          = "nginx-welcome"
        TF_DIR            = "terraform"
        TF_IN_AUTOMATION  = "true"
        TF_WORKSPACE      = "${ENV}"
    }

    stages {

        stage('Set IMAGE_URI') {
            steps {
                script {
                    if (params.DESTROY) {
                        // Image not needed during destroy
                        env.IMAGE_URI = "dummy"
                        env.IMAGE_TAG = "dummy"
                    } else {
                        // Respect Jenkins parameter
                        env.IMAGE_TAG = params.IMAGE_TAG
                        env.IMAGE_URI = "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}:${env.IMAGE_TAG}"
                    }

                    echo "Using IMAGE_TAG=${env.IMAGE_TAG}"
                    echo "Using IMAGE_URI=${env.IMAGE_URI}"
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
             when {
                expression { params.DESTROY == false }
            }
            steps {
                sh """
                docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                  aquasec/trivy:latest image --exit-code 1 --severity CRITICAL,HIGH \
                  ${ECR_REPO}:${IMAGE_TAG} || true
                """
            }
        }

        stage('ECR Login & Push') {
             when {
                expression { params.DESTROY == false }
            }
            steps {
                sh """
                aws ecr get-login-password --region ${AWS_REGION} \
                  | docker login --username AWS --password-stdin \
                    ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                docker tag ${ECR_REPO}:${IMAGE_TAG} ${IMAGE_URI}
                docker push ${IMAGE_URI}
                """
            }
        }

        // ---------------- Terraform ----------------

        stage('Terraform Format Check') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        def fmtResult = sh(
                            script: 'terraform fmt -check -recursive',
                            returnStatus: true
                        )
                        if (fmtResult != 0) {
                            echo "⚠️ Terraform files are not formatted. Run terraform fmt."
                        } else {
                            echo "✅ Terraform formatting OK."
                        }
                    }
                }
            }
        }

        stage('Terraform Init & Workspace') {
            steps {
                dir("${TF_DIR}") {
                    sh """
                    terraform init -reconfigure \
                      -backend-config="bucket=demo2-terraform-state-bucket" \
                      -backend-config="region=${AWS_REGION}" \
                      -backend-config="key=ecs/${ENV}/terraform.tfstate"

                    terraform workspace show
                    """
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir("${TF_DIR}") {
                    sh "terraform validate"
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.DESTROY == false }
            }
            steps {
                dir("${TF_DIR}") {
                    sh """
                    terraform plan -input=false \
                      -var="env=${ENV}" \
                      -var="ecr_image_uri=${IMAGE_URI}"
                    """
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.DESTROY == false }
            }
            steps {
                dir("${TF_DIR}") {
                    sh """
                    terraform apply -auto-approve -input=false \
                      -var="env=${ENV}" \
                      -var="ecr_image_uri=${IMAGE_URI}"
                    """
                }
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.DESTROY == true }
            }
            steps {
                dir("${TF_DIR}") {
                    sh """
                    terraform destroy -auto-approve -input=false \
                      -var="env=${ENV}" \
                      -var="ecr_image_uri=dummy"
                    """
                }
            }
        }
    }

    post {
        success {
            echo params.DESTROY
                ? "✅ Terraform destroy completed for ${ENV}"
                : "✅ Deployment successful for ${ENV}"
        }
        failure {
            echo params.DESTROY
                ? "❌ Terraform destroy FAILED for ${ENV}"
                : "❌ Deployment FAILED for ${ENV}"
        }
    }
}
