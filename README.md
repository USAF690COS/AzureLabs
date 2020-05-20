# AzureLabs
Deployment Templates Repo for Azure Training &amp; Test labs for 690 COS

## Solution Overivew
The Azure Lab solution is a cloud-based testing, training, and development environment that is used to orchestrate the deployment and configuration of lab instances based on a master lab environment. The solution is designed to take a single master lab environment that closely resembles a production environment and replicate all VMs or a subset of VMs to meet training, testing, and development needs of technicians.


The solution leverages IaaS and PaaS workloads running in Azure, as well as a GitHub repository for deployment of all services. 


## Deployment Templates (GitHub)
*Additional details about templates and deployment can be found in the readme files under the corresponding folder in this repository.*  
  
ARM (json) templates are used for the automated deployment of lab environments. The deployment workflow leverages ARM templates from 3 locations in the repo.  
  

### Deploy Lab
The azuredeploy.json template in the AzureLabs/ArmTemplates/Deploy Lab folder is the main template used to deploy the lab. It defines what type of lab should be deployed and in which region the lab will be deployed.   
  

### LabDefinitions
The LabDefinitions/azuredeploy.json is a linked template that is referenced via link from the main template. It is used to deploy the lab VM resources, as defined in the parameters file.   
  

### VM Templates
The VM Templates folder contains subfolders for each VM that can be deployed as part of a lab definition (configured in the vmList). Within these subfolders for each VM, the azuredeploy.json template file contains the deployment configurations necessary to create the VM resources in Azure.  

![Lab Deployment Flow](/images/ResourceDeploymentFlow.PNG)


*Additional details about templates and deployment can be found in the readme files under the corresponding folder in this repository.*  


## Azure Infrastructure
In addition to the lab environment resources that will be deployed to Azure for new lab instances, the solution also leverages Microsoft Azure for the configuration of the master lab environment, from which all VM deployments are referenced, as well as automation and maintenance activities for the solution.  

### Lab Automation Account
RG: LabAutomation  
Automation Account: LabAutomation  
 Runbooks:  
- BackupVMs
- DeployLab
- ProvisionImageSnapshots  
  Variables:  
- MasterRGName  
  
### Key Vault
RG: LabKeys  
Key Vault: USAF-690COS-LabKeys  
 Secrets:  
- snapStorageKey-westus
- snapStorageKey-westus2  

### Snapshot Repository
RG: MasterImageSnapshots  
- Snapshots of each master VM disk, timestamped with date/time of image snap
- This is essentailly your snapshot repository  

### Master Resource Group
RG: <MasterRGName>  
- Master RG, contains all resources for the master environment  
 Virtual Machines  
- all  
 VNET  
- VNET used by master VMs  
NICs, PIPs, etc  
- basically, this is the master environment that you are going to mirror. any resources required to build the replica labs should reside here, in the same RG, on the same VNET.  
  
### VM Image Snapshots (per region)
RG: vmImages-<regionName>  
- Snapshots of current/recent master VM disks that are used for deployment within the region
Storage Account: vmimagevhds<regionName>  
 Tags:  
- Active/Rollback tags for each VM disk. Used by ARM templates in dpeloyment of VMs. To update to a newer deployment image, update the tag to target the new snapshot.  
 Containers: vmimages  
- vhd files from each VM disk image snapshot. These are copied out to each region from the 'MasterImageSnapshots' RG. Once the VHD has been copied, a snapshot can be generated from the VHD file to be used in VM deployment within the region. 

