# Get current subscription
$subscription = Get-AzSubscription
$SubscriptionId = $subscription.Id
Select-AzSubscription -SubscriptionId $SubscriptionId

# Get number of labs to deploy
Write-Host "How many labs would you like to deploy?" -ForegroundColor Green -NoNewline
Write-Host "(Max 30)" -ForegroundColor Blue
$labCount = Read-Host

# Get lab name prefix (e.g. 'Student')
Write-Host "Type a lab name prefix" -ForegroundColor Green -NoNewline
Write-Host "(Example: Student)" -ForegroundColor Blue
$labUserPrefix = Read-Host

# Get the lab type
Write-Host "Lab template to deploy" -ForegroundColor Green -NoNewline
Write-Host "(Options: dcpromo, dhcp, gpa, sccm, sccmadv)" -ForegroundColor Blue
$labName = Read-Host

# Azure region to deploy lab
Write-Host "Type to Azure region where the lab will be deployed" -ForegroundColor Green -NoNewline
Write-Host "(Options: westus, westus2)" -ForegroundColor Blue
$location = Read-Host

$jobs = @()

For ($labNumber=1; $labNumber -le $labCount; $labNumber++) {
    If ($labCount -gt 1) {$userName = $labUserPrefix + $labNumber}
    Else {$userName = $labUserPrefix}
    $runbookParameters = @{"userName"=$userName.ToLower();"location"=$location.ToLower();"labName"=$labName.ToLower()}
    $jobs += Start-AzAutomationRunbook -AutomationAccountName 'LabAutomation' -ResourceGroupName 'LabAutomation' -Name 'DeployLab' -Parameters $runbookParameters    
}

Write-Host "Your labs are being deployed in Azure."  -ForegroundColor Magenta
Write-Host "Once your labs are ready, your VM connection information will be provided in the output below."  -ForegroundColor Magenta

ForEach ($job in $jobs) {
    $i=0
    $jobStatus = (Get-AzAutomationJob -ResourceGroupName 'LabAutomation' -AutomationAccountName 'LabAutomation' -id $job.JobId).Status
    do {
        # Waiting for job to complete
        Start-Sleep 5
        $i++
        $labInstance = "$labUserPrefix" + ($jobs.IndexOf($job) + 1)
        Write-Progress -Activity 'Deploying Labs' -Status $labInstance -PercentComplete ($i) -CurrentOperation "Deployment status: $jobStatus"
        $jobStatus = (Get-AzAutomationJob -ResourceGroupName 'LabAutomation' -AutomationAccountName 'LabAutomation' -id $job.JobId).Status
    }
    until (($jobStatus.Trim() -eq 'Completed') -or ($jobStatus.Trim() -eq 'Failed'))
}
Write-Progress -Activity 'Deploying Labs' -Completed

ForEach ($job in $jobs) {
        Write-Host $labUserPrefix ($jobs.IndexOf($job) + 1) "Lab Environment:" -ForegroundColor Green
        $output = (Get-AzAutomationJobOutput -ResourceGroupName 'LabAutomation' -AutomationAccountName 'LabAutomation' -id $job.JobId).Summary
        ForEach ($summary in $output) {write-host $summary}
        Write-Host ""
}