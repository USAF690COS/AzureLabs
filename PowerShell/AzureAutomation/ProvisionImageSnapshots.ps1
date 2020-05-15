<#
    .DESCRIPTION
        Finds newly created VHD backups of master VMs (created using the 'BackupVMs.ps1' script).
        Provisions snapshots for VM images to be used during automated lab deployment.
        Updates tags for 'Active' and 'Rollback' VM images, referenced by ARM templates for automation.

    .NOTES
        AUTHOR: Kevin Dillon
        LASTEDIT: 5-14-2020
#>

$connectionName = "AzureRunAsConnection"

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process

$connection = Get-AutomationConnection -Name $connectionName

# Wrap authentication in retry logic for transient network failures
$logonAttempt = 0
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzAccount `
                               -ServicePrincipal `
                               -Tenant $connection.TenantID `
                               -ApplicationId $connection.ApplicationID `
                               -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}

<#
    Start snapshot provisioning script
#>

$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId

$storageType = 'Standard_LRS'
$storageAccountPrefix = "vmimagevhds"
$regions = "westus", "westus2"
$masterResourceGroupName = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'MasterRGName' -ResourceGroupName 'LabAutomation').Value
$vms = (Get-AzVM -ResourceGroupName $masterResourceGroupName).name

ForEach ($region in $regions) {
    $resourceGroupName = "vmImages-" + $region
    $location = (Get-AzResourceGroup -Name $resourceGroupName).Location
    $storageAccountName = $storageAccountPrefix + $region
    $storageContainerName = "vmimages"
    $storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
    $storageAccountId = $storageAccount.Id
    $keyName = "snapStorageKey-" + $region    
    $storageAccountKey = (Get-AzKeyVaultSecret -vaultName "USAF-690COS-LabKeys" -name $keyName).SecretValueText
    $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

    # Find all disks for VM and create snapshot for each VHD
    ForEach ($vmName in $vms) {
        # Find OS Disk
        $vmOSDisk = $vmName + '-T'
        $osVHD = Get-AzStorageBlob -Container "vmimages" -Context $storageContext -Blob $vmOSDisk* | Sort-Object LastModified -Descending | Select-Object -First 1
        $osVHDName = $osVHD.name

        # If no disk is found (VM has never been backed up) then skip this VM
        If (!$osVHDName) {continue}

        # Search for corresponding data disks with same timestamp
        $diskTimestamp = $osVHDName.Replace($vmName, "")
        $allDisks = Get-AzStorageBlob -Container "vmimages" -Context $storageContext -Blob $vmName* | Where-Object -Property Name -Like *$diskTimestamp

        ForEach ($disk in $allDisks) {
            $sourceVHDName = $disk.name
            $sourceVHDURI = $disk.ICloudBlob.Uri.AbsoluteUri
            $snapshotName = $sourceVHDName.Replace(".vhd","")
            $diskName = $sourceVHDName.Replace($diskTimestamp,"")

            #Create Snapshot from VHD file
            $snapshotConfig = New-AzSnapshotConfig -AccountType $storageType -Location $location -CreateOption Import -StorageAccountId $storageAccountId -SourceUri $sourceVHDURI -HyperVGeneration 'V2'
            $snapshotProvisioningState = New-AzSnapshot -Snapshot $snapshotConfig -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName

            # If snapshot provisioning succeeds:
            If ($snapshotProvisioningState.ProvisioningState -eq 'Succeeded') {

                # Get existing Tags on storage account
                $tagActiveKey = $diskName + "Active"
                $tagActiveValue = $snapshotName
                $tagRollbackKey = $diskName + "Rollback"
                $tagRollbackValue = $storageAccount.Tags.$tagActiveKey

                # If new/current snapshot name is different from previous/active snapshot name
                # then updated 'Active' and 'Rollback' tags
                If ($tagActiveValue -ne $tagRollbackValue) {
                    
                    # Get existing Tags on storage account and add/update new values
                    $resourceTags = $storageAccount.Tags
                    $resourceTags.$tagRollbackKey = $tagRollbackValue
                    $resourceTags.$tagActiveKey = $tagActiveValue

                    Set-AzResource -Tag $resourceTags -ResourceId $storageAccountId -Force
                    Write-Output ("Updated active VM image snapshot for VM disk: " + $diskName)
                }
            }
        }
    }
}
