variable "subscription_id" {
  type        = string
  description = "Subscription ID to fetch all resources for"
}

variable "azurerm_export_terraform_verison" {
  type        = string
  description = "Current version used for the exportTerraform endpoint - if terraform block isn't removed from generated code this value should be updated to match the latest version"
  default     = "4.24.0"
}
