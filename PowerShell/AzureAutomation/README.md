# Azure Automation Powershell Scripts/Runbooks

## DeployLab
Powershell runbook used to deploy a lab instance.

### Parameters
*Placeholder*

### Outputs
*Placeholder*


## BackupVMs
Powershell runbook used to backup master VMs for generating new templates. 
>**NOTE** Use the 'LabRegions' variable in the Azure LabAutomation account to specify where backups of the VMs should be stored. Backups/snapshots need to be accessible in the region where a lab is provisioned. We are currently using the following region(s): westus2

### Parameters
*Placeholder*

### Outputs
*Placeholder*


## ProvisionImageSnapshots
Powershell runbook used to provision new snapshots and update deployment tags used to deploy VMs in new labs.
>**NOTE** All regions where backups are stored will have tags updated to ensure the latest backups/snapshots are used when provisioning a lab environment.

### Parameters
*Placeholder*

### Outputs
*Placeholder*