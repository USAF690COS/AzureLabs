#Provide the subscription Id of the subscription where snapshot is created
$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
$SubscriptionId

#Provide the name of your resource group where snapshot is created
$resourceGroupName ="Trn_Lab_DCrepl_001"

#Provide the snapshot name 
$snapshotName = "TrnLabDCreplDC2_snap041020"
$snapshotName

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#Know more about SAS here: https://docs.microsoft.com/en-us/Az.Storage/storage-dotnet-shared-access-signature-part-1
$sasExpiryDuration = "3600"

#Provide storage account name where you want to copy the snapshot. 
$storageAccountName = "vmimagevhds"

#Name of the storage container where the downloaded snapshot will be stored
$storageContainerName = "vmimages"

#Provide the key of the storage account where you want to copy snapshot. 
#$storageAccountKeyPrompt = 
$storageAccountKey = Read-Host -Prompt 'Storage Account Key'

#Provide the name of the VHD file to which snapshot will be copied.
$destinationVHDFileName = "DC2.vhd"

# Set the context to the subscription Id where Snapshot is created
Select-AzSubscription -SubscriptionId $SubscriptionId

#Generate the SAS for the snapshot 
$sas = Grant-AzSnapshotAccess -ResourceGroupName $ResourceGroupName -SnapshotName $snapshotName -DurationInSecond $sasExpiryDuration -Access Read
#Create the context for the storage account which will be used to copy snapshot to the storage account 
$destinationContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey

#Copy the snapshot to the storage account 
Start-AzStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer $storageContainerName -DestContext $destinationContext -DestBlob $destinationVHDFileName