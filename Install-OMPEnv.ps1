Write-Host "Setting up PowerShell 7 + Oh My Posh environment..." -ForegroundColor DarkRed



# Define script and theme paths (relative to script location)
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ompBaseDir = Join-Path $scriptDir "oh-my-posh"
$themesDir = Join-Path $ompBaseDir "themes"

# Error logging function
function Write-ErrorLog {
    param(
        [string]$Script,
        [string]$ErrorType,
        [string]$Description
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Script] [$ErrorType] - $Description"
    $logFile = Join-Path $scriptDir "errors.log"
    
    # Create file with header if it doesn't exist
    if (-not (Test-Path $logFile)) {
        $header = @"
# Terminal Customization - Error Log
# This file tracks errors and issues encountered during installation or usage
# Format: [TIMESTAMP] [SCRIPT] [ERROR_TYPE] - [DESCRIPTION]
# Created: $timestamp

"@
        Set-Content -Path $logFile -Value $header -Encoding UTF8
    }
    
    Add-Content -Path $logFile -Value $logEntry
    Write-Host "Error logged: $Description" -ForegroundColor Red
}

# Step 1: Install PowerShell 7
Write-Host "`nStep 1: Install PowerShell 7" -ForegroundColor Cyan
if (-not (Get-Command "pwsh.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing PowerShell 7..." -ForegroundColor Yellow
    winget install --id Microsoft.PowerShell --source winget --silent --accept-package-agreements --accept-source-agreements
}
else {
    Write-Host "PowerShell 7 already installed." -ForegroundColor Green
}

# Step 2: Install Oh My Posh
Write-Host "`nStep 2: Install Oh My Posh" -ForegroundColor Cyan
if (-not (Get-Command "oh-my-posh.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Oh My Posh..." -ForegroundColor Yellow
    try {
        winget install JanDeDobbeleer.OhMyPosh --source winget --silent
        Start-Sleep -Seconds 2
    }
    catch {
        $errorMsg = "Failed to install Oh My Posh via winget: $($_.Exception.Message)"
        Write-ErrorLog -Script "Install-OMPEnv.ps1" -ErrorType "WINGET_ERROR" -Description $errorMsg
    }
}
else {
    Write-Host "Oh My Posh already installed." -ForegroundColor Green
}

# Step 3: Ensure oh-my-posh is in PATH
Write-Host "`nStep 3: Add Oh My Posh binary path to PATH" -ForegroundColor Cyan

# First, try to find oh-my-posh.exe using Get-Command
$ompExe = $null
try {
    $ompCommand = Get-Command "oh-my-posh.exe" -ErrorAction Stop
    $ompExe = $ompCommand.Source
    Write-Host "Found oh-my-posh.exe via PATH: $ompExe" -ForegroundColor Green
}
catch {
    Write-Host "oh-my-posh.exe not found in PATH, searching common installation directories..." -ForegroundColor Yellow
    
    $ompSearchPaths = @(
        "$env:ProgramFiles\oh-my-posh",
        "$env:ProgramFiles (x86)\oh-my-posh",
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
        "$env:LOCALAPPDATA\Programs\oh-my-posh",
        "$env:USERPROFILE\scoop\apps\oh-my-posh\current",
        "$env:ProgramData\chocolatey\bin",
        "$env:USERPROFILE\.local\bin",
        "$env:USERPROFILE\AppData\Local\Microsoft\WinGet\Packages"
    )

    foreach ($path in $ompSearchPaths) {
        if (Test-Path $path) {
            $found = Get-ChildItem -Path $path -Recurse -Filter "oh-my-posh.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) {
                $ompExe = $found.FullName
                Write-Host "Found oh-my-posh.exe in: $ompExe" -ForegroundColor Green
                break
            }
        }
    }
}

if ($ompExe -and (Test-Path $ompExe)) {
    $ompRealDir = Split-Path $ompExe -Parent
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

    if (-not ($currentPath -split ";" | Where-Object { $_ -eq $ompRealDir })) {
        $newPath = "$currentPath;$ompRealDir"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
        Write-Host "Added Oh My Posh binary path to PATH: $ompRealDir" -ForegroundColor Green
    }
    else {
        Write-Host "Oh My Posh binary path already in PATH." -ForegroundColor Gray
    }
}
else {
    Write-Host "Could not find oh-my-posh.exe after installation." -ForegroundColor Red
    Write-ErrorLog -Script "Install-OMPEnv.ps1" -ErrorType "PATH_ERROR" -Description "Oh My Posh not found in PATH after installation"
    Write-Host "Trying to install Oh My Posh using alternative method..." -ForegroundColor Yellow
    
    # Try alternative installation methods
    try {
        # Try using winget with explicit source
        winget install JanDeDobbeleer.OhMyPosh --source winget --silent
        Start-Sleep -Seconds 3
        
        # Try to find it again
        $ompCommand = Get-Command "oh-my-posh.exe" -ErrorAction Stop
        $ompExe = $ompCommand.Source
        Write-Host "Successfully found oh-my-posh.exe after retry: $ompExe" -ForegroundColor Green
    }
    catch {
        $errorMsg = "Failed to install or locate Oh My Posh after retry: $($_.Exception.Message)"
        Write-ErrorLog -Script "Install-OMPEnv.ps1" -ErrorType "INSTALLATION_ERROR" -Description $errorMsg
        Write-Host "Failed to install or locate Oh My Posh. Please install manually:" -ForegroundColor Red
        Write-Host "1. Run: winget install JanDeDobbeleer.OhMyPosh --source winget" -ForegroundColor Yellow
        Write-Host "2. Or download from: https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Yellow
        Write-Host "3. Then re-run this script." -ForegroundColor Yellow
        exit 1
    }
}

# Step 4: Fix POSH_THEMES_PATH environment variable
Write-Host "`nStep 4: Configure POSH_THEMES_PATH" -ForegroundColor Cyan

# Set POSH_THEMES_PATH to point to our project themes directory
[Environment]::SetEnvironmentVariable("POSH_THEMES_PATH", $themesDir, "User")
Write-Host "Set POSH_THEMES_PATH to: $themesDir" -ForegroundColor Green

# Set OMP_BASE_DIR to point to our project oh-my-posh directory
[Environment]::SetEnvironmentVariable("OMP_BASE_DIR", $ompBaseDir, "User")
Write-Host "Set OMP_BASE_DIR to: $ompBaseDir" -ForegroundColor Green

# Also set them for current session
$env:POSH_THEMES_PATH = $themesDir
$env:OMP_BASE_DIR = $ompBaseDir

# Step 5: Create oh-my-posh themes directory
Write-Host "`nStep 5: Create oh-my-posh themes directory" -ForegroundColor Cyan
if (-not (Test-Path $themesDir)) {
    New-Item -ItemType Directory -Path $themesDir -Force | Out-Null
    Write-Host "Created themes directory: $themesDir" -ForegroundColor Green
}
else {
    Write-Host "Themes directory already exists: $themesDir" -ForegroundColor Gray
}

# Step 6: Create PowerShell profile if not exists
Write-Host "`nStep 6: Create PowerShell profile" -ForegroundColor Cyan
if (-not (Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "Created PowerShell profile: $PROFILE" -ForegroundColor Green
}

# Step 7: Ensure PSReadLine is up-to-date to prevent compatibility issues
Write-Host "`nStep 7: Update PSReadLine to prevent compatibility issues" -ForegroundColor Cyan

Write-Host "Updating PSReadLine to latest version..." -ForegroundColor Yellow
try {
    # Check current PSReadLine version
    $currentVersion = (Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    Write-Host "Current PSReadLine version: $currentVersion" -ForegroundColor Gray
    
    # Update PSReadLine to latest version
    Install-Module PSReadLine -Force -ErrorAction Stop
    Write-Host "PSReadLine updated successfully" -ForegroundColor Green
    
    # Verify new version
    $newVersion = (Get-Module PSReadLine -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version
    Write-Host "New PSReadLine version: $newVersion" -ForegroundColor Green
    
}
catch {
    Write-Host "Could not update PSReadLine: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Continuing with installation..." -ForegroundColor Gray
}

# Step 8: Inject dynamic Oh My Posh init logic into profile
Write-Host "`nStep 8: Append OMP init + theme switcher to profile" -ForegroundColor Cyan

$initBlock = @"
# BEGIN: Oh My Posh init block

# Use environment variables for paths (set by installer)
`$ompBaseDir = `$env:OMP_BASE_DIR
`$themesDir = `$env:POSH_THEMES_PATH

# Fallback if environment variables not set
if (-not `$ompBaseDir) {
    `$ompBaseDir = Join-Path (Split-Path -Path `$PROFILE -Parent) "oh-my-posh"
}
if (-not `$themesDir) {
    `$themesDir = Join-Path `$ompBaseDir "themes"
}

# Welcome message (only show first time)
`$welcomeFlagFile = Join-Path `$ompBaseDir ".welcome-shown"
if (-not (Test-Path `$welcomeFlagFile)) {
    Write-Host "`nWelcome to PowerShell 7 Plus!" -ForegroundColor Cyan
    Write-Host "Thank you for using our enhanced PowerShell environment!" -ForegroundColor Green
    Write-Host "`nTheme Management Commands:" -ForegroundColor Yellow
    Write-Host "  > theme <name>     - Switch to a theme (e.g., theme dracula)" -ForegroundColor Gray
    Write-Host "  > theme current    - Show current theme preference" -ForegroundColor Gray
    Write-Host "  > theme reset      - Reset to default theme" -ForegroundColor Gray
    Write-Host "  > theme            - Show help and available themes" -ForegroundColor Gray
    Write-Host "`nEnjoy your enhanced PowerShell experience!" -ForegroundColor Magenta
    
    # Mark welcome as shown
    Set-Content -Path `$welcomeFlagFile -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Encoding UTF8
}

# Initialize logging
`$logFile = Join-Path `$ompBaseDir "profile.log"

try {
    # Refresh environment variables to ensure PATH is current
    `$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    
    # Try multiple methods to find oh-my-posh.exe
    `$ompExe = `$null
    
    # Method 1: Try Get-Command (if already in PATH)
    try {
        `$ompExe = Get-Command "oh-my-posh.exe" -ErrorAction Stop
        Add-Content -Path `$logFile -Value "[`$(Get-Date)] Found oh-my-posh.exe via PATH: `$(`$ompExe.Source)"
    } catch {
        Add-Content -Path `$logFile -Value "[`$(Get-Date)] oh-my-posh.exe not in PATH, searching common locations"
        
        # Method 2: Search common installation directories
        `$ompSearchPaths = @(
            "`$env:ProgramFiles\oh-my-posh",
            "`$env:ProgramFiles (x86)\oh-my-posh", 
            "`$env:LOCALAPPDATA\Microsoft\WinGet\Packages",
            "`$env:LOCALAPPDATA\Programs\oh-my-posh",
            "`$env:USERPROFILE\scoop\apps\oh-my-posh\current",
            "`$env:ProgramData\chocolatey\bin",
            "`$env:USERPROFILE\.local\bin"
        )
        
        foreach (`$path in `$ompSearchPaths) {
            if (Test-Path `$path) {
                `$found = Get-ChildItem -Path `$path -Recurse -Filter "oh-my-posh.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
                if (`$found) {
                    `$ompExe = `$found
                    Add-Content -Path `$logFile -Value "[`$(Get-Date)] Found oh-my-posh.exe in: `$(`$found.FullName)"
                    break
                }
            }
        }
    }
    
    if (-not `$ompExe) {
        throw "Could not locate oh-my-posh.exe in PATH or common locations"
    }
    
    # Use POSH_THEMES_PATH environment variable
    `$themesDir = `$env:POSH_THEMES_PATH
    
    # Try to load user's saved theme preference first
    `$preferenceFile = Join-Path `$ompBaseDir ".theme-preference"
    `$themePath = `$null
    
    if (Test-Path `$preferenceFile) {
        try {
            `$savedTheme = Get-Content `$preferenceFile -Raw -ErrorAction Stop | ForEach-Object { `$_.Trim() }
            if (-not [string]::IsNullOrEmpty(`$savedTheme)) {
                # Try to find the saved theme
                `$savedThemePath = Join-Path -Path `$themesDir -ChildPath "`$savedTheme.omp.json"
                if (Test-Path `$savedThemePath) {
                    `$themePath = `$savedThemePath
                    Add-Content -Path `$logFile -Value "[`$(Get-Date)] Loading saved theme: `$savedTheme"
                } else {
                    Add-Content -Path `$logFile -Value "[`$(Get-Date)] Saved theme not found: `$savedTheme, falling back to default"
                }
            }
        } catch {
            Add-Content -Path `$logFile -Value "[`$(Get-Date)] Error reading theme preference: `$(`$_.Exception.Message)"
        }
    }
    
    # If no saved preference or saved theme not found, use default
    if (-not `$themePath) {
        `$themePath = Join-Path -Path `$themesDir -ChildPath "jandedobbeleer.omp.json"
        if (-not (Test-Path `$themePath)) {
            # If default theme doesn't exist, try to find any available theme
            `$availableThemes = Get-ChildItem -Path `$themesDir -Filter "*.omp.json" -ErrorAction SilentlyContinue
            if (`$availableThemes) {
                `$themePath = `$availableThemes[0].FullName
            }
        }
    }
    
    if (Test-Path `$themePath) {
        oh-my-posh init pwsh --config "`$themePath" | Invoke-Expression
        `$themeName = (Get-Item `$themePath).BaseName
        Add-Content -Path `$logFile -Value "[`$(Get-Date)] Theme loaded successfully: `$themeName"
    } else {
        Add-Content -Path `$logFile -Value "[`$(Get-Date)] No themes found, run Update-OMPThemes.ps1"
    }
} catch {
    Add-Content -Path `$logFile -Value "[`$(Get-Date)] Oh My Posh initialization failed: `$(`$_.Exception.Message)"
}

