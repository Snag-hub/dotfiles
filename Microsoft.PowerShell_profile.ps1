# ============================================================
# PowerShell Profile V2
# Ultimate Native Setup for .NET + React Full-Stack Engineering
# ============================================================

# -------------------------------
# Encoding
# -------------------------------
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# -------------------------------
# PSReadLine
# -------------------------------
Import-Module PSReadLine -ErrorAction SilentlyContinue

if (Get-Module PSReadLine) {
    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView

    Set-PSReadLineOption -Colors @{
        Command   = 'Cyan'
        Parameter = 'DarkCyan'
        String    = 'Yellow'
        Operator  = 'Gray'
        Variable  = 'Green'
        Number    = 'Magenta'
    }

    Set-PSReadLineKeyHandler -Chord Ctrl+d -Function DeleteChar
    Set-PSReadLineKeyHandler -Chord Ctrl+r -Function ReverseSearchHistory
    Set-PSReadLineKeyHandler -Chord RightArrow -Function AcceptNextSuggestionWord
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# -------------------------------
# Optional Modules
# Loads only if already installed.
# No new dependency required.
# -------------------------------
foreach ($module in @('Terminal-Icons', 'posh-git')) {
    if (Get-Module -ListAvailable -Name $module) {
        Import-Module $module -ErrorAction SilentlyContinue
    }
}

# -------------------------------
# Storage Files
# -------------------------------
$global:DirHistoryFile = "$HOME\.ps_dir_history"
$global:RecentFilesFile = "$HOME\.ps_recent_files"
$global:LastPromptTime = Get-Date

# -------------------------------
# Profile Helpers
# -------------------------------
function ep {
    notepad $PROFILE
}

function rp {
    . $PROFILE
}

function profile-path {
    $PROFILE
}

function profile-folder {
    Split-Path $PROFILE
}

# -------------------------------
# Admin Check
# -------------------------------
function Test-IsAdmin {
    try {
        $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch {
        return $false
    }
}

# -------------------------------
# Location History
# -------------------------------
function Register-LocationVisit {
    try {
        $entry = [PSCustomObject]@{
            Path = (Get-Location).Path
            Time = Get-Date
        }

        $entry | ConvertTo-Json -Compress | Add-Content $global:DirHistoryFile
    } catch {}
}

# -------------------------------
# File Access History
# -------------------------------
function Register-FileAccess {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $entry = [PSCustomObject]@{
            Path = $Path
            Time = Get-Date
        }

        $entry | ConvertTo-Json -Compress | Add-Content $global:RecentFilesFile
    } catch {}
}

function open {
    param(
        [Parameter(Mandatory)]
        [string]$File
    )

    if (Test-Path $File) {
        $resolvedPath = Resolve-Path $File
        Register-FileAccess -Path $resolvedPath
        Invoke-Item $resolvedPath
    } else {
        Write-Host "File not found: $File" -ForegroundColor Red
    }
}

function recent-files {
    if (!(Test-Path $global:RecentFilesFile)) {
        Write-Host "No recent file history yet" -ForegroundColor Yellow
        return
    }

    Get-Content $global:RecentFilesFile |
        ForEach-Object {
            try {
                $_ | ConvertFrom-Json
            } catch {}
        } |
        Where-Object { $_ -and $_.Path } |
        Sort-Object Time -Descending |
        Select-Object -First 20
}

# -------------------------------
# Smart Directory Jump
# -------------------------------
function j {
    param(
        [string]$Query
    )

    if (!(Test-Path $global:DirHistoryFile)) {
        Write-Host "No directory history yet" -ForegroundColor Yellow
        return
    }

    $entries = Get-Content $global:DirHistoryFile |
        ForEach-Object {
            try {
                $_ | ConvertFrom-Json
            } catch {}
        } |
        Where-Object { $_ -and $_.Path }

    if (!$entries) {
        Write-Host "No valid directory history found" -ForegroundColor Yellow
        return
    }

    $grouped = $entries | Group-Object Path | ForEach-Object {
        $last = ($_.Group | Sort-Object Time -Descending | Select-Object -First 1).Time
        $score = ($_.Count * 3) + (((Get-Date) - $last).TotalMinutes * -0.02)

        [PSCustomObject]@{
            Path  = $_.Name
            Score = $score
        }
    }

    if ($Query) {
        $grouped = $grouped | Where-Object { $_.Path -like "*$Query*" }
    }

    $target = $grouped |
        Where-Object { Test-Path $_.Path } |
        Sort-Object Score -Descending |
        Select-Object -First 1

    if ($target) {
        Set-Location $target.Path
    } else {
        Write-Host "No match found" -ForegroundColor Red
    }
}

function dirs {
    if (!(Test-Path $global:DirHistoryFile)) {
        Write-Host "No directory history yet" -ForegroundColor Yellow
        return
    }

    Get-Content $global:DirHistoryFile |
        ForEach-Object {
            try {
                $_ | ConvertFrom-Json
            } catch {}
        } |
        Where-Object { $_ -and $_.Path } |
        Group-Object Path |
        Sort-Object Count -Descending |
        Select-Object -First 20 Count, Name
}

# -------------------------------
# Project Helpers
# -------------------------------
function jp {
    Get-ChildItem "$HOME\source", "$HOME\projects" -Directory -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}

function slns {
    Get-ChildItem -Recurse -Filter *.sln -ErrorAction SilentlyContinue |
        Select-Object FullName
}

function csprojs {
    Get-ChildItem -Recurse -Filter *.csproj -ErrorAction SilentlyContinue |
        Select-Object FullName
}

function packages {
    Get-ChildItem -Recurse -Filter package.json -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notlike "*node_modules*" } |
        Select-Object FullName
}

