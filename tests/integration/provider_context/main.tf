# Test helper for tests/integration. It reads what the AWS Provider resolved
# from the test credentials and from the provider block in the test file. It
# declares only data sources, so it creates nothing in the account.

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_default_tags" "current" {}
