terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

# fetch all the resources in the subscription
resource "null_resource" "export_azure_resources_yaml" {
  provisioner "local-exec" {
    command = "az resource list --output yaml > azure-resources.yaml"
  }
}

data "local_file" "azure_resources" {
  depends_on = [null_resource.export_azure_resources_yaml]
  filename   = "./azure-resources.yaml"
}

locals {
  resources = yamldecode(data.local_file.azure_resources.content)
}

# generate terraform for each resource using count and save to files
resource "azapi_resource_action" "export_terraform_simple" {
  count = length(local.resources)

  type        = "Microsoft.AzureTerraform@2023-07-01-preview"
  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.AzureTerraform"
  action      = "exportTerraform"
  method      = "POST"

  body = {
    type           = "ExportResource"
    targetProvider = "azurerm"
    maskSensitive  = false
    resourceIds = [
      local.resources[count.index].id
    ]
  }

  response_export_values = ["*"]
}

locals {
  tf_block_replace = <<-EOT
  terraform {
    required_providers {
      azurerm = {
        source  = "azurerm"
        version = "${var.azurerm_export_terraform_verison}"
      }
    }
  }
  provider "azurerm" {
    features {}
  }
  EOT
}

resource "local_file" "exported_terraform" {
  count = length(local.resources)

  filename = "./generated-resources/${count.index}-${local.resources[count.index].name}.tf"
  content  = replace(azapi_resource_action.export_terraform_simple[count.index].output.properties.configuration, local.tf_block_replace, "")
}

# generate single import file for resources
resource "local_file" "exported_terraform_import" {
  filename = "./generated-resources/imported.tf"
  content  = join("\n", [for i, v in local.resources : azapi_resource_action.export_terraform_simple[i].output.properties.import])
}

resource "local_file" "exported_terraform_debug" {
  count = length(local.resources)

  filename = "./debug/${count.index}-${local.resources[count.index].name}.tf"
  # values cannot result to null in string templates
  content = <<EOT
  errors: ${azapi_resource_action.export_terraform_simple[count.index].output.properties.errors == null ? "" : azapi_resource_action.export_terraform_simple[count.index].output.properties.errors}
  skipped resources: ${azapi_resource_action.export_terraform_simple[count.index].output.properties.skippedResources == null ? "" : azapi_resource_action.export_terraform_simple[count.index].output.properties.skippedResources}
  EOT
}
