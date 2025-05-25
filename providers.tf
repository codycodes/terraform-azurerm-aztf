# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id                 = var.subscription_id
  resource_provider_registrations = "none" # TODO: register resource provider
  features {}
}
