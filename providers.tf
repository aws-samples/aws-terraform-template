provider "aws" {
  region = var.region

  # Stops the run before any change if the credentials belong to another account.
  allowed_account_ids = var.allowed_account_ids

  default_tags {
    tags = local.tags
  }
}

# Partial S3 backend. Each environment completes it with
# envs/<environment>/backend.tfbackend, which the reusable workflow passes to
# terraform init. For local runs:
#   terraform init -backend-config=envs/dev/backend.tfbackend
#
# To use HCP Terraform or Terraform Enterprise instead, replace this block
# with `cloud {}` and delete the backend.tfbackend files.
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
