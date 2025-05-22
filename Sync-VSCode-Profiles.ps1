$VSCodeUserDir = "$env:APPDATA\Code\User"
$ProfilesDir = Join-Path $VSCodeUserDir "profiles"
$SharedDir = "$VSCodeUserDir\shared-config"

# Create shared config folder if not exists
if (!(Test-Path $SharedDir)) {
    New-Item -ItemType Directory -Path $SharedDir
    Write-Host "Created shared config directory at $SharedDir"
}

$SharedSettings = Join-Path $SharedDir "settings.json"
$SharedKeybindings = Join-Path $SharedDir "keybindings.json"

if (!(Test-Path $SharedSettings) -or !(Test-Path $SharedKeybindings)) {
    Write-Host "ERROR: settings.json or keybindings.json not found in $SharedDir"
    exit
}

Get-ChildItem -Path $ProfilesDir -Directory | ForEach-Object {
    $ProfilePath = $_.FullName
    Copy-Item $SharedSettings -Destination "$ProfilePath\settings.json" -Force
    Copy-Item $SharedKeybindings -Destination "$ProfilePath\keybindings.json" -Force
    Write-Host "Synced profile: $($_.Name)"
}

Write-Host ""
Write-Host "All profile settings have been successfully synced."
