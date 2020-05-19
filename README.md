# AzureLabs
Deployment Templates Repo for Azure Training &amp; Test labs for 690 COS

## Solution Overivew
The Azure Lab solution is a cloud-based testing, training, and development environment that is used to orchestrate the deployment and configuration of lab instances based on a master lab environment. The solution is designed to take a single master lab environment that closely resembles a production environment and replicate all VMs or a subset of VMs to meet training, testing, and development needs of technicians.

## Solution Components
The solution leverages IaaS and PaaS workloads running in Azure, as well as a GitHub repository for deployment of all services. 


### Deployment Templates (GitHub)
*Additional details about templates and deployment can be found in the readme files under the corresponding folder in this repository.*

ARM (json) templates are used for the automated deployment of lab environments. The deployment workflow leverages ARM templates from 3 locations in the repo.


#### Deploy Lab
The azuredeploy.json template in the AzureLabs/ArmTemplates/Deploy Lab folder is the main template used to deploy the lab. It defines what type of lab should be deployed and in which region the lab will be deployed. 


#### LabDefinitions
The LabDefinitions/azuredeploy.json is a linked template that is referenced via link from the main template. It is used to deploy the lab VM resources, as defined in the parameters file. 


#### VM Templates
The VM Templates folder contains subfolders for each VM that can be deployed as part of a lab definition (configured in the vmList). Within these subfolders for each VM, the azuredeploy.json template file contains the deployment configurations necessary to create the VM resources in Azure.

![Lab Deployment Flow](/images/ResourceDeploymentFlow.PNG)


*Additional details about templates and deployment can be found in the readme files under the corresponding folder in this repository.*


### Azure Infrastructure
In addition to the lab environment resources that will be deployed to Azure for new lab instances, the solution also leverages Microsoft Azure for the configuration of the master lab environment, from which all VM deployments are referenced, as well as automation and maintenance activities for the solution.

