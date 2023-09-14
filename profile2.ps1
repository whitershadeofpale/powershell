# Import-Module oh-my-posh
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\sonicboom_light.omp.json" | Invoke-Expression
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\pure.omp.json" | Invoke-Expression
# Set-PoshPrompt jblab_2021
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView