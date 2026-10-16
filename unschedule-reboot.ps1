<#
    This script deletes the restart job created by "schedule-reboot.ps1".
    - If a job with a name "ITRestart" is found, its name and trigger date & time info is displayed.
    - If there are Kernel-General (12,13) events are found in the respective time window, they are displayed.
      Otherwise "No restart events found" message is displayed
    - User is prompted to delete the found job.
    - If Y/y is pressed, job is deleted inside a try-catch block.
    - Otherwise delete is not performed and a message displayed:
        "Delete is canceled."

    Example usage
        .\delete-restartjob.ps1 -Computer computername
        
    2024-07-04 Metin
#>
param(
    [string]$Computername
)

$ses1 = New-PSSession -ComputerName $Computername
Invoke-Command -Session $ses1 -ScriptBlock {
    $job1 = Get-ScheduledJob -Name "ITRestart" -ErrorAction SilentlyContinue
    if ($job1.Count -eq 1) {
        $sch1 = $job1 | Get-JobTrigger
        [datetime]$t0 = $sch1.At
        "Found job : $($job1.Name)"
        "Scheduled at : $t0"
        $ev1 = Get-WinEvent -FilterHashtable @{Logname="System";ProviderName="Microsoft-Windows-Kernel-General";Id=12,13;StartTime=$t0.AddMinutes(-30);EndTime=$t0.AddMinutes(30)} -ea SilentlyContinue
        if ($ev1.Count -gt 0) {
            $ev1 | ft TimeCreated, PSComputerName, Id, Logname, ProviderName, Message -AutoSize -Wrap
        }
        else {
            "No restart events found."
        }
        $resp1 = Read-Host "Delete this job (N/y)?"
        if ($resp1 -eq "y" -or $resp1 -eq "Y") {
            try {
                $job1 | Unregister-ScheduledJob -EA Stop
            }
            catch {
                $_.ErrorDetails.Message
            }
        }
        else {
            "Delete is canceled."
        }
    }
    else {
        "Found $($job1.Count) jobs. Delete not possible."
    }
}
Remove-PSSession -Session $ses1