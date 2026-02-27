[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string[]]$InputData,

    [Parameter(Mandatory=$true)]
    [string[]]$Headers
)

Begin {
    # Initialize an empty list to collect all lines
    $FullList = New-Object System.Collections.Generic.List[string]
}

Process {
    # Collect every line coming through the pipe
    foreach ($line in $InputData) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $FullList.Add($line.Trim())
        }
    }
}

End {
    $step = $Headers.Count
    for ($i = 0; $i -lt $FullList.Count; $i += $step) {
        $objHash = [ordered]@{}
        
        for ($j = 0; $j -lt $step; $j++) {
            $headerName = $Headers[$j]
            # Assign the line to the header, or an empty string if data is missing
            $value = if ($i + $j -lt $FullList.Count) { $FullList[$i + $j] } else { "" }
            $objHash[$headerName] = $value
        }
        
        [PSCustomObject]$objHash
    }
}
