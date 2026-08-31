# OTOMATIK URETILDI - 2026-08-31 08:41D:\Metin\docs\WindowsPowerShell\Modules\MetinMainModule\MetinMainModule.psm1
# "Get-DriveSpace", "Get-MonitorInfo", "Get-Uptime","Get-RebootInfoW","Get-HwInfo","Get-OSInfo","Get-BiosParams","Get-Lockouts","Get-LockoutLocation","Get-FileMetaData","Get-RebootReason","Get-MemoryConsumed","Get-LongNames","Get-PageTime","Play-Sound","Get-PendingReboot","Get-MemoryTotals","Get-LastCommandExecutionTime","Get-NewFiles","Get-Currency","Compare-Tree","Compare-File","Get-Encoding","Get-LoggedinUser","Get-DuplicateFiles","Get-IPwhois","Get-MOInstalledPrograms","Get-Encoding","List-MODevices","Get-NTFSFormatDate","Check-ActivationStatus","Test-ICMP"
# +logoff +poweroff +reboot
function Get-DriveSpace
{
<#
.SYNOPSIS
   This function prints capacity and free space in a drive.
.DESCRIPTION
   This function prints the capacity and free space in any drive on any computer.
   Gets this info via Get-WmiObject cmdlet, and checks connection to the remote computer
   via Test-Connection beforehand.
.EXAMPLE
   Get-DriveSpace
   This command prints info about C: drive on local computer.
.EXAMPLE
   Get-DriveSpace -deviceID=D:
   This command prints info about D: drive on local computer.
.EXAMPLE
    Get-DriveSpace -computername Server1
    This command prints info about C: drive on remote computer server1
.EXAMPLE
    Get-DriveSpace -computername Server1 -DeviceID D:
    This command prints info about D: drive on remote computer server1
#>
[CmdletBinding()]
Param(
    # Remote computer to be queried
    [string]$ComputerName=$env:computername,
    # Drive letter, ending with a colon.
    [string]$deviceID='C:'
)

    $bUp = Test-Connection -Quiet -Count 1 -ComputerName $ComputerName

    if (($ComputerName -ne $env:computername -and $bUp) -or ($ComputerName -eq $env:computername))
    {
        Get-WmiObject -ComputerName $ComputerName -Class Win32_LogicalDisk -Filter "DeviceID='$deviceID'" |
            select @{n="Host";e={$_.SystemName}}, @{n="FreeMB";e={"{0:N2}" -f ($_.Freespace / 1MB)}}, @{n="TotalMB";e={"{0:N2}" -f ($_.size/1MB)}}
    }
    elseif (!$bUp)
    {
        Write-Output "$computername is down"
    }
}

function Get-MonitorInfo
{
<#
.SYNOPSIS
    Prints info about the connected monitor.
.DESCRIPTION
    This function uses Get-WmiObject cmdlet class WmiMonitorID for the currently connected screen(s),
    and displays manufacturer, product code, serial number and production date info.

    No ping test is made before WMI query.
.EXAMPLE
    Get-MonitorInfo
    Manufacturer : LGD
    ProductCode  : 032C
    SerialNumber : 0
    Name         :
    Week         : 0
    Year         : 2011

    Manufacturer : DEL
    ProductCode  : A088
    SerialNumber : 2W2Y82BN1H3U
    Name         : DELL P1913
    Week         : 47
    Year         : 2012

    This command gets info about the local machine's screens, where LGD is the laptop screen,
    and DEL is the second monitor. Manufacturer codes are three-letter codes.
.EXAMPLE
    Get-MonitorInfo -ComputerName pc1
    This command gets info about remote computer PC1.
#>
[CmdletBinding()]
Param
(
    [Parameter(
    Position=0,
    ValueFromPipeLine=$true,
    ValueFromPipeLineByPropertyName=$true)]
    [string]$ComputerName = '.'
)

    Process
    {

        $ActiveMonitors = Get-WmiObject -Class WmiMonitorID -Namespace root\wmi -ComputerName $ComputerName
        $Graphics = Get-WmiObject -ComputerName $ComputerName -Class Win32_VideoController
        $monitorInfo = @()

        foreach ($monitor in $ActiveMonitors)
        {
            $mon = New-Object PSObject
            $manufacturer = $null
            $product = $null
            $serial = $null
            $name = $null
            $week = $null
            $year = $null

            
            $monitor.ManufacturerName | foreach {$manufacturer += [char]$_}
            $monitor.ProductCodeID | foreach {$product += [char]$_}
            $monitor.SerialNumberID | foreach {$serial += [char]$_}
            $monitor.UserFriendlyName | foreach {$name += [char]$_}

            $mon | Add-Member NoteProperty Manufacturer $manufacturer
            $mon | Add-Member NoteProperty ProductCode $product
            $mon | Add-Member NoteProperty SerialNumber $serial
            $mon | Add-Member NoteProperty Name $name
            $mon | Add-Member NoteProperty Week $monitor.WeekOfManufacture
            $mon | Add-Member NoteProperty Year $monitor.YearOfManufacture

            $monitorInfo += $mon
        }
        return $monitorInfo
    }
}

function Get-Uptime
{
<#
.SYNOPSIS
    This script will report uptime of given computer since last reboot.
.DESCRIPTION
    Pre-Requisites: Requires PowerShell 2.0 and WMI access to target computers (admin access).

    Queries WMI class Win32_OperatingSystem for LastBootUpTime value.

    Usage syntax:
    For local computer where script is being run: .\Get-Uptime.ps1.
    For list of remote computers: .\Get-Uptime.ps1 -ComputerList "c:\temp\computerlist.txt"

    Last Modified: 3/20/2012
    Created by
    Bhargav Shukla
    http://blogs.technet.com/bshukla
    http://www.bhargavs.com

    Downloaded from Technet at May 27th, 2015 (Metin)

    DISCLAIMER
    ==========
    THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE
    RISK OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

    Requires -Version 2.0
.EXAMPLE
    Get-Uptime.ps1 -Computer ComputerName
    Displays uptime of one remote computer
.EXAMPLE
    Get-Uptime.ps1 -ComputerList "c:\temp\computerlist.txt" | Export-Csv uptime-report.csv -NoTypeInformation
    Displays uptime of computers given in the computerlist.txt file, and exports them as csv file
#>
[CmdletBinding()]
param
(
	[Parameter(Position=0,ValuefromPipeline=$true)][string][alias("cn")]$computer,
	[Parameter(Position=1,ValuefromPipeline=$false)][string]$computerlist,
    [switch]$FastBoot
)

    If (-not ($computer -or $computerlist))
    {
	    $computers = $Env:COMPUTERNAME
    }

    If ($computer)
    {
	    $computers = $computer
    }

    If ($computerlist)
    {
	    $computers = Get-Content $computerlist
    }

    foreach ($computer in $computers)
    {
	    $Computerobj = "" | select ComputerName, Uptime, LastReboot
        $now = Get-Date
        if ($FastBoot) {
            $boottime = (Get-WinEvent -ComputerName $computer -FilterHashtable @{Logname="System";Id=1;ProviderName="*Kernel-General"} | where {$_.properties[3].Value -eq 2} | Select-Object -First 1).TimeCreated
        }
        else {
            $wmi = Get-WmiObject -ComputerName $computer -Query "SELECT LastBootUpTime FROM Win32_OperatingSystem"
            $boottime = $wmi.ConvertToDateTime($wmi.LastBootUpTime)
        }
        $uptime = $now - $boottime
        $d =$uptime.days
        $h =$uptime.hours
        $m =$uptime.Minutes
        $s = $uptime.Seconds
        $Computerobj.ComputerName = $computer
        $Computerobj.Uptime = "$d Days $h Hours $m Min $s Sec"
        $Computerobj.LastReboot = $boottime
    
        $Computerobj
    }
}

