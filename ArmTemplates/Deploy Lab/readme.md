# Deploy Lab
ARM Deployment Templates for lab Resource Group, VNET, and Load Balancer Deployments. 
Linked deployment initiated for unique lab environments based on input parameters for lab type and lab name...

Use labDeploy.ps1 to start this deployment.

## labDeploy.ps1
This script is formatted to deploy the Deploy Lab/azuredeploy.json ARM template. The script passes the required parameters to the template (either inline or using a parameter file), then retrieves and formats the following Outputs from the template for each vm deployed:
- VM Name
- IP Address
- RDP Connection Port

### Script Parameters
The labDeploy.ps1 script begins with the following lines:
```powershell
$templateParamterUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.parameters.json"
$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
$templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"

$outputs = New-AzSubscriptionDeployment -Location 'westus' -name 'LabDeployTags' -TemplateUri $templateUri -TemplateParameterFile $templateParamterFile
.......
```
#### Deployment Template
The ARM template that is used for the deployment.
**$templateUri:** The URL for the */Deploy Lab/azuredeploy.json* ARM template. 
> *(Mandatory)* This value should not be modified.

#### Deployment Parameters
Supplies necessary parameters to the ARM template for deployment options.
Paramters can be supplied in one of 3 ways:
- Template Parameter URI (uses parameter file located in github repo)
- Template Parameter File (uses parameter file stored on local machine)
- Parameters passed at runtime (passed as parameters to the script inline, or prompted for values at runtime)

**$templateParameterUri:** The URL for the */Deploy Lab/azuredeploy.parameters.json* ARM template. 
> *(Optional)* This is an optional parameter that will use the parameter file stored in github to reference the deployment input parameters.
> 

**$templateParameterFile:** The URL for the */Deploy Lab/azuredeploy.parameters.json* ARM template. 
> *(Recommended)* This is an optional parameter

