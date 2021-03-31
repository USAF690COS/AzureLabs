<#
    .DESCRIPTION
        Backup master VM images and copy updated VHD image files to each region.
        Snapshot backups complete quickly, but the VHD copy between regions can take 1 hour or longer.
        The 'ProvisionSnapshots' runbook should be run once VHD copies complete to provision snapshots in each region for deployment.

    .NOTES
        AUTHOR: Kevin Dillon
        LASTEDIT: 3-31-2021

    .PARAMETER vmList
        A comma-seperated list of VM names to backup. 
        Default value of 'all' is used to backup all VMs in the master resource group.
#>
param(
    [Parameter(Mandatory = $false)]
    [string] $vmList = 'none'
)

If ($vmList -eq 'none') {
    Write-Output ("You must provide a comma-seperated list of VMs to backup. Or type -all- to backup all master VMs...")
    exit
}

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
    Start Master VM image backup script
#>

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
$regions = "westus2"
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
    try {
        $vm = get-azvm -ResourceGroupName $sourceResourceGroupName -Name $vmName -ErrorAction Stop
    }
    catch {
        Write-Output ("A VM named: $vmName was not found...")
        continue
    }
    
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

    For ($vmCount = 0; $vmCount -le $snapshotList.Length; $vmCount++) {
        If ($sas[$vmCount]) {
            $vmSnapName = $snapshotList[$vmCount]
            $destinationVHDFileName = "$vmSnapName.vhd"
            Start-AzStorageBlobCopy -AbsoluteUri $sas[$vmCount].AccessSAS -DestContainer $targetStorageContainerName -DestContext $destinationContext[$counter] -DestBlob $destinationVHDFileName
        }
    }
}