function Set-OMPTheme {
    param([string]`$name)
    
    # Handle special commands
    if (`$name -eq "reset") {
        `$preferenceFile = Join-Path `$ompBaseDir ".theme-preference"
        if (Test-Path `$preferenceFile) {
            Remove-Item `$preferenceFile -Force -ErrorAction SilentlyContinue
            Add-Content -Path `$logFile -Value "[`$(Get-Date)] Theme preference reset"
            
            # Reload the profile to apply default theme immediately
            try {
                . `$PROFILE
                Add-Content -Path `$logFile -Value "[`$(Get-Date)] Profile reloaded, default theme applied"
            } catch {
                Add-Content -Path `$logFile -Value "[`$(Get-Date)] Profile reload failed: `$(`$_.Exception.Message)"
            }
        } else {
            Add-Content -Path `$logFile -Value "[`$(Get-Date)] No theme preference to reset"
        }
        return
    }
    
    if (`$name -eq "current") {
        `$preferenceFile = Join-Path `$ompBaseDir ".theme-preference"
        if (Test-Path `$preferenceFile) {
            try {
                `$currentTheme = Get-Content `$preferenceFile -Raw -ErrorAction Stop | ForEach-Object { `$_.Trim() }
                if (-not [string]::IsNullOrEmpty(`$currentTheme)) {
                    Write-Host "Current theme: `$currentTheme" -ForegroundColor Green
                    return
                }
            } catch {
                Add-Content -Path `$logFile -Value "[`$(Get-Date)] Error reading current theme: `$(`$_.Exception.Message)"
            }
        }
        Write-Host "No theme preference set. Using default theme." -ForegroundColor Gray
        return
    }
    
    # Validate parameter
    if ([string]::IsNullOrEmpty(`$name)) {
        Write-Host "Usage: theme <theme-name> | theme current | theme reset" -ForegroundColor Yellow
        Write-Host "Examples:" -ForegroundColor Gray
        Write-Host "  theme jandedobbeleer    - Switch to jandedobbeleer theme" -ForegroundColor Gray
        Write-Host "  theme current           - Show current theme preference" -ForegroundColor Gray
        Write-Host "  theme reset             - Reset to default theme" -ForegroundColor Gray
        Write-Host "`nAvailable themes:" -ForegroundColor Yellow
        
        # Use POSH_THEMES_PATH environment variable
        `$themesDir = `$env:POSH_THEMES_PATH
        
        if (Test-Path `$themesDir) {
            Get-ChildItem `$themesDir -Filter "*.omp.json" | ForEach-Object { 
                `$cleanName = `$_.BaseName -replace '\.omp$', ''
                Write-Host "  - `$cleanName" -ForegroundColor Gray 
            }
        } else {
            Write-Host "  Themes directory not found. Run Update-OMPThemes.ps1 first." -ForegroundColor Red
        }
        return
    }
    
    # Auto-append .omp.json if not provided
    if (-not `$name.EndsWith('.omp.json')) {
        `$name = "`$name.omp.json"
    }
    
    # Use POSH_THEMES_PATH environment variable
    `$themesDir = `$env:POSH_THEMES_PATH
    
    `$themePath = Join-Path `$themesDir `$name
    if (Test-Path `$themePath) {
        # Apply the theme
        oh-my-posh init pwsh --config "`$themePath" | Invoke-Expression
        
        # Save user preference
        `$preferenceFile = Join-Path `$ompBaseDir ".theme-preference"
        `$themeNameWithoutExt = `$name -replace '\.omp\.json$', ''
        Set-Content -Path `$preferenceFile -Value `$themeNameWithoutExt -Encoding UTF8
        
        # Log successful theme switch
        Add-Content -Path `$logFile -Value "[`$(Get-Date)] Theme switched to: `$themeNameWithoutExt"
        Write-Host "Theme switched to: `$themeNameWithoutExt" -ForegroundColor Green
    } else {
        # Show theme name without extension for cleaner error message
        `$themeNameWithoutExt = `$name -replace '\.omp\.json$', ''
        Add-Content -Path `$logFile -Value "[`$(Get-Date)] Theme not found: `$themeNameWithoutExt"
        Write-Host "Theme not found: `$themeNameWithoutExt" -ForegroundColor Red
        Write-Host "Available themes:" -ForegroundColor Yellow
        if (Test-Path `$themesDir) {
            Get-ChildItem `$themesDir -Filter "*.omp.json" | ForEach-Object { 
                `$cleanName = `$_.BaseName -replace '\.omp$', ''
                Write-Host "  - `$cleanName" -ForegroundColor Gray 
            }
        } else {
            Add-Content -Path `$logFile -Value "[`$(Get-Date)] Themes directory not found"
            Write-Host "  Themes directory not found. Run Update-OMPThemes.ps1 first." -ForegroundColor Red
        }
    }
}



