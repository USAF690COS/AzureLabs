# Get VM list from user
Write-Host "Type a list of VM(s) to back-up, or type" -ForegroundColor Green -NoNewline
Write-Host " [all] " -ForegroundColor Yellow -NoNewline
Write-Host "to backup all VMs: " -ForegroundColor Green
Write-Host "(Example: VM1, VM2, VM3)" -ForegroundColor Blue
$vmList = Read-Host

# Get current subscription
$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId

# Get Master Environment Resource Group Name
$sourceResourceGroupName = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'MasterRGName' -ResourceGroupName 'LabAutomation').Value

# Get list of VMs based on input parameter (delimited string; or 'all': get all VMs from Maseter RG)
If ($vmList.ToLower() -eq 'all') {
    $vms = (Get-AzVM -ResourceGroupName $sourceResourceGroupName).name
}
else {
    $vms = $vmList.Split(",")
    $vms = $vms | ForEach-Object {$_.Trim()}
}

# Setup variables
$storageAccountPrefix = "vmimagevhds"
$regions = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'LabRegions' -ResourceGroupName 'LabAutomation').Value
$masterImageRG = "MasterImageSnapshots"
$location = (Get-AzResourceGroup -Name $sourceResourceGroupName).Location
$sasExpiryDuration = "7200"
$destinationContext = @()
$snapshotList = @()
$sas = @()

# Create snapshot of all VMs
ForEach ($vmName in $vms) {
    $timeStamp = Get-Date -Format "yyyyMMddHHmm"
    $snapshotName = $vmName + '-T' + $timeStamp
    $snapshotList += $snapshotName

    #Create Snapshot of VM OS Disk and get SAS access token
    $vm = get-azvm -ResourceGroupName $sourceResourceGroupName -Name $vmName
    $snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption copy
    New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $masterImageRG 
    $sas += Grant-AzSnapshotAccess -ResourceGroupName $masterImageRG -SnapshotName $snapshotName -DurationInSecond $sasExpiryDuration -Access Read

    # Check if VM has data disks
    If ($vm.StorageProfile.DataDisks.Count -gt 0) { 
        # Create Snapshot of each data disk and get SAS access token
        For ($diskCount=0; $diskCount -lt $vm.StorageProfile.DataDisks.Count; $diskCount++){ 
                 
            #Snapshot name of data disk 
            $snapshotName = $vm.StorageProfile.DataDisks[$diskCount].Name + '-T' + $timeStamp
            $snapshotList += $snapshotName
             
            #Create snapshot configuration 
            $snapshot =  New-AzSnapshotConfig -SourceUri $vm.StorageProfile.DataDisks[$diskCount].ManagedDisk.Id -Location $location  -CreateOption copy 
            New-AzSnapshot -Snapshot $snapshot -SnapshotName $snapshotName -ResourceGroupName $masterImageRG
            $sas += Grant-AzSnapshotAccess -ResourceGroupName $masterImageRG -SnapshotName $snapshotName -DurationInSecond $sasExpiryDuration -Access Read
        } 
    } 
}

# Copy snapshot vhd file to VMImages storage account in each region
For ($counter=0 ; $counter -lt $regions.Length; $counter++) { 
    $targetStorageAccountName = $storageAccountPrefix + $regions[$counter]
    $targetStorageContainerName = "vmimages"
    $keyName = "snapStorageKey-" + $regions[$counter]    
    $storageAccountKey = (Get-AzKeyVaultSecret -vaultName "USAF-690COS-LabKeys" -name $keyName).SecretValueText
    $destinationContext += New-AzStorageContext -StorageAccountName $targetStorageAccountName -StorageAccountKey $storageAccountKey

    For ($vmCount = 0; $vmCount -lt $snapshotList.Length; $vmCount++) {
        $vmSnapName = $snapshotList[$vmCount]
        $destinationVHDFileName = "$vmSnapName.vhd"
        Start-AzStorageBlobCopy -AbsoluteUri $sas[$vmCount].AccessSAS -DestContainer $targetStorageContainerName -DestContext $destinationContext[$counter] -DestBlob $destinationVHDFileName          
    }
}