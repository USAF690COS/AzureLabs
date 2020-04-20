# Creates snapshot of each VM, then copies each snapshot to destination storage account containers

$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId

$regions = "westus", "westus2"
# $rgNamePrefix = "vmImages-"
$vms = "DC1", "DC2"
$storageAccountPrefix = "vmimagevhds"
$sourceResourceGroupName = "Lab-Kevin-DCPromo"
$location = "westus"
$destinationContext = @()
$snapshotList = @()
$sas = @()

# Create snapshot of all VMs
ForEach ($vmName in $vms) {
    $timeStamp = Get-Date -Format "yyyyMMddHHmm"
    $snapshotName = $vmName + $timeStamp
    $snapshotList += $snapshotName

    #Create Snapshot of VM and get SAS access token
    $vm = get-azvm -ResourceGroupName $sourceResourceGroupName -Name $vmName
    $snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
    New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $sourceResourceGroupName 
    $sas += Grant-AzSnapshotAccess -ResourceGroupName $sourceResourceGroupName -SnapshotName $snapshotName -DurationInSecond $sasExpiryDuration -Access Read
}

# Copy new snapshot to VMImages storage account in each region
For ($counter=0 ; $counter -lt $regions.Length; $counter++) { 
    $targetStorageAccountName = $storageAccountPrefix + $regions[$counter]
    $targetStorageContainerName = "vmimages"
    $sasExpiryDuration = "3600"
    $keyName = "snapStorageKey-" + $regions[$counter]    
    $storageAccountKey = (Get-AzKeyVaultSecret -vaultName "USAF-690COS-LabKeys" -name $keyName).SecretValueText
    $destinationContext += New-AzStorageContext -StorageAccountName $targetStorageAccountName -StorageAccountKey $storageAccountKey

    For ($vmCount = 0; $vmCount -lt $snapshotList.Length; $vmCount++) {
        #Copy the snapshot to the storage account 
        $vmSnapName = $snapshotList[$vmCount]
        $destinationVHDFileName = "$vmSnapName.vhd"
        Start-AzStorageBlobCopy -AbsoluteUri $sas[$vmCount].AccessSAS -DestContainer $targetStorageContainerName -DestContext $destinationContext[$counter] -DestBlob $destinationVHDFileName          
    }
}