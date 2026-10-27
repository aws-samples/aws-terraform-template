variable "region" {
  description = "AWS Region where the resources are deployed"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]+$", var.region))
    error_message = "The region must be an AWS Region code, such as us-east-1."
  }
}

variable "environment" {
  description = "Name of the environment where the resources are deployed, such as dev or prod"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,16}$", var.environment))
    error_message = "The environment must be 1 to 16 lowercase letters, numbers, or hyphens."
  }
}

variable "allowed_account_ids" {
  description = "AWS account IDs that this configuration can deploy to. The AWS Provider stops the run if the credentials belong to any other account."
  type        = list(string)

  validation {
    condition     = length(var.allowed_account_ids) > 0 && alltrue([for id in var.allowed_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "Set at least one AWS account ID. Each ID must have 12 digits."
  }
}

variable "tags" {
  description = "Tags that the AWS Provider adds to every resource, in addition to Environment"
  type        = map(string)
  default     = {}
}