function Get-RebootInfoW
{
<#
.SYNOPSIS
    Get latest reboot events from the computer. This is the function that runs with Get-WinEvent.
.DESCRIPTION
    Queries local or remote computer System event logs for boot (6005), shutdown (6006) or crash (6008) events
    to list the last reboot information.

    Use -NumberOfDays argument to search for required number of days past info.
    Use -Computername parameter to point to a remote computer. RemoteRegistry service on the remote computer
    is started to get this information.

    This is the function that runs with Get-WinEvent cmdlet. The older method uses Get-EventLog cmdlet.
    2018-01-08 Metin

.EXAMPLE
    Get-RebootInfo
    Get startup and shutdown events from the local computer from the last 30 days.
.EXAMPLE
    Get-RebootInfo -NumberOfDas 10
    Get startup and shutdown events from the local computer from the last 10 days.
.EXAMPLE
    Get-RebootInfo -ComputerName server1
    Get startup and shutdown events from remote computer server1, for the last 30 days.
.EXAMPLE
    Get-RebootInfo -ComputerName server1 -NumberOfDays -60
    Get startup and shutdown events from remote computer server1, for the last 60 days.
#>
[CmdletBinding()]
Param
(
  [string]$ComputerName=$env:Computername,
  [int]$NumberOfDays=30
)

    # [timespan]$uptime = New-TimeSpan -start 0 -end 0
    $currentTime = get-Date
    $startUpID = 6005
    $shutDownID = 6006
    $crashID = 6008
    $startingDate = (Get-Date -Hour 00 -Minute 00 -Second 00).adddays(-$numberOfDays)
    $IsHostUp = $false
    # $startingDate = Get-Date -Year 2016 -Month 1 -Day 1 -Hour 00 -Minute 00 -Second 00
    # $endingDate  = Get-Date -Year 2016 -Month 2 -Day 25 -Hour 00 -Minute 00 -Second 00

    if ($ComputerName -eq $env:Computername)
    {
        $events = Get-WinEvent -FilterHashTable @{LogName="system";ID=$startUpID,$shutDownID,$crashID;StartTime=$startingDate}
        $IsHostUp = $true
    }
    else
    {
        if (Test-Connection $ComputerName -Quiet -Count 1)
        {
            Write-Host "Host is up, fetching events..."
            # below disabled @ 2023-05-31, looks like no need on Win11?
            # Get-Service -ComputerName $ComputerName -Name RemoteRegistry | Start-Service
            $events = Get-WinEvent -ComputerName $ComputerName -FilterHashTable @{LogName="system";ID=$startUpID,$shutDownID,$crashID;StartTime=$startingDate}
            # canceled serivce stop @2017-01-11
            # Get-Service -ComputerName $ComputerName -Name RemoteRegistry | Stop-Service
            $IsHostUp = $true
        }
        else
        {
            Write-Host $ComputerName " appears to be down."
            $IsHostUp = $false
        }
    }

    if ($IsHostUp)
    {
        $i = $events.Count-1
        $Table1 = New-Object System.Data.DataTable "UptimeList"
        $Col1   = New-Object System.Data.DataColumn TimeCreated,([datetime])
        $Col2   = New-Object System.Data.DataColumn EventType,([string])
        $Col3   = New-Object System.Data.DataColumn Duration,([string])

        $Table1.Columns.Add($Col1)
        $Table1.Columns.Add($Col2)
        $Table1.Columns.Add($Col3)

        For($i=$events.Count-1; $i -ge 0; --$i)
        {
         $newrow = $Table1.NewRow()
         $newrow.TimeCreated = $events[$i].TimeCreated

         if ([int32]$events[$i].ID -eq 6005)
         {
            $newrow.EventType = "Startup"
            $eventtype="uptime"
         }
         elseif ([int32]$events[$i].ID -eq 6006)
         {
            $newrow.EventType = "Shutdown"
            $eventtype = "downtime"
         }
         elseif ([int32]$events[$i].ID -eq 6008)
         {
            $newrow.EventType = "-UNEXPECTED-"
            if ($events[$i].LevelDisplayName -eq 'Hata') # if Turkish locale
            {
                $eventtype += "/ " + ($events[$i].Message).Substring(0,24)
            }
            else # if English locale
            {
                $eventtype += "/ " + ($events[$i].Message).Substring(31,28)
            }
         }
         else
         {
            $newrow.EventType = "-unknown-"
            $eventtype = "-unknown-"
         }

          if ($i -eq 0)
          {
            $Duration  = (Get-Date) - $events[$i].TimeCreated
          }
          else
          {
            $Duration = $events[$i-1].TimeCreated - $events[$i].TimeCreated
          }
          $newrow.Duration = "$($Duration.Days) days, $($Duration.Hours) hours, $($Duration.Minutes) minutes, $($Duration.Seconds) seconds $eventtype"
         $Table1.Rows.Add($newrow)
        }

        Write-Host "From host " $ComputerName  ", starting from " $startingDate
        $Table1 | ft "TimeCreated", "EventType", "Duration" -Autosize
    }
}

function Get-HwInfo
{
<#
.SYNOPSIS
    Get some key hardware info from a computer.
.DESCRIPTION
    Queries the local or remote computer WMI for these information:
        -CPU Info (manufacturer, name, cache sizes, clock speeds, ID)
        -RAM Info (total RAM size, RAM speed, serial number, part numer)
    for local computer. And for a remote computer gets these additional info:
        -Sound Card
        -Video Card

.EXAMPLE
    Get-HwInfo
    Host :  LocalComputer
    Caption      :  Intel64 Family 6 Model 58 Stepping 9
    Manufacturer :  GenuineIntel
    Name         :  Intel(R) Core(TM) i5-3210M CPU @ 2.50GHz
    L2CacheSize  :  512
    L3CacheSize  :  3072
    MaxClockSpeed:  2501
    AddressWidth :  64
    DataWidth    :  64
    ProcessorId  :  BFEBFBFF000306A9
    Cores        :  2
    Logical CPUs :  4
    Total RAM    :  8192 MB
    RAM DataWidth:  64
    RAM Speed    :  1600
    RAM SerialNo :  F2312666
    RAM PartNum  :  NT8GC64B8HB0NS-DI
.EXAMPLE
    Get-HwInfo -ComputerName server
    Host :  server
    Caption      :  Intel64 Family 6 Model 58 Stepping 9
    Manufacturer :  GenuineIntel
    Name         :  Intel(R) Core(TM) i5-3210M CPU @ 2.50GHz
    L2CacheSize  :  512
    L3CacheSize  :  3072
    MaxClockSpeed:  2501
    AddressWidth :  64
    DataWidth    :  64
    ProcessorId  :  BFEBFBFF000306A9
    Cores        :  2
    Logical CPUs :  4
    Total RAM    :  8192 MB
    RAM DataWidth:  64
    RAM Speed    :  1600
    RAM SerialNo :  76352669
    RAM PartNum  :  NT8GC64B8HB0NS-DI
    Sound Device Name : IDT High Definition Audio CODEC
    Sound Device Manufacturer : IDT
    Sound Device Name : Intel(R) Ekran Icin Ses
    Sound Device Manufacturer : Intel(R) Corporation
    Graphics Card Name : Current Display Controller Configuration
    Video Mode : 1024 by 768 pixels, True Color, 60 Hertz
#>
[CmdletBinding()]
param (
    [string]$ComputerName=$env:Computername,
    [switch]$Detailed
)

    $HostUpAndRunning = $false

    if (Test-Connection $ComputerName -Quiet -Count 1) # seperate definitions for local and remote mode all unified
    {
        $chasistype = Get-WmiObject -ComputerName $ComputerName -Class win32_SystemEnclosure
        $BrandModel = Get-WmiObject -Computername $ComputerName -Class Win32_ComputerSystem | Select-Object Manufacturer, Model
        $arrChasistypes = ("Other","Unknown","Desktop","Low Profile Desktop","Pizza Box","Mini Tower","Tower","Portable","Laptop","Notebook","Handheld","Docking Station","All-in-One","Sub-Notebook","Space Saving","Lunch Box","Main System Chassis","Expansion Chassis","Sub-Chassis","Bus Expansion Chassis","Peripheral Chassis","Storage Chassis","Rack Mount Chassis","Sealed-Case PC")

        $sCPU =Get-WmiObject -ComputerName $ComputerName -class win32_processor
        $oMem = Get-WmiObject -ComputerName $ComputerName -class Win32_PhysicalMemory
        $oAu = Get-WmiObject -ComputerName $ComputerName -class Win32_SoundDevice
        # $oGr = Get-WmiObject -class Win32_DisplayControllerConfiguration -ComputerName $ComputerName
        # replaced by the following line [2017-10-16]
        $oGr = Get-WmiObject -ComputerName $ComputerName -Class Win32_VideoController
        $net = Get-WmiObject -ComputerName $ComputerName -Class win32_networkadapter | where {$_.NetConnectionStatus -ge 0}
        $arrNetconstat = ("Disconnected","Connecting","Connected","Hardware not present","Hardware Disabled","Hardware Malfunction","Media Disconnected","Authenticating","Authentication Required","Authentication Succeede","Authentication Failed","Invalid Address","Credentials Required")

        $HostUpAndRunning = $true
    }
    else
    {
        Write-Host $ComputerName " is down."

        $HostUpAndRunning = $false
    }

    if ($HostUpAndRunning)
    {
        Write-Host "Host         : " $ComputerName

        foreach ($sProperty in $chasistype.ChassisTypes)
        {
            Write-host("Enclosure Typ: " + $arrChasistypes[$sProperty-1]) -ErrorAction SilentlyContinue
        }
        Write-Host "Brand        : " $BrandModel.Manufacturer
        Write-Host "Model        : " $BrandModel.Model

        # CPU Info
        Write-Host "========= CPU ========="
        foreach($sProperty in $sCPU)
        {
            write-host "Caption      : " $sProperty.Caption
            write-host "Manufacturer : " $sProperty.Manufacturer
            write-host "Name         : " $sProperty.Name
            if ($Detailed) {
                write-host "L2CacheSize  : " $sProperty.L2CacheSize
                write-host "L3CacheSize  : " $sProperty.L3CacheSize
                write-host "MaxClockSpeed: " $sProperty.MaxClockSpeed
                write-host "AddressWidth : " $sProperty.AddressWidth
                write-host "DataWidth    : " $sProperty.DataWidth
                write-host "ProcessorId  : " $sProperty.ProcessorId
                write-host "Cores        : " $sProperty.NumberOfCores
                write-host "Logical CPUs : " $sProperty.NumberOfLogicalProcessors
            }
        }

        # Memory Info
        Write-Output "======= Memory ========"
        foreach($sProperty in $oMem)
        {
            Write-Host("Total RAM    :  " + ($sProperty.Capacity)/1024/1024 + " MB")
            Write-Host "RAM DataWidth: " $sProperty.DataWidth
            Write-Host "RAM Speed    : " $sProperty.Speed
            if ($Detailed) {
                Write-Host "RAM SerialNo : " $sProperty.SerialNumber
                Write-Host "RAM PartNum-  : " $sProperty.PartNumber
            }
        }

        # SoundCard Info
        if ($Detailed) {
            Write-Output "======== SOUND ========"
            foreach($sProperty in $oAu)
            {
                Write-Host("Sound Device Name : " + $sProperty.Caption)
                Write-Host("Sound Device Manufacturer : " + $sProperty.Manufacturer)
            }
        }

        # Graphics Card Info
        Write-Output "====== GRAPHICS ======="
        foreach($sProperty in $oGr)
        {
            Write-Host("Graphics Card Name : " + $sProperty.Caption)
            Write-Host("Video Mode : " + $sProperty.VideoModeDescription)
        }

        # Network Adapter Info
        Write-Output "========= NET ========="
        foreach ($sProperty in $net)
        {
            Write-Host( $sProperty.netconnectionid + " adaptor : " + ($sProperty.Name) + " - " + $sProperty.MACAddress + " - (" + $arrNetconstat[$sProperty.NetConnectionStatus] + ")")
        }
    }
}

