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
- Unit tests that mock the AWS Provider and need no AWS credentials, and an integration test that runs against a dedicated test account.
- Deploy and destroy workflows that plan in each environment, wait for the environment's approval where GitHub supports required reviewers, and apply the reviewed plan.
- TFLint, Checkov, terraform-docs, and pre-commit hooks.

> [!IMPORTANT]
> This is sample code, for non-production usage. You should work with your security and legal teams to meet your organizational security, regulatory, and compliance requirements before deployment.

## Repository configuration checklist

> Do the steps marked **(Reusable module)** only when you use this template for a reusable module instead of a root module.

- [ ] Update [CONTRIBUTING.md](./CONTRIBUTING.md) for your repository.
- [ ] Update [CODEOWNERS](./CODEOWNERS) with the users or teams that review pull requests.
- [ ] Install the [pre-commit hooks](./CONTRIBUTING.md#install-pre-commit-hooks).
- [ ] Replace the description at the top of this README with what your module deploys.
- [ ] In each AWS account, create the state bucket, its AWS KMS key, the GitHub OIDC identity provider, and the plan and apply IAM roles. See [Option 1: S3 backend with GitHub OIDC](https://github.com/aws-samples/aws-terraform-reusable-workflow#option-1-s3-backend-with-github-oidc) in the reusable workflow README. A repository created from this template after July 15, 2026 uses GitHub's [immutable OIDC subject format](https://docs.github.com/en/actions/reference/security/oidc#immutable-subject-claims), `repo:OWNER@OWNER-ID/REPO@REPO-ID`, so write the trust policies with that prefix. Get it with `gh api repos/OWNER/REPO/actions/oidc/customization/sub --jq .sub_claim_prefix`. Configure the bucket and the roles as described in [Security considerations](#security-considerations).
- [ ] Create a GitHub environment for each environment (`dev`, `test`, `prod`). For `prod`, add required reviewers and a deployment branch rule that allows only `main`. Required reviewers need a public repository, or GitHub Enterprise Cloud for a private or internal one. Without them, each environment applies right after its plan. See [Requirements](https://github.com/aws-samples/aws-terraform-reusable-workflow#requirements) in the reusable workflow README.
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

- **Deploy:** pull requests plan `dev` and post the plan as a comment. On `main`, each environment plans, waits for its GitHub environment's approval, and applies that saved plan. Then the next environment starts. An environment without required reviewers applies right after its plan.
- **Destroy:** run it manually. It destroys `prod`, then `test`, then `dev`, and each destroy plan waits for its environment's approval. Each destroy also appears in the environment's deployment history as a deployment that is now inactive. See [Destroy workflow](https://github.com/aws-samples/aws-terraform-reusable-workflow#destroy-workflow) in the reusable workflow README.

Each environment reads `envs/<environment>/terraform.tfvars`. The workflow also passes `region` and `environment` from its inputs. For sensitive values, use the reusable workflow's `secret-tfvars` secret with ephemeral variables. See [Sensitive variables](https://github.com/aws-samples/aws-terraform-reusable-workflow#sensitive-variables).

## Security considerations

### State bucket

Create each environment's state bucket with these controls. For details, see [Secure remote state storage](https://docs.aws.amazon.com/prescriptive-guidance/latest/terraform-aws-provider-best-practices/security.html#remote-state-storage) in the guide.

- **Versioning:** turn on S3 Versioning, so that you can restore an earlier version of the state.
- **Block Public Access:** keep all four S3 Block Public Access settings on, and keep Object Ownership set to Bucket owner enforced so that ACLs are disabled. New buckets have both by default.
- **TLS only:** add a bucket policy statement that denies `s3:*` on the bucket and its objects to every principal when `aws:SecureTransport` is `false`.
- **AWS KMS key:** encrypt the state with a customer managed key, the `kms_key_id` in `backend.tfbackend`. Write a key policy that lets only the plan and apply roles, and any role that people use for local runs, use the key, and only your key administrators manage it. The default key policy also lets IAM policies in the account grant use of the key.
- **Role permissions:** give each role access only to its state key, the lock file, and the key. See [AWS IAM](https://github.com/aws-samples/aws-terraform-reusable-workflow#aws-iam) in the reusable workflow README.

### Pull request plans

On pull requests, the Deploy workflow plans `dev` with the dev plan role. The plan runs the pull request's Terraform code before anyone reviews it. Providers, modules, and data sources such as `external` can run commands with the plan role's credentials, which can read the dev state. By default, workflows for pull requests from forks don't receive secrets or an OIDC token, so this applies to anyone who can push a branch to this repository. For the full list of what that code can reach, see [Security considerations](https://github.com/aws-samples/aws-terraform-reusable-workflow#security-considerations) in the reusable workflow README. In this repository:

- Trust the `pull_request` subject only in the dev plan role. The test and prod jobs plan only on `main`, so their plan roles need only `ref:refs/heads/main`.
- Protect `main` with a [ruleset](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets) or branch protection rule that requires an approving review from the code owners in [CODEOWNERS](./CODEOWNERS).
- Give write access only to people you trust with the dev plan role and the repository's secrets.

The Terraform test PR workflow runs the unit tests without AWS credentials or a backend.

## Tests

`tests/unit.tftest.hcl` mocks the AWS Provider with `mock_provider`, so the tests need no AWS credentials. They check the variable validation and the values that the module computes. Run them locally the same way as the Terraform test PR workflow:

```shell
terraform init -backend=false
terraform test
```

Integration tests apply the configuration with real credentials, check the results, and destroy what they created. `tests/integration/integration.tftest.hcl` uses the real AWS Provider with credentials for a dedicated test account, not one of the accounts in `envs`. Its provider block replaces the one in `providers.tf` and sets `allowed_account_ids` to the test account, so a run with credentials for any other account stops before Terraform creates anything. The test has two runs:

- `provider_context` applies the helper module in `tests/integration/provider_context`, which only reads data sources. It checks the account, Region, and default tags that the AWS Provider resolved.
- `apply` applies the root module and checks its outputs. When you add resources, add assertions on them to this run.

When the test finishes, `terraform test` destroys what it created, even if an assertion fails. The sample's only resource is `random_pet`, so the test creates nothing in the account, and a read-only role is enough to run it.

The test needs Terraform 1.13 or later. Initialize with its test directory so that Terraform installs the helper module, and pass the ID of the test account, which must be a dedicated account and not one of the accounts in `envs`. `region` defaults to `us-east-1`:

```shell
terraform init -backend=false -test-directory=tests/integration
terraform test -test-directory=tests/integration \
  -var='allowed_account_ids=["999988887777"]' \
  -var='region=us-east-1'
```

The Terraform test PR workflow runs only the tests in `tests`, so it doesn't run the integration test and needs no AWS credentials.

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
