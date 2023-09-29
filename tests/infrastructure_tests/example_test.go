package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	// Uncomment the following line when creating a reusable module.
	// "github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// Go to https://github.com/gruntwork-io/terratest/ for more examples and tests.
func TestTerraformAwsExample(t *testing.T) {
	t.Parallel()

	// Uncomment the following line when creating a reusable module.
	// // Copy providers.tf with deferred deletion
	// defer os.Remove("../providers.tf")
	// files.CopyFile("providers.tf.test", "../providers.tf")

	uniqueId := random.UniqueId()
	envId := strings.ToLower(uniqueId)
	region := os.Getenv("AWS_REGION")

	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../",
		Lock:         true,
		EnvVars: map[string]string{
			"TF_CLOUD_ORGANIZATION": os.Getenv("TF_CLOUD_ORGANIZATION"),
			"TF_CLOUD_HOSTNAME":     os.Getenv("TF_CLOUD_HOSTNAME"),
			"TF_WORKSPACE":          os.Getenv("TF_WORKSPACE"),
			// For Terraform Enterprise, change the domain name in the TF_TOKEN_app_terraform_io variable
			// like documented in https://developer.hashicorp.com/terraform/cli/config/config-file#environment-variable-credentials
			"TF_TOKEN_app_terraform_io": os.Getenv("TF_TOKEN"),
		},
		Vars: map[string]interface{}{
			"region":      region,
			"environment": envId,
		},
	})

	// Clean up resources with "terraform destroy" at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Check that the example resource is in the expected state
	expected_output := fmt.Sprintf("Hello, %s World!", strings.ToUpper(envId))
	hello_world_output := terraform.Output(t, terraformOptions, "hello_world")
	assert.Equal(t, expected_output, hello_world_output)
}
