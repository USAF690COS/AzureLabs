# Find newest VHD image and create snapshots for each VM
# tag storage account with 'Active' and 'Rollback' snapshot names for each VM
# to be referenced in ARM template for VM deployments

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

    # Create snapshot for each VM VHD
    ForEach ($vmName in $vms) {

        $sourceVHD = Get-AzStorageBlob -Container "vmimages" -Context $storageContext -Blob $vmName* | Sort-Object LastModified -Descending | Select-Object -First 1
        $sourceVHDName = $sourceVHD.name
        $sourceVHDURI = $sourceVHD.ICloudBlob.Uri.AbsoluteUri
        $snapshotName = $sourceVHDName.Replace(".vhd","")

        #Create Snapshot from VHD file
        $snapshotConfig = New-AzSnapshotConfig -AccountType $storageType -Location $location -CreateOption Import -StorageAccountId $storageAccountId -SourceUri $sourceVHDURI -HyperVGeneration 'V2'
        $snapshotProvisioningState = New-AzSnapshot -Snapshot $snapshotConfig -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName

        # If snapshot provisioning succeeds:
        If ($snapshotProvisioningState.ProvisioningState -eq 'Succeeded') {

            # Get existing Tags on storage account
            $tagActiveKey = $vmName + "Active"
            $tagActiveValue = $snapshotName
            $tagRollbackKey = $vmName + "Rollback"
            $tagRollbackValue = $storageAccount.Tags.$tagActiveKey

            # If new/current snapshot name is different from previous/active snapshot name
            # then updated 'Active' and 'Rollback' tags
            If ($tagActiveValue -ne $tagRollbackValue) {
                
                # Get existing Tags on storage account and add/update new values
                $resourceTags = $storageAccount.Tags
                $resourceTags.$tagActiveKey = $tagActiveValue
                $resourceTags.$tagRollbackKey = $tagRollbackValue

                Set-AzResource -Tag $resourceTags -ResourceId $storageAccountId -Force
            }
        }
    }
}

