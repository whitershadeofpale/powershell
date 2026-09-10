param(
    [string]$Computername=$env:COMPUTERNAME,
    [int]$Days=30
)
[datetime]$scripttime = Get-Date
[datetime]$currentTime=Get-Date "1970-01-01"
[datetime]$previousTime=$scripttime.AddDays(-$days)

Write-Host "PrevTime = $previousTime"

if (Test-ICMP $Computername) {
    $evs1 = Get-WinEvent -cn $Computername -FilterHashtable @{
        Logname="System";
        ProviderName=("Microsoft-Windows-Kernel-Power","Microsoft-Windows-Power-Troubleshooter","Microsoft-Windows-Kernel-General","eventlog");
        Id=1,12,13,42,107,6005,6006,6008;
        StartTime=$scripttime.AddDays(-$days)
    } | Sort-Object TimeCreated
    $diffSeconds = 10
    Write-Host "CurrentTime $($evs1[0].TimeCreated)"
    # ============================
    $evs2 = $evs1 | ForEach-Object {
        if ($_.ProviderName -eq "Microsoft-Windows-Power-Troubleshooter" -and $_.Id -eq 1) {
            [datetime]$currentTime = $_.TimeCreated
            $currentType = "Start"

            [int]$fark = ($currentTime - $previousTime).TotalSeconds
            if (($fark -gt $diffSeconds) -and ($currentType -ne $previousType)) {
                [PSCustomObject]@{
                    Time= $currentTime
                    Type = $currentType
                    Id = $_.Id
                    Fark = $fark
                    Aynimi = ($currentType -eq $previousType)
                }
            }
        }
        elseif ($_.ProviderName -eq "eventlog" -and $_.Id -eq 6005) {
            [datetime]$currentTime = $_.TimeCreated
            $currentType = "Start"

            [int]$fark = ($currentTime - $previousTime).TotalSeconds
            if (($fark -gt $diffSeconds) -and ($currentType -ne $previousType)) {
                [PSCustomObject]@{
                    Time= $currentTime
                    Type = $currentType
                    Id = $_.Id
                    Fark = $fark
                    Aynimi = ($currentType -eq $previousType)
                }
            }
        }
        elseif ($_.ProviderName -eq "Microsoft-Windows-Kernel-General" -and $_.Id -eq 12) {
            [datetime]$currentTime = $_.TimeCreated
            $currentType = "Start"
        
            [int]$fark = ($currentTime - $previousTime).TotalSeconds
            if (($fark -gt $diffSeconds) -and ($currentType -ne $previousType)) {
                [PSCustomObject]@{
                    Time= $currentTime
                    Type = $currentType
                    Id = $_.Id
                    Fark = $fark
                    Aynimi = ($currentType -eq $previousType)
                }
            }
        }
        elseif ($_.ProviderName -eq "Microsoft-Windows-Kernel-General" -and $_.Id -eq 13) {
            [datetime]$currentTime = $_.TimeCreated
            $currentType = "Shutdown"

            [int]$fark = ($currentTime - $previousTime).TotalSeconds
            if (($fark -gt $diffSeconds) -and ($currentType -ne $previousType)) {
                [PSCustomObject]@{
                    Time= $currentTime
                    Type = $currentType
                    Id = $_.Id
                    Fark = $fark
                    Aynimi = ($currentType -eq $previousType)
                }
            }
        }
        elseif ($_.ProviderName -eq "eventlog" -and $_.Id -eq 6006) {
            [datetime]$currentTime = $_.TimeCreated
            $currentType = "Shutdown"
            Write-Host "current: $currentTime, previous : $previousTime"
            [int]$fark = ($currentTime - $previousTime).TotalSeconds
            if (($fark -gt $diffSeconds) -and ($currentType -ne $previousType)) {
                [PSCustomObject]@{
                    Time= $currentTime
                    Type = $currentType
                    Id = $_.Id
                    Fark = $fark
                    Aynimi = ($currentType -eq $previousType)
                }
            }
        }
        elseif ($_.ProviderName -eq "Microsoft-Windows-Kernel-Power" -and $_.Id -eq 107) {
            [datetime]$currentTime = $_.TimeCreated
            $currentType = "Shutdown"

            [int]$fark = ($currentTime - $previousTime).TotalSeconds
            if (($fark -gt $diffSeconds) -and ($currentType -ne $previousType)) {
                [PSCustomObject]@{
                    Time= $currentTime
                    Type = $currentType
                    Id = $_.Id
                    Fark = $fark
                    Aynimi = ($currentType -eq $previousType)
                }
            }
        }
        elseif ($_.ProviderName -eq "eventlog" -and $_.Id -eq 6008) {
            [datetime]$currentTime = Get-Date -Date ("$($_.Properties[1].Value -replace([char]0x200e,'')) $($_.Properties[0].Value)")
            $currentType = "Shutdown"

            [int]$fark = ($currentTime - $previousTime).TotalSeconds
    #        if (($fark -gt $diffSeconds) -and ($currentType -ne $previousType)) {
                [PSCustomObject]@{
                    Time= $currentTime
                    Type = $currentType
                    Id = $_.Id
                    Fark = $fark
                    Aynimi = ($currentType -eq $previousType)
                }
    #       }
            # else{
            #     Write-Host "current: $currentTime, previous : $previousTime"
            #     Write-Host "current: $currentType, previous : $previousType"
            # }
        }
        elseif ($_.ProviderName -eq "Microsoft-Windows-Kernel-Power" -and $_.Id -eq 42) {
            [datetime]$currentTime = $_.TimeCreated
            $currentType = "Shutdown"

            [int]$fark = ($currentTime - $previousTime).TotalSeconds
            if (($fark -gt $diffSeconds) -and ($currentType -ne $previousType)) {
                [PSCustomObject]@{
                    Time= $currentTime
                    Type = $currentType
                    Id = $_.Id
                    Fark = $fark
                    Aynimi = ($currentType -eq $previousType)
                }
            }
        }
        [datetime]$previousTime = $currentTime
        $previousType = $currentType
    }
    # ============================

    $evs2 += [PSCustomObject]@{
        Time = $scripttime
        Type = "Shutdown"
        Id   = 0
        Fark = [int]($scripttime - $previousTime).TotalSeconds
    }

    $evs2 | ft -AutoSize

    [datetime]$previousTime=$scripttime.AddDays(-$days)
    [string]$previousType=""
    $totalUptime=0
    # $prevUptime=$evs2[0].Time
    $evs2 | Sort-Object -Property Time | ForEach-Object {
        [int]$fark = ($_.Time - $previousTime).TotalSeconds
        if (($fark -gt 0) -and ($_.Time -gt 0) -and ($_.Type -ne $previousType)) {
            if ($_.Type -eq "Shutdown") {
                $fark1 = ($_.Time - $previousTime).TotalSeconds
                $totalUptime += $fark1
                # Write-Host "$($_.Time) - $($_.Id) = $fark1"
            }
            else {
                $prevUptime = $_.Time
            }
        }
        else {
            "current : $($_.Time) - $($_.Type)"
            "previous : $previousTime - $previousType"
        }
        $previousTime = $_.Time
    }

    # $evs2 | Out-GridView
    "{0:N1} seconds" -f $totalUptime
    "{0:N1} hours" -f ($totalUptime/3600)
    "{0:N1} days" -f ($totalUptime/3600/24)
}
else {
    Write-Host "$Computername is not reachable"
}