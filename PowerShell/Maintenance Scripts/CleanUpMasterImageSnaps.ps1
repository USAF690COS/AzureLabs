<# 
Cleans snaps in the MasterImageSnapshots RG
    -Check for and temporarily delete any resource group locks
    -Get a list of snapshots at the resource group level
    -Keep the 4 most recent snapshots/blobs per disk and 1 per month for the previous X months, delete all others
    -Reapply resource group locks
#>

#region - Define variables
$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id

$lockName = "MSFT_Lab_Solution"
$lockLevel = "CanNotDelete"
$lockNotes = "DO NOT DELETE! This resource is a critical component of the MIcrosoft deployed Lab Solution."

#$storageAccountPrefix = "vmimagevhds"

#Keep the last 4 snaps and blobs for each VM disk
$numOfImagesToKeep = 4

#Keep 1 snap and blob for each VM disk. 1 per month for the past X months
$numOfMonthsToKeep = 6

#Set the subscription context for this script
Select-AzSubscription -SubscriptionId $SubscriptionId

#Master resource group name set to Trn_Lab_DCrepl_001
$masterResourceGroupName = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'MasterRGName' -ResourceGroupName 'LabAutomation').Value
#$labRegions = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'LabRegions' -ResourceGroupName 'LabAutomation').Value
#endregion - Define variables

#Get list of VM names in the Master resource group
$vmNames = (Get-AzVM -ResourceGroupName $masterResourceGroupName).name
$resourceGroupName = "MasterImageSnapshots"
    
#region - Remove resource lock
$rgLock = Get-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $lockName
If($rgLock) {
    #RG is locked, must delete before editing
    Write-Host "Removing resource group lock: $rgLock.Name `n"
    Remove-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $lockName -WhatIf -Force
}
#endregion - Remove resource lock
    
#Define storage account variables for this region
<#
$storageAccountName = $storageAccountPrefix + $region
$storageContainerName = "vmimages"
$keyName = "snapStorageKey-" + $region    
$storageAccountKey = (Get-AzKeyVaultSecret -vaultName "USAF-690COS-LabKeys" -name $keyName).SecretValueText
$storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
#>

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
            #$vmAllOSBlobs = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmOSDiskName*).Name
            
            #Add last x snapshots and blobs to list to keep
            $vmOSSnapsToKeep = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmOSDiskName*).Name | Sort-Object -Bottom $numOfImagesToKeep
            #$vmOSBlobsToKeep = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmOSDiskName*).Name | Sort-Object -Bottom $numOfImagesToKeep

            #Add last X month's OS snapshot/blob to list to keep, 1 per month
            $currentMonth = (Get-Date).Month
            $currentYear = (Get-Date).Year
            For($i=1;$i -le $numOfMonthsToKeep;$i++) {
                #Define timespan by number of days to search for snaps and blobs
                #For example, if $i = 2, timespan to search is 60 days/2 months from current date/time.
                $days = $i * 30
                $timeSpan = New-TimeSpan -Days $days
                
                #Get the year and month value for that timespan. Two digit month and 4 digit year
                $currentMonth = "{0:D2}" -f ((Get-Date) - $timeSpan).Month
                $currentYear = ((Get-DAte) -$timeSpan).Year

                #Get the last snap and blob from that Year/Month 
                $lastSnapOfTheMonth = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmOSDiskName*$currentYear$currentMonth*).Name | Sort-Object -Bottom 1
                #$lastBlobOfTheMonth = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmOSDiskName*$currentYear$currentMonth*).Name | Sort-Object -Bottom 1
                
                #Add snap/blob names to list to keep
                $vmOSSnapsToKeep+=$lastSnapOfTheMonth
                #$vmOSBlobsToKeep+=$lastBlobOfTheMonth
            }

            #Cleanup snapshots
            ForEach ($snap in $vmAllOSSnaps) {
                If(!$vmOSSnapsToKeep.Contains($snap)) {
                    #OS snapshot is not in list to keep, delete it
                    Write-Host "Delete snapshot = $snap `n"
                    Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snap -WhatIf -Force
                }
            }
        }
        Else {
            #This is a data disk
            
            #Get list snapshots and blobs for this data disk
            $vmAllDataDiskSnaps = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDisk*).Name
            #$vmAllDataDiskBlobs = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmDisk*).Name
            
            #Get list of snapshots and blobs to keep
            $vmDataDiskSnapsToKeep = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDisk*).Name | Sort-Object -Bottom $numOfImagesToKeep
            #$vmDataDiskBlobsToKeep = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmDisk*).Name | Sort-Object -Bottom $numOfImagesToKeep                

            #Add last X month's data snapshot/blob to list to keep, 1 per month
            $currentMonth = (Get-Date).Month
            $currentYear = (Get-Date).Year
            For($i=1;$i -le $numOfMonthsToKeep;$i++) {
                #Define timespan by number of days to search for snaps and blobs
                #For example, if $i = 2, timespan to search is 60 days/2 months from current date/time.
                $days = $i * 30
                $timeSpan = New-TimeSpan -Days $days

                #Get the year and month value for that timespan. Two digit month and 4 digit year
                $currentMonth = "{0:D2}" -f ((Get-Date) - $timeSpan).Month
                $currentYear = ((Get-DAte) -$timeSpan).Year

                #Get the last snap and blob from that Year/Month 
                $lastSnapOfTheMonth = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDisk*$currentYear$currentMonth*).Name | Sort-Object -Bottom 1
                #$lastBlobOfTheMonth = (Get-AzStorageBlob -Container $storageContainerName -Context $storageContext -Blob $vmDisk*$currentYear$currentMonth*).Name | Sort-Object -Bottom 1
                
                #Add snap/blob names to list to keep
                $vmDataDiskSnapsToKeep+=$lastSnapOfTheMonth
                #$vmDataDiskBlobsToKeep+=$lastBlobOfTheMonth
            }

            #Search thru all snapshots
            ForEach ($snap in $vmAllDataDiskSnaps) {
                If(!$vmDataDiskSnapsToKeep.Contains($snap)) {
                    #Datadisk snapshot is not in list to keep, delete it
                    Write-Host "Delete snapshot = $snap `n"
                    Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snap -WhatIf -Force
                }
            }
        }
        #endregion - Cleanup snapshots
    }
}

#region - Reapply resource group lock
Write-Host "Reapplying resource group lock: $lockName `n"
New-AzResourceLock -LockName $lockName -LockLevel $lockLevel -LockNotes $lockNotes -ResourceGroupName $resourceGroupName -WhatIf -Force
#endregion - Readd resource group lock