# aztf

Fetch ClickOps Resources from an Azure Subscription and Import Directly to Terraform - 100% Terraform!

## Setup

### Simple configuration

```terraform
provider "azurerm" {
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.AzureTerraform"] # this provider needs to be registered for exporting resources as Terraform!
  features {}
}

provider "azapi" {}
```
