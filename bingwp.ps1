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

$bing = "www.bing.com"
$xmlURL = "http://www.bing.com/HPImageArchive.aspx?format=xml&idx=0&n=1&mkt=en-US"
$saveDir = "D:\Wallpapers"
$fullstop = $false

New-Item -ItemType Directory -Path $saveDir -ErrorAction SilentlyContinue | Out-Null

#$picOpts="zoom"
$picExt = ".jpg"
$desiredPicRes = "_1920x1080"

[xml]$response = (New-Object System.Net.WebClient).DownloadString($xmlURL)

$defaultPicURL = $response.images.image.url
$desiredPicURL = $response.images.image.urlbase + $desiredPicRes + $picExt

# rip off all unnecessary characters
$checkfile = $defaultPicURL.split("&")[0]
$checkfile = $checkfile.split(".")[1] + "." + $checkfile.split(".")[2]

Write-Host "today's wallpaper: $checkfile"

# rip off extension as well to check existency with a wildcard
$checkfile = $checkfile.substring(0,$checkfile.length-4)

$bugun = "{0:G}" -f (Get-Date)
$logfile = Join-Path -Path $saveDir -ChildPath "binglog.txt"

if ((dir (Join-Path -Path $saveDir -ChildPath ($checkfile + "*"))).Count -eq 0) {

    try { 
        $resp = iwr -Uri ($bing + $desiredPicURL) -EA Stop -Method Head

        # desired URL OK
        Write-Host "desired res OK."
        $picName = $desiredPicURL.split(".")[1] + "." + $desiredPicURL.split(".")[2]
        $fullPath = Join-Path -Path $saveDir -ChildPath $picName
    }
    catch {
        # desired not available
        try {
            $resp = iwr -Uri ($bing + $defaultPicURL) -EA Stop -Method Head
            Write-Host "desired not found, falling back to default."
            $picName = $defaultPicURL.split("&")[0]
            $picName = $picName.split(".")[1] + "." + $picName.split(".")[2]
            $fullPath = Join-Path -Path $saveDir -ChildPath $picName
        }
        catch {
            # neither default available
            Write-Host "None available right now."
            $fullstop = $true
            Break
        }

    }
    finally {
        if ($fullstop) {
            # here means nothing found
            Add-Content -Path $logfile -Value "$bugun - nothing found."
        }
        else {
            # hear means something is found, either desired or default
            try {
                $resp = iwr -Uri ($bing + $defaultPicURL) -OutFile $fullPath
                Add-Content -Path $logfile -Value "$bugun - downloaded : $fullpath"
                Set-WallPaper $fullpath
            }
            catch {
                $hata = $PSItem.Exception.ToString()
                Write-Host "last stage error: $hata"
                Add-Content -Path $logfile -Value "$bugun - last stage error."
            }
        }
    }
}
else {
    Write-Host "File is already downloaded:" (dir (Join-Path -Path $saveDir -ChildPath ($checkfile + "*")))[0]
    Add-Content -Path $logfile -Value "$bugun - file is already downloaded."
}
Start-Sleep -Seconds 4

# $spotlight = "C:\Users\metin\AppData\Local\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"

# $files = Get-ChildItem -Path $spotlight | where { $_.Length -gt 300000 }

# $files | ForEach-Object { Copy-Item $PSItem -Destination (Join-Path -Path $saveDir -ChildPath ($PSItem.Name+".jpg")) }