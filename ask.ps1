$devam=$true
while ($devam) {
    "Bugun ne istersin?"
    " [1] Sysinternals Suite indir"
    " [2] Process Explorer indir"
    " [3] Process Monitor indir"
    " [4] Autoruns indir"
    " [5] Sysmon indir"
    " [6] Caskaydia Mono indir"
    " [7] Lib1 indir ve kur"
    " [8] Sade bir prompt hazirla"
    " [9] Daha karmasik bir prompt hazirla"
    " [q] Cikis"

    $secim = Read-Host "Secimin hangisi?"
    $datecode=Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
    $downfolder = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path

    switch ($secim) {
        "1" {
                $target="https://live.sysinternals.com/files/SysinternalsSuite.zip"
                $filename="Sysinternals_${datecode}.zip"
                $fulldest = Join-Path $downfolder $filename
                Invoke-WebRequest -Uri $target -OutFile $fulldest
                Unblock-File $fulldest
                if (-Not (Test-Path "C:\Tools")) { New-Item -ItemType Directory -Path "C:\Tools"}
                Expand-Archive -Path $fulldest -DestinationPath "C:\Tools" -Force
                Break
            }
        "2" {
                $target="https://live.sysinternals.com/files/ProcessExplorer.zip"
                $filename="ProcessExplorer_${datecode}.zip"
                $fulldest = Join-Path $downfolder $filename
                Invoke-WebRequest -Uri $target -OutFile $fulldest
                Unblock-File $fulldest
                if (-Not (Test-Path "C:\Tools")) { New-Item -ItemType Directory -Path "C:\Tools"}
                Expand-Archive -Path $fulldest -DestinationPath "C:\Tools" -Force
                Break
            }
        "3" {
                $target="https://live.sysinternals.com/files/ProcessMonitor.zip"
                $filename="ProcessMonitor_${datecode}.zip"
                $fulldest = Join-Path $downfolder $filename
                Invoke-WebRequest -Uri $target -OutFile $fulldest
                Unblock-File $fulldest
                if (-Not (Test-Path "C:\Tools")) { New-Item -ItemType Directory -Path "C:\Tools"}
                Expand-Archive -Path $fulldest -DestinationPath "C:\Tools" -Force
                Break
            }
        "4" {
                $target="https://live.sysinternals.com/files/Autoruns.zip"
                $filename="Autoruns_${datecode}.zip"
                $fulldest = Join-Path $downfolder $filename
                Invoke-WebRequest -Uri $target -OutFile $fulldest
                Unblock-File $fulldest
                if (-Not (Test-Path "C:\Tools")) { New-Item -ItemType Directory -Path "C:\Tools"}
                Expand-Archive -Path $fulldest -DestinationPath "C:\Tools" -Force
                Break
            }
        "5" {
                $target="https://live.sysinternals.com/files/Sysmon.zip"
                $filename="Sysmon_${datecode}.zip"
                $fulldest = Join-Path $downfolder $filename
                Invoke-WebRequest -Uri $target -OutFile $fulldest
                Unblock-File $fulldest
                if (-Not (Test-Path "C:\Tools")) { New-Item -ItemType Directory -Path "C:\Tools"}
                Expand-Archive -Path $fulldest -DestinationPath "C:\Tools" -Force
                Break
            }
        "6" {
                $target="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip"
                $filename="CascadiaMono_${datecode}.zip"
                $fulldest = Join-Path $downfolder $filename
                Invoke-WebRequest -Uri $target -OutFile $fulldest
                Unblock-File $fulldest
                if (-Not (Test-Path "$downfolder\Caskaydia")) { New-Item -ItemType Directory -Path "$downfolder\Caskaydia"}
                Expand-Archive -Path $fulldest -DestinationPath "$downfolder\Caskaydia" -Force
                Remove-Item "$downfolder\Caskaydia\LICENSE", "$downfolder\Caskaydia\README.md" -ea silent
                Break
            }
        "7" {
                $cevap = Read-Host "Lib1.ps1 dosyasi Modul klasorune indirilecek. Devam edelim mi (buyuk harflerle EVET yazmalisin)?"
                if ($cevap -ceq "EVET") {
                    $target="https://raw.githubusercontent.com/whitershadeofpale/powershell/master/Lib1.ps1"

                    $modfolder=Join-Path ([environment]::getfolderpath(5)) "WindowsPowershell\Modules" # join mydocuments and WindowsPowerShell
                    $filename="Lib1.ps1"
                    $fulldest = Join-Path "$modfolder\Lib1" $filename
                    if (-Not (Test-Path "$modfolder\Lib1")) { New-Item -ItemType Directory -Path "$modfolder\Lib1"}
                    Invoke-WebRequest -Uri $target -OutFile $fulldest
                    Unblock-File $fulldest
                    Move-Item -Path $fulldest -Destination (Join-Path -Path (Split-Path $fulldest -Parent) -ChildPath "Lib1.psm1")
                }
                Break
            }
        "8" {
                $cevap = Read-Host "profil doyasinin uzerine yazilacak. Devam edelim mi (buyuk harflerle EVET yazmalisin)?"
                if ($cevap -ceq "EVET") {
                    $profurl="https://raw.githubusercontent.com/whitershadeofpale/powershell/master/profile3.ps1"

                    try{
                        if (-Not (Test-Path (Split-Path $profile -Parent))) {
                            mkdir (Split-Path $profile -Parent)
                            "created profile folder"
                        }
                        if (Test-Path $profile) {
                            $datecode=Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
                            $rename_path = Join-Path -Path (Split-Path $profile -Parent) -ChildPath "profile_${datecode}.ps1"
                            Move-Item -Path $profile -Destination $rename_path
                            "moved profile to profile_${datecode}.ps1"
                        }
                        Invoke-WebRequest -Uri $profurl -ea SilentlyContinue -OutFile $profile
                        "profile-3 file downloaded as ${profile}"
                    }
                    catch {
                        Write-Error "Something went wrong: $($_.Exception.Response.StatusCode)"
                    }
                }
                Break
            }
        "9" {
                $cevap = Read-Host "profil doyasinin ve Windows Terminal json dosyasinin uzerine yazilacak. Devam edelim mi (buyuk harflerle EVET yazmalisin)?"
                if ($cevap -ceq "EVET") {
                    $profurl="https://raw.githubusercontent.com/whitershadeofpale/powershell/master/profile1.ps1"
                    $termconfig="https://raw.githubusercontent.com/whitershadeofpale/powershell/master/settings1.json"
                    $termpath = "C:\Users\$($env:USERNAME)\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
                    $NerdFonts="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip"
                    
                    try{
                        if (-Not (Test-Path (Split-Path $profile -Parent))) {
                            mkdir (Split-Path $profile -Parent)
                            "created profile folder"
                        }
                        if (Test-Path $profile) {
                            $datecode=Get-Date -Format "yyyy-MM-ddTHH-mm-ss"
                            $rename_path = Join-Path -Path (Split-Path $profile -Parent) -ChildPath "profile_${datecode}.ps1"
                            Move-Item -Path $profile -Destination $rename_path
                            "moved profile to profile_${datecode}.ps1"
                        }
                        Invoke-WebRequest -Uri $profurl -ea SilentlyContinue -OutFile $profile
                        "profile-1 file downloaded as ${profile}"
                    
                        Invoke-WebRequest -Uri $termconfig -ea SilentlyContinue -OutFile "terminal_config_${datecode}.json"
                        "Windows Terminal configuration file downloaded to current folder. Move it to ${termpath}"
                    
                        $cevap=Read-Host "Download Caskaydia fonts (E/h)?"
                        if ($cevap -eq "E" -or $cevap -eq "e") {
                            Invoke-WebRequest -Uri $NerdFonts -OutFile "CascadiaMono.zip"
                            Unblock-File CascadiaMono.zip
                            Expand-Archive -Path ".\CascadiaMono.zip" -DestinationPath "Caskaydia" -Force
                            Remove-Item ".\Caskaydia\LICENSE", ".\Caskaydia\README.md" -ea silent
                            "Expanded to Caskaydia folder. Install them manually by right clicking."
                            Start-Sleep -Seconds 5
                            Start-Process ".\Caskaydia"
                        }
                    }
                    catch {
                        Write-Error "Something went wrong: $($_.Exception.Response.StatusCode)"
                    }
                }
                Break
            }
        "q" { $devam=$false;break }
    }
}