function Get-OSInfo
{
<#
.SYNOPSIS
    Get OS info from a computer.

    Revised 2026-05-20 : Added UBR, removed unnecessary info
.DESCRIPTION
    Queries WMI win32_OperatingSystem object for these fields:

        - Host Description
        - OS Caption
        - OS Version
        - OS architecture (32-bit / 64-bit)
        - Build Number
        - SP major version
        - OS installed date-time

    Ping test is done beforehand.

.EXAMPLE
    Get-OSInfo -ComputerName server
    Host :  server
    Description :
    Caption     :  Microsoft Windows 7 Professional
    Version     :  6.1.7601
    Architecture:  64-bit
    BuildNumber :  7601
    SP Major v. :  1
    Installed on:  18.02.2013 21:12:54
Lookup : https://en.wikipedia.org/wiki/Windows_10_version_history#Version_2004_(May_2020_Update)
#>
[CmdletBinding()]
param (
    [string]$ComputerName=$env:Computername
)

    $HostUpAndRunning = $false

    if ($ComputerName -eq $env:Computername)
    {
        $sOS =Get-WmiObject -class Win32_OperatingSystem
        $UBR = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR
        $HostUpAndRunning = $true
    }
    else
    {
        if (Test-Connection $ComputerName -Quiet -Count 1)
        {
            $sOS =Get-WmiObject -class Win32_OperatingSystem -computername $ComputerName

            $ses1 = New-PSSession -ComputerName $ComputerName -ErrorAction SilentlyContinue

            $UBR = icm -Session $ses1 -ScriptBlock {
                (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR
            } -ea silent

            Remove-PSSession -Session $ses1
            $HostUpAndRunning = $true
        }
        else
        {
            Write-Host $ComputerName " is down."

            $HostUpAndRunning = $false
        }
    }

    if ($HostUpAndRunning)
    {
        # Write-Host "Host : " $ComputerName
        foreach($sProperty in $sOS)
        {
            $datetimeformat = ([WMI] '').ConvertToDateTime($sProperty.InstallDate)
            $obj = [ordered]@{ Host = $ComputerName
                      Caption = $sProperty.Caption
                      Version = $sProperty.Version
                      BuildNumber = $sProperty.BuildNumber
                      UBR = $UBR
                      Architecture = $sProperty.OSArchitecture
                      InstalledOn = $datetimeformat
            }
            $obj
            # write-host "Description : " $sProperty.Description
            # write-host "Caption     : " $sProperty.Caption
            # if ($sProperty.Caption -like "*Windows 10*")
            # {
            #     Write-Host "Win10Version: " $VersionNumber
            # }
            # write-host "Version     : " $sProperty.Version
            # write-host "Architecture: " $sProperty.OSArchitecture
            # write-host "BuildNumber : " $sProperty.BuildNumber
            # write-host "SP Major v. : " $sProperty.ServicePackMajorVersion
            # # bu bi yontem $datetimeformat = [datetime]::ParseExact($sProperty.InstallDate.SubString(0,14),"yyyyMMddhhmmss",$null)
            
            # write-host "Installed on: " $datetimeformat
        }
    }
}

function Get-BiosParams
{
<#
.SYNOPSIS
    Gets information about BIOS from a computer.
.DESCRIPTION
    Queries the local or remote computer WMI win32_BIOS object for these info:

    -BIOS Version
    -BIOS Manufacturer
    -BIOS Name
    -BIOS Serial Number
    -BIOS Version

    Ping test is done beforehand.
.EXAMPLE
    Get-BiosParams -ComputerName server
    Host :  server


    SMBIOSBIOSVersion : A07
    Manufacturer      : Dell Inc.
    Name              : BIOS Date: 10/08/12 19:55:01 Ver: A07.00
    SerialNumber      : 97PQBW1
    Version           : DELL   - 1072009
#>
[CmdletBinding()]
Param(
    $ComputerName=$env:COMPUTERNAME
)

    if ($ComputerName -eq $env:Computername)
    {
        # Write-Host "Host : " $ComputerName
        Get-WmiObject -Class Win32_bios | select PSComputerName, Name, SerialNumber, Manufacturer
    }
    else
    {
        if (Test-Connection $ComputerName -Quiet -Count 1)
        {
            # Write-Host "Host : " $ComputerName
            Get-WmiObject -Class Win32_bios -ComputerName $ComputerName | select PSComputerName, Name, SerialNumber, Manufacturer
        }
        else
        {
            Write-Host $ComputerName " is down."
        }
    }
}

function Get-Lockouts
{
<#
    .SYNOPSIS
    This cmdlet, unlike its orignal one below, is more simple, more
    to-the-point. Takes a list of domain controllers, queries their
    security event logs for lockout events and bad login attempts
    and displays them in list form.

    .DESCRIPTION
    If no argument is given, it is assumed that the last 1 hour period
    is to be queried. If one argument is given, it has to be a username
    argument and security logs are queried that contains this username
    for 4740 (lockout), 4771 (kerberos pre-auth failed) and 
    4625 (bad login attempt) events.

    There is a type parameter whose default value is 1, in which case
    it only displays lockout events. If any other value is provided,
    along with 4740 lockout events, 4625 and 4771 (bad password)
    events are also listed.

    .EXAMPLE
    Below command queries 4740, 4771 and 4625 events in all DCs in the 
    domain for the last hour

        Get-Lockouts

    .EXAMPLE
    Below command queries 4740, 4771 and 4625 events in all DCs and 
    filters them for user "ali.kurt"

        Get-Lockouts ali.kurt
    .EXAMPLE
    Below example queries for any user account for the last 8 hours

        Get-Lockouts -Username ali.kurt -Duration 8

    .EXAMPLE
    Below example queries for any user account for the last 8 hours, 
    for all bad password events also

        Get-Lockouts -Username ali.kurt -Duration 8 -Type 2
#>

    param(
        [string]$UserName,
        [int]$Duration=1,
        [int]$Type=1
    )

    $domain = [System.Directoryservices.Activedirectory.Domain]::GetCurrentDomain()

    if ($Type=1)
    {
        $eventlist = 4740
    }
    else {
        $eventlist = (4740,4625,4771)
    }

    $resultevents = @()
    if ($UserName)
    {
        $domain.DomainControllers.Name | ForEach-Object {
            $ev = Get-WinEvent -ComputerName $_ -FilterHashtable @{LogName="Security";Id=$eventlist;StartTime=(Get-Date).AddHours(-$Duration)} -ea SilentlyContinue | Where-Object { $PSItem.Message -match $UserName }
            $resultevents += $ev
        }
        $resultevents | Sort TimeCreated -Descending | select TimeCreated, Id, @{N="Username";E={$_.properties[0].Value}}, @{N="Workstation";E={$_.properties[1].Value}}, @{N="Domain";E={$_.properties[5].Value}},@{N="WhoDid";E={$_.properties[3].Value}},@{N="DC";E={$_.properties[4].Value}} | ft -AutoSize
    }
    else
    {
        $domain.DomainControllers.Name | ForEach-Object {
            $ev = Get-WinEvent -ComputerName $_ -FilterHashtable @{LogName="Security";Id=$eventlist;StartTime=(Get-Date).AddHours(-$Duration)} -ea SilentlyContinue
            $resultevents += $ev
        }
        $resultevents | Sort TimeCreated -Descending | select TimeCreated, Id, @{N="Username";E={$_.properties[0].Value}}, @{N="Workstation";E={$_.properties[1].Value}}, @{N="Domain";E={$_.properties[5].Value}},@{N="WhoDid";E={$_.properties[3].Value}},@{N="DC";E={$_.properties[4].Value}} | ft -AutoSize
    }

    if ($resultevents.Count -eq 0) {
        "No events within last $Duration hours"
    }
}

function Get-LockoutLocation
{
<#
    .SYNOPSIS
    Taken from
    https://blogs.technet.microsoft.com/poshchap/2014/05/16/tracing-the-source-of-account-lockouts/
    Returns the location of last lockout cases (within last 1 hour, written in miliseconds).

    .DESCRIPTION
    within last 1 hour, if any lockouts are happend, this function returns the date and time they occured,
    name of the account and the device on which lockout happened. Primary DC is automatically queried.

    .PARAMETER UserName
    This is a mandatory parameter. If not supplied, a prompt will ask for one. If not given, simply
    it will not run.

    .EXAMPLE
    Get-LockoutLocation -UserName 'sedat.senisler'
#>
param(
    [Parameter(Mandatory=$true)][string]$UserName
)

    $PDC = Get-ADDomainController -Discover -Service PrimaryDC

    Get-WinEvent -ComputerName $PDC -Logname Security `
        -FilterXPath "*[System[EventID=4740 and TimeCreated[timediff(@SystemTime) <= 3600000]] and EventData[Data[@Name='TargetUserName']='$UserName']]" |
        Select-Object TimeCreated,@{Name='User Name';Expression={$_.Properties[0].Value}},@{Name='Source Host';Expression={$_.Properties[1].Value}}
}

Function Get-FileMetaData
{
# -----------------------------------------------------------------------------
# Script: Get-FileMetaDataReturnObject.ps1
# Author: ed wilson, msft
# Date: 01/24/2014 12:30:18
# Keywords: Metadata, Storage, Files
# comments: Uses the Shell.APplication object to get file metadata
# Gets all the metadata and returns a custom PSObject
# it is a bit slow right now, because I need to check all 266 fields
# for each file, and then create a custom object and emit it.
# If used, use a variable to store the returned objects before attempting
# to do any sorting, filtering, and formatting of the output.
# To do a recursive lookup of all metadata on all files, use this type
# of syntax to call the function:
# Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName
# note: this MUST point to a folder, and not to a file.
# -----------------------------------------------------------------------------
<#
   .SYNOPSIS
    This function gets file metadata and returns it as a custom PS Object
   .DESCRIPTION
    This function gets file metadata using the Shell.Application object and
    returns a custom PSObject object that can be sorted, filtered or otherwise
    manipulated.
   .EXAMPLE
    Get-FileMetaData -folder "e:\music"
    Gets file metadata for all files in the e:\music directory
   .Example
    Get-FileMetaData -folder (gci e:\music -Recurse -Directory).FullName
    This example uses the Get-ChildItem cmdlet to do a recursive lookup of
    all directories in the e:\music folder and then it goes through and gets
    all of the file metada for all the files in the directories and in the
    subdirectories.
   .EXAMPLE
    Get-FileMetaData -folder "c:\fso","E:\music\Big Boi"
    Gets file metadata from files in both the c:\fso directory and the
    e:\music\big boi directory.
   .EXAMPLE
    $meta = Get-FileMetaData -folder "E:\music"
    This example gets file metadata from all files in the root of the
    e:\music directory and stores the returned custom objects in a $meta
    variable for later processing and manipulation.
   .Parameter Folder
    The folder that is parsed for files
   .Notes
    NAME:  Get-FileMetaData
    AUTHOR: ed wilson, msft
    LASTEDIT: 01/24/2014 14:08:24
    KEYWORDS: Storage, Files, Metadata
    HSG: HSG-2-5-14
   .Link
     Http://www.ScriptingGuys.com
 #Requires -Version 2.0
 #>
 Param([string[]]$folder)
 foreach($sFolder in $folder)
  {
   $a = 0
   $objShell = New-Object -ComObject Shell.Application
   $objFolder = $objShell.namespace($sFolder)

   foreach ($File in $objFolder.items())
    {
     $FileMetaData = New-Object PSOBJECT
      for ($a ; $a  -le 266; $a++)
       {
         if($objFolder.getDetailsOf($File, $a))
           {
             $hash += @{$($objFolder.getDetailsOf($objFolder.items, $a))  =
                   $($objFolder.getDetailsOf($File, $a)) }
            $FileMetaData | Add-Member $hash
            $hash.clear()
           } #end if
       } #end for
     $a=0
     $FileMetaData
    } #end foreach $file
  } #end foreach $sfolder
}

function Get-RebootReason
{
<#
.Synopsis
   Tries to get reason about the shutdown / reboot.
.DESCRIPTION
   Queries the [remote] computer's system log using Get-WinEvent with event
   codes 41, 109, 1001, 1074, 1076, 6005, 6006, 6008.
.EXAMPLE
   Get-RebootReason -ComputerName server1 -StartTime (Get-Date).AddDays(-7) -EndTime (Get-Date)
.EXAMPLE
   Another example of how to use this cmdlet
#>
    Param
    (
        # Computer to be queried
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromRemainingArguments=$false,
                   Position=0)]
        [string]$ComputerName=$env:COMPUTERNAME,

        # StartTime that the query starts from, defaults to 3 days ago.
        $StartTime = (Get-Date).AddDays(-3),

        # Endtime defaults to now + 1 hour
        $EndTime = (Get-Date).AddHours(1)
    )

    try {
        Get-WinEvent -ComputerName $ComputerName -FilterHashTable @{LogName='System';StartTime=$StartTime;EndTime=$EndTime;ID=41,109,1001,1074,1076,6005,6006,6008} -ea Stop
    }
    catch {
        Write-Host "$ComputerName host and $StartTime - $EndTime range returned nothing."
    }

}

function Get-MemoryConsumed
{
<#
.Synopsis
    Find amount of memory a process consumes.
.DESCRIPTION
    By default calculates how much private bytes totally a process (or processes, given by -ProcessName property)
    totally consumes.

    Private bytes is the total amount of virtual memory allocated to the process (some of which may be on swap),
    except shared memory, where as working set the the amount of RAM it occupies together with shared allocations.
    Private Working set is the amount it occupies in RAM except shared memory.

    Possible values for PSField :
        - PrivateMemorySize/64 (default) :
        - WorkingSet
        - VirtualMemorySize/64 (-removed-)
        - MaxWorkingSet (-removed-)
        - MinWorkingSet (-removed-)
        - NonpagedSystemMemorySize/64
        - PagedMemorySize/64
        - PagedSystemMemorySize/64
        - PeakPagedMemorySize/64
        - PeakVirtualMemorySize (-removed-)
        - PeakWorkingSet

    Metin Ozmener 2018-03-08
.EXAMPLE
    Get-MemoryConsumed -ProcessName firefox
#>
    Param
    (
        [Parameter(Mandatory=$true)][string]$ProcessName,
        [ValidateSet("PrivateMemorySize","PrivateMemorySize64","WorkingSet","NonpagedSystemMemorySize","NonpagedSystemMemorySize64","PagedMemorySize","PagedMemorySize64","PagedSystemMemorySize","PagedSystemMemorySize64","PeakPagedMemorySize","PeakPagedMemorySize64","PeakWorkingSet")]
        [string]$PSField = "PrivateMemorySize"
    )

    $pslist = get-process -Name $Processname -ErrorAction SilentlyContinue | select $PSField
    $numps = (gps $ProcessName).Length

    $MemSum = ($pslist.$PSField | Measure-Object -Sum).Sum

    write-Output([string]($numps) + " processes")
    Write-Output("{0:N0}" -f $MemSum + " Bytes")
    Write-Output("{0:N0}" -f [int]($MemSum/1024/1024) + " MB")
}

function Get-LongNames
{
<#
.Synopsis
   Finds files with long path+file names.
.DESCRIPTION
   Queries the folder given by the -Path parameter and it subfolders for long file+path names
   longer than limit given by the -Threshold parameter.

   Metin 2018-05-22
.EXAMPLE
   Get-Longnames -Path D:\tools -Threshold 200
#>
    Param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$Threshold=200
    )

    Get-ChildItem -Path $Path -Recurse | foreach { if (($_.FullName).Length -gt $Threshold) {Write-Host ($_.FullName).Length, $_.DirectoryName }}
}

function Get-PageTime
{
<#
.SYNOPSIS
    Measures loading time of a web page.
.DESCRIPTION
    Tries to connect to the address given by the -URL parameter, number of -Times times
    and displays the results.

    Don't forget to use http or https in front of the url.

    Taken from:
    https://blogs.technet.microsoft.com/fromthefield/2013/07/22/using-powershell-to-measure-page-download-time/

    Metin, 2018-05-26
.EXAMPLE
    Get-PageTime -url http://www.ozmener.net -times 10
#>
    param($URL, $Times)
    $i = 0
    While ($i -lt $Times)
    {
        $Request = New-Object System.Net.WebClient
        $Request.UseDefaultCredentials = $true
        $Start = Get-Date
        $PageRequest = $Request.DownloadString($URL)
        $TimeTaken = "{0:N}" -f (((Get-Date) - $Start).TotalMilliseconds)
        $Request.Dispose()
        Write-Host Request $i took $TimeTaken ms -ForegroundColor Green
        $i ++
    }
}

function Play-Sound
{
<#
.SYNOPSIS
    Play a sound to draw attention.
.DESCRIPTION
    This function by default plays a notification sound to draw attention.

    -Play argument can be used to play arbitrary sound file. It must be a waveform file.

    Taken from:
    https://social.technet.microsoft.com/Forums/tr-TR/2af7ca7a-52aa-4d0a-9eb7-38b863e66d45/powershell-alarm-sound-in-task-scheduler-with-option-run-whether-user-is-logged-on-or-not?forum=Offtopic
    Metin, 2018-06-26
.EXAMPLE
    > Play-Sound
        Plays
#>
    [CmdletBinding()]
    Param
    (
        [string]$Play = "C:\Windows\Media\Alarm01.wav",
        [int]$Number = 1
    )

    if (!(Test-Path $Play))
    {
        $wavs = Get-ChildItem -Path "C:\Windows\Media\*.wav" | Sort-Obeject -Property Length

        $Median = [math]::floor($wavs.Length/2)

        $Play = $wavs[$Median]
    }


    $sound = new-Object System.Media.SoundPlayer;

    while ($Number -gt 0)
    {
        $sound.SoundLocation="$Play";
        $sound.Play()

        $Number = $Number - 1
    }
}

Function Get-PendingReboot
{
<#
.SYNOPSIS
    Gets the pending reboot status on a local or remote computer.

.DESCRIPTION
    This function will query the registry on a local or remote computer and determine if the
    system is pending a reboot, from Microsoft updates, Configuration Manager Client SDK, Pending Computer
    Rename, Domain Join or Pending File Rename Operations. For Windows 2008+ the function will query the
    CBS registry key as another factor in determining pending reboot state.  "PendingFileRenameOperations"
    and "Auto Update\RebootRequired" are observed as being consistant across Windows Server 2003 & 2008.

    CBServicing = Component Based Servicing (Windows 2008+)
    WindowsUpdate = Windows Update / Auto Update (Windows 2003+)
    CCMClientSDK = SCCM 2012 Clients only (DetermineIfRebootPending method) otherwise $null value
    PendComputerRename = Detects either a computer rename or domain join operation (Windows 2003+)
    PendFileRename = PendingFileRenameOperations (Windows 2003+)
    PendFileRenVal = PendingFilerenameOperations registry value; used to filter if need be, some Anti-
                     Virus leverage this key for def/dat removal, giving a false positive PendingReboot

.PARAMETER ComputerName
    A single Computer or an array of computer names.  The default is localhost ($env:COMPUTERNAME).

.PARAMETER ErrorLog
    A single path to send error data to a log file.

.EXAMPLE
    PS C:\> Get-PendingReboot -ComputerName (Get-Content C:\ServerList.txt) | Format-Table -AutoSize

    Computer CBServicing WindowsUpdate CCMClientSDK PendFileRename PendFileRenVal RebootPending
    -------- ----------- ------------- ------------ -------------- -------------- -------------
    DC01           False         False                       False                        False
    DC02           False         False                       False                        False
    FS01           False         False                       False                        False

    This example will capture the contents of C:\ServerList.txt and query the pending reboot
    information from the systems contained in the file and display the output in a table. The
    null values are by design, since these systems do not have the SCCM 2012 client installed,
    nor was the PendingFileRenameOperations value populated.

.EXAMPLE
    PS C:\> Get-PendingReboot

    Computer           : WKS01
    CBServicing        : False
    WindowsUpdate      : True
    CCMClient          : False
    PendComputerRename : False
    PendFileRename     : False
    PendFileRenVal     :
    RebootPending      : True

    This example will query the local machine for pending reboot information.

.EXAMPLE
    PS C:\> $Servers = Get-Content C:\Servers.txt
    PS C:\> Get-PendingReboot -Computer $Servers | Export-Csv C:\PendingRebootReport.csv -NoTypeInformation

    This example will create a report that contains pending reboot information.

.LINK
    Component-Based Servicing:
    http://technet.microsoft.com/en-us/library/cc756291(v=WS.10).aspx

    PendingFileRename/Auto Update:
    http://support.microsoft.com/kb/2723674
    http://technet.microsoft.com/en-us/library/cc960241.aspx
    http://blogs.msdn.com/b/hansr/archive/2006/02/17/patchreboot.aspx

    SCCM 2012/CCM_ClientSDK:
    http://msdn.microsoft.com/en-us/library/jj902723.aspx

.NOTES
    Author:  Brian Wilhite
    Email:   bcwilhite (at) live.com
    Date:    29AUG2012
    PSVer:   2.0/3.0/4.0/5.0
    Updated: 27JUL2015
    UpdNote: Added Domain Join detection to PendComputerRename, does not detect Workgroup Join/Change
             Fixed Bug where a computer rename was not detected in 2008 R2 and above if a domain join occurred at the same time.
             Fixed Bug where the CBServicing wasn't detected on Windows 10 and/or Windows Server Technical Preview (2016)
             Added CCMClient property - Used with SCCM 2012 Clients only
             Added ValueFromPipelineByPropertyName=$true to the ComputerName Parameter
             Removed $Data variable from the PSObject - it is not needed
             Bug with the way CCMClientSDK returned null value if it was false
             Removed unneeded variables
             Added PendFileRenVal - Contents of the PendingFileRenameOperations Reg Entry
             Removed .Net Registry connection, replaced with WMI StdRegProv
             Added ComputerPendingRename
#>

[CmdletBinding()]
param(
	[Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
	[Alias("CN","Computer")]
	[String[]]$ComputerName="$env:COMPUTERNAME",
	[String]$ErrorLog
	)

Begin {  }## End Begin Script Block
Process {
  Foreach ($Computer in $ComputerName) {
	Try {
	    ## Setting pending values to false to cut down on the number of else statements
	    $CompPendRen,$PendFileRename,$Pending,$SCCM = $false,$false,$false,$false

	    ## Setting CBSRebootPend to null since not all versions of Windows has this value
	    $CBSRebootPend = $null

	    ## Querying WMI for build version
	    $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer -ErrorAction Stop

	    ## Making registry connection to the local/remote computer
	    $HKLM = [UInt32] "0x80000002"
	    $WMI_Reg = [WMIClass] "\\$Computer\root\default:StdRegProv"

	    ## If Vista/2008 & Above query the CBS Reg Key
	    If ([Int32]$WMI_OS.BuildNumber -ge 6001) {
		    $RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
		    $CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"
	    }

	    ## Query WUAU from the registry
	    $RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\")
	    $WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired"

	    ## Query PendingFileRenameOperations from the registry
	    $RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\Session Manager\","PendingFileRenameOperations")
	    $RegValuePFRO = $RegSubKeySM.sValue

	    ## Query JoinDomain key from the registry - These keys are present if pending a reboot from a domain join operation
	    $Netlogon = $WMI_Reg.EnumKey($HKLM,"SYSTEM\CurrentControlSet\Services\Netlogon").sNames
	    $PendDomJoin = ($Netlogon -contains 'JoinDomain') -or ($Netlogon -contains 'AvoidSpnSet')

	    ## Query ComputerName and ActiveComputerName from the registry
	    $ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName\","ComputerName")
	    $CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName\","ComputerName")

	    If (($ActCompNm -ne $CompNm) -or $PendDomJoin) {
	        $CompPendRen = $true
	    }

	    ## If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
	    If ($RegValuePFRO) {
		    $PendFileRename = $true
	    }

	    ## Determine SCCM 2012 Client Reboot Pending Status
	    ## To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
	    $CCMClientSDK = $null
	    $CCMSplat = @{
	        NameSpace='ROOT\ccm\ClientSDK'
	        Class='CCM_ClientUtilities'
	        Name='DetermineIfRebootPending'
	        ComputerName=$Computer
	        ErrorAction='Stop'
	    }
	    ## Try CCMClientSDK
	    Try {
	        $CCMClientSDK = Invoke-WmiMethod @CCMSplat
	    } Catch [System.UnauthorizedAccessException] {
	        $CcmStatus = Get-Service -Name CcmExec -ComputerName $Computer -ErrorAction SilentlyContinue
	        If ($CcmStatus.Status -ne 'Running') {
	            Write-Warning "$Computer`: Error - CcmExec service is not running."
	            $CCMClientSDK = $null
	        }
	    } Catch {
	        $CCMClientSDK = $null
	    }

	    If ($CCMClientSDK) {
	        If ($CCMClientSDK.ReturnValue -ne 0) {
		        Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"
		    }
		    If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) {
		        $SCCM = $true
		    }
	    }

	    Else {
	        $SCCM = $null
	    }

	    ## Creating Custom PSObject and Select-Object Splat
	    $SelectSplat = @{
	        Property=(
	            'Computer',
	            'CBServicing',
	            'WindowsUpdate',
	            'CCMClientSDK',
	            'PendComputerRename',
	            'PendFileRename',
	            'PendFileRenVal',
	            'RebootPending'
	        )}
	    New-Object -TypeName PSObject -Property @{
	        Computer=$WMI_OS.CSName
	        CBServicing=$CBSRebootPend
	        WindowsUpdate=$WUAURebootReq
	        CCMClientSDK=$SCCM
	        PendComputerRename=$CompPendRen
	        PendFileRename=$PendFileRename
	        PendFileRenVal=$RegValuePFRO
	        RebootPending=($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
	    } | Select-Object @SelectSplat

	} Catch {
	    Write-Warning "$Computer`: $_"
	    ## If $ErrorLog, log the file to a user specified location/path
	    If ($ErrorLog) {
	        Out-File -InputObject "$Computer`,$_" -FilePath $ErrorLog -Append
	    }
	}
  }## End Foreach ($Computer in $ComputerName)
}## End Process

