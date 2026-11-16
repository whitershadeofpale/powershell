# November 2026
nal we get-winevent
nal reboot restart-computer -force
nal poweroff stop-computer -force
nal uptime Get-Uptime
nal rsv Restart-Service
nal ti Test-Icmp

function ks {Stop-Process -Name spotify* -force}
function tail {
    param(
        [Parameter(ValueFromPipeline)]$InputObject,
        $n=5
    )
    $InputObject | Select-Object -Last $n
}

$lsusb = {Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' } | ft -auto}
$rdpevs = {Get-WinEvent -FilterHashtable @{Logname="Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational";Id=1149} -max 2 | Format-Table Timecreated, Message -AutoSize -Wrap}
$IIS_alan_adlari = @('date','time','sip','csmethod','csuristem','csuriquery','sport','csusername','cip','UserAgent','Referer','scstatus','scsubstatus','scwin32status','timetaken')

$global:IsEmptyCommand = $false

Set-PSReadLineKeyHandler -Key Enter -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ([string]::IsNullOrWhiteSpace($line)) {
        $global:IsEmptyCommand = $true
    } else {
        $global:IsEmptyCommand = $false
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine($key, $arg)
}

function prompt() {
    $c1          = [char]0xE0B6 # left half disk
    $c2          = [char]0xE0B4 # right half disk

    (Get-PSProvider FileSystem).Home="D:\Folder"
    $tag_time = date -U %R
    $tag_path = (pwd).Path
    $tag_path = $tag_path.replace("D:\Folder","~")

    # ---------------------------------------
    if ((Get-History).Length -gt 0)
    {
        if ($global:IsEmptyCommand) { $LastExecutionTime=0 }
        else {
            $LastExecutionTime = [long]((Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime).TotalMilliSeconds
            if ($LastExecutionTime -gt 5000) {
                Play-Sound -Play "C:\Windows\Media\Windows Proximity Notification.wav"
            }
        }
    }
    else
    {
        $LastExecutionTime = "0"
    }

    if ($LastExecutionTime -gt 3600000) {
        $LastExecutionTime = $LastExecutionTime/3600000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "$Duration hour"
    }
    elseif ($LastExecutionTime -gt 60000) {
        $LastExecutionTime = $LastExecutionTime/60000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "$Duration min"
    }
    elseif ($LastExecutionTime -gt 2000)
    {
        $LastExecutionTime = $LastExecutionTime/1000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "$Duration sec"
    }
    elseif ($LastExecutionTime -gt 10) {
        $Duration = "$LastExecutionTime ms"
    }
    else { $Duration ="" }
    # ---------------------------------------

    $dollar_sign=[char]::ConvertFromUtf32(0x1F4B2)
    # path
    Write-host "`r`n$c1" -ForegroundColor DarkGray -NoNewline;
    write-Host $tag_path -BackgroundColor DarkGray -ForegroundColor green -NoNewline;
    write-host $c2 -ForegroundColor DarkGray -NoNewline
    # time
    Write-host "-$c1" -ForegroundColor DarkGray -NoNewline;
    write-Host $tag_time -BackgroundColor DarkGray -ForegroundColor Yellow -NoNewline;
    write-host $c2 -ForegroundColor DarkGray -NoNewline

    if ($Duration) {
        # last command duration
        Write-host "-$c1" -ForegroundColor DarkGray -NoNewline;
        write-Host $Duration -BackgroundColor DarkGray -ForegroundColor Magenta -NoNewline;
        write-host $c2 -ForegroundColor DarkGray
    }
    else {
        Write-Host ""
    }
    Write-Host "$dollar_sign" -ForegroundColor Green -NoNewline
    return ' '
}