function codehere {
    if (Get-Command code -ErrorAction SilentlyContinue) {
        code .
    } else {
        Write-Host "VS Code command 'code' not found" -ForegroundColor Yellow
    }
}

function vshere {
    $sln = Get-ChildItem -Filter *.sln -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($sln) {
        Invoke-Item $sln.FullName
    } else {
        Write-Host "No solution file found" -ForegroundColor Yellow
    }
}

# -------------------------------
# Command Timer
# -------------------------------
function Get-CommandDuration {
    try {
        $now = Get-Date
        $duration = ($now - $global:LastPromptTime).TotalMilliseconds
        $global:LastPromptTime = $now
        return [Math]::Round($duration, 0)
    } catch {
        return 0
    }
}

# -------------------------------
# Git Helpers for Prompt
# -------------------------------
function Get-CurrentGitBranch {
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        $branch = git branch --show-current 2>$null

        if ($branch) {
            return $branch
        }

        return $null
    } catch {
        return $null
    }
}

# -------------------------------
# Fast Project Tag Detection
# Lightweight only, safe for prompt.
# -------------------------------
function Get-ProjectTags {
    $tags = @()

    if (Get-ChildItem -Path . -Filter *.sln -ErrorAction SilentlyContinue | Select-Object -First 1) {
        $tags += ".NET"
    }

    if (Get-ChildItem -Path . -Filter *.csproj -ErrorAction SilentlyContinue | Select-Object -First 1) {
        $tags += "C#"
    }

    if (Test-Path package.json) {
        $tags += "Node"
    }

    if ((Test-Path vite.config.js) -or (Test-Path vite.config.ts)) {
        $tags += "Vite"
    }

    if ((Test-Path next.config.js) -or (Test-Path next.config.mjs) -or (Test-Path next.config.ts)) {
        $tags += "Next"
    }

    if ((Test-Path docker-compose.yml) -or (Test-Path compose.yml)) {
        $tags += "Docker"
    }

    return $tags
}

# -------------------------------
# Prompt
# -------------------------------
function prompt {
    Register-LocationVisit

    $path = (Get-Location).Path
    $homePath = [Regex]::Escape($HOME)
    $shortPath = $path -replace "^$homePath", "~"

    $branch = Get-CurrentGitBranch
    $tags = Get-ProjectTags
    $time = Get-CommandDuration

    if (Test-IsAdmin) {
        Write-Host "[ADMIN] " -NoNewline -ForegroundColor Red
    }

    if ($branch) {
        Write-Host "[$branch] " -NoNewline -ForegroundColor Yellow
    }

    foreach ($tag in $tags) {
        Write-Host "[$tag] " -NoNewline -ForegroundColor Magenta
    }

    Write-Host "PS " -NoNewline -ForegroundColor Cyan
    Write-Host $shortPath -NoNewline -ForegroundColor Green
    Write-Host " (${time}ms)" -NoNewline -ForegroundColor DarkGray
    Write-Host " >" -NoNewline -ForegroundColor Cyan

    return " "
}

