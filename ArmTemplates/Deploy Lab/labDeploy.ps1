$templateParamterUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.parameters.json"
$templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"

New-AzSubscriptionDeployment -Location 'westus2' -name 'LabTestWestUS2' -TemplateParameterUri $templateParamterUri -TemplateUri $templateUri