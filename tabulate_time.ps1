# Bu script, 17.02.2026'da AI kullanarak hazirlandi
[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $true)]
    $InputObject
)

process {
    foreach ($item in $InputObject) {
        # 'ordered' kullanarak kolon sirasini garanti altina aliyoruz
        $out = [ordered]@{
            "TimeCreated" = $item.TimeCreated  # Zaman damgasini ilk siraya koyduk
        }
        
        if ($item.Properties) {
            for ($i = 0; $i -lt $item.Properties.Count; $i++) {
                $out["$i"] = $item.Properties[$i].Value
            }
            [PSCustomObject]$out
        } 
        else {
            # Eger Properties yoksa ama TimeCreated varsa yine de objeyi oluştur
            [PSCustomObject]$out
        }
    }
}