#Requires -Version 5.1
<#
.SYNOPSIS
    Şüpheli PDF dosyalarının STATİK analizi için yardımcı fonksiyonlar.

.DESCRIPTION
    strings, exiftool, sha256sum, pdfid, pdf-parser ve pdfdetach/mutool'un
    temel işlevlerinin PowerShell karşılıklarını içerir. Hiçbir fonksiyon PDF'i
    bir okuyucuda açmaz, içindeki betikleri veya gömülü dosyaları çalıştırmaz.
    Yine de şüpheli örnekleri izole bir ortamda (VM / Windows Sandbox) işleyin.

    Dışa açılan fonksiyonlar:
      Get-Strings, Get-PdfId, Get-PdfObject, Search-PdfObject,
      Export-PdfEmbedded, Get-PdfMetadata
#>

# 1 bayt = 1 karakter: metindeki ofsetler dosyadaki bayt ofsetleriyle birebir eşleşir.
$script:Latin1 = [Text.Encoding]::GetEncoding('ISO-8859-1')

#region Özel (dışa açılmayan) yardımcılar

function Get-PdfText {
    param([Parameter(Mandatory)][string]$Path)
    $script:Latin1.GetString([IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).ProviderPath))
}

# --- PDF string ( (...) veya <hex> ) -> .NET string -----------------------------------
function ConvertFrom-PdfString {
    param([string]$Token)
    if ($Token.StartsWith('<')) {
        $hex = $Token -replace '[<>\s]', ''
        if ($hex.Length % 2) { $hex += '0' }
        $b = [byte[]]::new([int]($hex.Length / 2))
        for ($i = 0; $i -lt $b.Length; $i++) { $b[$i] = [Convert]::ToByte($hex.Substring(2 * $i, 2), 16) }
    } else {
        $inner = $Token.Substring(1, $Token.Length - 2)
        $list  = [Collections.Generic.List[byte]]::new()
        for ($i = 0; $i -lt $inner.Length; $i++) {
            $c = $inner[$i]
            if ($c -ne '\') { $list.Add([byte]$c); continue }
            $i++; if ($i -ge $inner.Length) { break }
            $n = $inner[$i]
            if     ($n -ceq 'n') { $list.Add(10) }
            elseif ($n -ceq 'r') { $list.Add(13) }
            elseif ($n -ceq 't') { $list.Add(9) }
            elseif ($n -ceq 'b') { $list.Add(8) }
            elseif ($n -ceq 'f') { $list.Add(12) }
            elseif ($n -match '[0-7]') {
                $oct = [string]$n
                while ($oct.Length -lt 3 -and ($i + 1) -lt $inner.Length -and $inner[$i + 1] -match '[0-7]') { $i++; $oct += $inner[$i] }
                $list.Add([byte]([Convert]::ToInt32($oct, 8) -band 255))
            }
            elseif ($n -eq "`r" -or $n -eq "`n") {
                if ($n -eq "`r" -and ($i + 1) -lt $inner.Length -and $inner[$i + 1] -eq "`n") { $i++ }
            }
            else { $list.Add([byte]$n) }
        }
        $b = $list.ToArray()
    }
    if     ($b.Length -ge 2 -and $b[0] -eq 0xFE -and $b[1] -eq 0xFF) { [Text.Encoding]::BigEndianUnicode.GetString($b, 2, $b.Length - 2) }
    elseif ($b.Length -ge 2 -and $b[0] -eq 0xFF -and $b[1] -eq 0xFE) { [Text.Encoding]::Unicode.GetString($b, 2, $b.Length - 2) }
    elseif ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { [Text.Encoding]::UTF8.GetString($b, 3, $b.Length - 3) }
    else   { $script:Latin1.GetString($b) }
}

# --- D:20150827173103-04'00' -> 2015:08:27 17:31:03-04:00 (exiftool biçimi) ----------------
function Format-PdfDate {
    param([string]$D)
    if ($D -notmatch "^D:(\d{4})(\d{2})?(\d{2})?(\d{2})?(\d{2})?(\d{2})?([Zz+\-])?(\d{2})?'?(\d{2})?") { return $D }
    $y  = $Matches[1]
    $mo = if ($Matches[2]) { $Matches[2] } else { '01' }
    $d  = if ($Matches[3]) { $Matches[3] } else { '01' }
    $h  = if ($Matches[4]) { $Matches[4] } else { '00' }
    $mi = if ($Matches[5]) { $Matches[5] } else { '00' }
    $s  = if ($Matches[6]) { $Matches[6] } else { '00' }
    $sign = $Matches[7]; $tz = ''
    if ($sign -eq '+' -or $sign -eq '-') {
        $th = if ($Matches[8]) { $Matches[8] } else { '00' }
        $tm = if ($Matches[9]) { $Matches[9] } else { '00' }
        $tz = "$sign${th}:$tm"
    } elseif ($sign -match '[Zz]') { $tz = 'Z' }
    "${y}:${mo}:${d} ${h}:${mi}:${s}${tz}"
}

# --- Info sözlüğünden anahtar değeri oku (son geçen kazanır: incremental update) -------------
function Get-PdfInfoValue {
    param([string]$Dict, [string]$Key)
    $rx = "/$Key\s*(\((?:[^()\\]|\\[\s\S]|\((?:[^()\\]|\\[\s\S])*\))*\)|<[0-9A-Fa-f\s]*>)"
    $m  = [regex]::Matches($Dict, $rx)
    if ($m.Count) { ConvertFrom-PdfString $m[$m.Count - 1].Groups[1].Value }
}

# --- XMP: hem <tag>..</tag> hem tag="..." biçimini dener --------------------------------------
function Get-XmpValue {
    param([string]$Xmp, [string]$Tag)
    $m = [regex]::Match($Xmp, "(?s)<$Tag(?:\s[^>]*)?>(.*?)</$Tag>")
    if ($m.Success) { return (($m.Groups[1].Value -replace '<[^>]+>', ' ') -replace '\s+', ' ').Trim() }
    $m = [regex]::Match($Xmp, "$Tag=`"([^`"]*)`"")
    if ($m.Success) { return $m.Groups[1].Value }
}

# --- ObjStm / Metadata akışlarını aç (Info veya XMP burada olabilir) ---------------------------
function Get-PdfStreamText {
    param([byte[]]$Bytes, [string]$Text)
    foreach ($m in [regex]::Matches($Text, '(?s)stream\r?\n(.*?)\r?\nendstream')) {
        $pre = $Text.Substring([Math]::Max(0, $m.Index - 400), [Math]::Min(400, $m.Index))
        $k = $pre.LastIndexOf('obj'); if ($k -ge 0) { $pre = $pre.Substring($k + 3) }
        if ($pre -notmatch '/Type\s*/(ObjStm|Metadata)|/Subtype\s*/XML') { continue }
        $g = $m.Groups[1]
        try {
            if ($pre -match '/FlateDecode') {
                $ms  = [IO.MemoryStream]::new($Bytes, $g.Index + 2, $g.Length - 2)   # zlib başlığı: 2 bayt
                $ds  = [IO.Compression.DeflateStream]::new($ms, [IO.Compression.CompressionMode]::Decompress)
                $out = [IO.MemoryStream]::new(); $ds.CopyTo($out)
                $txt = $script:Latin1.GetString($out.ToArray())
            } else { $txt = $g.Value }
            [pscustomobject]@{ Kind = $(if ($pre -match '/ObjStm') { 'ObjStm' } else { 'Meta' }); Text = $txt }
        } catch { }
    }
}

# --- Magic byte ile dosya türü -----------------------------------------------------------------
function Get-MagicType {
    param([byte[]]$B)
    $h = (($B | Select-Object -First 8) | ForEach-Object { '{0:X2}' -f $_ }) -join ''
    switch -regex ($h) {
        '^25504446'   { return 'PDF',  'application/pdf' }
        '^504B0304'   { return 'ZIP/OOXML', 'application/zip' }
        '^D0CF11E0'   { return 'OLE2 (doc/xls/ppt/msi)', 'application/x-ole-storage' }
        '^4D5A'       { return 'EXE/DLL (PE)', 'application/x-dosexec' }
        '^89504E47'   { return 'PNG',  'image/png' }
        '^FFD8FF'     { return 'JPEG', 'image/jpeg' }
        '^7B5C7274'   { return 'RTF',  'text/rtf' }
        '^1F8B'       { return 'GZIP', 'application/gzip' }
        '^377ABCAF'   { return '7z',   'application/x-7z-compressed' }
        '^52617221'   { return 'RAR',  'application/vnd.rar' }
        default       { return 'Bilinmiyor', '' }
    }
}

#endregion

#region Dışa açılan fonksiyonlar

function Get-Strings {
    <#
    .SYNOPSIS
        Linux'taki "strings -a" karşılığı: dosyadaki okunabilir ASCII dizilerini listeler.
    .EXAMPLE
        Get-Strings .\supheli.pdf | Select-String 'http|javascript|/JS|eval|exportDataObject|OpenAction'
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [int]$MinLength = 4)
    [regex]::Matches((Get-PdfText $Path), "[\x20-\x7E]{$MinLength,}") | ForEach-Object Value
}

function Get-PdfId {
    <#
    .SYNOPSIS
        pdfid.py karşılığı: şüpheli PDF anahtar kelimelerini sayar (/JS, /OpenAction, /EmbeddedFile ...).
    .DESCRIPTION
        /J#61vaScript gibi #xx ile gizlenmiş isimleri çözdükten sonra sayar.
        Sıkıştırılmış akışların (ObjStm vb.) içine bakmaz.
    .EXAMPLE
        Get-PdfId .\supheli.pdf
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)
    $t = Get-PdfText $Path
    # /J#61vaScript gibi #xx ile gizlenmiş isimleri çöz
    $t = [regex]::Replace($t, '#([0-9A-Fa-f]{2})',
         { param($m) [char][Convert]::ToInt32($m.Groups[1].Value,16) })

    "PDF Header: " + [regex]::Match($t,'%PDF-\d\.\d').Value
    $words = 'obj','endobj','stream','endstream','xref','trailer','startxref',
             '/Page','/Encrypt','/ObjStm','/JS','/JavaScript','/AA','/OpenAction',
             '/AcroForm','/JBIG2Decode','/RichMedia','/Launch','/EmbeddedFile','/XFA'
    foreach ($w in $words) {
        $p = if ($w.StartsWith('/')) { [regex]::Escape($w) + '(?![A-Za-z])' }
             else { "(?<![A-Za-z])$w(?![A-Za-z])" }
        '{0,-15}{1}' -f $w, [regex]::Matches($t,$p).Count
    }
}

function Get-PdfObject {
    <#
    .SYNOPSIS
        pdf-parser --object N karşılığı: numarası verilen nesneyi gösterir.
    .EXAMPLE
        Get-PdfObject .\supheli.pdf 9
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][int]$Id)
    $t = Get-PdfText $Path
    foreach ($m in [regex]::Matches($t, "(?s)(?<![0-9])$Id\s+\d+\s+obj(.*?)endobj")) {
        $v = $m.Value
        if ($v.Length -gt 1500) { $v = $v.Substring(0,1500) + "`n... [kesildi]" }
        $v
    }
}

