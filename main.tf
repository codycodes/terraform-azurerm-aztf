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
  resources    = yamldecode(local_file.azure_resources.content)
  resource_map = tomap({ for i, v in local.resources : i => v })
}

# generate terraform for each resource and save to file
resource "azapi_resource_action" "export_terraform" {
  for_each = local.resource_map

  type        = "Microsoft.AzureTerraform@2023-07-01-preview"
  resource_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.AzureTerraform"
  action      = "exportTerraform"
  method      = "POST"

  body = {
    type           = "ExportResource"
    resourceName   = "resource_${each.key}"
    fullProperties = false # we want as close to valid tf as possible
    targetProvider = var.target_provider
    maskSensitive  = var.mask_sensitive_arguments
    resourceIds = [
      each.value.id
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

# NOTE: if these files are edited outside of Terraform, you may want to consider removing them from state
#       using a removed block with destroy set to false
#       please track the following issue for updates: https://github.com/hashicorp/terraform-provider-local/issues/262
resource "local_file" "exported_terraform" {
  for_each = tomap(
    {
      for i, resource in azapi_resource_action.export_terraform : i => resource
      if can(resource.output.properties.configuration) && !contains(var.resource_ids_to_skip, one(resource.body.resourceIds))
    }
  )

  filename = "./generated-resources/${each.key}-${local.resource_map[each.key].name}.tf"
  content  = replace(each.value.output.properties.configuration, local.tf_block_replace, "")

  lifecycle {
    # currently this option is not respected (changes are not ignored if file is updated)
    ignore_changes = [content]
  }
}

# generate single import file for resources
resource "local_file" "exported_terraform_import" {
  filename = "./generated-resources/imported.tf"
  content = join("\n", [
    for i, v in local.resources : can(values(azapi_resource_action.export_terraform)[i].output.properties.import) ?
    values(azapi_resource_action.export_terraform)[i].output.properties.import :
    "# Could not import ${one(values(azapi_resource_action.export_terraform)[i].body.resourceIds)}, please check debug log for details\n"
    ]
  )
}

# generate debug info (if applicable)
locals {
  debug_resources = [
    for i, resource in azapi_resource_action.export_terraform :
    {
      name              = local.resource_map[i].name
      errors            = resource.output.properties.errors,
      skipped_resources = resource.output.properties.skippedResources,
    } if resource.output.properties.errors != null || resource.output.properties.skippedResources != null
  ]
}

resource "local_file" "exported_terraform_debug" {
  count = length(local.debug_resources) >= 1 ? 1 : 0

  filename = "./exportTerraformSkippedResourcesAndErrors.log"
  content  = yamlencode(local.debug_resources)
}
