#Define variables for Scheduled task

#Array of actions for scheduled task
$stactions = (New-ScheduledTaskAction -Execute 'Net' -Argument 'use S: \\st690coslab001.file.core.windows.net\scripts /u:st690coslab001 gBs1e1P7z7F7B8Ei/gFmbGA37nadjwsoRbZVLV95kFw825J6RRxmAEJlY+iqvsdstawQWahgw++nQ1WyilRmtg== /persistent:yes'),
             (New-ScheduledTaskAction -Execute 'xcopy' -Argument 'S: C:\scripts\ /s /e /y')

#Specify credentials for running the task
$stprin = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators"
$sttrigger = New-ScheduledTaskTrigger -AtLogOn

#Create a new task with these parameters
$task = New-ScheduledTask -Action $stactions -Principal $stprin -Trigger $sttrigger

#Register task with task scheduler service
Register-ScheduledTask 'Stage Scripts' -InputObject $task -Force