# Creates snapshot of each VM, then copies each snapshot to destination storage account container
# Need to update storageaccount key to use keyvault
# need to modify loops - create all snapshots first (very fast), then loop through regions
# to copy all snapshots to storage account in that region

$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId

$regions = "westus", "westus2"
$rgNamePrefix = "vmImages-"
$vms = "DC1", "DC2"
$storageAccountPrefix = "vmimagevhds"
$sourceResourceGroupName = "Lab-Kevin-DCPromo"
$location = "westus"

ForEach ($vmName in $vms) {
    #create snapshot of each VM
    $timeStamp = Get-Date -Format "yyyyMMddHHmm"
    $snapshotName = $vmName + $timeStamp
    $snapshotName

    $vm = get-azvm -ResourceGroupName $sourceResourceGroupName -Name $vmName

    $snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy

    New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $sourceResourceGroupName 

    #Copy new snapshot to VMImages storage account in each region
    ForEach ($region in $regions) {   
        $targetResourceGroup = $rgNamePrefix + $region
        $targetStorageAccountName = $storageAccountPrefix + $region
        $targetStorageContainerName = "vmimages"
        $sasExpiryDuration = "3600"
        $destinationVHDFileName = "$snapshotName.vhd"

        #**Need to change to keyvault
        $storageAccountKey = Read-Host -Prompt "$targetStorageAccountName key:" 

        #Generate the SAS for the snapshot 
        $sas = Grant-AzSnapshotAccess -ResourceGroupName $sourceResourceGroupName -SnapshotName $snapshotName -DurationInSecond $sasExpiryDuration -Access Read

        #Create the context for the storage account which will be used to copy snapshot to the storage account 
        $destinationContext = New-AzStorageContext -StorageAccountName $targetStorageAccountName -StorageAccountKey $storageAccountKey

        #Copy the snapshot to the storage account 
        Start-AzStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer $targetStorageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName          
    }
}