# -------------------------------
# Native Utility Commands
# -------------------------------
function which {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    Get-Command $Name -ErrorAction SilentlyContinue |
        Select-Object Name, Source, CommandType
}

function touch {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path $Path) {
        (Get-Item $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
}

function trash {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (!(Test-Path $Path)) {
        Write-Host "Path not found: $Path" -ForegroundColor Red
        return
    }

    try {
        $item = Get-Item $Path
        $shell = New-Object -ComObject Shell.Application

        if ($item.PSIsContainer) {
            $parentPath = Split-Path $item.FullName -Parent
            $folderName = Split-Path $item.FullName -Leaf
        } else {
            $parentPath = $item.DirectoryName
            $folderName = $item.Name
        }

        $folder = $shell.Namespace($parentPath)
        $folderItem = $folder.ParseName($folderName)

        if ($folderItem) {
            $folderItem.InvokeVerb("delete")
        }
    } catch {
        Write-Host "Failed to move to Recycle Bin: $Path" -ForegroundColor Red
    }
}

# -------------------------------
# Directory Listing
# -------------------------------
function ll {
    Get-ChildItem
}

function la {
    Get-ChildItem -Force
}

function lla {
    Get-ChildItem -Force |
        Format-Table Mode, LastWriteTime, Length, Name -AutoSize
}

# -------------------------------
# Navigation
# -------------------------------
function .. {
    Set-Location ..
}

function ... {
    Set-Location ../..
}

function mkcd {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    New-Item -ItemType Directory -Path $Name -Force | Out-Null
    Set-Location $Name
}

function home {
    Set-Location $HOME
}

function docs {
    Set-Location "$HOME\Documents"
}

function desktop {
    Set-Location "$HOME\Desktop"
}

function downloads {
    Set-Location "$HOME\Downloads"
}

# -------------------------------
# Clipboard Helpers
# -------------------------------
function cpath {
    (Get-Location).Path | Set-Clipboard
    Write-Host "Current path copied to clipboard" -ForegroundColor Green
}

function copyfile {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (Test-Path $Path) {
        Resolve-Path $Path | Set-Clipboard
        Write-Host "File path copied to clipboard" -ForegroundColor Green
    } else {
        Write-Host "File not found: $Path" -ForegroundColor Red
    }
}

# -------------------------------
# Archive Helpers
# -------------------------------
function unzip {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Destination = "."
    )

    if (!(Test-Path $Path)) {
        Write-Host "Archive not found: $Path" -ForegroundColor Red
        return
    }

    Expand-Archive -Path $Path -DestinationPath $Destination -Force
}

function zip {
    param(
        [Parameter(Mandatory)]
        [string]$Source,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    if (!(Test-Path $Source)) {
        Write-Host "Source not found: $Source" -ForegroundColor Red
        return
    }

    Compress-Archive -Path $Source -DestinationPath $Destination -Force
}

# -------------------------------
# Network Helpers
# -------------------------------
function myip {
    Get-NetIPAddress |
        Where-Object {
            $_.AddressFamily -eq 'IPv4' -and
            $_.IPAddress -notlike '169.*' -and
            $_.IPAddress -ne '127.0.0.1'
        } |
        Select-Object InterfaceAlias, IPAddress
}

function flushdns {
    Clear-DnsClientCache
    Write-Host "DNS cache cleared" -ForegroundColor Green
}

# -------------------------------
# System Info
# -------------------------------
function sysinfo {
    try {
        $os = Get-CimInstance Win32_OperatingSystem

        [PSCustomObject]@{
            User       = $env:USERNAME
            Computer   = $env:COMPUTERNAME
            PowerShell = $PSVersionTable.PSVersion.ToString()
            OS         = $os.Caption
            OSVersion  = $os.Version
            Uptime     = ((Get-Date) - $os.LastBootUpTime)
        }
    } catch {
        Write-Host "Unable to collect system info" -ForegroundColor Red
    }
}

function battery {
    Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue |
        Select-Object EstimatedChargeRemaining, BatteryStatus
}

# ============================================================
# .NET Productivity
# ============================================================

function drestore {
    dotnet restore
}

function dbuild {
    dotnet build
}

function drun {
    dotnet run
}

function dwatch {
    dotnet watch run
}

function dtest {
    dotnet test
}

function dclean {
    dotnet clean
}

function dformat {
    dotnet format
}

function dpublish {
    dotnet publish -c Release
}

function dnewapi {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    dotnet new webapi -n $Name
}

function dnewmvc {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    dotnet new mvc -n $Name
}

function dnewclasslib {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    dotnet new classlib -n $Name
}

function dnewxunit {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    dotnet new xunit -n $Name
}

function daddref {
    param(
        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(Mandatory)]
        [string]$Reference
    )

    dotnet add $Project reference $Reference
}

