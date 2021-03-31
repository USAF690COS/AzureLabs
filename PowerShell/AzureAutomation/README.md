# Azure Automation Powershell Scripts/Runbooks

## DeployLab
Powershell runbook used to deploy a lab instance.

### Parameters
*Placeholder*

### Outputs
*Placeholder*


## BackupVMs
Powershell runbook used to backup master VMs for generating new templates. 
> [!NOTE] Use the 'LabRegions' variable in the LabAutomation account to specify where backups of the VMs should be stored.
> This allows snapshots of those VMs to be readily accessible in regions where the labs would be deployed.

### Parameters
*Placeholder*

### Outputs
*Placeholder*


## ProvisionImageSnapshots
Powershell runbook used to provision new snapshots and update deployment tags used to deploy VMs in new labs.

### Parameters
*Placeholder*

### Outputs
*Placeholder*