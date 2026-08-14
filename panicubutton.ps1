param(
    [ValidateSet("Last1min","Last5min","Last15min","Last30min","Last1hour")]$Duration
)

$sysmonEvents = @{
1="Process creation"
2="A process changed a file creation time"
3="Network connection"
4="Sysmon service state changed"
5="Process terminated"
6="Driver loaded"
7="Image loaded"
8="CreateRemoteThread"
9="RawAccessRead"
10="ProcessAccess"
11="FileCreate"
12="Registry create and delete"
13="Registry Value Set"
14="Registry Rename"
15="FileCreateStreamHash"
16="ServiceConfigurationChange"
17="Pipe Created"
18="Pipe Connected"
19="WmiEventFilter activity detected"
20="WmiEventConsumer activity detected"
21="WmiEventConsumerToFilter activity detected"
22="DNS query"
23="FileDelete"
24="ClipboardChange"
25="ProcessTampering"
250="Error"
}

if ((New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator))
        {
            $Elevated = $true
        }
else {
    Write-Host "Security and Sysmon event will not show, since not elevated"
    $Elevated = $false
}
    

if ($Duration -eq "LastHour") {
        $st = (Get-Date).AddHours(-1)
}
elseif ($Duration -eq "Last30min") {
        $st = (Get-Date).AddMinutes(-30)
}
elseif ($Duration -eq "Last15min") {
        $st = (Get-Date).AddMinutes(-15)
}
elseif ($Duration -eq "Last5min") {
        $st = (Get-Date).AddMinutes(-5)
}
elseif ($Duration -eq "Last1min") {
        $st = (Get-Date).AddMinutes(-1)
}
else {
    $st = (Get-Date).AddMinutes(-1)
}

Write-Host "Current time is $(Get-Date -UFormat %T)"
Write-Host "Searching since $(Get-Date -Date $st -UFormat %T)"

# =================== System Events ===================
Write-Host "Listing system events..."
$ev1 = Get-WinEvent -Filterhashtable @{Logname="System";StartTime=$st} -ea silent
Write-Host "$($ev1.Count) system events"
if ($ev1.Count -gt 0) {
    $ev1 | D:\Smalltools\powershell\tabulate_time.ps1 | Out-GridView -Title "System events"
}

# =================== Application Events ===================
Write-Host "Listing application events..."
$ev1 = Get-WinEvent -Filterhashtable @{Logname="Application";StartTime=$st} -ea silent
Write-Host "$($ev1.Count) application events"
if ($ev1.Count -gt 0) {
    $ev1 | D:\Smalltools\powershell\tabulate_time.ps1 | Out-GridView -Title "Application events"
}

# =================== Elevation check ===================
if ($Elevated) {
# =================== Security Events ===================
    Write-Host "Listing security events..."
    $ev1 = Get-WinEvent -Filterhashtable @{Logname="Security";StartTime=$st} -ea silent
    Write-Host "$($ev1.Count) security events"
    if ($ev1.Count -gt 0) {
        $ev1 | D:\Smalltools\powershell\tabulate_time.ps1 | Out-GridView -Title "Security events"
    }

# =================== Sysmon Events ===================
    Write-Host "Listing sysmon events..."
    $ev1 = Get-WinEvent -Filterhashtable @{Logname="Microsoft-Windows-Sysmon/Operational";StartTime=$st} -ea silent
    Write-Host "$($ev1.Count) sysmon events"
    if ($ev1.Count -gt 0) {
        $ev1 | Select-Object TimeCreated, Id,
        @{N="EventType";E={$sysmonEvents[$_.Id]}},
        @{N="PId";E={$_.Properties[3].Value}},
        @{N="Img";E={$_.Properties[4].Value}},
        @{N="Usr-Trgt";E={$_.Properties[5].Value}},
        @{N="Prot-Creat";E={$_.Properties[6].Value}},
        @{N="Img-Initd-Usr";E={$_.Properties[7].Value}},
        @{N="SrcIP";E={$_.Properties[9].Value}},
        @{N="SrcPort";E={$_.Properties[11].Value}},
        @{N="DstcIP";E={$_.Properties[14].Value}},
        @{N="DstPort";E={$_.Properties[16].Value}} |
            Out-GridView -Title "Sysmon events"
    }
}

# =================== Task Scheduler Events ===================
Write-Host "Listing task scheduler events..."
$ev1 = Get-WinEvent -Filterhashtable @{Logname="Microsoft-Windows-TaskScheduler/Operational";StartTime=$st} -ea silent
Write-Host "$($ev1.Count) task scheduler events"
if ($ev1.Count -gt 0) {
    $ev1 | D:\Smalltools\powershell\tabulate_time.ps1 | Out-GridView -Title "Task Scheduler events"
}

$ids_to_exclude = (ps firefox* -ea silent).Id
$ids_to_exclude += (ps spotify* -ea silent).Id

$conn_estab = Get-NetTCPConnection -State Established -ea silent | 
    Where-Object {$_.OwningProcess -notin $ids_to_exclude} | 
    Select-Object -Property RemoteAddress, 
        RemotePort, 
        LocalPort,
        OwningProcess,
        @{N="ProcName";E={(ps -id $_.OwningProcess).Name}}, 
        @{N="Country";E={if ($_.RemoteAddress -notmatch "\b127.0.0.|\b10.10.|\b192.168.|\172.16.") {(ipwhois $_.RemoteAddress -service ipinfolite -ea silent).country}}}

Write-Host "$($conn_estab.Count) established connections"
$conn_estab | Out-GridView -Title "Established Connections"

$conn_listen = Get-NetTCPConnection -State Listen -ea silent |
    Select-Object LocalPort,
        OwningProcess,
        @{N="ProcName";E={(ps -id $_.OwningProcess).Name}}
Write-Host "$($conn_listen.Count) listening connections"
$conn_estab | Out-GridView -Title "Listening Connections"

$other_connections = Get-NetTCPConnection -State Closed, CloseWait, Closing, DeleteTCB, FinWait1, FinWait2, LastAck, SynReceived, SynSent, TimeWait -ea silent |
    Select-Object RemoteAddress,
        LocalPort,
        RemotePort,
        OwningProcess,
        @{N="ProcName";E={(ps -id $_.OwningProcess).Name}}, 
        @{N="Country";E={if ($_.RemoteAddress -notmatch "\b127.0.0.|\b10.10.|\b192.168.|\172.16.") {(ipwhois $_.RemoteAddress -service ipinfolite -ea silent).country}}}
Write-Host "$($conn_listen.Count) inactive connections"
$conn_estab | Out-GridView -Title "Inactive Connections"
