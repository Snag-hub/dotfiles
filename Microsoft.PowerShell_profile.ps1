
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\easy-term.omp.json" | Invoke-Expression

# PSReadLine with Vim Mode
Import-Module PSReadLine
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -ViModeIndicator Prompt
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Additional Modules
Import-Module Terminal-Icons
Import-Module posh-git

# Aliases
Set-Alias ll ls
Set-Alias vim nvim
Set-Alias g git