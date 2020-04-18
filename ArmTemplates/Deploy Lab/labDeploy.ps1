$templateParamterUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.parameters.json"
$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
$templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"

$outputs = New-AzSubscriptionDeployment -Location 'westus' -name 'LabDeployWestUS' -TemplateUri $templateUri -TemplateParameterFile $templateParamterFile
$outputs