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