# Function to show welcome message again
function Show-OMPWelcome {
    Write-Host "`nWelcome to PowerShell 7 Plus!" -ForegroundColor Cyan
    Write-Host "Thank you for using our enhanced PowerShell environment!" -ForegroundColor Green
    Write-Host "`nTheme Management Commands:" -ForegroundColor Yellow
    Write-Host "  • theme <name>     - Switch to a theme (e.g., theme dracula)" -ForegroundColor Gray
    Write-Host "  • theme current    - Show current theme preference" -ForegroundColor Gray
    Write-Host "  • theme reset      - Reset to default theme" -ForegroundColor Gray
    Write-Host "  • theme            - Show help and available themes" -ForegroundColor Gray
    Write-Host "  • welcome         - Show this welcome message again" -ForegroundColor Gray
    Write-Host "`nEnjoy your enhanced PowerShell experience!" -ForegroundColor Magenta
}

# Set aliases for theme management
Set-Alias -Name theme -Value Set-OMPTheme -Scope Global -ErrorAction SilentlyContinue
Set-Alias -Name welcome -Value Show-OMPWelcome -Scope Global -ErrorAction SilentlyContinue
# END: Oh My Posh init block
"@

# Replace or inject Oh My Posh logic into profile
$profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue

if ($profileContent -and (Select-String -Path $PROFILE -Pattern "BEGIN: Oh My Posh init block" -Quiet)) {
    # Remove old Oh My Posh block and add new one
    $profileContent = $profileContent -replace '(?s)# BEGIN: Oh My Posh init block.*?# END: Oh My Posh init block', ''
    $profileContent = $profileContent.TrimEnd() + "`n`n$initBlock"
    Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
    Write-Host "Replaced old Oh My Posh logic with updated version." -ForegroundColor Green
}
else {
    # Add new Oh My Posh block
    Add-Content -Path $PROFILE -Value "`n$initBlock"
    Write-Host "Injected Oh My Posh logic into profile." -ForegroundColor Green
}

