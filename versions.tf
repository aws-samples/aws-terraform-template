terraform {
  # 1.11 makes S3 native state locking (use_lockfile) generally available.
  required_version = ">= 1.11"

  # Root modules set an upper bound so that a new major version isn't
  # installed without review. The dependency lock file pins the exact version.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}
