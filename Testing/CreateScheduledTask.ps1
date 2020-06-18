#Define variables for Scheduled task
$staction = New-ScheduledTaskAction -Execute 'Net' -Argument 'use S: \\st690coslab001.file.core.windows.net\scripts /u:st690coslab001 gBs1e1P7z7F7B8Ei/gFmbGA37nadjwsoRbZVLV95kFw825J6RRxmAEJlY+iqvsdstawQWahgw++nQ1WyilRmtg== /persistent:yes'
$stprin = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators"
$sttrigger = New-ScheduledTaskTrigger -AtLogOn

#Create new scheduled task to map network share
Register-ScheduledTask -Action $staction -Trigger $sttrigger -Principal $stprin -TaskName 'Map Scripts Share' -Force