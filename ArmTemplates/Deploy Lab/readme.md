# Deploy Lab - (Updating Documentation for Script Modifications)
ARM Deployment Templates for lab Resource Group, VNET, and Load Balancer Deployments. 
Linked deployment initiated for unique lab environments based on input parameters.

Use labDeploy.ps1 to start this deployment.

## labDeploy.ps1
Deploys the *Deploy Lab/azuredeploy.json* ARM template. 
The script passes the required deployment parameters to the template (either inline or using a parameter file), then retrieves and formats the following Output once the deployment is complete:
- VM Name
- IP Address
- RDP Connection Port

### Script Parameters
The labDeploy.ps1 script contains 2 sets of parameters
1. Deployment parameters
2. Template parameters

#### Deployment Parameters
Location
DeploymentName

#### Deployment Template
The ARM template that is used for the deployment.
**$templateUri:** The URL for the */Deploy Lab/azuredeploy.json* ARM template. 
> *(Mandatory)* This value should not be modified.

#### Deployment Parameters
Supplies necessary parameters to the ARM template for deployment options.
Paramters can be supplied in one of 2 ways:
- Template Parameter File (uses parameter file stored on local machine)
- Parameters passed at runtime (passed as parameters to the script inline, or prompted for values at runtime)

**$templateParameterFile:** The local path where the *azuredeploy.parameters.json* parameter file is stored.  
> *(Recommended)* This is an optional parameter
Use:
```powershell
$templateParamterFile = "C:\git\AzureLabs\ArmTemplates\Deploy Lab\azuredeploy.parameters.json"
$templateUri = "https://raw.githubusercontent.com/USAF690COS/AzureLabs/master/ArmTemplates/Deploy%20Lab/azuredeploy.json"

$outputs = New-AzSubscriptionDeployment -Location 'westus' -name 'LabDeployTags' -TemplateUri $templateUri -TemplateParameterFile $templateParamterFile
.......
```

