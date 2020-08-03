<# 
For each region, do the following
    -Check for and temporarily delete any resource group locks
    -Search the vmImages resource group for any snapshots
    -Keep only the 4 most recent snapshots per disk, delete all others
    -Search vmimages container, keep only the 4 most recent snapshots per disk, delete all others
    -Reapply resource group locks
#>

#region - Define variables
$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id

$lockName = "MSFT_Lab_Solution"
$lockLevel = "CanNotDelete"
$lockNotes = "DO NOT DELETE! This resource is a critical component of the MIcrosoft deployed Lab Solution."

$storageAccountPrefix = "vmimagevhds"
$regions = "westus"
$numOfSnapshotsToKeep = 4
#endregion - Define variables

#region - Work

#Set the subscription context for this script
Select-AzSubscription -SubscriptionId $SubscriptionId

#Master resource group name set to Trn_Lab_DCrepl_001
$masterResourceGroupName = (Get-AzAutomationVariable -AutomationAccountName LabAutomation -Name 'MasterRGName' -ResourceGroupName 'LabAutomation').Value

#Get list of VM names in the Master resource group
$vms = (Get-AzVM -ResourceGroupName $masterResourceGroupName).name

ForEach ($region in $regions) {
    $resourceGroupName = "vmImages-" + $region
    
    #region - Remove resource lock
    $rgLock = Get-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $lockName
    If($rgLock) {
        #RG is locked, must delete before editing
        #Remove-AzResourceLock -ResourceGroupName $resourceGroupName -LockName $lockName -Force
    }
    #endregion - Remove resource lock

    #$location = (Get-AzResourceGroup -Name $resourceGroupName).Location

    <#
    $storageAccountName = $storageAccountPrefix + $region
    $storageContainerName = "vmimages"
    #$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
    #$storageAccountId = $storageAccount.Id
    $keyName = "snapStorageKey-" + $region    
    $storageAccountKey = (Get-AzKeyVaultSecret -vaultName "USAF-690COS-LabKeys" -name $keyName).SecretValueText
    $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
    
    #$blobs = Get-AzStorageBlob -Container $storageContainerName -Context $storageContext 
    #>
    ForEach ($vmName in $vms) {
        #Get a list of disks for that VM
        $vmInstanceInfo = Get-AzVM -ResourceGroupName $masterResourceGroupName -Name $vmName -Status
        $vmDisks = $vmInstanceInfo.Disks.Name
        ForEach ($vmDisk in $vmDisks) {
            $vmAllSnaps = @()
            $vmSnapsToKeep = @()
            If($vmDisk.Contains("OsDisk")) {
                #This is an OS Disk
                #Write-Output "OSDisk = [$vmDisk] `n"
                $vmOSSnapshotName = $vmDisk.Split("_")[0] + '-T'
                $vmAllSnaps = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmOSSnapshotName*)
                $vmSnapsToKeep = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmOSSnapshotName*) | Sort-Object -Bottom $numOfSnapshotsToKeep
                ForEach ($snap in $vmAllSnaps) {
                    If(!$vmAllSnaps.Contains($snap)) {
                        #OS snapshot is not in list to keep, delete it
                        Write-Output "Delete snapshot = $snap `n"
                        #Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snap -Force -WhatIf
                    }
                }
                #Write-Output "OSSnapshotname = $vmOSSnapshotName `n"
            }
            Else {
                #This is a data disk
                #Write-Output "DataDisk = $vmDisk `n"
                $vmAllSnaps = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDisk*)
                $vmSnapsToKeep = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDisk*) | Sort-Object -Bottom $numOfSnapshotsToKeep
                ForEach ($snap in $vmAllSnaps) {
                    If(!$vmAllSnaps.Contains($snap)) {
                        #Datadisk snapshot in list to keep, delete it
                        Write-Output "Delete snapshot = $snap `n"
                        #Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $snap -Force -WhatIf
                    }
                }
            }
        }

        #For each disk, keep the last 4 instances
        <#
        #region - OSDisk
        #Define OS disk name
        $vmOSSnapshotName = $vmName + '-T'
       
        #Get a list of all the OS snapshots for this VM
        $vmAllOSsnapshots = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmOSSnapshotName*).Name

        #Get last 4 snapshots for the OS disk
        $vmOSsnapshotsToKeep = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmOSSnapshotName*).Name | Sort-Object -Bottom $numOfSnapshotsToKeep

        #Compare each OSsnapshot to the OSsnapshots to keep
        ForEach ($vmSnapshot in $vmAllOSsnapshots) {
            If(!$vmOSsnapshotsToKeep.Contains($vmSnapshot)) {
                #vmSnapshot is not in list to keep, delete snapshot
                Write-Output "Delete snapshot= [$vmSnapshot] `n"
                #Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmSnapshot -Force -WhatIf
            }
        }
        #endregion - OSDisk

        #region - DataDisks
        If($vmInstanceInfo.Disks.Count -gt 1) {
            #This VM has data disks
            $vmDataDisks = For($i=1;$i -lt $vmInstanceInfo.Disks.Count;$i++) {$vmInstanceInfo.Disks[$i].Name}
            ForEach ($vmDataDisk in $vmDataDisks) {
                #Get all data disk snapshots for this disk
                $vmAllDataDisksnapshots = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDataDisk*).Name

                #Get list of snapshots to keep
                $vmDataDisksnapshotsToKeep = (Get-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmDataDisk*).Name | Sort-Object -Bottom $numOfSnapshotsToKeep

                ForEach ($vmSnapshot in $vmAllDataDisksnapshots) {
                    If(!$vmDataDisksnapshotsToKeep.Contains($vmSnapshot)) {
                        #vmSnapshot is not in list to keep, delete snapshot
                        Write-Output "Delete snapshot= [$vmSnapshot] `n"
                        #Remove-AzSnapshot -ResourceGroupName $resourceGroupName -SnapshotName $vmSnapshot -Force -WhatIf
                    }
                }

            }
        }

        #endregion - GetDisks
        #>
        <#
        $osVHD = Get-AzStorageBlob -Container "vmimages" -Context $storageContext -Blob $vmOSDisk* | Sort-Object LastModified -Descending | Select-Object -First 1
        $osVHDName = $osVHD.name

        # Search for corresponding data disks with same timestamp
        $diskTimestamp = $osVHDName.Replace($vmName, "")
        $allDisks = Get-AzStorageBlob -Container "vmimages" -Context $storageContext -Blob $vmName* | Where-Object -Property Name -Like *$diskTimestamp
        ForEach ($disk in $allDisks) {
            $sourceVHDName = $disk.name
            $sourceVHDURI = $disk.ICloudBlob.Uri.AbsoluteUri
            $snapshotName = $sourceVHDName.Replace(".vhd","")
            
            #$diskName = $sourceVHDName.Replace($diskTimestamp,"")

            #Create Snapshot from VHD file
            #$snapshotConfig = New-AzSnapshotConfig -AccountType $storageType -Location $location -CreateOption Import -StorageAccountId $storageAccountId -SourceUri $sourceVHDURI -HyperVGeneration $vmGen
            #$snapshotProvisioningState = New-AzSnapshot -Snapshot $snapshotConfig -ResourceGroupName $resourceGroupName -SnapshotName $snapshotName
        } #>
    }
        
    #region - Readd resource group ock
    #New-AzResourceLock -LockName $lockName -LockLevel $lockLevel -LockNotes $lockNotes -ResourceGroupName $resourceGroupName -Force
    #endregion - Readd resource group lock
    
}
#endregion - Work