# Step 9: Sanitize profile
Write-Host "`nStep 9: Sanitize PowerShell profile" -ForegroundColor Cyan
$content = Get-Content $PROFILE -Raw
# Only remove extra blank lines, don't remove parameter declarations
$fixed = $content -replace '(\r?\n){3,}', "`r`n`r`n"
Set-Content -Path $PROFILE -Value $fixed -Encoding UTF8
Write-Host "Profile sanitized." -ForegroundColor Green

# Step 10: Run Update-OMPThemes.ps1
Write-Host "`nStep 10: Run Update-OMPThemes.ps1" -ForegroundColor Cyan
$updateScript = Join-Path $scriptDir "Update-OMPThemes.ps1"
if (Test-Path $updateScript) {
    Write-Host "Running Update-OMPThemes.ps1..." -ForegroundColor Yellow
    try {
        & $updateScript
    }
    catch {
        $errorMsg = "Failed to run Update-OMPThemes.ps1: $($_.Exception.Message)"
        Write-ErrorLog -Script "Install-OMPEnv.ps1" -ErrorType "THEME_UPDATE_ERROR" -Description $errorMsg
    }
}
else {
    Write-Host "Update-OMPThemes.ps1 not found. Skipping." -ForegroundColor DarkYellow
    Write-ErrorLog -Script "Install-OMPEnv.ps1" -ErrorType "MISSING_FILE" -Description "Update-OMPThemes.ps1 not found in script directory"
}

