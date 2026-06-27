#Requires -Version 5.1
<#
.SYNOPSIS
    NTFS surucusunun olusturulma (formatlama) zamanini sorgular.

.DESCRIPTION
    NtQueryVolumeInformationFile native API'si kullanilarak FileFsVolumeInformation
    yapisindan VolumeCreationTime alani okunur. Procmon'un QueryInformationVolume
    olayinda Detail sutununda gosterdigi degerin aynisidir.

.PARAMETER DriveLetter
    Sorgulanacak surucu harfi. ornek: C, D, E
    Varsayilan: C

.EXAMPLE
    .\Get-VolumeCreationTime.ps1
    .\Get-VolumeCreationTime.ps1 -DriveLetter D
    .\Get-VolumeCreationTime.ps1 -DriveLetter C,D,E

.NOTES
    Yazar  : Claude
    Gereksinim: Windows, .NET Framework 4.5+
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]]$DriveLetter = @('C')
)

# ── P/Invoke tanimlari ──────────────────────────────────────────────────────
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

# ── Sorgulama ve cikti ─────────────────────────────────────────────────────
$results = foreach ($letter in $DriveLetter) {
    $letter = $letter.Trim().TrimEnd(':').ToUpper()

    try {
        $utcTime   = [NtfsVolumeInfo]::GetVolumeCreationTimeUtc($letter)
        $localTime = $utcTime.ToLocalTime()

        [PSCustomObject]@{
            Surucu           = "${letter}:"
            OlusturulmaTarihi_Yerel = $localTime.ToString('yyyy-MM-dd HH:mm:ss')
            OlusturulmaTarihi_UTC   = $utcTime.ToString('yyyy-MM-dd HH:mm:ss')
            Ham_UTC_FileTime        = $utcTime.ToFileTimeUtc()
            Durum            = 'OK'
        }
    }
    catch {
        [PSCustomObject]@{
            Surucu           = "${letter}:"
            OlusturulmaTarihi_Yerel = '-'
            OlusturulmaTarihi_UTC   = '-'
            Ham_UTC_FileTime        = '-'
            Durum            = "Hata: $_"
        }
    }
}

# Konsol ciktisi
$results | Format-Table -AutoSize

# Istege bagli: CSV'ye aktar
# $results | Export-Csv -Path "$PSScriptRoot\VolumeCreationTimes.csv" -NoTypeInformation -Encoding UTF8
