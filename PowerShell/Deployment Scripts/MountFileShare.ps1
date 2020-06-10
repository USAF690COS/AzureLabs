$resourceGroupName = "VROLabs_RG"
$storageAccountName = "vrouploads"
$fileShareName = "scripts"
$passwd = ConvertTo-SecureString "_Nh-6mecl4w3vwd3SeU8Cqrr8-0I32T-gV" -AsPlainText -Force
$pscredential = New-Object System.Management.Automation.PSCredential('a5f89b61-54e7-44d9-8368-2e950b05ceff', $passwd)
$tenantId = "6c0bed0e-26fd-4e45-9fbf-38123d270b36"

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process

# Wrap authentication in retry logic for transient network failures
$logonAttempt = 0
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult = Connect-AzAccount -ServicePrincipal -Credential $pscredential -Tenant $tenantId
    Start-Sleep -Seconds 30
}

# These commands require you to be logged into your Azure account, run Login-AzAccount if you haven't
# already logged in.
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName
$storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName
$fileShare = Get-AzStorageShare -Context $storageAccount.Context | Where-Object { 
    $_.Name -eq $fileShareName -and $_.IsSnapshot -eq $false
}

if ($fileShare -eq $null) {
    throw [System.Exception]::new("Azure file share not found")
}

# The value given to the root parameter of the New-PSDrive cmdlet is the host address for the storage account, 
# <storage-account>.file.core.windows.net for Azure Public Regions. $fileShare.StorageUri.PrimaryUri.Host is 
# used because non-Public Azure regions, such as sovereign clouds or Azure Stack deployments, will have different 
# hosts for Azure file shares (and other storage resources).
$password = ConvertTo-SecureString -String $storageAccountKeys[0].Value -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "AZURE\$($storageAccount.StorageAccountName)", $password
New-PSDrive -Name "S" -PSProvider FileSystem -Root "\\$($fileShare.StorageUri.PrimaryUri.Host)\$($fileShare.Name)" -Credential $credential -Persist