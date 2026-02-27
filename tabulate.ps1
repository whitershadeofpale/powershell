# Bu script, 17.02.2026'da AI kullanarak hazirlandi
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true)]
    $InputObject
)

process {
    # Boru hattından gelen her bir nesne (event) için bu blok çalışır
    foreach ($item in $InputObject) {
        $out = [ordered]@{}
        
        # Eğer nesnenin Properties alanı varsa (WinEvent nesnesi gibi)
        if ($item.Properties) {
            for ($i = 0; $i -lt $item.Properties.Count; $i++) {
                $out["$i"] = $item.Properties[$i].Value
            }
            [PSCustomObject]$out
        } 
        else {
            # Properties yoksa nesneyi olduğu gibi bırak (opsiyonel)
            $item
        }
    }
}