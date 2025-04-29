provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

# Terraform backend configuration
# Option 1: S3 backend (default)
terraform {
  backend "s3" {
    bucket       = "my-terraform-state-bucket"
    key          = "path/to/my/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

# Option 2: Terraform Cloud/Enterprise (alternative)
# Delete the backend "s3" block above and uncomment the cloud block below
# to use Terraform Cloud/Enterprise
# terraform {
#   cloud {}
# }

# Note: You can only have one backend configuration active at a time.
