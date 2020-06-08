<#
    .DESCRIPTION
        Deploy Lab

    .NOTES
        AUTHOR: Kevin Dillon
        LAST EDIT: 6-8-2020
        LAST CHANGE: Moved runbook to new RG, updated output to write FQDN vs. PIP

    .PARAMETER labName
        The name of the lab instance type to deploy.
        This name corresponds to a lab definition parameter file that is used to deploy the lab instance. 
        Allowed values include: dc1, dcpromo, dhcp, sccm, gpa.        

    .PARAMETER location (Optional)
        Azure region to deploy new lab resources. 
        Default value of 'westus2'.

    .PARAMETER userName (Optional)
        Name of user creating lab, used in resource group name to identify lab owner.           

#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('dc1','dcpromo','dhcp','sccm','gpa')]
    [string] $labName,

    [Parameter(Mandatory = $true)]
    [string] $userName,

    [Parameter(Mandatory = $false)]
    [string] $location = 'westus2'
)

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
    Start lab deployment script
#>

$templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"
$templateParameters = @{
    userName = $userName.ToLower()
    location = $location.ToLower()
    labName = $labName.ToLower()
}

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
