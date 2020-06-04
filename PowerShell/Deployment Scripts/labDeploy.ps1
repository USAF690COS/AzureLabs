# Get current subscription
$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId

# Get lab name prefix (e.g. 'Student')
Write-Host "Type a lab name prefix" -ForegroundColor Green -NoNewline
Write-Host "(Example: Student)" -ForegroundColor Blue
$userName = Read-Host

# Get the lab type
Write-Host "Lab template to deploy" -ForegroundColor Green -NoNewline
Write-Host "(Options: dcpromo, dhcp, gpa, sccm)" -ForegroundColor Blue
$labName = Read-Host

# Azure region to deploy lab
Write-Host "Type to Azure region where the lab will be deployed" -ForegroundColor Green -NoNewline
Write-Host "(Options: westus, westus2)" -ForegroundColor Blue
$location = Read-Host

$templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"
$templateParameters = @{
    userName = $userName.ToLower()
    location = $location.ToLower()
    labName = $labName.ToLower()
}

#$templateParameters = @{"userName"=$userName;"location"=$location.ToLower();"labName"=$labName.ToLower()}
$deploymentName = "$userName-$labName-$location"

$outputs = New-AzSubscriptionDeployment -Location $location -name $deploymentName -TemplateUri $templateUri -TemplateParameterObject $templateParameters

$resourceGroupName = $outputs.Outputs.resourceGroupName.Value
$resourceGroupName

$ipConfigValues = $outputs.Outputs.ipConfigurations.Value

For ($outputCount=0; $outputCount -lt $ipConfigValues.Count; $outputCount++) {
    $PIPResource = Get-AzResource -id $ipConfigValues[$outputCount].PublicIPResourceID.Value
    $PublicIP = (Get-AzPublicIpAddress -Name $PIPResource.Name).DnsSettings.Fqdn
    $PublicPort = $ipConfigValues[$outputCount].VMPublicPort.Value
    $VMName = $ipConfigValues[$outputCount].VMName.Value
    $RDPConnection = $VMName + " - " + $PublicIP + ':' + $PublicPort
    $RDPConnection
}