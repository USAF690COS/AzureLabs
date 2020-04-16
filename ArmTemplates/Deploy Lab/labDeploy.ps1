$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
$templateFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.json"

New-AzSubscriptionDeployment -Location 'westus2' -name 'LabTestWestUS2' -TemplateParameterFile $templateParamterFile -TemplateFile $templateFile