function daddpkg {
    param(
        [Parameter(Mandatory)]
        [string]$Package
    )

    dotnet add package $Package
}

function dlistpkg {
    dotnet list package
}

function doutdated {
    dotnet list package --outdated
}

# ============================================================
# React / Node / npm Productivity
# ============================================================

function ni {
    npm install
}

function nr {
    npm run @args
}

function ndev {
    npm run dev
}

function nstart {
    npm start
}

function nbuild {
    npm run build
}

function ntest {
    npm test
}

function nlint {
    npm run lint
}

function npreview {
    npm run preview
}

function nclean {
    if (Test-Path node_modules) {
        Remove-Item node_modules -Recurse -Force
    }

    if (Test-Path package-lock.json) {
        Remove-Item package-lock.json -Force
    }

    npm install
}

function nscripts {
    if (!(Test-Path package.json)) {
        Write-Host "package.json not found" -ForegroundColor Yellow
        return
    }

    $pkg = Get-Content package.json -Raw | ConvertFrom-Json

    if ($pkg.scripts) {
        $pkg.scripts.PSObject.Properties |
            Select-Object Name, Value
    } else {
        Write-Host "No scripts found in package.json" -ForegroundColor Yellow
    }
}

# ============================================================
# Smart Full-Stack Project Detection
# ============================================================

function Find-ProjectFolder {
    param(
        [Parameter(Mandatory)]
        [string[]]$Keywords,

        [string[]]$PreferredFiles = @()
    )

    $folders = Get-ChildItem -Directory -ErrorAction SilentlyContinue

    foreach ($keyword in $Keywords) {
        $matches = $folders |
            Where-Object { $_.Name -like "*$keyword*" }

        foreach ($match in $matches) {
            if ($PreferredFiles.Count -eq 0) {
                return $match.FullName
            }

            foreach ($file in $PreferredFiles) {
                if (Test-Path (Join-Path $match.FullName $file)) {
                    return $match.FullName
                }
            }
        }
    }

    foreach ($folder in $folders) {
        foreach ($file in $PreferredFiles) {
            if (Test-Path (Join-Path $folder.FullName $file)) {
                return $folder.FullName
            }
        }
    }

    return $null
}

function Convert-ToPwshPathLiteral {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    return $Path.Replace("'", "''")
}

function Start-PwshCommandInFolder {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Command
    )

    $safePath = Convert-ToPwshPathLiteral -Path $Path
    Start-Process pwsh -ArgumentList "-NoExit", "-Command", "Set-Location -LiteralPath '$safePath'; $Command"
}

function fsdetect {
    $frontendPath = Find-ProjectFolder `
        -Keywords @("client", "frontend", "ui", "web", "react", "app") `
        -PreferredFiles @("package.json")

    $backendPath = Find-ProjectFolder `
        -Keywords @("server", "backend", "api", "service") `
        -PreferredFiles @("*.csproj")

    [PSCustomObject]@{
        Frontend = $frontendPath
        Backend  = $backendPath
    }
}

