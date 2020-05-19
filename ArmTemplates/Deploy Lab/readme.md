# Deploy Lab - (Updating Documentation for Script Modifications)
ARM Deployment Templates for lab Resource Group, VNET, and Load Balancer Deployments. 
Linked deployment initiated for unique lab environments based on input parameters.

This template deploys resources common to all lab instances.

It is primarily launched using the /LabAutomation/LabAutomation/DeployLab runbook.

## DeployLab (PowerShell Automation Runbook)
Deploys the *Deploy Lab/azuredeploy.json* ARM template. 
The runbook passes the required deployment parameters to the template, then retrieves and formats the following Output once the deployment is complete:
- VM Name
- IP Address
- RDP Connection Port

**$templateParameterFile:** The local path where the *azuredeploy.parameters.json* parameter file is stored.  
> *(Recommended)* This is an optional parameter
Use:
```powershell
# Placeholder
.......
```

