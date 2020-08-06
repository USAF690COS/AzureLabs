<# 
For each region, do the following
    -Check for and temporarily delete any resource group locks
    -Get a list of snapshots at the resource group level
    -Get a list of blobs in the vmimages container
    -Keep only the 4 most recent snapshots/blobs per disk, delete all others
    -Reapply resource group locks
#>

#region - Define variables
$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id

$lockName = "MSFT_Lab_Solution"
$lockLevel = "CanNotDelete"
$lockNotes = "DO NOT DELETE! This resource is a critical component of the MIcrosoft deployed Lab Solution."

$storageAccountPrefix = "vmimagevhds"
$numOfImagesToKeep = 4
#endregion - Define variables

#Set the subscription context for this script
Select-AzSubscription -SubscriptionId $SubscriptionId

#Master resource group name set to Trn_Lab_DCrepl_001
$masterResourceGroupName = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'MasterRGName' -ResourceGroupName 'LabAutomation').Value
$labRegions = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'LabRegions' -ResourceGroupName 'LabAutomation').Value

#Get list of VM names in the Master resource group
$vmNames = (Get-AzVM -ResourceGroupName $masterResourceGroupName).name
#$vmNames = "TrnLabCMPS1", "TrnLabCMWS16", "TrnLabCMW10-01", "TrnLabCMW10-02"
ForEach ($region in $labRegions) {
    $resourceGroupName = "vmImages-" + $region
    
    #region - Remove resource lock
    $rgLock = Get-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $lockName
    If($rgLock) {
        #RG is locked, must delete before editing
        Write-Host "Removing resource group lock: $rgLock.Name `n"
        Remove-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $lockName -Force
    }
    #endregion - Remove resource lock
    
    #Define storage account variables
    $storageAccountName = $storageAccountPrefix + $region
    $storageContainerName = "vmimages"
    $keyName = "snapStorageKey-" + $region    
    $storageAccountKey = (Get-AzKeyVaultSecret -vaultName "USAF-690COS-LabKeys" -name $keyName).SecretValueText
    $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

    ForEach ($vmName in $vmNames) {
        #Get a list of disks for that VM
        $vmInstanceInfo = Get-AzVM -ResourceGroupName $masterResourceGroupName -Name $vmName -Status
        $vmDiskNames = $vmInstanceInfo.Disks.Name
        
        ForEach ($vmDisk in $vmDiskNames) {
            #region - Cleanup snapshots and blobs
            If($vmDisk.Contains("OsDisk")) {
                #Define OS disk name
                $vmOSDiskName = $vmDisk.Split("_")[0] + '-T'
                
                #Get all snapshots and blobs for this OS Disk
                $vmAllOSSnaps = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmOSDiskName*).Name
                $vmAllOSBlobs = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmOSDiskName*).Name
                
                #Get list of snapshots and blobs to keep
                $vmOSSnapsToKeep = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmOSDiskName*).Name | Sort-Object -Bottom $numOfImagesToKeep
                $vmOSBlobsToKeep = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmOSDiskName*).Name | Sort-Object -Bottom $numOfImagesToKeep

                #Search thru all snapshots
                ForEach ($snap in $vmAllOSSnaps) {
                    If(!$vmOSSnapsToKeep.Contains($snap)) {
                        #OS snapshot is not in list to keep, delete it
                        Write-Host "Delete snapshot = $snap `n"
                        Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snap -Force
                    }
                }

                #Search thru all blobs
                ForEach ($blob in $vmAllOSBlobs) {
                    If(!$vmOSBlobsToKeep.Contains($blob)) {
                        #OS blob is not in list to keep, delete it
                        Write-Host "Delete OS blob = $blob `n"
                        Remove-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $blob -Force
                    }
                }
            }
            Else {
                #This is a data disk
                
                #Get list snapshots and blobs for this data disk
                $vmAllDataDiskSnaps = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDisk*).Name
                $vmAllDataDiskBlobs = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmDisk*).Name
                
                #Get list of snapshots and blobs to keep
                $vmDataDiskSnapsToKeep = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDisk*).Name | Sort-Object -Bottom $numOfImagesToKeep
                $vmDataDiskBlobsToKeep = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmDisk*).Name | Sort-Object -Bottom $numOfImagesToKeep                

                #Search thru all snapshots
                ForEach ($snap in $vmAllDataDiskSnaps) {
                    If(!$vmDataDiskSnapsToKeep.Contains($snap)) {
                        #Datadisk snapshot is not in list to keep, delete it
                        Write-Host "Delete snapshot = $snap `n"
                        Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snap -Force
                    }
                }

                #Search thru all blobs
                ForEach ($blob in $vmAllDataDiskBlobs) {
                    If(!$vmDataDiskBlobsToKeep.Contains($blob)) {
                        #Datadisk blob is not in list to keep, delete it
                        Write-Host "Delete blob = $blob `n"
                        Remove-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $blob -Force
                    }
                }
            }
            #endregion - Cleanup snapshots and blobs
        }
    }      
    #region - Readd resource group lock
    Write-Host "Reapplying resource group lock: $lockName `n"
    New-AzResourceLock -LockName $lockName -LockLevel $lockLevel -LockNotes $lockNotes -ResourceGroupName $resourceGroupName -Force
    #endregion - Readd resource group lock   
}