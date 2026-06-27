Add-Type @'
using System;
using System.IO;
using System.Runtime.InteropServices;

public static class VolumeTest
{
    [StructLayout(LayoutKind.Sequential)]
    public struct IO_STATUS_BLOCK { public IntPtr Status; public IntPtr Information; }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct FILE_FS_VOLUME_INFORMATION
    {
        public long  VolumeCreationTime;
        public uint  VolumeSerialNumber;
        public uint  VolumeLabelLength;
        public byte  SupportsObjects;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string VolumeLabel;
    }

    [DllImport("ntdll.dll")]
    public static extern int NtQueryVolumeInformationFile(
        IntPtr hFile, ref IO_STATUS_BLOCK iosb,
        IntPtr buf, uint len, uint infoClass);

    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern IntPtr CreateFile(
        string path, uint access, uint share,
        IntPtr sa, uint cd, uint flags, IntPtr tmpl);

    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr h);

    public static void Test(string path, uint access, uint flags, string label)
    {
        Console.WriteLine("\n--- " + label + " ---");
        Console.WriteLine("Path: " + path + " | Access: 0x" + access.ToString("X") + " | Flags: 0x" + flags.ToString("X"));

        IntPtr h = CreateFile(path, access, 0x7, IntPtr.Zero, 3, flags, IntPtr.Zero);
        if (h == new IntPtr(-1)) {
            Console.WriteLine("CreateFile FAILED. Win32Error: " + Marshal.GetLastWin32Error());
            return;
        }
        Console.WriteLine("CreateFile OK. Handle: " + h);

        IntPtr buf = Marshal.AllocHGlobal(1024);
        try {
            var iosb = new IO_STATUS_BLOCK();
            int st = NtQueryVolumeInformationFile(h, ref iosb, buf, 1024, 1);
            Console.WriteLine("NTSTATUS: 0x" + ((uint)st).ToString("X8"));
            if (st == 0) {
                var info = (FILE_FS_VOLUME_INFORMATION)Marshal.PtrToStructure(buf, typeof(FILE_FS_VOLUME_INFORMATION));
                Console.WriteLine("VolumeCreationTime (raw): " + info.VolumeCreationTime);
                Console.WriteLine("VolumeCreationTime (UTC): " + DateTime.FromFileTimeUtc(info.VolumeCreationTime));
                Console.WriteLine("VolumeLabel: " + info.VolumeLabel);
            }
        } finally { Marshal.FreeHGlobal(buf); CloseHandle(h); }
    }
}
'@ -Language CSharp

$combos = @(
    @{ path="\\\\.\\C:";  access=0x0080; flags=0x02000000; label="Device path, READ_ATTRIBUTES, BACKUP_SEMANTICS" },
    @{ path="\\\\.\\C:";  access=0x0080; flags=0x02000000 -bor 0x00200000; label="Device path, READ_ATTRIBUTES, BACKUP+NO_BUFFERING" },
    @{ path="\\\\.\\C:";  access=0x80000000; flags=0x02000000; label="Device path, GENERIC_READ, BACKUP_SEMANTICS" },
    @{ path="C:\\";       access=0x0080; flags=0x02000000; label="Root path C:\\, READ_ATTRIBUTES" },
    @{ path="C:\\";       access=0x80000000; flags=0x02000000; label="Root path C:\\, GENERIC_READ" }
)

# foreach ($c in $combos) {
#     [VolumeTest]::Test($c.path, $c.access, $c.flags, $c.label)
# }

[VolumeTest]::Test("C:\\",0x0080,0x02000000,"Root path C:\\, READ_ATTRIBUTES")