# AWS Terraform Module Template

[![Checkov](https://github.com/aws-samples/aws-terraform-template/actions/workflows/checkov.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/checkov.yml)
[![TFLint](https://github.com/aws-samples/aws-terraform-template/actions/workflows/tflint.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/tflint.yml)
[![terraform-docs](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-docs.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-docs.yml)
[![Terraform test PR](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-test-pr.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-test-pr.yml)

This repository provides the template to use for all Terraform Modules.
<!-- TOC -->

- [AWS Terraform Module Template](#aws-terraform-module-template)
  - [Repository configuration checklist](#repository-configuration-checklist)
  - [Backend Configuration](#backend-configuration)
    - [Option 1: Terraform Cloud/Enterprise (Default)](#option-1-terraform-cloudenterprise-default)
    - [Option 2: S3 Backend](#option-2-s3-backend)
  - [Module Sourcing](#module-sourcing)
    - [GitHub Module Sourcing](#github-module-sourcing)
    - [Terraform Registry Modules](#terraform-registry-modules)
    - [Local Modules](#local-modules)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Security](#security)
  - [License](#license)

<!-- /TOC -->

## Repository configuration checklist

> Perform the steps identified as **(Reusable module)** when using this template to create a repository that will contain a reusable module. Ignore these steps when creating a standard module.

- [ ] Update the [CONTRIBUTING.md](./CONTRIBUTING.md) file to reflect the current repository
- [ ] Update the [CODEOWNERS](./CODEOWNERS) file with the users or groups that should review pull requests
- [ ] Install [Pre-Commit Hooks](./CONTRIBUTING.md#install-pre-commit-hooks)
- [ ] Install [Visual Studio Code Recommended Extensions](./CONTRIBUTING.md#install-visual-studio-code-recommended-extensions)
- [ ] Update the [description](./README.md#terraform-module-template) in this [README.md](./README.md) file to reflect the solution the module is implementing
- [ ] Create the repository secrets, variables and environments as documented in the [Terraform Reusable Workflow Prerequisites](https://github.com/aws-samples/aws-terraform-reusable-workflow#prerequisites).
- [ ] Update the [Deploy workflow](./.github/workflows/deploy.yml) with your environment, regions, and workflow triggers.
- [ ] (Optional) Update the [Destroy workflow](./.github/workflows/destroy.yml).
- [ ] (Reusable module) Update the content of the `locals.tf` file to what is needed by the reusable module. Usually, `tags` are not created by reusable modules, but rather by modules that call the reusable module.
- [ ] (Reusable module) Delete the [envs](./envs/) folder.
- [ ] (Reusable module) Delete the [terraform.tfvars](./terraform.tfvars) file.
- [ ] (Reusable module) Create an `examples` folder at the root of the repository where to put an example module calling the reusable module. Use a [Git URL](https://developer.hashicorp.com/terraform/language/modules/sources#generic-git-repository) selecting the latest [revision](https://developer.hashicorp.com/terraform/language/modules/sources#selecting-a-revision) to source the reusable module.
- [ ] Configure the S3 backend in providers.tf with your bucket name, key, and region
- [ ] Delete this checklist and start coding!

## Backend Configuration

This template supports two backend configuration options for storing Terraform state:

### Option 1: S3 Backend (Default)

The default configuration uses S3 for state management. The configuration is already set up in `providers.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "path/to/my/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    # Enable state locking with a local lock file (useful for CI/CD environments)
    use_lock_file = true
  }
}
```

Update your GitHub Actions workflow to use the S3 backend:

```yaml
with:
  deploy: true
  tf-version: ${{ vars.TF_VERSION }}
  aws-region: ${{ matrix.region }}
  environment: ${{ matrix.environment }}
  local-execution-mode: true
  ref: v1.3.0
```

### Option 2: Terraform Cloud/Enterprise

Alternatively, you can use Terraform Cloud/Enterprise for state management. To use this option:

1. Delete the `backend "s3"` block and uncomment the `cloud` block in `providers.tf`:
   ```hcl
   terraform {
     cloud {}
   }
   ```

2. Update your GitHub Actions workflow with Terraform Cloud/Enterprise parameters:
   ```yaml
   with:
     tf-organization: ${{ vars.TF_ORGANIZATION }}
     tf-hostname: ${{ vars.TF_HOSTNAME }}
     tf-workspace: ${{ vars.APP_NAME }}-${{ matrix.environment }}
   secrets:
     tf-token: ${{ secrets.TF_TOKEN }}
   ```

## Module Sourcing

This template supports multiple methods for sourcing Terraform modules:

### GitHub Module Sourcing

To source modules from GitHub repositories securely:

#### Public Repository Sourcing

For public repositories, always use commit hashes to prevent supply chain attacks:

1. Public repository root module:
   ```hcl
   module "example" {
     source = "github.com/organization/repository?ref=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"

     # Module inputs
     example_input = "value"
   }
   ```

2. Public repository submodule:
   ```hcl
   module "example" {
     source = "github.com/organization/repository//path/to/module?ref=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"

     # Module inputs
     example_input = "value"
   }
   ```

#### Private Repository Sourcing

For private repositories, you can use version tags as they're within your organization's control:

1. Private repository root module:
   ```hcl
   module "example" {
     source = "github.com/organization/private-repository?ref=v1.0.0"

     # Module inputs
     example_input = "value"
   }
   ```

2. Private repository submodule:
   ```hcl
   module "example" {
     source = "github.com/organization/private-repository//path/to/module?ref=v1.0.0"

     # Module inputs
     example_input = "value"
   }
   ```

#### GitHub Actions Configuration

Update your GitHub Actions workflow to enable GitHub module sourcing:

```yaml
with:
  local-execution-mode: true
  enable-github-modules: true
secrets:
  github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Terraform Registry Modules

#### Public Registry Modules

For public registry modules, it's recommended to use the GitHub source instead of the Terraform Registry for better security control:

```hcl
# RECOMMENDED: Source directly from GitHub with commit hash pinning
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0"

  # Module inputs
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

```hcl
# NOT RECOMMENDED: Using Terraform Registry for public modules
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  # Module inputs
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

Using GitHub source with commit hash pinning provides better protection against supply chain attacks compared to the Terraform Registry, as it ensures the exact code version is used and cannot be tampered with.

#### Private Registry Modules

For private registry modules within your organization:

```hcl
module "internal_vpc" {
  source  = "app.terraform.io/my-organization/vpc/aws"
  version = "1.0.0"

  # Module inputs
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

### Security Best Practices

1. **Public modules**: Always pin to specific commit hashes to prevent supply chain attacks
2. **Private modules**: Version tags are acceptable as they're within your organization's control
3. **Avoid using branch references** as they can change over time:
   ```hcl
   # NOT RECOMMENDED for production
   module "example" {
     source = "github.com/organization/repository?ref=main"
   }
   ```
4. **Regularly audit and update** pinned versions to incorporate security patches

### Local Modules

To source modules from local paths:

```hcl
module "local_example" {
  source = "./modules/example"

  # Module inputs
  example_input = "value"
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | >=3.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [random_pet.main](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | The environment where to deploy the solution | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region where to deploy the resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hello_world"></a> [hello\_world](#output\_hello\_world) | Test output |
| <a name="output_random_pet"></a> [random\_pet](#output\_random\_pet) | Dummy output |
<!-- END_TF_DOCS -->

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=5.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >=3.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | >=3.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [random_pet.main](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | The environment where to deploy the solution | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region where to deploy the resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_hello_world"></a> [hello\_world](#output\_hello\_world) | Test output used by Terrastest |
| <a name="output_random_pet"></a> [random\_pet](#output\_random\_pet) | Dummy output |
<!-- END_TF_DOCS -->
