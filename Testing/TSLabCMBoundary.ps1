<#
    .DESCRIPTION
        Creates a lab troubleshooting scenario for SCCM boundaries. Creates a new IP range based boundary
        and removes the existing boundary from the current boundary group, effectively leaving clients outside of the boundary for SCCM
#>

#Sets execution policy for this session, if code-signing is enabled. Uncomment line below.
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
$oldBoundary = Get-CMBoundary -BoundaryId "16777218"
$newBoundary = New-CMBoundary -Name "TSBoundaryGroup" -Type IPRange -Value "10.10.0.1-10.10.0.21"
#endregion

#region main
#Add this new boundary to the existing BG
Add-CMBoundaryToGroup -BoundaryGroupId "16777218" -InputObject $newBoundary

#Remove the old boundary from the existing BG
Remove-CMBoundaryFromGroup -BoundaryGroupId "16777218" -BoundaryInputObject $oldBoundary -Force
#endregion
