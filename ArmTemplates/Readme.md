# ArmTemplates
ARM Deployment Templates Folder for for Azure Training &amp; Test labs for 690 COS.


## Deployment Templates (GitHub)
ARM (json) templates are used for the automated deployment of lab environments. The deployment workflow leverages ARM templates from 3 locations in the repo.


### Deploy Lab
The azuredeploy.json template in the AzureLabs/ArmTemplates/Deploy Lab folder is the main template used to deploy the lab. It defines what type of lab should be deployed and in which region the lab will be deployed. 

The template contains the following input parameters to be supplied during deployment:

| Parameter name | Description |
| -------------- | ----------- |
| userName | The name of the user creating the lab, used in the Resource Group name |
| location | The Azure region where the new lab instance will be deployed |
| labName | The name of the lab definition, or type of lab, that will be deployed |

The main template deploys the following resources for the new lab environment:
- Resource Group
- VNET
- Public IP
- Load Balancer

All additional resource created in the linked deployments will be deployed into this resource group and will leverage these networking resources.


### LabDefinitions
The LabDefinitions/azuredeploy.json is a linked template that is referenced via link from the main template. It is used to deploy the lab VM resources, as defined in the parameters file. 

Each lab type will have a separate parameters file in the LabDefinitions folder, which contains a single parameter, 'vmList'. This parameter contains a list of the VMs that will be deployed as part of the lab definition.

Each VM is deployed from a linked template located in the ArmTemplates/VM Templates folder of this repo.


### VM Templates
The VM Templates folder contains subfolders for each VM that can be deployed as part of a lab definition (configured in the vmList). Within these subfolders for each VM, the azuredeploy.json template file contains the deployment configurations necessary to create the following resources in Azure for the VM deployment:
- NIC
- Managed Disk(s)
- VM
- Inbound NAT Rule (for RDP access)

The following diagram depicts the deployment flow for a new lab environment instance consisting of 2 VMs (DC1 & DC2):

![Lab Deployment Flow](/images/ResourceDeploymentFlow.PNG)

Additional details about templates and deployment can be found in the readme files under the corresponding folder in this repository.

