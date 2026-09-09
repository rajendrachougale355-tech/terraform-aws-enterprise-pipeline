pipeline {
    agent any

    // Parameters allow choosing environment & action at run time
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'UAT', 'prod'], description: 'Select deployment environment')
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Select Terraform action')
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_DIR             = "environments/${params.ENVIRONMENT}"
        TF_VAR_dev_vpc_cidr     = "10.0.0.0/16"
        TF_VAR_dev_public_cidr  = "10.0.1.0/24"
        TF_VAR_dev_private_cidr = "10.0.2.0/24"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Format Check') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform fmt -check'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        // Approval gate for dangerous steps (Apply / Destroy)
        stage('Manual Approval') {
            when {
                expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
            }
            steps {
                script {
                    input message: "Approve ${params.ACTION} for ${params.ENVIRONMENT} environment?", ok: 'Proceed'
                }
            }
        }

        stage('Terraform Execute') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        if (params.ACTION == 'apply') {
                            sh 'terraform apply -input=false tfplan'
                        } else if (params.ACTION == 'destroy') {
                            sh 'terraform destroy -auto-approve'
                        } else {
                            echo "Action was set to 'plan'. Stopping after plan step."
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Prevents plain-text state files or credentials from remaining on Jenkins executor
        }
    }
}
