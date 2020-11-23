# Maintenance Powershell Scripts

## BackupVMs
Creates a VHD snapshot of each OS and data disk, if any, for a VM. Each snapshot is then copied to a storage account in the respective Azure regions for future lab deployments.

### Parameters
    VMLIST
        - Required: No
        - Type: String
        - Description: Comma separated value of VM names to be backed up. Ex. VM1,VM2, VM3. 
        Type 'all' to back up all VMs in the master resource group. 

### Outputs
N/A


## CleanUpImages
Manages storage of VHD snapshots per region and storage account. Ensures we have copies of the last 4 most recent snapshots/blobs and at least 1 snapshot/blob per disk from the last 6 months. This will allow us to rollback to different versions of the VMs in the master resource group.

### Parameters
N/A

### Outputs
N/A


## ProvisionSnapshots
Used to provision new snapshots and update deployment tags used to deploy VMs in new labs.

### Parameters
N/A

### Outputs
N/A