End {  }## End End

}

function Get-MemoryTotals
{
<#
.SYNOPSIS
   This function calculates total memory consumption of multiple instances of same
   executable image.
.DESCRIPTION
   Assuming there are multiple processes of a same executable image, this function calculates
   the sum of individual images. To change the type of memory, use respective arguments.
.EXAMPLE
   Get-MemoryTotals
   This function gives by default totals of PrivateMemorySize64 field.
.EXAMPLE
   Get-MemoryTotals -virtual
   This function gives totals of VirtualMemorySize64 field.
.EXAMPLE
   Get-MemoryTotals -workingset
   This function gives totals of WorkingSet64 field.
.EXAMPLE
   Get-MemoryTotals -paged
   This function gives totals of PagedMemorySize64 field.
.EXAMPLE
   Get-MemoryTotals -nonpaged
   This function gives totals of NonpagedSystemMemorySize64 field.
#>

param(
    [switch]$virtual,
    [switch]$workingset,
    [switch]$paged,
    [switch]$nonpaged
)


if ($virtual)
{
    $column = "VirtualMemorySize64"
}
elseif ($workingset)
{
    $column = "WorkingSet64"
}
elseif ($paged)
{
    $column = "PagedMemorySize64"
}
elseif ($nonpaged)
{
    $column = "NonpagedSystemMemorySize64"
}
else
{
    $column = "PrivateMemorySize64"
}

Get-Process |
Group-Object ProcessName |
Select-Object -Property Count,
    @{
        Name = 'ProcessName';
        Expression = { $_.Name }
      },
    @{
        Name = $column;
        Expression = { "{0,20:N0}" -f ($_.Group | Measure-Object -Property $column -Sum).Sum}
     } | Sort -Property $column -Descending
}

