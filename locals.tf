locals {
  name = "example-${lower(var.environment)}"

  tags = {
    name        = local.name
    environment = var.environment
    GitRepo     = "https://github.com/aws-samples/aws-terraform-template"
  }
}
