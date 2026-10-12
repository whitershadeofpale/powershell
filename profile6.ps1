function reboot {
    restart-computer -force
}

function poweroff {
    stop-computer -force
}

function Prompt
{
    $prompt_path = Get-Location
    $prompt_right = Get-Date -Format " dd MMM, ddd | HH:mm "
    $winlogo = [char]0xE70F
    $prompt_char = [char]0x276f
    $elevated = [char]0xF79F
    $prompt_user = $env:username
    $prompt_computer = $env:computername
    <#
    $battery = gcim Win32_Battery
    $BatteryGlyph = ""

    if ($battery.Status -ne "OK") { $BatteryGlyph = [char]0xf12a } 

    if ($battery.BatteryStatus -eq 1) { $BatteryGlyph += [char]0xf063 }
    elseif ($battery.BatteryStatus -eq 2) { $BatteryGlyph += [char]0xf062 }

    if ($battery.EstimatedChargeRemaining -ge 80) { $bcolor = "green"}
    elseif ($battery.EstimatedChargeRemaining -ge 50) { $bcolor = "cyan"}
    elseif ($battery.EstimatedChargeRemaining -gt 30) { $bcolor = "blue"}
    else { $bcolor = "red"}
    $prompt_battery = "[$BatteryGlyph $($battery.EstimatedChargeRemaining)] "
    #>
    # leftmost: Path
    Write-Host $prompt_user -ForegroundColor DarkBlue -NoNewline
    Write-Host "@" -ForegroundColor DarkMagenta -NoNewline 
    Write-Host "$prompt_computer " -ForegroundColor Yellow -NoNewline
    Write-Host $prompt_path -ForegroundColor Cyan -NoNewline
    $current_Y = [Console]::CursorTop
    $console_width = [Console]::BufferWidth
    [Console]::SetCursorPosition($console_width-($prompt_right.length + 1),$current_Y)

    # Rightmost: Battery + date&time
    Write-Host $prompt_right -ForegroundColor Magenta

    if ((Get-History).Length -gt 0)
    {
        $LastExecutionTime = [long]((Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime).TotalMilliSeconds
    }
    else
    {
        $LastExecutionTime = "0"
    }

    if ($LastExecutionTime -gt 3600000) {
        $LastExecutionTime = $LastExecutionTime/3600000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "($Duration hour) "
    }
    elseif ($LastExecutionTime -gt 60000) {
        $LastExecutionTime = $LastExecutionTime/60000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "($Duration min) "
    }
    elseif ($LastExecutionTime -gt 2000)
    {
        $LastExecutionTime = $LastExecutionTime/1000
        $Duration = "{0:n1}" -f $LastExecutionTime
        $Duration = "($Duration sec) "
    }
    elseif ($LastExecutionTime -gt 10) {
        $Duration = "($LastExecutionTime ms) "
    }
    else { $Duration ="" }
    
    # second line: elevation + duration + prompt
    if ((New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator))
        {
            Write-Host "$elevated " -ForegroundColor White -BackgroundColor Red -NoNewline
            Write-Host "$Duration" -ForegroundColor Magenta -NoNewline
            Write-Host "$winlogo $prompt_char" -ForegroundColor White -NoNewline
        }
    else {
        Write-Host "$Duration" -ForegroundColor Magenta -NoNewline
        Write-Host "$winlogo $prompt_char" -ForegroundColor White -NoNewline
    }

    Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView
    Set-PSReadLineOption -PromptText "$winlogo $prompt_char "

    # if required to diplay path in the title bar:
    $host.ui.rawui.WindowTitle = (Get-Location)
    return " "
}