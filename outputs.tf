output "hello_world" {
  description = "Test output"
  value       = "Hello, ${upper(var.environment)} World!"
}

output "random_pet" {
  description = "Dummy output"
  value       = random_pet.main
}
