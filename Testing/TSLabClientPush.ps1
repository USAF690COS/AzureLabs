<#
    .DESCRIPTION
        Creates a lab troubleshooting scenario for client push installation.
        Removes the client push install account from the local admins group on the
        targeted system
#>

#Temporary sets execution policy for this session. Uncomment line below.
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

$computer = "TrnLabCMW10-02";
$domainUser = "area01/svc.sccm.cp"
$groupObj =[ADSI]"WinNT://$computer/Administrators,group" 
$userObj = [ADSI]"WinNT://$domainUser,user"
$groupObj.Remove($userObj.Path)