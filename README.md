# aztf

Fetch ClickOps Resources from an Azure Subscription and Import Directly to Terraform - 100% Terraform!

## Why 🤔

ClickOps & IaC are like yin-yang - one inherently can't exist without the other. When you have a bunch of Azure resources that need to be brought into IaC, this module can help!

While other methods exist, namely [`aztfexport`](https://github.com/Azure/aztfexport) and now the [Azure Portal](https://techcommunity.microsoft.com/blog/azuretoolsblog/announcing-public-preview-of-terraform-export-from-the-azure-portal/4409889), there are a couple downsides, including:

* Requires installing and managing another tool
* Portal only for a single resource that does not provide options of the REST API

Whereas this module allows you to import all resources in your subscription, all within Terraform!

## Features ✨

* **Fetch all resources from your subscription, and attempts to generate config for each to be directly manageable in Terraform thereafter**
  * Generates `import` blocks under the imported.tf file
  * Creates an easy mapping of resources to trace (each resource gets its own file)
  * Any generated configuration issues are added to a log file
* Uses the official `Microsoft.AzureTerraform` provider and REST API endpoint (same as `aztfexport` and Azure Portal!)
  * Supports `azurerm` and `azapi` providers for exported config
  * Automatically names resources following the Terraform resource naming conventions (lowercase underscores ftw!)
  * Provides helpful options not currently found in the Azure Portal, like the ability to control, `var.mask_sensitive_arguments`
* Allows you to specify resources you *don't* want to generate configuration for using `var.resource_ids_to_skip`
* Customizable directory to store generated resources in (could be a separate workspace)
* Helpful `nextSteps.md` sharing what you may need to do next to get the resources fully imported into your Terraform state (& you can turn this off if you want!)

## Setup ⚡

### Root Module Configuration 🔝

When calling this module, from your root module, ensure your provider has the `"Microsoft.AzureTerraform"` provider registered:

```terraform
provider "azurerm" {
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none"
  resource_providers_to_register  = ["Microsoft.AzureTerraform"] # this provider needs to be registered for exporting resources as Terraform!
  features {}
}

provider "azapi" {}
```

### Current Constraints on the Module 🪢

As you can imagine, the ability to use Terraform to generate its own configuration can result in some quirky behavior. Below are some of the quirks and how to resolve them!

#### A Note on Short-Circuiting 🤖

> [!NOTE]
> This module uses shortcircuiting to workaround dynamic values which aren't known at plan-time as they haven't been applied yet.

 To workaround the dynamic apply issue, we have two variables which effectively act in a similar way to the `-target` option of `terraform plan`:

   1. When you initially configure the module, just run a Terraform plan/apply (defaults are set such that it will succeed)
   2. After the first apply, set the `first_run_resources_fetched` input variable to `true` and run a Terraform plan/apply
   3. Finally, set the `second_run_resources_generated` input variable to `true` and run a Terraform plan/apply

At this point, you should be seeing configuration successfully fetched from the provider!

#### A Note on Your Favorite TACOS 🌮

> [!WARNING]
> If you run this plan on a remote, you might not see the configuration files generated!
> See below for the workaround/fix

When running this on a `remote` you may see a successful apply, but scratching your head looking for the configuration!
To workaround this, set the [Execution Mode](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/settings#execution-mode) to `local`