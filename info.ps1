$ErrorActionPreference = "SilentlyContinue"

$NativeCode = @'
using System;
using System.IO;
using System.Runtime.InteropServices;

public static class NtfsVolumeInfo
{
    // IO_STATUS_BLOCK
    [StructLayout(LayoutKind.Sequential)]
    private struct IO_STATUS_BLOCK
    {
        public IntPtr Status;
        public IntPtr Information;
    }

    // FileFsVolumeInformation yapisi (InfoClass = 1)
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct FILE_FS_VOLUME_INFORMATION
    {
        public long   VolumeCreationTime;   // LARGE_INTEGER (100ns ticks, UTC)
        public uint   VolumeSerialNumber;
        public uint   VolumeLabelLength;
        public byte   SupportsObjects;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string VolumeLabel;
    }

    [DllImport("ntdll.dll")]
    private static extern int NtQueryVolumeInformationFile(
        IntPtr           FileHandle,
        ref IO_STATUS_BLOCK IoStatusBlock,
        IntPtr           FsInformation,
        uint             Length,
        uint             FsInformationClass   // 1 = FileFsVolumeInformation
    );

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern IntPtr CreateFile(
        string lpFileName,
        uint   dwDesiredAccess,
        uint   dwShareMode,
        IntPtr lpSecurityAttributes,
        uint   dwCreationDisposition,
        uint   dwFlagsAndAttributes,
        IntPtr hTemplateFile
    );

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);

    private const uint FILE_READ_ATTRIBUTES    = 0x0080;
    private const uint FILE_SHARE_READ         = 0x0001;
    private const uint FILE_SHARE_WRITE        = 0x0002;
    private const uint FILE_SHARE_DELETE       = 0x0004;
    private const uint OPEN_EXISTING           = 0x0003;
    private const uint FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;
    private static readonly IntPtr INVALID_HANDLE = new IntPtr(-1);

    /// <summary>
    /// Belirtilen surucunun VolumeCreationTime degerini DateTime olarak doner (UTC).
    /// </summary>
    public static DateTime GetVolumeCreationTimeUtc(string driveLetter)
    {
        // Surucu kok yolunu normallestir: "C" → "C:\"
        // Not: "\\.\C:" formati Win32Error 161 (gecersiz yol) uretebiliyor;
        //      kok dizin yolu (C:\) FILE_FLAG_BACKUP_SEMANTICS ile guvenilir calisiyor.
        string letter = driveLetter.TrimEnd('\\', '/').TrimEnd(':').ToUpper();
        string path   = letter + @":\";

        IntPtr hFile = CreateFile(
            path,
            FILE_READ_ATTRIBUTES,
            FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
            IntPtr.Zero,
            OPEN_EXISTING,
            FILE_FLAG_BACKUP_SEMANTICS,
            IntPtr.Zero
        );

        if (hFile == INVALID_HANDLE)
            throw new IOException(
                string.Format("Surucu acilamadi: {0}  Win32 hata kodu: {1}",
                    path, Marshal.GetLastWin32Error()));

        try
        {
            int structSize = Marshal.SizeOf(typeof(FILE_FS_VOLUME_INFORMATION));
            IntPtr buffer  = Marshal.AllocHGlobal(structSize);
            try
            {
                IO_STATUS_BLOCK iosb = new IO_STATUS_BLOCK();
                int status = NtQueryVolumeInformationFile(
                    hFile,
                    ref iosb,
                    buffer,
                    (uint)structSize,
                    1   // FileFsVolumeInformation
                );

                // NTSTATUS 0 = STATUS_SUCCESS
                if (status != 0)
                    throw new InvalidOperationException(
                        string.Format("NtQueryVolumeInformationFile basarisiz. NTSTATUS: 0x{0:X8}", (uint)status));

                var info = (FILE_FS_VOLUME_INFORMATION)
                    Marshal.PtrToStructure(buffer, typeof(FILE_FS_VOLUME_INFORMATION));

                // Windows FILETIME: 1 Ocak 1601 00:00:00 UTC'den 100ns tik sayisi
                return DateTime.FromFileTimeUtc(info.VolumeCreationTime);
            }
            finally { Marshal.FreeHGlobal(buffer); }
        }
        finally { CloseHandle(hFile); }
    }
}
'@

