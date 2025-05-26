# nextSteps.md

Hopefully, if everything has gone well, congrats! 🎉
Your resources are now in Terraform but may need a few more updates to work.

Firstly, you will need to create the following files adjacent to the resources in `generated-resources`:

- [ ] **main.tf** - includes your `terraform` block with `required_providers`

- [ ] **providers.tf** - includes relevant `provider` blocks and their configuration

If there are any resources that did not export, you'll find them in`exportTerraformSkippedResourcesAndErrors.log`

Now, some files may have some configuration that does not match the current Terraform requirements.
Navigate to the folder your generated resources are located in and run a `terraform init` followed up by `terraform validate`

Once you have resolved any configuration changes, run `terraform plan`.
If all goes well, you should see a plan with the successfully generated resources correctly setup for import 🤠

> NOTE: there is currently an issue where if files are updated outside of Terraform that were created using the `local_file` resource
> (as in this case), then there is no way to ignore_changes on those files.
  
Instead, you can choose to remove those from state (and if needed re-import them later).
To do so you can follow this pattern:

```terraform
removed {
  from = local_file.azure_resources["0"]

  lifecycle {
    destroy = false
  }
}
```

For more info, check [`removed` block docs](https://developer.hashicorp.com/terraform/language/resources/syntax)
