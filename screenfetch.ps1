$user_name = $env:Username
$computer_name = $env:COMPUTERNAME
$os_version = Get-CimInstance -ClassName Win32_OperatingSystem
$uptime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
$uptimeSpan = (Get-Date) - (Get-Date $uptime)
$uptime_formatted = "{0}d {1}h {2}m" -f $uptimeSpan.Days, $uptimeSpan.Hours, $uptimeSpan.Minutes
$ip_address = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()).IPAddressToString
$ip_address = ($ip_address | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}$' -and $_ -ne '<localhost>' })
$memory = "{0:N0}" -f ((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory/1GB)
$cpu = (Get-CimInstance -ClassName Win32_Processor).Name
$BrandModel = Get-CimInstance -Class Win32_ComputerSystem
$VideoController = Get-CimInstance -Class Win32_VideoController
$hfIds = (Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -ExpandProperty HotFixID) -join ', '
$datecode = Get-Date -Format "yyyy-MM-ddTHH:mm"
$ipqueryurl = "https://ipinfo.io/$IPAddress"
$externalIP = "-N/A-"
try {
    $ipinfo = Invoke-RestMethod -Uri $ipqueryurl -ErrorAction Stop
    $externalIP = $ipinfo.ip
} catch {
    $externalIP = $_.Exception.Response.StatusCode
}

Write-Host ""
Write-Host "============================================  " -ForegroundColor DarkMagenta
Write-Host "WWW                PPPPPPPP        SSSSSS     " -ForegroundColor Blue -NoNewline; Write-Host $user_name  -ForegroundColor Blue -NoNewline; Write-Host "@" -ForegroundColor Red -NoNewline;Write-Host "$computer_name    " -ForegroundColor White -NoNewline;Write-Host "($datecode)" -ForegroundColor Gray -BackgroundColor DarkBlue
Write-Host "  WWW              PPPPPPPPP     SSSSSSSSSS   " -ForegroundColor Blue -NoNewline; Write-Host "PC Info        : " -ForegroundColor Green -NoNewline; Write-Host "$($BrandModel.Manufacturer) | $($BrandModel.Model)" -ForegroundColor White
Write-Host "  WWW              PPP     PPP   SSS     SSS  " -ForegroundColor Blue -NoNewline; Write-Host "OS Version     : " -ForegroundColor Green -NoNewline; Write-Host $os_version.Caption -ForegroundColor White
Write-Host "   WWW             PPP     PPP   SSSS         " -ForegroundColor Blue -NoNewline; Write-Host "Kernel         : " -ForegroundColor Green -NoNewline; Write-Host $os_version.Version -ForegroundColor White
Write-Host "    WWW            PPPPPPPPP       SSSSS      " -ForegroundColor Blue -NoNewline; Write-Host "CPU            : " -ForegroundColor Green -NoNewline; Write-Host $cpu -ForegroundColor White
Write-Host "     WWW           PPPPPPPP          SSSSS    " -ForegroundColor Blue -NoNewline; Write-Host "RAM            : " -ForegroundColor Green -NoNewline; Write-Host "$memory GB" -ForegroundColor White
Write-Host "    WWW            PPP                 SSSSS  " -ForegroundColor Blue -NoNewline; Write-Host "IP Adddress    : " -ForegroundColor Green -NoNewline; Write-Host $ip_address -ForegroundColor White
Write-Host "   WWW             PPP                   SSS  " -ForegroundColor Blue -NoNewline; Write-Host "GPU            : " -ForegroundColor Green -NoNewline; Write-Host "$($VideoController.Name)" -ForegroundColor White
Write-Host "  WWW              PPP           SSS     SSS  " -ForegroundColor Blue -NoNewline; Write-Host "Resolution     : " -ForegroundColor Green -NoNewline; Write-Host "$($VideoController.VideoModeDescription)" -ForegroundColor White
Write-Host " WWW               PPP            SSSSSSSSSS  " -ForegroundColor Blue -NoNewline; Write-Host "Last Updates   : " -ForegroundColor Green -NoNewline; Write-Host $hfIds -ForegroundColor White
Write-Host "WWW    powershell  PPP              SSSSS     " -ForegroundColor Blue -NoNewline; Write-Host "Uptime         : " -ForegroundColor Green -NoNewline; Write-Host $uptime_formatted -ForegroundColor White
Write-Host "                                              " -ForegroundColor Blue -NoNewline; Write-Host "External IP    : " -ForegroundColor Green -NoNewline; Write-Host $externalIP -ForegroundColor White
Write-Host "============================================  " -ForegroundColor DarkMagenta
write-Host ""