function fsdev {
    param(
        [string]$Frontend,
        [string]$Backend
    )

    if ($Frontend) {
        $frontendPath = Find-ProjectFolder `
            -Keywords @($Frontend, "client", "frontend", "ui", "web", "react", "app") `
            -PreferredFiles @("package.json")
    } else {
        $frontendPath = Find-ProjectFolder `
            -Keywords @("client", "frontend", "ui", "web", "react", "app") `
            -PreferredFiles @("package.json")
    }

    if ($Backend) {
        $backendPath = Find-ProjectFolder `
            -Keywords @($Backend, "server", "backend", "api", "service") `
            -PreferredFiles @("*.csproj")
    } else {
        $backendPath = Find-ProjectFolder `
            -Keywords @("server", "backend", "api", "service") `
            -PreferredFiles @("*.csproj")
    }

    if (!$frontendPath) {
        Write-Host "Frontend folder not found." -ForegroundColor Red
        Write-Host "Looked for folder names containing: client, frontend, ui, web, react, app" -ForegroundColor Yellow
        Write-Host "Also checked for package.json inside folders." -ForegroundColor Yellow
        return
    }

    if (!$backendPath) {
        Write-Host "Backend folder not found." -ForegroundColor Red
        Write-Host "Looked for folder names containing: server, backend, api, service" -ForegroundColor Yellow
        Write-Host "Also checked for .csproj inside folders." -ForegroundColor Yellow
        return
    }

    Write-Host "Frontend: $frontendPath" -ForegroundColor Green
    Write-Host "Backend : $backendPath" -ForegroundColor Green

    Start-PwshCommandInFolder -Path $backendPath -Command "dotnet watch run"
    Start-PwshCommandInFolder -Path $frontendPath -Command "npm run dev"
}

function dev {
    if (Test-Path package.json) {
        try {
            $pkg = Get-Content package.json -Raw | ConvertFrom-Json

            if ($pkg.scripts.dev) {
                npm run dev
                return
            }

            if ($pkg.scripts.start) {
                npm start
                return
            }
        } catch {}
    }

    $frontendPath = Find-ProjectFolder `
        -Keywords @("client", "frontend", "ui", "web", "react", "app") `
        -PreferredFiles @("package.json")

    if ($frontendPath) {
        Start-PwshCommandInFolder -Path $frontendPath -Command "npm run dev"
        return
    }

    if (Get-ChildItem -Filter *.csproj -ErrorAction SilentlyContinue) {
        dotnet run
        return
    }

    $backendPath = Find-ProjectFolder `
        -Keywords @("server", "backend", "api", "service") `
        -PreferredFiles @("*.csproj")

    if ($backendPath) {
        Start-PwshCommandInFolder -Path $backendPath -Command "dotnet run"
        return
    }

    Write-Host "No known dev command found" -ForegroundColor Yellow
}

function apiwatch {
    dotnet watch run
}

function uiwatch {
    npm run dev
}

# ============================================================
# API Testing Helpers
# ============================================================

function getjson {
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    Invoke-RestMethod -Uri $Url -Method Get
}

function postjson {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$Body
    )

    Invoke-RestMethod `
        -Uri $Url `
        -Method Post `
        -ContentType "application/json" `
        -Body $Body
}

function putjson {
    param(
        [Parameter(Mandatory)]
        [string]$Url,

        [Parameter(Mandatory)]
        [string]$Body
    )

    Invoke-RestMethod `
        -Uri $Url `
        -Method Put `
        -ContentType "application/json" `
        -Body $Body
}

function deletejson {
    param(
        [Parameter(Mandatory)]
        [string]$Url
    )

    Invoke-RestMethod -Uri $Url -Method Delete
}

function localhost {
    param(
        [int]$Port = 3000
    )

    Start-Process "http://localhost:$Port"
}

function swagger {
    param(
        [int]$Port = 5000
    )

    Start-Process "http://localhost:$Port/swagger"
}

# ============================================================
# Cleanup Helpers
# ============================================================

function clean-dotnet {
    Get-ChildItem -Recurse -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @("bin", "obj") } |
        Remove-Item -Recurse -Force

    Write-Host "Cleaned .NET bin and obj folders" -ForegroundColor Green
}

