terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket       = "your-bucket-name"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true  # Replaces deprecated dynamodb_table in AWS Provider v6+
  }
}