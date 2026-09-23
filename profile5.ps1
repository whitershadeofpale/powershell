nal we get-winevent
nal reboot restart-computer
nal poweroff stop-computer 
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

function prompt {
    $IsOk = $?
    $esc    = [char]27
    $reset  = "$esc[0m"
    $red    = "$esc[38;2;255;85;85m"     # #FF5555
    $blue   = "$esc[38;2;167;199;231m"   # #A7C7E7
    $purple = "$esc[38;2;195;174;214m"   # #C3AED6
    $green  = "$esc[38;2;168;216;185m"   # #A8D8B9
    $yellow = "$esc[38;2;242;213;160m"   # #F2D5A0
    $gray   = "$esc[38;2;92;84;112m"     # #5C5470

    $prompt_char = [char]0x276f
    $dolu_top = [char]0x25CF
    $bos_top = [char]0x25CB

    $userHost = $env:COMPUTERNAME

    # Gecerli dizin (Home kisayolu ile)
    $path = $PWD.Path.Replace($HOME, "~")

    # Git branch (varsa)
    # $gitBranch = $null
    # if (Get-Command git -ErrorAction SilentlyContinue) {
    #     $branch = git rev-parse --abbrev-ref HEAD 2>$null
    #     if ($LASTEXITCODE -eq 0 -and $branch) {
    #         $gitBranch = $branch
    #     }
    # }

    $datestr = Get-Date -U "%d %b %a"
    $timestr = Get-Date -U %R

    $line1 = "[$green$userHost$reset] - [$blue$path$reset] - [$purple$datestr$reset]"
    if ($gitBranch) {
        $line1 += "$gray on $reset$purple($gitBranch)$reset"
    }

    if ($global:IsEmptyCommand) {
        $statstr = "$green$bos_top $reset"
    }else {
        if ($IsOk) {
            $statstr = "$green$dolu_top $reset"
        } else {
            $statstr = "$red$dolu_top $reset"
        }
    }
    # Alt satir: prompt oku
    $line2 = "$statstr $purple$timestr$reset $yellow$prompt_char$reset "

    Write-Host ""
    Write-Host $line1
    Set-PSReadLineOption -PromptText $line2
    return $line2
}