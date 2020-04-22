$templateParamterUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.parameters.json"
$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
$templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"
$templateFile = "C:\git\AzureLabs\Testing\azuredeploy.json"

$outputs = New-AzResourceGroupDeployment -ResourceGroupName 'DeployFromSnapshot' -name 'TestTagWestUS' -TemplateFile $templateFile
$outputs