# Integration tests. They use the real AWS Provider with credentials for a
# dedicated test account, apply the configuration, check the results, and
# destroy everything that they created when they finish. They need Terraform
# 1.13 or later, for the variable blocks. Pass the test account's ID:
#   terraform init -backend=false -test-directory=tests/integration
#   terraform test -test-directory=tests/integration \
#     -var='allowed_account_ids=["999988887777"]'

variable "allowed_account_ids" {
  description = "ID of the dedicated test account. The AWS Provider stops the test if the credentials belong to any other account."
  type        = list(string)
}

variable "region" {
  description = "AWS Region where the test runs"
  type        = string
  default     = "us-east-1"
}

# Replaces the provider block in providers.tf for every run in this file.
provider "aws" {
  region = var.region

  # Stops the first run before anything is created if the credentials belong
  # to an account other than the test account.
  allowed_account_ids = var.allowed_account_ids

  default_tags {
    tags = merge(var.tags, {
      Environment = var.environment
    })
  }
}

variables {
  environment = "integration"
  tags = {
    Project = "aws-terraform-template"
  }
}

# Reads the account, Region, and default tags that the AWS Provider resolved.
# The helper module declares only data sources, so this run creates nothing.
run "provider_context" {
  command = apply

  module {
    source = "./tests/integration/provider_context"
  }

  assert {
    condition     = contains(var.allowed_account_ids, output.account_id)
    error_message = "The credentials don't belong to the test account."
  }

  assert {
    condition     = output.region == var.region
    error_message = "The AWS Provider doesn't use the Region that the test passes."
  }

  assert {
    condition     = output.default_tags == tomap({ Environment = "integration", Project = "aws-terraform-template" })
    error_message = "The AWS Provider default tags don't include the Environment tag and the tags variable."
  }
}

run "apply" {
  command = apply

  assert {
    condition     = output.hello_world == "Hello, INTEGRATION World!"
    error_message = "The hello_world output doesn't match the environment."
  }

  # The pet name is known only after apply.
  assert {
    condition     = can(regex("^example-integration-[a-z]+-[a-z]+$", output.random_pet.id))
    error_message = "The random_pet name doesn't start with the environment's prefix or doesn't have two words."
  }
}
