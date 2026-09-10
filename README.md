 **Phase 1: Project Restructuring & Directory Alignment**

We reorganized the repository structure to eliminate double-nested folders and adhere to enterprise Infrastructure as Code (IaC) standards.

#### **Directory Layout**

```text
terraform-aws-enterprise-pipeline/
├── Jenkinsfile                  # Multi-environment pipeline script
├── README.md                    # Project documentation
├── environments/                # Target environment configurations
│   ├── dev/                     # Development environment
│   │   ├── backend.tf           # S3 + DynamoDB remote backend configuration
│   │   ├── main.tf              # Environment module calls
│   │   ├── variables.tf         # Input variable definitions
│   │   └── terraform.tfvars     # Variable assignment values
│   ├── UAT/                     # User Acceptance Testing environment
│   └── prod/                    # Production environment
└── modules/                     # Re-usable custom modules
    ├── vpc/                     # Custom VPC, Subnets, Gateways
    ├── security_groups/         # Ingress and Egress rules
    └── ec2/                     # Compute instances

```

---

### **Phase 2: Remote Backend Setup (AWS S3 & DynamoDB)**

To enable remote state tracking and prevent state locks during parallel executions, we set up an S3 bucket and DynamoDB locking table.

#### **1. AWS S3 & DynamoDB Provisioning**

```bash
# Set environment variables
export AWS_REGION="us-east-1"
export BUCKET_NAME="your-unique-tfstate-bucket-name"

# Create S3 Bucket for State Storage
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $AWS_REGION

# Enable S3 Versioning for Rollback Safety
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Create DynamoDB Table for State Locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $AWS_REGION

```

#### **2. Backend Configuration (`environments/dev/backend.tf`)**

```hcl
terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "your-unique-tfstate-bucket-name"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # Replaces deprecated dynamodb_table in AWS Provider v6+
  }
}

```

---

### **Phase 3: Declarative Jenkinsfile Pipeline Configuration**

We created a parameterized declarative `Jenkinsfile` at the root of the repository to manage initialization, formatting checks, planning, manual approval, and execution.

#### **`Jenkinsfile`**

```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'UAT', 'prod'], description: 'Select target environment')
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Select Terraform action')
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_DIR             = "environments/${params.ENVIRONMENT}"
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
                            echo "Action set to 'plan'. Skipping execution."
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs() // Deletes build workspace artifacts post-execution
        }
    }
}

```

---

### **Phase 4: Step-by-Step Troubleshooting Log**

During testing, we encountered and resolved three production-level pipeline errors.

#### **Error 1: S3 Bucket Access Denied (HTTP Status 403 / Forbidden)**

* **Symptom:** `Terraform Init` stage failed with `Unable to access object "dev/terraform.tfstate" in S3 bucket "your-bucket-name": api error Forbidden: Forbidden`.
* **Root Cause:**
1. `backend.tf` contained the un-replaced placeholder string `"your-bucket-name"`.
2. The Jenkins build runner lacked valid AWS permissions/roles to access the S3 bucket.


* **Resolution Steps:**
1. Updated `environments/dev/backend.tf` with the exact, real S3 bucket name created in AWS.
2. Attached an IAM Role (`Jenkins-Terraform-Role`) with S3 and DynamoDB policies directly to the EC2 instance running Jenkins (or injected AWS credentials via Jenkins Credentials Manager).



#### **Error 2: Pipeline Failed at Format Stage (`terraform fmt -check` Exit Code 3)**

* **Symptom:** Jenkins pipeline initialized successfully but failed on `Terraform Format Check` stage with `ERROR: script returned exit code 3`.
* **Root Cause:** `terraform fmt -check` returns exit code `3` if any `.tf` file in the directory does not strictly adhere to HashiCorp standard spacing and formatting guidelines.
* **Resolution Steps:**
1. Executed auto-formatting across all environments and custom modules from the workspace terminal:
```bash
terraform fmt -recursive

```


2. Committed and pushed formatted files back to GitHub:
```bash
git add .
git commit -m "Fix terraform formatting across environments and modules"
git push origin main

```





#### **Error 3: Deprecated `dynamodb_table` Warning in AWS Provider v6.x**

* **Symptom:** `terraform init` issued a warning: `The parameter "dynamodb_table" is deprecated. Use parameter "use_lockfile" instead.`
* **Root Cause:** HashiCorp AWS Provider v6.0+ replaced the `dynamodb_table` parameter syntax in backend blocks with `use_lockfile`.
* **Resolution Steps:**
1. Updated `backend.tf` syntax:
```hcl
terraform {
  backend "s3" {
    bucket       = "your-bucket-name"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

```


2. Re-initialized backend:
```bash
terraform init -reconfigure

```





---

### **Phase 5: Final Pipeline Verification**

1. Opened Jenkins Dashboard → **`terraform-aws-enterprise-pipeline`**.
2. Clicked **Build with Parameters**:
* Selected `ENVIRONMENT` = `dev`
* Selected `ACTION` = `plan`


3. Clicked **Build** and verified console output:
* **Stage `Checkout Code`:** Success
* **Stage `Terraform Init`:** Success (S3 backend connected, DynamoDB lock acquired)
* **Stage `Terraform Format Check`:** Success (Exit code 0)
* **Stage `Terraform Plan`:** Success (`tfplan` artifact generated)
* **Workspace Cleanup:** Success (`cleanWs()` executed)
