$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
$templateFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.json"

New-AzSubscriptionDeployment -Location 'westus' -name 'TestLab2' -TemplateParameterFile $templateParamterFile -TemplateFile $templateFile