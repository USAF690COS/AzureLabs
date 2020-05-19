# PLEASE USE THE AZURE AUTOMATION RUNBOOK - LabAutomation/DeployLab - TO CREATE SINGLE LAB INSTANCES, OR
# USE THE PowerShell/Deployment Scripts/BatchDeployLab.ps1 SCRIPT TO CREATE SINGLE OR MULTIPLE LAB INSTANCES
# THIS SCRIPT WILL BE REMOVED AT SOME POINT IN THE NEAR FUTURE

<#
$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
$templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"

$outputs = New-AzSubscriptionDeployment -Location 'westus' -name 'LabDeployTags' -TemplateUri $templateUri -TemplateParameterFile $templateParamterFile

$resourceGroupName = $outputs.Outputs.resourceGroupName.Value
$resourceGroupName

$ipConfigValues = $outputs.Outputs.ipConfigurations.Value

For ($outputCount=0; $outputCount -lt $ipConfigValues.Count; $outputCount++) {
    $PIPResource = Get-AzResource -id $ipConfigValues[$outputCount].PublicIPResourceID.Value
    $PublicIP = (Get-AzPublicIpAddress -Name $PIPResource.Name).IpAddress
    $PublicPort = $ipConfigValues[$outputCount].VMPublicPort.Value
    $VMName = $ipConfigValues[$outputCount].VMName.Value
    $RDPConnection = $VMName + " - " + $PublicIP + ':' + $PublicPort
    $RDPConnection
}

#>