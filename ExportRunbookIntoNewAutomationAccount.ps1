# Author: Matt Smith
# Description: I had a need to archive some automation runbooks locally and then import them into a new Azure Automation Account.
#              This script accomplished this nicely. 

# $SubscriptionId needed if you have access to multiple subscriptions.
$SubscriptionId = 'SubscriptionId'
$ResourceGroupName = 'AutomationResourceGroup'
$OldAutomationAccountName = 'OldAutomationAccount'
$NewAutomationAccountName = 'NewAutomationAccount'
$Path = "C:\temp\PathToSaveTo"

Connect-AzureRmAccount
# Setting Context needed if you have access to multiple subscriptions.
Set-AzureRmContext -SubscriptionId $SubscriptionId
# Get our runbooks from our old automation account.
$runBooks = Get-AzureRmAutomationRunbook -ResourceGroupName $ResourceGroupName -AutomationAccountName $OldAutomationAccountName  -Verbose
$runBooks | ForEach-Object -Process { 
Write-Output "Processing: $_.Name"

# Export locally
Export-AzureRmAutomationRunbook -ResourceGroupName $_.ResourceGroupName `
    -AutomationAccountName $_.AutomationAccountName `
    -Name $_.Name `
    -Slot "Published" `
    -OutputFolder $Path `
    -Verbose
}

# Get all the scripts that were successfully saved
Get-ChildItem -Path $Path -Filter *.ps1 -Recurse -File -Name| ForEach-Object {
    # Setup our complete path and runbook name
    $ScriptPath = "$Path\$_"
    $Script = [System.IO.Path]::GetFileNameWithoutExtension($_)

    Write-Host "Processing: $Script at $ScriptPath";

    # Import into our new Azure Automation Runbook
    Import-AzureRmAutomationRunbook -Path $ScriptPath `
    -Description "Restored from $OldAutomationAccountName" `
    -Name $Script `
    -Type PowerShell `
    -AutomationAccountName $NewAutomationAccountName `
    -ResourceGroupName $ResourceGroupName `
    -Published
}