module "aztf" {
  source  = "app.terraform.io/codycodes/aztf/azurerm"
  version = "0.0.1"

  # as these are both true, this is the end state of the module
  # where the resources have been fetched and now exist
  first_run_resources_fetched    = true
  second_run_resources_generated = true

  create_next_steps = true # create a file with the nextSteps after resources are fetched

  generated_resources_directory = "./generated-resources" # will place on your local machine here
  subscription_id               = var.subscription_id
  mask_sensitive_arguments      = true
  target_provider               = "azurerm"

}
