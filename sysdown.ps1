# 2026-03-31
Write-Host "This tool is for downloading indiviual tools from Sysinternals web site."

$url = "https://live.sysinternals.com/files/"

$targetpath = "C:\Tools\"

$list = Invoke-WebRequest -UseBasicParsing -Uri $url

$htmObj = New-Object -ComObject "HTMLFile"
$htmObj.IHTMLDocument2_write($list.Content)
$pattern = '(\w+,\s+\w+\s+\d+,\s+\d+\s+\d+:\d+\s+[AP]M)\s+(\d+)\s+(\S+)' # weekday, month day, year time AM/PM    size    filename

$indxStart = ($html.body.outerText | sls -Pattern $pattern).Matches[0].Index    # skip header lines
$indxEnd = ($html.body.outerText).Length

$raw = $html.body.outerText.Substring($indxStart, $indxEnd-$indxStart)

$results = [regex]::Matches($raw, $pattern) | ForEach-Object {
    [PSCustomObject]@{
        Date     = $_.Groups[1].Value.Trim()
        Size     = [int]$_.Groups[2].Value
        FileName = $_.Groups[3].Value
    }
}

$fulllist = @()

foreach ($itez in ($list.Links)) {
    $fulllist += [PSCustomObject]@{
        Name = $itez.href.replace("/files/", "")
        Link = $itez.href
    }
}

$keeploop = $true

while ($keeploop) {
    $keyword = Read-Host "Enter a few-letter keyword (q for quit)"
    if ($keyword -eq "q" -or $keyword -eq "quit") {exit}

    $filtered = $fulllist | Where-Object { $_.Name -like "*$keyword*" }

    $filtered2 = $results | Where-Object { $_.FileName -like "*$keyword*" -and $_.Filename -match ".zip$"}

    Write-Host "filtered $($filtered.Count) items"
    if ($filtered.Count -eq 0) {
        Write-Host "No matches found. Please try again."
    } else {
        Write-Host "Found:`r`n------"
        for ($i = 0; $i -lt $filtered.Count; $i++) {
            Write-Host "[$i] $($filtered[$i].Name)"
        }
        for ($i = 0; $i -lt $filtered2.Count; $i++) {
            Write-Host "[$i] $($filtered2[$i].Date) - $($filtered2[$i].FileName)"
        }
    }
    [Console]::Out.Flush()
    $choice = Read-Host "Enter the number you want"

    if ($choice -eq "q" -or $choice -eq "Q" -or $choice -eq "quit" -or $choice -eq "QUIT") {
        exit
    }
    elseif ([int][char]$choice -ge 48 -and [int][char]$choice -le 57) {
        $choice = [int]$choice
    }
    else {
        Write-Host "Not an integer."
        exit
    }

    Write-Host "You have chosen: $($filtered[$choice].Name)"
    $answ = Read-Host "Proceed to download (y/N)?"
    $downloadPath = $targetpath + $filtered[$choice].Name

    if ($answ -eq "y" -or $answ -eq "Y") {
        $downloadUrl = $url + $filtered[$choice].Name
        Write-Host "Downloading from: $downloadUrl"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath
        Write-Host "Download completed: $downloadPath"
    } else {
        Write-Host "Download cancelled."
    }
}   