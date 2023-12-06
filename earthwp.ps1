Function Set-WallPaper($Image) {
    <#
    .SYNOPSIS
    Applies a specified wallpaper to the current user's desktop
       
    .PARAMETER Image
    Provide the exact path to the image
     
    .EXAMPLE
    Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
     
    #>

    $MethodDefinition = @'
    using System; 
    using System.Runtime.InteropServices;
     
    public class Params
    { 
        [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
        public static extern int SystemParametersInfo (Int32 uAction, 
                                                       Int32 uParam, 
                                                       String lpvParam, 
                                                       Int32 fuWinIni);
    }
'@

    Add-Type -TypeDefinition $MethodDefinition
     
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
     
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
     
    $ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
}

$url="https://earthview.withgoogle.com"
$hedef=(((iwr $url).Links | where {$_.title -eq "Explore Earth Views"} | 
	select -expand href) -split "-")[-1];iwr "$url\download\$hedef.jpg" -Outfile "D:\wallpaper\$hedef.jpg"

Set-Wallpaper -Image "D:\wallpaper\$hedef.jpg"