Function Get-LastCommandExecutionTime {
<#
    .SYNOPSIS
    Taken from
        https://learn-powershell.net/2012/06/26/quick-hits-how-long-did-that-last-command-take/
    on 2019-10-17
        Gets the execution time of the last command used.
    .EXAMPLE
        Get-LastCommandExecutionTime

        Description
        -----------
        Gets the last execution time of the last command run.
#>
    Process {
        (Get-History)[-1].EndExecutionTime - (Get-History)[-1].StartExecutionTime
    }
}

Function Get-NewFiles
{
<#
    .SYNOPSIS
        Find the newest files under given directory and sorts them from the newest to the oldest.
    .DESCRIPTION
        By default, it finds the newly edited 5 files in the current directory (and its subs).
        Number of files to be found, the target directory, the property (whether LastwriteTime or CreationTime)
        for which the files will be searched and the type of files (defaults to *.*) can be changed via parameters.

        Without specifying parameter names, the order of parameters:

            1. Path to be searched in
            2. File type to be searched for
            3. Number of items to be listed / File property to look for

        The reverse sort is not yet supported.

        Metin - 2020 (July ~ August ?)
        Help edit : 2021-02-10
    .EXAMPLE
        This finds the newest 5 files in the current directory, based on LastWritTime property.
            Get-NewFiles
    .EXAMPLE
        This finds the newest 3 *.txt files in D:\data according to CreationTime property.
            Get-NewFiles -Path D:\data -Include *.txt -First 3 -Property "CreationTime"
    .EXAMPLE
        This is also the same as the above example:
            Get-NewFiles D:\data *.txt 3
    .EXAMPLE
        Since the search results are grouped according to folders, this can be done to flat it down:
            Get-NewFiles | Format-Table Name, LastWriteTime, Length
#>
    Param(
        [Parameter(Position=0)]
            [string]$Path="$pwd\*",
        [Parameter(Position=1)]
            [string]$Include="*.*",
        [Parameter(Position=2)]
            [int32]$First=5,
        [Parameter(Position=3)]
            [string]$Property="LastWriteTime"
    )

    if (($Path[-2] -ne "\") -or ($Path[-1] -ne "*"))
    {
        $Path = "$Path\*"
    }

    Get-ChildItem -Path $Path -Include $Include -Recurse |
        Sort-Object -Property $Property -Descending |
        Select-Object -First $First
}

function Get-Currency
{
    $uri = "https://www.tcmb.gov.tr/kurlar/today.xml"
    [xml]$xmlData = Invoke-WebRequest -Uri $uri

    $xmlData.Tarih_Date.Currency[0].CurrencyCode
    $xmlData.Tarih_Date.Currency[0].BanknoteSelling

    $xmlData.Tarih_Date.Currency[3].CurrencyCode
    $xmlData.Tarih_Date.Currency[3].BanknoteSelling
}

function Compare-Tree
{
<#
.SYNOPSIS
    Simplifies comparing directories.
.DESCRIPTION
    Instead of writing
        Compare-Object -ReferenceObject (dir C:\Folder -recurse) -DifferenceObject (dir D:\Folder -recurse)
    simply write
        Compare-Tree C:\Folder D:\Folder
    Both Source and Target (misnamed) parameters are mandatory.

    2021-07-05 Metin
.EXAMPLE
    Compare-Tree C:\Folder D:\Folder

    Compares C:\Folder and D:\Folder directories file by file.
#>

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Source,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Target
    )

    if (Test-Path -Path $Source)
    {
        if (Test-Path -Path $Target)
        {
            $d1 = Get-ChildItem -Path $Source -Recurse | Select-Object -ExpandProperty Name | Sort-Object Name
            $d2 = Get-ChildItem -Path $Target -Recurse | Select-Object -ExpandProperty Name | Sort-Object Name

            Compare-Object -ReferenceObject $d1 -DifferenceObject $d2

            Write-Host "Source: $($d1.Count) / Target: $($d2.Count)"
        }
        else {
            Write-Error "Target path is nonexistent!"
        }
    }
    else {
        Write-Error "Source path is nonexistent!"
    }
}

function Compare-File
{
<#
.SYNOPSIS
    Simplifies comparing directories.
.DESCRIPTION
    Instead of writing
        Compare-Object -ReferenceObject (Get-Content C:\something.txt) -DifferenceObject (Get-Content D:\something.txt)
    simply write
        Compare-Tree C:\Folder D:\Folder
    Both Source and Target (misnamed) parameters are mandatory.

    2021-07-05 Metin
.EXAMPLE
    Compare-Tree C:\Folder D:\Folder

    Compares C:\Folder and D:\Folder directories file by file.
#>

    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Source,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$Target
    )

    if (Test-Path -Path $Source)
    {
        if (Test-Path -Path $Target)
        {
            Write-Host "Computing hash of source file: $Source"
            $d1 = Get-FileHash -Algorithm SHA256 -Path $Source
            Write-Host "Computing hash of target file: $Target"
            $d2 = Get-FileHash -Algorithm SHA256 -Path $Target

            if ($d1.Hash -eq $d2.Hash)
            {
                Write-Host "Completely identical"
            }
            else {
                Write-Host "They are different"
            }
        }
        else {
            Write-Error "Target path is nonexistent!"
        }
    }
    else {
        Write-Error "Source path is nonexistent!"
    }
}

