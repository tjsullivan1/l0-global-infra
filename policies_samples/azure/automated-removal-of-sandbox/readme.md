# Auto-deleting expired resources from Azure

This is a sample of an Azure Automation job and policy that combined will cleanup Azure resources.

## Deployment
### Policy

First, you will need to create a new policy definition based on add-expiration-policy.json. You can configure timestamp by adjusting this value: "value": "[addDays(utcNow(), 2)]". In my sample, this is set to two days forward. This will automatically add a tag ("ExpirationDate") to all resource groups that are created or updated in an Azure subscription where this policy is assigned. The policy will not modify the tag if it exists, but will recreate if it is deleted. The value is not enforced, so a user with permissions can modify this value. 

### Azure Automation Runbook

Remove-ExpiredResources.ps1 can be added as a runbook in Azure Automation and then scheduled to run on a daily basis. It will evaluate the expiration tag and delete the resource groups that have a date in the past.

## Potential Future Enhancements

- An allow list of resources to allow to remain around longer (rather than a longLived tag)
- An evaluation of long-lived resources by resource creation date and notification that those resources are still there
- Cost analysis of long-lived resources