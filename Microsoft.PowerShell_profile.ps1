oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\sonicboom_dark.omp.json" | Invoke-Expression
# PSReadLine with Vim Mode
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History

# Additional Modules
Import-Module Terminal-Icons
Import-Module posh-git

# Aliases
Set-Alias ll ls
Set-Alias vim nvim
Set-Alias g git

oh-my-posh init pwsh | Invoke-Expression
