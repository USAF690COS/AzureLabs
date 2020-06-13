<#
    .DESCRIPTION
        Creates a lab troubleshooting scenario for SCCM applications. Adds a requirement that prevents
        the app from installing on targeted systems.
#>

#Temporary sets execution policy for this session. Uncomment line below.
#Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

#region Connect to ConfigMgr Site
$SiteCode = "PS1"
$ProviderMachineName = "TrnLabCMPS1.area01.lab" 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
}
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName
}
Set-Location "$($SiteCode):\"
#endregion

#region Define Variables
$RuleName = "Free Disk Space of any local drive Greater than or equal to 100000000 MB"
# use * for all rules
$SourceApplicationName = "SourceApp"
$DestApplicationName = "SDC NIPR and SIPR - Google Chrome - 200408"
$DestDeploymentTypeIndex = 0
#endregion

#region Add the new requirement
# get the applications
$SourceApplication = Get-CMApplication -Name $SourceApplicationName | ConvertTo-CMApplication
$DestApplication = Get-CMApplication -Name $DestApplicationName | ConvertTo-CMApplication

# get requirement rules from source application
$Requirements = $SourceApplication.DeploymentTypes[0].Requirements | Where-Object {$_.Name -match $RuleName}

# apply requirement rules
$Requirements | ForEach-Object {
    
    #Check if the requirement already exists on the destination app
    $RuleExists = $DestApplication.DeploymentTypes[$DestDeploymentTypeIndex].Requirements | Where-Object {$_.Name -match $RuleName}
    if($RuleExists) {

        Write-Warning "The rule `"$($_.Name)`" already exists in target application deployment type"

    } else{
        
        Write-Host "Apply rule `"$($_.Name)`" on target application deployment type"

        # create new rule ID
        $_.RuleID = "Rule_$( [guid]::NewGuid())"
        
        #Add the requirement to the dest app
        $DestApplication.DeploymentTypes[$DestDeploymentTypeIndex].Requirements.Add($_)
    }
}

# push changes
$CMApplication = ConvertFrom-CMApplication -Application $DestApplication
$CMApplication.Put()
#endregion