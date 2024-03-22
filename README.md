# AWS Terraform Module Template

[![Checkov](https://github.com/aws-samples/aws-terraform-template/actions/workflows/checkov.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/checkov.yml)
[![TFLint](https://github.com/aws-samples/aws-terraform-template/actions/workflows/tflint.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/tflint.yml)
[![terraform-docs](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-docs.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-docs.yml)
[![Terraform test PR](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-test-pr.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-test-pr.yml)

This repository provides the template to use for all Terraform Modules.
<!-- TOC -->

- [AWS Terraform Module Template](#aws-terraform-module-template)
  - [Repository configuration checklist](#repository-configuration-checklist)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Security](#security)
  - [License](#license)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

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
- [ ] Delete this checklist and start coding!

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
