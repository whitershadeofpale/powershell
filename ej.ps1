$drives = Get-Volume | ? {$_.DriveType -eq "Removable" -and $_.Size -ne 0}

if ($drives) {
    $drives
    $drives = $drives | Select-Object -ExpandProperty DriveLetter

    $resp = Read-Host "Which one should I eject? (Enter the drive letter, e.g. E)"

    if ($resp -in $drives) {
        $ErrorActionPreference="Stop"
        try {
            $driveEject = New-Object -comObject Shell.Application
            $driveEject.Namespace(17).ParseName("${resp}:").InvokeVerb("Eject")
        }
        catch {
            Write-Host "An error occurred while trying to eject the drive ${resp}:"
            Write-Host $_.Exception.Message
        }
    }
    else {
        Write-Host "It seems there is no $resp drive currently."
    }
}
else {
    Write-Host "No removable drives found."
}