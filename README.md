# AWS Terraform Root Module Template

[![Checkov](https://github.com/aws-samples/aws-terraform-template/actions/workflows/checkov.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/checkov.yml)
[![TFLint](https://github.com/aws-samples/aws-terraform-template/actions/workflows/tflint.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/tflint.yml)
[![terraform-docs](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-docs.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-docs.yml)
[![Terraform test PR](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-test-pr.yml/badge.svg)](https://github.com/aws-samples/aws-terraform-template/actions/workflows/terraform-test-pr.yml)

A template repository for a Terraform root module that deploys to several AWS accounts through the [Terraform reusable workflow](https://github.com/aws-samples/aws-terraform-reusable-workflow). It follows [Best practices for using the Terraform AWS Provider](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/introduction.html) in AWS Prescriptive Guidance.

The template includes:

- An S3 backend with native state locking, completed for each environment by `envs/<environment>/backend.tfbackend`.
- Version constraints with an upper bound for the AWS Provider, and a committed dependency lock file with checksums for Linux, macOS, and Windows.
- `allowed_account_ids` on the AWS Provider, so that a run with credentials for the wrong account stops before it changes anything.
- Unit tests that mock the AWS Provider and need no AWS credentials.
- Deploy and destroy workflows that plan in each environment, wait for the environment's approval, and apply the reviewed plan.
- TFLint, Checkov, terraform-docs, and pre-commit hooks.

## Repository configuration checklist

> Do the steps marked **(Reusable module)** only when you use this template for a reusable module instead of a root module.

- [ ] Update [CONTRIBUTING.md](./CONTRIBUTING.md) for your repository.
- [ ] Update [CODEOWNERS](./CODEOWNERS) with the users or teams that review pull requests.
- [ ] Install the [pre-commit hooks](./CONTRIBUTING.md#install-pre-commit-hooks).
- [ ] Replace the description at the top of this README with what your module deploys.
- [ ] In each AWS account, create the state bucket, its AWS KMS key, the GitHub OIDC identity provider, and the plan and apply IAM roles. See [Option 1: S3 backend with GitHub OIDC](https://github.com/aws-samples/aws-terraform-reusable-workflow#option-1-s3-backend-with-github-oidc) in the reusable workflow README.
- [ ] Create a GitHub environment for each environment (`dev`, `test`, `prod`). For `prod`, add required reviewers and a deployment branch rule that allows only `main`.
- [ ] Create the repository variable `TF_VERSION` (for example, `1.17.0`) and the repository secrets `<ENV>_AWS_PLAN_ROLE_ARN`, `<ENV>_AWS_APPLY_ROLE_ARN`, and `PLAN_ENCRYPTION_KEY`.
- [ ] In a private or internal repository with [GitHub Code Security](https://docs.github.com/en/code-security/concepts/code-scanning/code-scanning) enabled, create the repository variable `CODE_SCANNING_ENABLED` with the value `true`, so that the Checkov workflow uploads its results to code scanning. Public repositories upload them without this variable. In other repositories, the results are only in the workflow log.
- [ ] In each `envs/<environment>/` folder, set your account ID in `terraform.tfvars` and your state bucket in `backend.tfbackend`.
- [ ] In the [Deploy](./.github/workflows/deploy.yml) and [Destroy](./.github/workflows/destroy.yml) workflows, set your environments and Regions, and pin the reusable workflow to the full commit SHA of the release you use.
- [ ] (Reusable module) Delete the `envs` folder, the root `terraform.tfvars` file, the `backend "s3"` block, the `provider "aws"` block, the Deploy and Destroy workflows, and `.terraform.lock.hcl`. Reusable modules don't configure providers or backends, and Terraform reads the lock file only from the root module.
- [ ] (Reusable module) Change the AWS Provider constraint in `versions.tf` to a lower bound only, such as `>= 6.0`, so that callers can choose the version.
- [ ] (Reusable module) Remove `locals.tf` and the `tags` variable if the module doesn't need them. The root module that calls a reusable module usually sets the tags.
- [ ] (Reusable module) Add an `examples` folder with a root module that calls the reusable module.
- [ ] Delete this checklist and start coding.

## Backend configuration

### S3 backend (default)

`providers.tf` declares a partial S3 backend with the settings that every environment shares:

```hcl
terraform {
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
```

Each environment completes it with `envs/<environment>/backend.tfbackend`, so that its state stays in a bucket in its own account:

```hcl
bucket     = "amzn-s3-demo-bucket-dev"
key        = "aws-terraform-template/terraform.tfstate"
region     = "us-east-1"
kms_key_id = "alias/terraform-state"
```

The reusable workflow passes this file to `terraform init`. For local runs, pass it yourself:

```shell
terraform init -backend-config=envs/dev/backend.tfbackend
```

To switch environments locally, run `terraform init -reconfigure` with the other environment's file.

### HCP Terraform or Terraform Enterprise

1. In `providers.tf`, replace the `backend "s3"` block with an empty `cloud` block, and delete the `backend.tfbackend` files:

   ```hcl
   terraform {
     cloud {}
   }
   ```

2. Pass the organization, workspace, and token to the reusable workflow:

   ```yaml
   with:
     tf-organization: ${{ vars.TF_ORGANIZATION }}
     tf-workspace: my-app-dev
   secrets:
     tf-token: ${{ secrets.TF_TOKEN }}
     plan-encryption-key: ${{ secrets.PLAN_ENCRYPTION_KEY }}
   ```

For execution modes, dynamic provider credentials, and Terraform Enterprise, see [Option 2](https://github.com/aws-samples/aws-terraform-reusable-workflow#option-2-hcp-terraform-or-terraform-enterprise) in the reusable workflow README.

## Deploy and destroy

- **Deploy:** pull requests plan `dev` and post the plan as a comment. On `main`, each environment plans, waits for its GitHub environment's approval, and applies that saved plan. Then the next environment starts.
- **Destroy:** run it manually. It destroys `prod`, then `test`, then `dev`, and each destroy plan waits for its environment's approval.

Each environment reads `envs/<environment>/terraform.tfvars`. The workflow also passes `region` and `environment` from its inputs. For sensitive values, use the reusable workflow's `secret-tfvars` secret with ephemeral variables. See [Sensitive variables](https://github.com/aws-samples/aws-terraform-reusable-workflow#sensitive-variables).

## Tests

`tests/unit.tftest.hcl` mocks the AWS Provider with `mock_provider`, so the tests need no AWS credentials. They check the variable validation and the values that the module computes. Run them locally the same way as the Terraform test PR workflow:

```shell
terraform init -backend=false
terraform test
```

Integration tests create real resources, check them, and destroy them. Put them in `tests/integration`, configure the provider in them with `allowed_account_ids` set to a dedicated test account, and run them with credentials for that account:

```shell
terraform test -test-directory=tests/integration
```

For more information, see [Best practices for testing](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/best-practices-for-testing.html) in the guide.

## Module sources

Pin every module that you call, and review a new version before you upgrade to it.

- **Public Terraform Registry:** set `source` to the module address and `version` to an exact version. This is the simplest option, and Dependabot can propose upgrades. The trade-off is that the publisher controls which code a version number points to.

  ```hcl
  module "vpc" {
    source  = "terraform-aws-modules/vpc/aws"
    version = "6.7.3"
  }
  ```

- **Git repository pinned to a commit:** set `ref` to a full commit SHA, and record the release in a comment. The code that runs is always the code that you reviewed. The trade-off is that each upgrade means finding and reviewing a new SHA.

  ```hcl
  module "vpc" {
    source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=b3abd6df2ecf052451a361ed55b8f06f8742a795" # v6.7.3
  }
  ```

- **Private registry:** for modules that your organization publishes in HCP Terraform or Terraform Enterprise, use the registry address and an exact version, such as `source = "app.terraform.io/my-organization/vpc/aws"`.
- **Local path:** for modules in the same repository, use a relative path, such as `source = "./modules/network"`.

Don't use a branch name as `ref`. The code behind a branch changes without review.

### Private modules on GitHub

To download modules from private GitHub repositories in the workflows, set `enable-github-modules: true` and pass a token that can read those repositories as the `github-token` secret. The workflow's own `GITHUB_TOKEN` can read only this repository, so use a GitHub App installation token or a fine-grained personal access token with read-only `contents` access. For details, see [Private modules on GitHub](https://github.com/aws-samples/aws-terraform-reusable-workflow#private-modules-on-github).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.7 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [random_pet.main](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_account_ids"></a> [allowed\_account\_ids](#input\_allowed\_account\_ids) | AWS account IDs that this configuration can deploy to. The AWS Provider stops the run if the credentials belong to any other account. | `list(string)` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Name of the environment where the resources are deployed, such as dev or prod | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where the resources are deployed | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags that the AWS Provider adds to every resource, in addition to Environment | `map(string)` | `{}` | no |

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
