# ===============================
# PowerShell Profile (Ultimate Native Setup)
# ===============================

# UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# -------------------------------
# PSReadLine
# -------------------------------
Import-Module PSReadLine

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

# -------------------------------
# Modules
# -------------------------------
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module posh-git -ErrorAction SilentlyContinue

# -------------------------------
# Storage Files
# -------------------------------
$global:DirHistoryFile = "$HOME\.ps_dir_history"
$global:RecentFilesFile = "$HOME\.ps_recent_files"

# -------------------------------
# Track Directory Visits
# -------------------------------
function Register-LocationVisit {
    try {
        $entry = [PSCustomObject]@{
            Path = (Get-Location).Path
            Time = (Get-Date)
        }
        $entry | ConvertTo-Json -Compress | Add-Content $global:DirHistoryFile
    } catch {}
}

# -------------------------------
# Track File Access
# -------------------------------
function Register-FileAccess($path) {
    try {
        $entry = [PSCustomObject]@{
            Path = $path
            Time = (Get-Date)
        }
        $entry | ConvertTo-Json -Compress | Add-Content $global:RecentFilesFile
    } catch {}
}

# Auto-track file opens (wrapper)
function open {
    param($file)
    if (Test-Path $file) {
        Register-FileAccess (Resolve-Path $file)
        Invoke-Item $file
    }
}

# -------------------------------
# SMART DIRECTORY JUMP (zoxide++)
# -------------------------------
function j {
    param([string]$query)

    if (!(Test-Path $global:DirHistoryFile)) {
        Write-Host "No history yet" -ForegroundColor Yellow
        return
    }

    $entries = Get-Content $global:DirHistoryFile |
        ForEach-Object { $_ | ConvertFrom-Json }

    $grouped = $entries | Group-Object Path | ForEach-Object {
        $last = ($_.Group | Sort-Object Time -Descending | Select-Object -First 1).Time
        $score = $_.Count * 3 + ((Get-Date) - $last).TotalMinutes * -0.02
        [PSCustomObject]@{
            Path  = $_.Name
            Score = $score
        }
    }

    if ($query) {
        $grouped = $grouped | Where-Object { $_.Path -like "*$query*" }
    }

    $target = $grouped | Sort-Object Score -Descending | Select-Object -First 1

    if ($target) {
        Set-Location $target.Path
    } else {
        Write-Host "No match found" -ForegroundColor Red
    }
}

# -------------------------------
# PROJECT-AWARE BOOST
# -------------------------------
function jp {
    $projects = Get-ChildItem "$HOME\source","$HOME\projects" -Directory -ErrorAction SilentlyContinue
    if ($projects) {
        $projects | ForEach-Object { $_.FullName }
    }
}

# -------------------------------
# COMMAND TIMER
# -------------------------------
$global:LastCommandTime = Get-Date

Register-EngineEvent PowerShell.OnIdle -Action {
    $global:LastCommandTime = Get-Date
} | Out-Null

function Get-CommandDuration {
    $now = Get-Date
    $duration = ($now - $global:LastCommandTime).TotalMilliseconds
    return [math]::Round($duration, 0)
}

# -------------------------------
# PROMPT (clean + info-rich)
# -------------------------------
function prompt {
    Register-LocationVisit

    $path = Get-Location
    $git = Get-GitStatus
    $time = Get-CommandDuration

    if ($git) {
        Write-Host "[$($git.Branch)] " -NoNewline -ForegroundColor Yellow
    }

    Write-Host "PS $path " -NoNewline -ForegroundColor Cyan
    Write-Host "(${time}ms)" -NoNewline -ForegroundColor DarkGray
    Write-Host " >" -NoNewline -ForegroundColor Cyan

    return " "
}

# -------------------------------
# Aliases
# -------------------------------
Set-Alias ll Get-ChildItem
Set-Alias la "Get-ChildItem -Force"
Set-Alias g git
Set-Alias grep Select-String
Set-Alias cls Clear-Host
Set-Alias vim nvim -ErrorAction SilentlyContinue

# -------------------------------
# Navigation
# -------------------------------
function .. { Set-Location .. }
function ... { Set-Location ../.. }

function mkcd {
    param($name)
    New-Item -ItemType Directory -Path $name | Out-Null
    Set-Location $name
}

# -------------------------------
# Git Shortcuts
# -------------------------------
function gst { git status }
function gco { git checkout $args }
function gcm { git commit -m $args }
function gaa { git add . }

function gswitch {
    $branches = git branch --all 2>$null |
        ForEach-Object { $_.Trim().TrimStart('* ') }
    $branches
    $name = Read-Host "Branch"
    if ($name) { git checkout $name }
}

# -------------------------------
# REAL Git Completion (dynamic)
# -------------------------------
Register-ArgumentCompleter -CommandName git -ScriptBlock {
    param($commandName, $wordToComplete)

    $branches = git branch --all 2>$null |
        ForEach-Object { $_.Trim().TrimStart('* ') }

    $cmds = 'add','branch','checkout','clone','commit','diff','fetch','init','log','merge','pull','push','rebase','status','switch'

    ($cmds + $branches) |
        Where-Object { $_ -like "$wordToComplete*" } |
        Sort-Object -Unique |
        ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

# -------------------------------
# dotnet / npm completion
# -------------------------------
Register-ArgumentCompleter -CommandName dotnet -ScriptBlock {
    param($wordToComplete)
    'build','run','new','restore','publish','clean','test','add','remove','sln' |
    Where-Object { $_ -like "$wordToComplete*" } |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -CommandName npm -ScriptBlock {
    param($wordToComplete)
    'install','run','start','test','build','publish','update' |
    Where-Object { $_ -like "$wordToComplete*" } |
    ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# -------------------------------
# Startup Message
# -------------------------------
Write-Host "PowerShell ready 🚀 (Ultimate Mode)" -ForegroundColor Green