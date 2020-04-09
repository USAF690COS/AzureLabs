$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
$templateFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.json"

New-AzDeployment -name 'DeployLab' -Location 'westus' -TemplateParameterFile $templateParamterFile -TemplateFile $templateFile