# Add-Type'i yalnizca henuz eklenmemisse calistir (oturum genelinde tekrar kullanim icin)
if (-not ([System.Management.Automation.PSTypeName]'NtfsVolumeInfo').Type) {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
}

# ---------------------------------------------------------------------
function UykuAnaliz {
    # Bu fonksiyon, bilgisayarın sistem olay gunlugu kayitlarinin izin verdigi olcude
    # ne kadar acik kaldigini dakika cinsinden verir.
    # Tam deger degildir, yaklasik degerdir.
    # 2026-08-10, Metin

    $evs1 = Get-WinEvent -FilterHashtable @{
        Logname="System";
        ProviderName=("Microsoft-Windows-Kernel-Power","Microsoft-Windows-Power-Troubleshooter","Microsoft-Windows-Kernel-General","eventlog");
        Id=1,12,13,42,107,6005,6006,6008
    }
    $diffSeconds = 10
    $evs2 = $evs1 | Sort-Object TimeCreated | ForEach-Object {
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

    $evs2 += [PSCustomObject]@{
        Time = Get-Date
        Type = "Shutdown"
    }

    [datetime]$previousTime=Get-Date "1970-01-01"
    [string]$previousType=""
    $totalUptime=0
    $prevUptime=$evs2[0].Time
    $evs2 | Sort-Object -Property Time | ForEach-Object {
        [int]$fark = ($_.Time - $previousTime).TotalSeconds
        if (($fark -gt 0) -and ($_.Time -gt 0) -and ($_.Type -ne $previousType)) {
            if ($_.Type -eq "Shutdown") {
                $totalUptime += ($_.Time - $prevUptime).TotalSeconds
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
    return [int]($totalUptime/60)   # in minutes
}
# ---------------------------------------------------------------------
$dataTable = @()

# Bilgisayar adi
$dataTable += [PSCustomObject]@{
    Etiket = "Bilgisayar Adi"
    Deger = hostname
}

# Gecerli kullanici
$dataTable += [PSCustomObject]@{
    Etiket = "Gecerli Kullanici"
    Deger = $env:USERNAME
}

# Yerellestirme
$dataTable += [PSCustomObject]@{
    Etiket = "Yerellestirme"
    Deger = (Get-Culture).Name
}

# Saat dilimi
$dataTable += [PSCustomObject]@{
    Etiket = "Saat Dilimi"
    Deger = (Get-TimeZone).Id
}

# CPU bilgisi
$a = Get-CimInstance Win32_Processor
$dataTable += [PSCustomObject]@{
    Etiket = "CPU"
    Deger = "$($a.Name) - ($($a.NumberOfLogicalProcessors) Cores x $($a.ThreadCount) Threads)"
}

# Bellek
$a = gcim Win32_PhysicalMemory
$i = 1
$a | ForEach-Object {
    $dataTable += [PSCustomObject]@{
        Etiket = "Bellek-$i"
        Deger = "{0:N0} GB" -f (($_.Capacity)/1GB)
    }
    $i++
}

# Ekran karti
$a = gcim Win32_VideoController
$i = 1
$a | Foreach-Object {
    $dataTable += [PSCustomObject]@{
        Etiket = "Ekran Karti-$i"
        Deger = "$($_.Name) - ($([int]($_.AdapterRAM / 1MB)) MB)"
    }
    $dataTable += [PSCustomObject]@{
        Etiket = "Yapi-$i"
        Deger = "$($_.AdapterDACType)"
    }

    $dataTable += [PSCustomObject]@{
        Etiket = "Cozunurluk-$i"
        Deger = $_.VideoModeDescription
    }
    $i++
}

# Disk bilgisi
$a = Get-PhysicalDisk | Select FriendlyName, MediaType, BusType
$i = 1
$a | ForEach-Object {
    $dataTable += [PSCustomObject]@{
        Etiket = "Disk Bilgisi-$i"
        Deger = "$($_.FriendlyName) - $($_.MediaType) - $($_.BusType)"
    }
    $i++
}

# Boot partition bilgisi
$a = Get-Partition | where IsBoot -eq $true | Select DiskNumber, PartitionNumber, DriveLetter
$b = $a.DriveLetter
$dataTable += [PSCustomObject]@{
    Etiket = "Boot Partition"
    Deger = "${b}:"
}
$a = gcim Win32_LogicalDisk -Filter "DeviceID='${b}:'"
$dataTable += [PSCustomObject]@{
    Etiket = "Boot Bos Alan"
    Deger = "%{0:N0} bos, Toplam {1:N0} GB partition" -f [int](100*($a.Freespace/$a.Size)), [int]($a.Size/1GB)
} 

# Boot partition olusturma tarihi

$utcTime   = [NtfsVolumeInfo]::GetVolumeCreationTimeUtc("${b}:")
$a = $utcTime.ToLocalTime()
$a = $a.ToString('yyyy-MM-dd HH:mm:ss')
$dataTable += [PSCustomObject]@{
    Etiket = "${b}: format tarihi"
    Deger = "$a"
}

# Isletim bilgisi
$a = Get-CimInstance Win32_OperatingSystem
$b = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR
$dataTable += [PSCustomObject]@{
    Etiket = "Isletim Sistemi"
    Deger = "$($a.BuildNumber).$($b)"
}

# System eventlog bilgisi
$a = Get-WinEvent -LogName System -Oldest -MaxEvents 1
$dataTable += [PSCustomObject]@{
    Etiket = "Ilk System Event"
    Deger = Get-Date -Date $a.TimeCreated -format "yyyy-MM-dd HH:mm:ss"
}

# Application eventlog bilgisi
$a = Get-WinEvent -LogName Application -Oldest -MaxEvents 1
$dataTable += [PSCustomObject]@{
    Etiket = "Ilk Application Event"
    Deger = Get-Date -Date $a.TimeCreated -format "yyyy-MM-dd HH:mm:ss"
}

# Sistem kac kere acilmis
$a = Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-Kernel-Boot';Id=20} -Max 1 | select TimeCreated, @{N="ID";E={$_.Properties[2].Value}}
$dataTable += [PSCustomObject]@{
    Etiket = "Sistem kac kere acilmis"
    Deger = "$($a.ID)"
}
$dataTable += [PSCustomObject]@{
    Etiket = "Son acilis tarihi"
    Deger = Get-Date -Date $a.TimeCreated -format "yyyy-MM-dd HH:mm:ss"
}

$dataTable += [PSCustomObject]@{
    Etiket = "Son acilistan bu yana"
    Deger = ((Get-Date) - $a.TimeCreated).TotalDays.ToString("N1") + " gun"
}

# Toplam acik kalma suresi (Kernel-General 12/13 eventleri)
$evs1 = Get-WinEvent -FilterHashtable @{Logname="System";ProviderName="*Kernel-General";Id=12,13} | select-Object -Property TimeCreated, Id | Sort-Object -Property TimeCreated 
$evs1 += [pscustomobject]@{TimeCreated = (Get-Date); Id = 13} # sanal kapanma tam su an

$total = 0
$evs1 | ForEach-Object {
    if ($_.Id -eq 12) {
        $start = $_.TimeCreated
    } elseif ($_.Id -eq 13) {
        $end = $_.TimeCreated
        $diff = $end - $start
        $total += $diff.TotalMinutes
    }
}
$dataTable += [PSCustomObject]@{
    Etiket = "Toplam acik kalma suresi"
    Deger = "{0:N1} gun" -f ($total/60/24)
}

$a = UykuAnaliz
$dataTable += [PSCustomObject]@{
    Etiket = "Acik kalma v2"
    Deger = "{0:N1} saat veya {1:N1} gun" -f [int]([int]$a/60), [int]([int]$a/60/24)
}
$total2 = [int]$a # in minutes

$a = $evs1[0].TimeCreated
$c = Get-Date
$b = ($c - [datetime]$a).TotalDays

# Yukaridaki toplam acik kalma suresinin hangi tarihten baslayarak hesaplandigi
$dataTable += [PSCustomObject]@{
    Etiket = "Hesaplama baslangici"
    Deger = "$($a.ToString('yyyy-MM-dd HH:mm:ss')) - $([math]::Round($b,1)) gun once"
}

# Yukaridaki tarihten baslayarak yuzde kac acikti
$dataTable += [PSCustomObject]@{
    Etiket = "Acik kalma yuzdesi"
    Deger = "%{0:N1} - v2 hesabi %{1:N1}" -f (100*$total/(60*24*$b)), (100*$total2/(60*24*$b))
}

# Boot ID ile kıyaslamak uzere toplam Kernel-General 12 event sayisi
$dataTable += [PSCustomObject]@{
    Etiket = "Izlenebilen acilis sayisi"
    Deger = "{0:N0} kez" -f ($evs1 | ? Id -eq 12 | Measure-Object | Select-Object -ExpandProperty Count)
}

# Beklenmeyen kapanmalar, Kernel-Power 41
$a = Get-WinEvent -FilterHashtable @{Logname="System";ProviderName="*Kernel-Power";Id=41} -ea silent | Measure-Object | Select-Object -ExpandProperty Count
$dataTable += [PSCustomObject]@{
    Etiket = "Beklenmeyen kapanmalar"
    Deger = "$a kez"
}

# batarya durumu
if (gcim Win32_Battery) {
    if (Test-Path "$env:TEMP\battery-report.html") {
        $datetimecode=(Get-Date -Format FileDateTime).ToString()

        Rename-Item "$env:TEMP\battery-report.html" "$env:TEMP\battery-report-$datetimecode.html" -Force
    }
    powercfg /batteryreport /output "$env:TEMP\battery-report.html" | Out-Null
    $html = Get-Content "$env:TEMP\battery-report.html" -Raw

    $design = [regex]::Match(
        $html,
        'DESIGN CAPACITY.*?<td>([\d.]+)\s*mWh',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    ).Groups[1].Value

    $full = [regex]::Match(
        $html,
        'FULL CHARGE CAPACITY.*?<td>([\d.]+)\s*mWh',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    ).Groups[1].Value

    $dataTable += [PSCustomObject]@{
        Etiket = "Batarya ilkgun kapasitesi"
        Deger = "$design mWh"
    }

    $dataTable += [PSCustomObject]@{
        Etiket = "Bugun icin kapasite"
        Deger = "$full mWh"
    }

    $design = [int]($design.replace(",|.",""))
    $full = [int]($full.replace(",|.",""))

    $dataTable += [PSCustomObject]@{
        Etiket = "Batarya sagligi (+%80)"
        Deger = "{0:N1} %" -f (100*$full/$design)
    }
}

# Smart Disk bilgisi
$SMART = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus | Select-Object Active, PredictFailure, Reason, @{Name="Device";E={$_ -match 'Prod_([^\\]+)' | Out-Null;$Matches[1]}}
$SMART | ForEach-Object {
    $dataTable += [PSCustomObject]@{
        Etiket = "SMART - $($_.Device)"
        Deger = "Active=$($_.Active), PredictFailure=$($_.PredictFailure), Reason=$($_.Reason)"
    }
}

# storage reliablility bilgisi - sadece yukseltilmis ayricaliklarla
if ((New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator))
{
    $a = Get-PhysicalDisk | Get-StorageReliabilityCounter | Select DeviceId, Temperature, Wear, ReadErrorsTotal, WriteErrorsTotal, PowerOnHours
    $a | ForEach-Object {
        $dataTable += [PSCustomObject]@{
            Etiket = "Reliability - $($_.DeviceId)"
            Deger = "Temperature=$($_.Temperature)C, Wear=$($_.Wear)%, ReadErrors=$($_.ReadErrorsTotal), WriteErrors=$($_.WriteErrorsTotal), PowerOnHours=$($_.PowerOnHours)"
        }
    }
}
else {
    Write-Host "SSD / NVMe diskler hakkinda bilgi icin yonetici yetkileriyle calistirin."
}

# System-Disk kaynakli hatalar
$a = Get-WinEvent -FilterHashtable @{Logname="System";ProviderName="disk";Level=2} -ea silent | Measure-Object | Select-Object -ExpandProperty Count
$dataTable += [PSCustomObject]@{
    Etiket = "Disk kaynakli hatalar"
    Deger = $a
}

# System-NTFS kaynakli hatalar
$a = Get-WinEvent -FilterHashtable @{Logname="System";ProviderName="ntfs";Level=2} -ea silent | Measure-Object | Select-Object -ExpandProperty Count
$dataTable += [PSCustomObject]@{
    Etiket = "NTFS kaynakli hatalar"
    Deger = $a
}

$dataTable | Out-GridView -Title "Sistem Bilgisi" -OutputMode None

Write-Host "System olay gunlugundeki hatalarin sayilari:"
Get-WinEvent -FilterHashtable @{Logname="System";Level=2} | Group-Object -Property ProviderName -NoElement | Sort-Object Count -Descending | Format-Table -AutoSize