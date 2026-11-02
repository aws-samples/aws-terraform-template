output "account_id" {
  description = "ID of the AWS account that the test credentials belong to"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS Region that the AWS Provider uses"
  value       = data.aws_region.current.region
}

output "default_tags" {
  description = "Default tags that the AWS Provider adds to every resource"
  value       = data.aws_default_tags.current.tags
}