# Step 11: Set PowerShell 7 as default shell
Write-Host "`nStep 11: Set PowerShell 7 as default shell" -ForegroundColor Cyan

# Set PowerShell 7 as default for .ps1 files
try {
    $ps1Association = (Get-ItemProperty -Path "HKCR:\Microsoft.PowerShellScript.1\Shell\0\Command" -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
    if ($ps1Association -and $ps1Association -notlike "*pwsh.exe*") {
        Set-ItemProperty -Path "HKCR:\Microsoft.PowerShellScript.1\Shell\0\Command" -Name "(Default)" -Value '"C:\Program Files\PowerShell\7\pwsh.exe" "%1" %*'
        Write-Host "Set PowerShell 7 as default for .ps1 files" -ForegroundColor Green
    }
    else {
        Write-Host "PowerShell 7 already default for .ps1 files" -ForegroundColor Gray
    }
}
catch {
    Write-Host "Could not set PowerShell 7 as default for .ps1 files" -ForegroundColor Yellow
}

# Step 12: Refresh environment variables
Write-Host "`nStep 12: Refresh environment variables" -ForegroundColor Cyan
try {
    # Try to use refreshenv if available (from Chocolatey)
    refreshenv
    Write-Host "Environment variables refreshed using refreshenv." -ForegroundColor Green
}
catch {
    # Manual PATH refresh if refreshenv is not available
    Write-Host "refreshenv not available, manually refreshing PATH..." -ForegroundColor Yellow
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $env:PATH = "$machinePath;$userPath"
    Write-Host "PATH manually refreshed." -ForegroundColor Green
}

# # Step 13: Reload profile
# Write-Host "`nStep 13: Reload PowerShell profile" -ForegroundColor Cyan
# . $PROFILE
# Write-Host "PowerShell profile reloaded." -ForegroundColor Green

# Step 14: Restart terminal
Write-Host "`nStep 14: Restart terminal" -ForegroundColor Cyan
Start-Sleep -Seconds 2
Start-Process wt.exe

# Step 15: Close current terminal
[System.Environment]::Exit(0)