function Get-Encoding
{
<#
.SYNOPSIS
    Get the encoding of a text file.
.DESCRIPTION
    Taken from https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/get-text-file-encoding
    this file reads the first 4 bytes from the given text file,
    and determines encoding according to:
        - 0xEF 0xBB 0xBF : UTF-8
        - 0x2B 0x2F 0x76 : UTF-7
        - 0xFF 0xFE      : Unicode
        - 0xFE 0xFE      : Unicode BE
        - 0x00 0x00 0xFE 0xFF : UTF-32
    Modified, 2026-02-13 Metin
.EXAMPLE
    Get-Encoding -Path D:\file.txt
.EXAMPLE
    dir $home -Filter *.txt -Recurse | Get-Encoding
#>
  param
  (
    [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [Alias('FullName')]
    [string]
    $Path
  )

  process
  {
    $bom = New-Object -TypeName System.Byte[](4)

    $file = New-Object System.IO.FileStream($Path, 'Open', 'Read')

    $null = $file.Read($bom,0,4)
    $file.Close()
    $file.Dispose()

    $enc = "ASCI" # [Text.Encoding]::ASCII
    if ($bom[0] -eq 0x2b -and $bom[1] -eq 0x2f -and $bom[2] -eq 0x76)
      { $enc = "UTF7"
        # $enc =  [Text.Encoding]::UTF7 
     }
    if ($bom[0] -eq 0xff -and $bom[1] -eq 0xfe)
      { $enc = "Unicode16 LE" # which is like 65 00
        # $enc =  [Text.Encoding]::Unicode 
      }
    if ($bom[0] -eq 0xfe -and $bom[1] -eq 0xff)
      { $enc = "Unicode16 BE" # which is like 00 65
        #$enc =  [Text.Encoding]::BigEndianUnicode
      }
    if ($bom[0] -eq 0x00 -and $bom[1] -eq 0x00 -and $bom[2] -eq 0xfe -and $bom[3] -eq 0xff)
      { $enc = "UTF32"
        # $enc =  [Text.Encoding]::UTF32
      }
    if ($bom[0] -eq 0xef -and $bom[1] -eq 0xbb -and $bom[2] -eq 0xbf)
      { $enc = "UTF8"
        # $enc =  [Text.Encoding]::UTF8
      }

    [PSCustomObject]@{
      Encoding = $enc
      Path = $Path
    }
  }
}

Function Get-LoggedinUser {
<#
.SYNOPSIS

.DESCRIPTION

.EXAMPLE

.EXAMPLE

#>

    [CmdletBinding()]
    [Alias("host")]
    Param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [string]$ComputerName=$env:COMPUTERNAME
    )

    try {
        $str = (Get-WmiObject -ComputerName $computername -Class Win32_ComputerSystem -ErrorAction stop).Username

    }

    catch {
        $str = "cannot connect to: $computername"
    }

    finally {
        Write-Host $str
    }

}

