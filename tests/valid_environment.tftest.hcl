variables {
  region      = "us-east-1"
  environment = "dev"
}

run "valid_environment" {

  command = apply

  assert {
    condition     = output.hello_world == "Hello, DEV World!"
    error_message = "Environment name did not match expected"
  }
}
