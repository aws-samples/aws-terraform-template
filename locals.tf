locals {
  name = "example-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
  })
}
