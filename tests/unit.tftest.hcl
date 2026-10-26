# Unit tests. The mocked AWS Provider needs no credentials, so these tests run
# in seconds on any machine and in pull requests:
#   terraform init -backend=false
#   terraform test

mock_provider "aws" {}

variables {
  region              = "us-east-1"
  environment         = "dev"
  allowed_account_ids = ["111122223333"]
}

run "valid_environment" {
  command = plan

  assert {
    condition     = output.hello_world == "Hello, DEV World!"
    error_message = "The hello_world output doesn't match the environment."
  }

  assert {
    condition     = random_pet.main.prefix == "example-dev"
    error_message = "The resource name prefix doesn't include the environment."
  }
}

run "rejects_invalid_environment" {
  command = plan

  variables {
    environment = "Dev Environment"
  }

  expect_failures = [var.environment]
}

run "rejects_invalid_account_id" {
  command = plan

  variables {
    allowed_account_ids = ["1234"]
  }

  expect_failures = [var.allowed_account_ids]
}

run "rejects_invalid_region" {
  command = plan

  variables {
    region = "US East"
  }

  expect_failures = [var.region]
}