function clean-node {
    Get-ChildItem -Recurse -Directory -Filter node_modules -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force

    Write-Host "Cleaned node_modules folders" -ForegroundColor Green
}

function clean-dist {
    Get-ChildItem -Recurse -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -in @("dist", "build", "out") } |
        Remove-Item -Recurse -Force

    Write-Host "Cleaned frontend build folders" -ForegroundColor Green
}

function clean-all {
    clean-dotnet
    clean-dist
    Write-Host "Cleaned .NET and frontend build artifacts" -ForegroundColor Green
}

# ============================================================
# Environment Variable Helpers
# ============================================================

function envget {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    [Environment]::GetEnvironmentVariable($Name, "User")
}

function envset {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Value
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Write-Host "User environment variable set: $Name" -ForegroundColor Green
}

function envremove {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    [Environment]::SetEnvironmentVariable($Name, $null, "User")
    Write-Host "User environment variable removed: $Name" -ForegroundColor Green
}

function envdev {
    $env:ASPNETCORE_ENVIRONMENT = "Development"
    $env:NODE_ENV = "development"

    Write-Host "Session environment set to Development" -ForegroundColor Green
}

# ============================================================
# Git Shortcuts
# ============================================================

function gst {
    git status
}

function gaa {
    git add .
}

function gco {
    git checkout @args
}

function gcm {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Message
    )

    git commit -m ($Message -join " ")
}

function gpull {
    git pull
}

function gpush {
    git push
}

function glog {
    git log --oneline --graph --decorate --all
}

function gswitch {
    if (!(Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Host "Git is not available" -ForegroundColor Red
        return
    }

    $branches = git branch --all 2>$null |
        ForEach-Object {
            $_.Trim().TrimStart('*').Trim()
        } |
        Sort-Object -Unique

    if (!$branches) {
        Write-Host "No branches found" -ForegroundColor Yellow
        return
    }

    $branches
    $name = Read-Host "Branch"

    if ($name) {
        git checkout $name
    }
}

function gnew {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    git checkout -b $Name
}

function gundo {
    git reset --soft HEAD~1
}

# ============================================================
# Completion
# ============================================================

Register-ArgumentCompleter -CommandName git -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    $branches = @()

    if (Get-Command git -ErrorAction SilentlyContinue) {
        $branches = git branch --all 2>$null |
            ForEach-Object {
                $_.Trim().TrimStart('*').Trim()
            }
    }

    $cmds = @(
        'add',
        'branch',
        'checkout',
        'clone',
        'commit',
        'diff',
        'fetch',
        'init',
        'log',
        'merge',
        'pull',
        'push',
        'rebase',
        'restore',
        'status',
        'switch'
    )

    ($cmds + $branches) |
        Where-Object { $_ -like "$wordToComplete*" } |
        Sort-Object -Unique |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Register-ArgumentCompleter -CommandName dotnet -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    @(
        'build',
        'run',
        'new',
        'restore',
        'publish',
        'clean',
        'test',
        'add',
        'remove',
        'sln',
        'tool',
        'format',
        'watch',
        'list'
    ) |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Register-ArgumentCompleter -CommandName npm -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete)

    @(
        'install',
        'run',
        'start',
        'test',
        'build',
        'publish',
        'update',
        'audit',
        'init',
        'ci',
        'create'
    ) |
        Where-Object { $_ -like "$wordToComplete*" } |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# -------------------------------
# Aliases
# -------------------------------
if (Get-Command git -ErrorAction SilentlyContinue) {
    Set-Alias g git -ErrorAction SilentlyContinue
}

if (Get-Command Select-String -ErrorAction SilentlyContinue) {
    Set-Alias grep Select-String -ErrorAction SilentlyContinue
}

if (Get-Command Clear-Host -ErrorAction SilentlyContinue) {
    Set-Alias cls Clear-Host -ErrorAction SilentlyContinue
}

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias vim nvim -ErrorAction SilentlyContinue
}

# -------------------------------
# Startup Message
# Shows only once per session.
# -------------------------------
if (-not $global:ProfileLoadedMessageShown) {
    Write-Host "PowerShell ready 🚀 (Full-Stack Mode)" -ForegroundColor Green
    $global:ProfileLoadedMessageShown = $true
}