function Get-DuplicateFiles
{
<#
# .SYNOPSIS
    Finds duplicate files under a given directory.
    2023-03-11, from https://woshub.com/find-duplicate-files-powershell/

# .DESCRIPTION
    First, all files are checked for size. For those have the same size are subjected to MD5 hashing,
    as a result of which more robust and cost effective way of finding duplicates is achieved.

    Path is a mandatory argument and cannot be omitted having no default value.

    Hash algorightm cannot be changed with cmdlet arguments.

    2022-11-03, taken from http://woshub.com/find-duplicate-files-powershell/

# .EXAMPLE
    Get-DuplicateFiles -Path D:\files
# .EXAMPLE
    To delete duplicate files manually, a grid view can be used in parallel (dont forget to delete -WhatIf)

    $dupfiles = Get-DuplicateFiles -Path D:\files
    $dupfiles | Out-GridView -Title "Select files to delete" -OutputMode Multiple -PassThru | Remove-Item -Verbose -WhatIf
#>
    param(
        [Parameter(Mandatory=$true)][string]$Path
    )
    Get-ChildItem -Path $Path -Recurse | 
        Group-Object -Property Length | 
            Where-Object {$_.Count -gt 1 } | 
                Select-Object -ExpandProperty Group | 
                    Get-FileHash -Algorithm MD5 | 
                        Group-Object -Property hash | 
                            Where-Object {$_.count -gt 1} | 
                                ForEach-Object {$_.Group | Select-Object Path, hash }
}

