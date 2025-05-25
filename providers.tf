# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none" # TODO: register resource provider
  features {}
}

# TODO: register provider
# TODO: remove dependence on az command
# TODO: generate a providers.tf and main.tf
# TODO: provide instructions on what to do after import - remove sensitive values if needed, etc.
# TODO: only generate debug files if there's an error
# TODO: for custom naming of resources generated?  # TODO: revisit this based on number of resources