function Search-PdfObject {
    <#
    .SYNOPSIS
        pdf-parser --search karşılığı: anahtar kelimeyi içeren nesneleri listeler.
    .EXAMPLE
        Search-PdfObject .\supheli.pdf 'OpenAction'
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Keyword)
    $t = Get-PdfText $Path
    foreach ($m in [regex]::Matches($t, '(?s)(?<![0-9])(\d+)\s+(\d+)\s+obj(.*?)endobj')) {
        if ($m.Groups[3].Value -match [regex]::Escape($Keyword)) {
            "obj {0} {1}" -f $m.Groups[1].Value, $m.Groups[2].Value
            $b = $m.Groups[3].Value
            if ($b.Length -gt 600) { $b = $b.Substring(0,600) + ' ...' }
            $b
        }
    }
}

function Export-PdfEmbedded {
    <#
    .SYNOPSIS
        pdfdetach / mutool extract karşılığı: gömülü dosyaları diske yazar (ÇALIŞTIRMAZ).
    .DESCRIPTION
        Çıkarılan dosyalar bilerek .bin uzantısıyla kaydedilir. Magic sütunu dosya türünü ele verir:
        D0 CF 11 E0 = eski Office (OLE2), 50 4B 03 04 = ZIP/OOXML, 4D 5A = Windows çalıştırılabilir dosyası.
        Çıkardığınız dosyaları Office veya başka bir uygulamayla açmayın.
    .EXAMPLE
        Export-PdfEmbedded .\supheli.pdf | Format-Table -AutoSize
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [string]$OutDir = '.\pdf_extracted')

    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).ProviderPath)
    $t     = $script:Latin1.GetString($bytes)
    New-Item -ItemType Directory -Force $OutDir | Out-Null

    foreach ($o in [regex]::Matches($t, '(?s)(?<![0-9])(\d+)\s+\d+\s+obj(.*?)endobj')) {
        $body = $o.Groups[2].Value
        if ($body -notmatch '/Type\s*/EmbeddedFile') { continue }
        $s = [regex]::Match($body, '(?s)stream\r?\n')
        if (-not $s.Success) { continue }

        $start = $o.Groups[2].Index + $s.Index + $s.Length
        $end   = $t.LastIndexOf('endstream', $o.Groups[2].Index + $o.Groups[2].Length)
        $len   = $end - $start

        $out = [IO.MemoryStream]::new()
        try {
            if ($body -match '/FlateDecode') {
                $ms = [IO.MemoryStream]::new($bytes, $start + 2, $len - 2)   # 2 bayt zlib başlığı
                $ds = [IO.Compression.DeflateStream]::new($ms, [IO.Compression.CompressionMode]::Decompress)
                $ds.CopyTo($out)
            } else {
                while ($len -gt 0 -and $bytes[$start+$len-1] -in 10,13) { $len-- }
                $out.Write($bytes, $start, $len)
            }
        } catch {
            Write-Warning ("obj {0}: akış çözülemedi ({1})" -f $o.Groups[1].Value, $_.Exception.Message)
            continue
        }

        $data = $out.ToArray()
        $file = Join-Path $OutDir ("obj{0}.bin" -f $o.Groups[1].Value)   # uzantı bilerek .bin
        [IO.File]::WriteAllBytes($file, $data)

        [pscustomobject]@{
            Obj    = $o.Groups[1].Value
            Dosya  = $file
            Boyut  = $data.Length
            Magic  = (($data | Select-Object -First 4) | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
            SHA256 = (Get-FileHash $file -Algorithm SHA256).Hash
        }
    }
}

