param(
    [string]$Title = "Notification",
    [string]$Message = "This is a notification message."
)
Add-Type -AssemblyName System.Windows.Forms
$Form = New-Object System.Windows.Forms.NotifyIcon
$Form.Icon = [System.Drawing.SystemIcons]::Information
$Form.BalloonTipTitle = $Title
$Form.BalloonTipText = $Message
$Form.Visible = $true
$Form.ShowBalloonTip(5000)
Start-Sleep -Seconds 5
$Form.Dispose()