function Get-IPwhois {
    <#
.SYNOPSIS
    Returns geographical info about an IP address.
.DESCRIPTION
    This function uses external free services to return geographical information about and IP address.
    The detail and accuracy of the returned info may change from service to service.
    Invoke-RestMethod is used to fetch data. So JSON data is returned.
    ipwhois alias exists somewhere.

    First version, probably 2021-02-25
    Last change 2026-08-14 (ipinfolite): Probably the most generous lookups.
.EXAMPLE
    Full usage:

        Get-IpWhoIs -IPAddress 1.1.1.1
.EXAMPLE
    Alias usage with default service being ipinfolite, since 2026-08-14:
    
        ipinfo 8.8.8.8
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false,ParameterSetName="list")]
            [switch]$ListServices,
        [Parameter(Position=0,Mandatory=$true,ParameterSetName="request")]
            [string]$IPAddress,
            [Parameter(Position=1)]
            [ValidateSet("ipinfolite","ipstack","ipwho","ipapi","iplocation","ipinfo")]
            [string]$Service="ipinfolite"
    )

    switch ($PSCmdlet.ParameterSetName) {
        "list" {
            Write-Host "Available services are : ipstack, ipwho, ipapi, iplocation, ipinfo, ipinfolite"
            return
        }
        "request" {
            # discovered 2021-02-25
            if ($Service -eq "ipstack") {
                $ak="cb2d58a7065bf3406114d49808aabc65"
                $service_current = "http://api.ipstack.com/${IPAddress}?access_key=${ak}"
            }

            # discovered 2023-01-30
            if ($Service -eq "ipapi") {
                $service_current = "http://ip-api.com/json/$IPAddress"
            }

            if ($Service -eq "ipwho") {
                $service_current = "https://ipwho.is/$IPAddress"
            }
            
            # discovered 2024-09-25 - seems like there's no limit
            if ($Service -eq "iplocation") {
                $service_current = "https://api.iplocation.net/?ip=$IPAddress"
            }
            
            # learnt from chatgpt 2025-03-06 auth may be necessary at some point but works
            if ($Service -eq "ipinfo") {
                $service_current = "https://ipinfo.io/$IPAddress"
                $strHeader = @{Authorization = "Bearer 25b47ed349ef92"}
            }

            # learnt from chatgpt 2026-08-14 that NEW lite version has not daily limit
            if ($service -eq "ipinfolite") {
                $service_current = "https://api.ipinfo.io/lite/$IPAddress"
                $strHeader = @{Authorization = "Bearer f1ca02945e7d64"}
            }

            Write-Verbose "starting with $service_current"

            try {
                $res = Invoke-RestMethod -Uri $service_current -UseBasicParsing -ErrorAction Stop -Headers $strHeader
            }

            catch {
                $hata1 = 'Hata1:'+$_.Exception
                $hata2 = 'Hata2:'+$_.Exception.StatusCode.Value
                $res = [PSCustomObject]@{
                    Status = $hata1
                    City = $hata1
                    Country = $hata2
                } | Format-List *
            }
            $res
        }
    }
}

function Get-MOInstalledPrograms {
<#
    I think this was the first version I found for Giuseppe, back in the 2016.
    Added to this module @ 2023-06-08
    2024-07-01 : use gcim win32_product as a complementary tool
    Metin
#>
    param(
        [string]$computername
    )

    if ($computername) {
        Invoke-Command -ComputerName $computername {
                Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |  ForEach-object { (Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_).DisplayName}
        }
    }
    else {
        Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall |  ForEach-object { (Get-ItemProperty Microsoft.PowerShell.Core\Registry::$_).DisplayName}
    }
}


function poweroff
{
	Stop-Computer -Force
}

function reboot
{
	Restart-Computer -Force
}

function List-MODevices
{
<# 
.SYNOPSIS
    lsusb for Windows

.DESCRIPTION
    Lists PNP devices, filtering only present ones and those who have USB* in their
    instance ID.

.EXAMPLE
    List-MODevice -cn computer
    
    2024-04-04 https://winaero.com/how-to-find-and-list-connected-usb-devices-in-windows-10/
#>
    param($Computername)

    if ($Computername) {
        if (Test-Connection -Quiet -Count 1 -ComputerName $Computername) {
            Invoke-Command -cn $Computername {Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' } | Format-Table -AutoSize}
        }
    }
    else {
        Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' } | Format-Table -AutoSize
    }
}

function Get-NTFSFormatDate
{
<#
 .SYNOPSIS
    Retrieves formating date of an NTFS volume.
.DESCRIPTION
    2025-01-22 Metin - long after discovering Get-Item method
.EXAMPLE
    Get-NTFSFormatDate -Volume 'C:\'
#>    

param(
    [Parameter(Mandatory=$true)][string]$Volume,
    [string]$ComputerName
)
    if ($ComputerName) {
        $ses1 = New-PSSession -ComputerName $ComputerName
        Invoke-Command -Session $ses1 -ScriptBlock {
            try {
                $vol1 = Get-Item -Path $Using:Volume -ErrorAction Stop
                Get-Date -Date $vol1.CreationTime -Format "yyyy-MM-dd HH:mm:ss"
            }
            catch {
                Write-Error "Volume $Using:Volume not found on $env:COMPUTERNAME"
            }
        }
    }
    else {
        try {
            $item = Get-Item -Path $Volume -ErrorAction Stop
            $item.CreationTime
        }
        catch {
            Write-Error "Volume $Volume not found"
        }
    }
    Remove-PSSession -Session $ses1
}

function Check-ActivationStatus {
    <#
    .SYNOPSIS
        Check the activation status of a remote computer.
    .DESCRIPTION
        This function checks the activation status of a remote computer by querying the SoftwareLicensingProduct class.
        If no computer name is provided, the local computer is queried.

        Possible LicenseStatus values:

            0 - Unlicensed
            1 - Licensed
            2 - OOBGrace
            3 - OOTGrace - the computer configuration has been changed, and it cannot be activated 
                automatically, or more than 180 days passed
            4 - NonGenuineGrace
            5 - Notification - Windows trial period is over
            6 - ExtendedGrace (you can extend the Windows evaluation period several times using the 
                slmgr /rearm command or convert the evaluation to a full version)

        2025-01-23 Metin [https://woshub.com/check-windows-activation-status/]
    .EXAMPLE
        Check-ActivationStatus -remoteComputer "Server01"
    #>
    param(
        [string[]]$ComputerName=$env:COMPUTERNAME
    )

    Invoke-Command -ea silent -ComputerName $ComputerName -ScriptBlock { 
        $strExplaination = ("Unlicensed","Licensed","OOBGrace","OOTGrace","NonGenuineGrace","Notification","ExtendedGrace")
        # Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey } | Select-Object Name, @{N="Status";E={"$($_.LicenseStatus) - $($strExplaination[$_.LicenseStatus])"}}, PSComputerName 
        try {
            Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" -EA Stop | Where-Object { $_.PartialProductKey } | Select-Object Name, @{N="Status";E={"$($_.LicenseStatus) - $($strExplaination[$_.LicenseStatus])"}}, PSComputerName 
        } 
        catch {
            [PSCustomObject]@{
                Name = "."
                status = "Gcim Error"
                PSComputerName = $ComputerName
            }
        }
        
    }
}

function Test-ICMP {
<#
    2025-03-18 Metin, ChatGPT yapti
#>
    param (
        [string]$Computername = "8.8.8.8",
        [int]$Timeout = 1000  # Milisaniye cinsinden
    )

    $ping = New-Object System.Net.NetworkInformation.Ping
    $task = $ping.SendPingAsync($Computername, $Timeout)

    # Task.WaitAny ile $Timeout suresi kadar bekle
    $completed = [System.Threading.Tasks.Task]::WaitAny(@($task), $Timeout)

    if ($completed -eq 0) {
        # Ping islemi tamamlandi, sonucu al
        $reply = $task.Result
        if ($reply.Status -eq "Success") {
            $True
        } else {
            $False
        }
    } else {
        # Belirtilen sure icinde yanit alinamadi
        $False
    }
}
