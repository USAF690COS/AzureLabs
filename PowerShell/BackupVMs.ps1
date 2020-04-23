# Creates snapshot of each VM, then copies each snapshot to destination storage account containers

$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId

$storageAccountPrefix = "vmimagevhds"
$regions = "westus", "westus2"
$masterImageRG = "MasterImageSnapshots"

# Name of RG containing master VMs
$sourceResourceGroupName = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'MasterRGName' -ResourceGroupName 'LabAutomation').Value
$vms = (Get-AzVM -ResourceGroupName $sourceResourceGroupName).name
$location = (Get-AzResourceGroup -Name $sourceResourceGroupName).Location
$destinationContext = @()
$snapshotList = @()
$sas = @()

# Create snapshot of all VMs
ForEach ($vmName in $vms) {
    $timeStamp = Get-Date -Format "yyyyMMddHHmm"
    $snapshotName = $vmName + '-T' + $timeStamp
    $snapshotList += $snapshotName

    #Create Snapshot of VM and get SAS access token
    $vm = get-azvm -ResourceGroupName $sourceResourceGroupName -Name $vmName
    $snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
    New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $masterImageRG 
    $sas += Grant-AzSnapshotAccess -ResourceGroupName $masterImageRG -SnapshotName $snapshotName -DurationInSecond $sasExpiryDuration -Access Read
}

# Copy snapshot vhd file to VMImages storage account in each region
For ($counter=0 ; $counter -lt $regions.Length; $counter++) { 
    $targetStorageAccountName = $storageAccountPrefix + $regions[$counter]
    $targetStorageContainerName = "vmimages"
    $sasExpiryDuration = "7200"
    $keyName = "snapStorageKey-" + $regions[$counter]    
    $storageAccountKey = (Get-AzKeyVaultSecret -vaultName "USAF-690COS-LabKeys" -name $keyName).SecretValueText
    $destinationContext += New-AzStorageContext -StorageAccountName $targetStorageAccountName -StorageAccountKey $storageAccountKey

    For ($vmCount = 0; $vmCount -lt $snapshotList.Length; $vmCount++) {
        $vmSnapName = $snapshotList[$vmCount]
        $destinationVHDFileName = "$vmSnapName.vhd"
        Start-AzStorageBlobCopy -AbsoluteUri $sas[$vmCount].AccessSAS -DestContainer $targetStorageContainerName -DestContext $destinationContext[$counter] -DestBlob $destinationVHDFileName          
    }
}