function Get-PdfMetadata {
    <#
    .SYNOPSIS
        exiftool benzeri çıktı: dosya bilgileri, PDF sürümü, Linearized, sayfa sayısı, revizyonlar,
        Info sözlüğü ve XMP alanları.
    .DESCRIPTION
        Tam bir PDF ayrıştırıcısı değildir. Şifreli PDF'lerde metin alanları okunamaz;
        Info nesnesi ObjStm içindeyse sonuç sezgisel olabilir (Info Source satırına bakın).
        PDF olmayan dosyalarda yalnızca dosya bilgilerini ve magic byte türünü verir.
    .EXAMPLE
        Get-PdfMetadata .\supheli.pdf | Format-List
    .EXAMPLE
        Get-ChildItem .\ornekler -Filter *.pdf -Recurse | Get-PdfMetadata | ConvertTo-Json -Depth 3
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)][Alias('FullName')][string[]]$Path)

    process {
        foreach ($p in $Path) {
            $fi    = Get-Item -LiteralPath $p
            $bytes = [IO.File]::ReadAllBytes($fi.FullName)
            $text  = $script:Latin1.GetString($bytes)
            $head  = $text.Substring(0, [Math]::Min(1024, $text.Length))

            $type, $mime = Get-MagicType $bytes
            $version = $null
            if ($head -match '%PDF-(\d\.\d)') { $version = $Matches[1] }

            $o = [ordered]@{}
            $o['File Name']                   = $fi.Name
            $o['Directory']                   = $fi.DirectoryName
            $o['File Size']                   = if ($bytes.Length -lt 1000) { "$($bytes.Length) bytes" } else { '{0:N0} kB' -f ($bytes.Length / 1000) }
            $o['File Modification Date/Time'] = $fi.LastWriteTime.ToString('yyyy:MM:dd HH:mm:ssK')
            $o['File Access Date/Time']       = $fi.LastAccessTime.ToString('yyyy:MM:dd HH:mm:ssK')
            $o['File Creation Date/Time']     = $fi.CreationTime.ToString('yyyy:MM:dd HH:mm:ssK')
            $o['File Attributes']             = [string]$fi.Attributes
            $o['File Type']                   = $type
            $o['MIME Type']                   = $mime

            if ($type -ne 'PDF') { $o['Warning'] = 'Dosya PDF imzası taşımıyor (veya imza ilk 1 KB içinde değil)'; [pscustomobject]$o; continue }

            # Akışları sadeleştir (hız) + ObjStm/Metadata akışlarını aç
            $flat   = [regex]::Replace($text, '(?s)stream\r?\n.*?\r?\nendstream', 'stream endstream')
            $extra  = @(Get-PdfStreamText $bytes $text)
            $objstm = (($extra | Where-Object Kind -eq 'ObjStm' | ForEach-Object Text) -join "`n")
            $corpus = $flat + "`n" + $objstm

            # Info sözlüğü: trailer'daki son /Info N 0 R
            $infoDict = $null; $infoSrc = 'Info nesnesi'
            $im = [regex]::Matches($flat, '/Info\s+(\d+)\s+\d+\s+R')
            if ($im.Count) {
                $id = $im[$im.Count - 1].Groups[1].Value
                $om = [regex]::Matches($flat, "(?s)(?<![0-9])$id\s+\d+\s+obj(.*?)endobj")
                if ($om.Count) { $infoDict = $om[$om.Count - 1].Groups[1].Value }
            }
            if (-not $infoDict) { $infoDict = $corpus; $infoSrc = 'sezgisel (Info nesnesi ObjStm içinde olabilir)' }

            # Sayfa sayısı: kök /Pages düğümünün /Count değeri
            $pages = $null
            foreach ($d in [regex]::Matches($corpus, '<<(?:(?!<<|>>)[\s\S])*?/Type\s*/Pages(?![A-Za-z])(?:(?!<<|>>)[\s\S])*?>>')) {
                if ($d.Value -notmatch '/Parent' -and $d.Value -match '/Count\s+(\d+)') { $pages = [int]$Matches[1] }
            }
            if ($null -eq $pages) { $pages = [regex]::Matches($corpus, '/Type\s*/Page(?![A-Za-z])').Count }

            $o['PDF Version'] = $version
            $o['Linearized']  = if ($head -match '/Linearized') { 'Yes' } else { 'No' }
            $o['Page Count']  = $pages
            $o['Revisions (%%EOF)'] = [regex]::Matches($text, '%%EOF').Count
            $o['Encrypted']   = if ($flat -match '/Encrypt(?![A-Za-z])') { 'Yes (metin alanları okunamayabilir)' } else { 'No' }
            $o['Info Source'] = $infoSrc

            foreach ($k in 'Title', 'Author', 'Subject', 'Keywords', 'Creator', 'Producer') {
                $v = Get-PdfInfoValue $infoDict $k
                if ($v) { $o[$k] = $v }
            }
            foreach ($k in 'CreationDate', 'ModDate') {
                $v = Get-PdfInfoValue $infoDict $k
                if ($v) { $o[$k -replace 'Date', ' Date'] = Format-PdfDate $v }
            }

            # XMP
            $xmp = $null
            foreach ($s in (@($text) + @($extra | Where-Object Kind -eq 'Meta' | ForEach-Object Text))) {
                $m = [regex]::Match($s, '(?s)<x:xmpmeta.*?</x:xmpmeta>')
                if ($m.Success) { $xmp = [Text.Encoding]::UTF8.GetString($script:Latin1.GetBytes($m.Value)); break }
            }
            if ($xmp) {
                $map = [ordered]@{
                    'XMP Title' = 'dc:title'; 'XMP Creator' = 'dc:creator'; 'XMP Description' = 'dc:description'
                    'XMP Creator Tool' = 'xmp:CreatorTool'; 'XMP Create Date' = 'xmp:CreateDate'
                    'XMP Modify Date' = 'xmp:ModifyDate'; 'XMP Producer' = 'pdf:Producer'
                    'XMP Document ID' = 'xmpMM:DocumentID'; 'XMP Instance ID' = 'xmpMM:InstanceID'
                }
                foreach ($label in $map.Keys) {
                    $v = Get-XmpValue $xmp $map[$label]
                    if ($v) { $o[$label] = $v }
                }
            }

            [pscustomobject]$o
        }
    }
}

#endregion

Export-ModuleMember -Function Get-Strings, Get-PdfId, Get-PdfObject, Search-PdfObject, Export-PdfEmbedded, Get-PdfMetadata
