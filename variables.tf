variable "subscription_id" {
  type        = string
  description = "Subscription ID to fetch all resources for"
}

variable "azurerm_export_terraform_verison" {
  type        = string
  description = "Current version used for the exportTerraform endpoint - if terraform block isn't removed from generated code this value should be updated to match the latest version"
  default     = "4.24.0"
}

variable "resource_ids_to_skip" {
  type        = list(string)
  description = "List of resource IDs to skip. Can be run after resource IDs are fetched to file"
  default     = []
}

variable "create_next_steps" {
  type        = bool
  description = "Should a nextSteps.md document be generated to instruct the maintainer after resources have been generated?"
  default     = true
}

# the following are opinionated variables for the module that can be overriddencheck
variable "mask_sensitive_arguments" {
  type        = bool
  description = "Should sensitive attributes be included with the generated template? Defaults to false"
  default     = true
}

variable "target_provider" {
  type        = string
  description = "Configures the generated code to use the azurerm or azapi provider"
  default     = "azurerm"
  validation {
    condition     = var.target_provider == "azurerm" || var.target_provider == "azapi"
    error_message = "The target_provider only supports azurerm or azapi"
  }
}

# These are workaround variables that allow us to handle dynamic collections of data only known at apply time.
# For Terraform to successfully plan further stages, it needs to have fetched these values into state first
variable "first_run_resources_fetched" {
  type        = bool
  description = "Workaround to short-circuit apply-time dependencies. The first run should have this set to 'false' with subsequent runs set to 'true'"
  default     = false
}
variable "second_run_resources_generated" {
  type        = bool
  description = "Workaround to short-circuit apply-time dependencies. The first & second runs should have this set to 'false' with subsequent runs set to 'true'"
  default     = false
}


