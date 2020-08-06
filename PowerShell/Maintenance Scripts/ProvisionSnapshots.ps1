# Find newest VHD image and create snapshots for each VM
# (Note: only creates new snap if VHD file is newer than current/latest snap)
# Tag storage account with 'Active' and 'Rollback' snapshot names for each VM
# (Tags referenced in ARM template for VM deployments)

$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId

$storageType = 'Standard_LRS'
$storageAccountPrefix = "vmimagevhds"
$regions = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'LabRegions' -ResourceGroupName 'LabAutomation').Value
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
        # Get VM Generation (V1 or V2)
        $vmSourceDisk = (Get-AzVM -ResourceGroupName $masterResourceGroupName -Name $vmName).StorageProfile.OsDisk.Name
        $vmGen = (Get-AzDisk -ResourceGroupName $masterResourceGroupName -DiskName $vmSourceDisk).HyperVGeneration
        
        # Find OS Disk
        $vmOSDisk = $vmName + '-T'
        $osVHD = Get-AzStorageBlob -Container "vmimages" -Context $storageContext -Blob $vmOSDisk* | Sort-Object LastModified -Descending | Select-Object -First 1
        $osVHDName = $osVHD.name

        # Search for corresponding data disks with same timestamp
        $diskTimestamp = $osVHDName.Replace($vmName, "")
        $allDisks = Get-AzStorageBlob -Container "vmimages" -Context $storageContext -Blob $vmName* | Where-Object -Property Name -Like *$diskTimestamp

        ForEach ($disk in $allDisks) {
            $sourceVHDName = $disk.name
            $sourceVHDURI = $disk.ICloudBlob.Uri.AbsoluteUri
            $snapshotName = $sourceVHDName.Replace(".vhd","")
            $diskName = $sourceVHDName.Replace($diskTimestamp,"")

            #Create Snapshot from VHD file
            $snapshotConfig = New-AzSnapshotConfig -AccountType $storageType -Location $location -CreateOption Import -StorageAccountId $storageAccountId -SourceUri $sourceVHDURI -HyperVGeneration $vmGen
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
                }
            }
        }
    }
}