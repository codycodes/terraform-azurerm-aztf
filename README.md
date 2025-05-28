# aztf

Fetch ClickOps Resources from an Azure Subscription and Import Directly to Terraform - 100% Terraform!

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