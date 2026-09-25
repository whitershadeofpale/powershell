param(
    [string]$Computername=$env:COMPUTERNAME,
    [int]$Days=7,
    [Switch]$Details
)

[datetime]$t1 = Get-Date    # time of script run
[datetime]$t0 = $t1.AddDays(-$days) # start of search

# Getting related events
if (Test-ICMP $Computername) {
    $evs = Get-WinEvent -ComputerName $Computername -FilterHashtable @{
        Logname="System";
        ProviderName=("Microsoft-Windows-Kernel-Power","Microsoft-Windows-Power-Troubleshooter","Microsoft-Windows-Kernel-General","eventlog");
        Id=1,12,13,42,107,6005,6006,6008;
        StartTime=$t0
    } | Sort-Object -Property TimeCreated

    # fixing time for 6008 events
    foreach ($ev in $evs) {
        if ($ev.Id -eq 6008) {
            [datetime]$time6008 = Get-Date -Date ("$($ev.Properties[1].Value -replace([char]0x200e,'')) $($ev.Properties[0].Value)")
            $ev.TimeCreated = $time6008
        }
    }

    # what is the state of the computer at t0
    if ($Details) { $evs[0] }
    if ($evs[0].Id -in (1,12,6005)) { # these are bootup events
        $previous_action = "up"
        $pseudo0 = [PSCustomObject]@{
            TimeCreated = $t0
            Id = 13 # pseudo down event
            ProviderName = "Microsoft-Windows-Kernel-General"
        }
    }
    elseif ($evs[0].Id -in (13,42,107,6006,6008)) { # these are shutdown events
        $previous_action = "down"
        $pseudo0 = [PSCustomObject]@{
            TimeCreated = $t0
            Id = 12 # pseudo up event
            ProviderName = "Microsoft-Windows-Kernel-General"
        }
    }
    $pseudo1 = [PSCustomObject]@{
            TimeCreated = $t1
            Id = 13
            ProviderName = "Microsoft-Windows-Kernel-General"
        }

    $evs2 = ($evs | select TimeCreated, Id, ProviderName) + $pseudo0 + $pseudo1 | 
        Where-Object {-Not (($_.ProviderName -eq "Microsoft-Windows-Kernel-General") -and ($_.Id -eq 1))} | 
            Sort-Object -Property TimeCreated

    if ($Details) {
        $evs2 | Out-GridView
    }
    # Build the final array with human-readable up-down column
    $ignore_window = 30 # seconds
    $previous_time = $evs2[0].TimeCreated
    $evs3 = foreach ($ev in $evs2) {
        if ($ev.ProviderName -eq "Microsoft-Windows-Power-Troubleshooter" -and $ev.Id -eq 1) {
            [int]$diff = ($ev.TimeCreated - $previous_time).TotalSeconds
            if (-Not ($previous_action -eq "up" -and ($diff -le $ignore_window))) {
                [PSCustomObject]@{
                    TimeCreated = $ev.TimeCreated
                    Id = $ev.Id
                    ProviderName = $ev.ProviderName
                    Action = "Up"
                    Seconds = $diff
                }
            }
            $previous_action = "up"
            $previous_time = $ev.TimeCreated
        }
        elseif ($ev.ProviderName -eq "Eventlog" -and $ev.Id -eq 6005) {
            [int]$diff = ($ev.TimeCreated - $previous_time).TotalSeconds
            if (-Not ($previous_action -eq "up" -and ($diff -le $ignore_window))) {
                [PSCustomObject]@{
                    TimeCreated = $ev.TimeCreated
                    Id = $ev.Id
                    ProviderName = $ev.ProviderName
                    Action = "Up"
                    Seconds = $diff
                }
            }
            $previous_action = "up"
            $previous_time = $ev.TimeCreated
        }
        elseif ($ev.ProviderName -eq "Microsoft-Windows-Kernel-General" -and $ev.Id -eq 12) {
            [int]$diff = ($ev.TimeCreated - $previous_time).TotalSeconds
            if (-Not ($previous_action -eq "up" -and ($diff -le $ignore_window))) {
                [PSCustomObject]@{
                    TimeCreated = $ev.TimeCreated
                    Id = $ev.Id
                    ProviderName = $ev.ProviderName
                    Action = "Up"
                    Seconds = $diff
                }
            }
            $previous_action = "up"
            $previous_time = $ev.TimeCreated
        }
        elseif ($ev.ProviderName -eq "Microsoft-Windows-Kernel-General" -and $ev.Id -eq 13) {
            [int]$diff = ($ev.TimeCreated - $previous_time).TotalSeconds
            if (-Not ($previous_action -eq "down" -and ($diff -le $ignore_window))) {
                [PSCustomObject]@{
                    TimeCreated = $ev.TimeCreated
                    Id = $ev.Id
                    ProviderName = $ev.ProviderName
                    Action = "Down"
                    Seconds = $diff
                }
            }
            $previous_action = "down"
            $previous_time = $ev.TimeCreated
        }
        elseif ($ev.ProviderName -eq "Eventlog" -and $ev.Id -eq 6006) {
            [int]$diff = ($ev.TimeCreated - $previous_time).TotalSeconds
            if (-Not ($previous_action -eq "down" -and ($diff -le $ignore_window))) {
                [PSCustomObject]@{
                    TimeCreated = $ev.TimeCreated
                    Id = $ev.Id
                    ProviderName = $ev.ProviderName
                    Action = "Down"
                    Seconds = $diff
                }
            }
            $previous_action = "down"
            $previous_time = $ev.TimeCreated
        }
        elseif ($ev.ProviderName -eq "Eventlog" -and $ev.Id -eq 6008) {
            [int]$diff = ($ev.TimeCreated - $previous_time).TotalSeconds
            if (-Not ($previous_action -eq "down" -and ($diff -le $ignore_window))) {
                [PSCustomObject]@{
                    TimeCreated = $ev.TimeCreated
                    Id = $ev.Id
                    ProviderName = $ev.ProviderName
                    Action = "Down"
                    Seconds = $diff
                }
            }
            $previous_action = "down"
            $previous_time = $ev.TimeCreated
        }
        elseif ($ev.ProviderName -eq "Microsoft-Windows-Kernel-Power" -and $ev.Id -eq 107) {
            [int]$diff = ($ev.TimeCreated - $previous_time).TotalSeconds
            if (-Not ($previous_action -eq "down" -and ($diff -le $ignore_window))) {
                [PSCustomObject]@{
                    TimeCreated = $ev.TimeCreated
                    Id = $ev.Id
                    ProviderName = $ev.ProviderName
                    Action = "Down"
                    Seconds = $diff
                }
            }
            $previous_action = "down"
            $previous_time = $ev.TimeCreated
        }
        elseif ($ev.ProviderName -eq "Microsoft-Windows-Kernel-Power" -and $ev.Id -eq 42) {
            [int]$diff = ($ev.TimeCreated - $previous_time).TotalSeconds
            if (-Not ($previous_action -eq "down" -and ($diff -le $ignore_window))) {
                [PSCustomObject]@{
                    TimeCreated = $ev.TimeCreated
                    Id = $ev.Id
                    ProviderName = $ev.ProviderName
                    Action = "Down"
                    Seconds = $diff
                }
            }
            $previous_action = "down"
            $previous_time = $ev.TimeCreated
        }
    }
    if ($Details) { $evs3 | Out-GridView }

    $total_seconds = ($evs3 | Where-Object Action -eq "down"| Measure-Object -Sum -Property Seconds).Sum
    $total_downs = ($evs3 | Where-Object Action -eq "down" | Measure-Object).Count -1
    if ($pseudo0.Id -eq 13) { $total_downs = $total_downs - 1}
    [int]$total_hours = $total_seconds/3600


    "total seconds: {0:N0}" -f $total_seconds
    "total hours  : {0:N1}" -f $total_hours
    "total days : {0:N1}" -f ($total_hours/24)
    "total of $total_downs shutdown(s) in $Days days"
}
else {
    Write-Host "$_ is down."
}