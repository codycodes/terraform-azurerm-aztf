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
resource "azapi_resource_action" "fetch_resources" {
  type        = "Microsoft.ResourceGraph@2024-04-01"
  resource_id = "/providers/Microsoft.ResourceGraph"
  method      = "POST"
  action      = "resources"

  body = {
    query         = "resources"
    subscriptions = [var.subscription_id]
  }

  response_export_values = ["*"]
}

resource "local_file" "azure_resources" {
  filename = "./azure-resources.yaml"
  content  = yamlencode([for resource in azapi_resource_action.fetch_resources.output.data : { name = resource.name, id = resource.id }])
}

locals {
  resources = yamldecode(local_file.azure_resources.content)
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
    resourceName   = "resource${count.index}"
    fullProperties = false # we want as close to valid tf as possible
    targetProvider = var.target_provider
    maskSensitive  = var.mask_sensitive_arguments
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
  content  = replace(can(azapi_resource_action.export_terraform_simple[count.index].output.properties.configuration) ? azapi_resource_action.export_terraform_simple[count.index].output.properties.configuration : "", local.tf_block_replace, "")
}

# generate single import file for resources
resource "local_file" "exported_terraform_import" {
  filename = "./generated-resources/imported.tf"
  content  = join("\n", [for i, v in local.resources : can(azapi_resource_action.export_terraform_simple[i].output.properties.import) ? azapi_resource_action.export_terraform_simple[i].output.properties.import : ""])
}

resource "local_file" "exported_terraform_debug" {
  count = length(local.resources)

  filename = "./debug/${count.index}-${local.resources[count.index].name}.txt"
  # values cannot result to null in string templates
  content = <<EOT
  errors: ${azapi_resource_action.export_terraform_simple[count.index].output.properties.errors == null ? "" : join("\n", azapi_resource_action.export_terraform_simple[count.index].output.properties.errors)}
  skipped resources: ${azapi_resource_action.export_terraform_simple[count.index].output.properties.skippedResources == null ? "" : join("\n", azapi_resource_action.export_terraform_simple[count.index].output.properties.skippedResources)}
  EOT
}
