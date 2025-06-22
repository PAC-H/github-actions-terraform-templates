package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestTerraformBasicExample(t *testing.T) {
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../../terraform/environments/staging",
		Vars: map[string]interface{}{
			"resource_group_name": "test-rg-terratest",
			"location":            "East US",
		},
	})

	// defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	assert.Equal(t, "test-rg-terratest", resourceGroupName)
}
