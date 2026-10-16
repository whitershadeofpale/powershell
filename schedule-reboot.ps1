<#
    This script schedules a job on remote computer to restart.
    - No other job can be scheduled.
    - If another job with the same name exists, delete is prompted.
    - If deleted, new job creation is commenced.
    - If delete is canceled, no more jobs created and script exists.
    - If ScheduleTime is not given, default is "23:00".

    Example usage
        .\schedule-reboot.ps1 -computername computername -ScheduledTime 22:30

    2024-07-04 Metin
#>
param(
    [Parameter(Mandatory)][string]$Computername,
    [string]$ScheduleTime="23:00"
)
$ScheduleTime
$ses1 = New-PSSession -ComputerName $Computername
$bDontDelete = $false

Invoke-Command -Session $ses1 -ScriptBlock {
    $prev1 = Get-ScheduledJob -Name "ITRestart" -EA SilentlyContinue
    if ($prev1) {
        "There is a similar job named $($prev1.Name)"
        "Scheduled to run At $(($prev1 | Get-JobTrigger).At)"
        $event1 = Get-WinEvent -FilterHashtable @{Logname="Microsoft-Windows-TaskScheduler/Operational";Id=106} -MaxEvents 1 -ErrorAction SilentlyContinue | 
                    Select-Object TimeCreated, @{N="Name";E={$_.Properties[0].Value}} |
                        Where-Object {$_.Name -match "ITRestart"}
        if ($event1.Name -like "*ITRestart") {
            "Time Created : $($event1.TimeCreated)"
            "Path : $($event1.Name)"
        }
        else {
            "No more info in the TaskScheduler eventlog."
        }
        $resp1 = Read-Host "Delete it (N/y)?"
        if ($resp1 -eq "y" -or $resp1 -eq "Y") {
            try {
                Unregister-ScheduledJob -InputObject $prev1 -ea Stop
            }
            catch {
                $_.ErrorDetails.Message
                $bDontDelete = $true
            }
        }
        else {
            "Since you have chosen not to delete, you cannot create a new job."
            $bDontDelete = $true
        }
    }
    if ($bDontDelete) {
        "no new job created."
    }
    else {
        $trig1 = New-JobTrigger -Once -At $Using:ScheduleTime
        $obj1 = Register-ScheduledJob -Trigger $trig1 -Name "ITRestart" -ScriptBlock {Restart-Computer -Force}
        $trig2 = $obj1 | Get-JobTrigger
        "Registered Job : $($obj1.Name)"
        "Trigger : $($trig2.At)"
    }
}

Remove-PSSession -Session $ses1