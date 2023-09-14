function Prompt
{
    $pc = hostname
    Write-Host "[$pc] " -ForegroundColor Green -NoNewLine

    if ((New-Object Security.Principal.WindowsPrincipal(
	[Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
	[Security.Principal.WindowsBuiltInRole]::Administrator))
    {
	Write-Host "[Elevated] " -ForegroundColor Red -NoNewLine
    }

    Write-Host "["(Get-Date -UFormat %R)"] " -ForegroundColor Blue -NoNewline
    if ((Get-History).Length -gt 0)
    {
        $LastExecutionTime = "{0:N0}" -f ((Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime).TotalMilliSeconds
    }
    else
    {
        $LastExecutionTime = "0"
    }
    Write-Host "[$LastExecutionTime ms] " -ForegroundColor Yellow -NoNewLine
    Write-Host (Get-Location) -ForegroundColor Cyan
    Set-PSReadLineOption -PromptText "$winlogo > "
    Write-Host ">" -NoNewline
    $host.ui.rawui.WindowTitle = (Get-Location)
    return " "
}