# Get number of labs to deploy
Write-Host "How many labs would you like to deploy?" -ForegroundColor Green -NoNewline
Write-Host "(Max 10)" -ForegroundColor Blue
$labCount = Read-Host

# Get lab name prefix (e.g. 'Student')
Write-Host "Type a lab name prefix" -ForegroundColor Green -NoNewline
Write-Host "(Example: Student)" -ForegroundColor Blue
$labUserPrefix = Read-Host

# Get the lab type
Write-Host "Lab template to deploy" -ForegroundColor Green -NoNewline
Write-Host "(Options: dcpromo or dhcp)" -ForegroundColor Blue
$labName = Read-Host

# Azure region to deploy lab
Write-Host "Type to Azure region where the lab will be deployed" -ForegroundColor Green -NoNewline
Write-Host "(Options: westus, westus2)" -ForegroundColor Blue
$location = Read-Host

$jobs = @()

For ($labNumber=1; $labNumber -le $labCount; $labNumber++) {
    $userName = $labUserPrefix + $labNumber

    #$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
    $templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"
    $templateFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.json"

    $templateParameters = @{
        userName = $userName
        location = $location
        labName = $labName
    }

    $deploymentName = $templateParameters.userName + $templateParameters.labName
    $jobs += Start-Job {New-AzDeployment -Location $args[0] -Name $args[1] -TemplateFile $args[2] -TemplateParameterObject $args[3]} `
        -ArgumentList $location, $deploymentName, $templateFile, $templateParameters
}

$jobs | Wait-Job

ForEach ($job in $jobs) {

    Write-Host $labUserPrefix ($jobs.IndexOf($job) + 1) "Lab Environment:" -ForegroundColor Green

    # Break output into string array
    $outstring = $outputs | Out-String -width 4096 
    $arrayout = $outstring.Split("`n")
    foreach ($line in $arrayout) {

        If ($line -match "resourceGroupName") {
            #find resourceGroupName
            $newString = $line.Substring($line.LastIndexOf(" "), ($line.Length - $line.LastIndexOf(" "))).Trim()
            $newString = $newString.Replace('"', "")
            $newString = $newString.Replace(",","")
            $resourceGroupName = $newString
            $resourceGroupName
        }
        ElseIf ($line -match "VMName") {
            #find VMName
            $newString = $line.Substring($line.LastIndexOf(" "), ($line.Length - $line.LastIndexOf(" "))).Trim()
            $newString = $newString.Replace('"', "")
            $newString = $newString.Replace(",","")
            $VMName = $newString
            Write-Host "$VMName - " -NoNewline
        }
        ElseIf ($line -match "PublicIPResourceID") {
            #find PublicIPResourceID, then run code to pull IP
            $newString = $line.Substring($line.LastIndexOf(" "), ($line.Length - $line.LastIndexOf(" "))).Trim()
            $newString = $newString.Replace('"', "")
            $newString = $newString.Replace(",","")
            $PIPID = $newString
            $PIPResource = Get-AzResource -id $PIPID
            $PublicIP = (Get-AzPublicIpAddress -Name $PIPResource.Name).IpAddress
            $PublicIPString = $PublicIP + ":"
            Write-Host $PublicIPString -NoNewline
        }
        ElseIf ($line -match "VMPublicPort") {
            #Find VM Public Port
            $newString = $line.Substring($line.LastIndexOf(" "), ($line.Length - $line.LastIndexOf(" "))).Trim()
            $newString = $newString.Replace('"', "")
            $newString = $newString.Replace(",","")
            $PublicPort = $newString
            Write-Host $PublicPort 
        }
    }
}