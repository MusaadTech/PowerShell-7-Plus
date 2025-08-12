Write-Host "Setting up PowerShell 7 + Oh My Posh environment..." -ForegroundColor DarkRed

# Step 0: Ask user to close all open terminal sessions
Write-Host "`nStep 0: Close all open terminal sessions" -ForegroundColor Cyan
$closeTerminals = Read-Host "Do you want to close all open terminal sessions? (y/n)"

if ($closeTerminals -eq "y" -or $closeTerminals -eq "Y") {
    Write-Host "Closing all open terminal sessions..." -ForegroundColor Yellow
    
    try {
        # Get current process ID and session ID to avoid closing the current terminal
        $currentPID = $PID
        $currentSessionId = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
        
        Write-Host "Current process ID: $currentPID" -ForegroundColor Gray
        Write-Host "Current session ID: $currentSessionId" -ForegroundColor Gray
        
        # Find all Windows Terminal processes, but exclude the current session
        $allTerminalProcesses = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue
        
        if ($allTerminalProcesses) {
            Write-Host "Found $($allTerminalProcesses.Count) Windows Terminal processes total." -ForegroundColor Gray
            
            # Filter out processes from the current session
            $terminalProcessesToClose = $allTerminalProcesses | Where-Object { 
                $_.SessionId -ne $currentSessionId
            }
            
            if ($terminalProcessesToClose) {
                Write-Host "Found $($terminalProcessesToClose.Count) terminal sessions from other sessions to close. Closing them..." -ForegroundColor Yellow
                $terminalProcessesToClose | ForEach-Object {
                    Write-Host "Closing terminal process ID: $($_.Id) from session: $($_.SessionId)" -ForegroundColor Gray
                    try {
                        Stop-Process -Id $_.Id -Force -ErrorAction Stop
                        Write-Host "Successfully closed terminal process ID: $($_.Id)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Failed to close terminal process ID: $($_.Id): $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
                Write-Host "All other terminal sessions closed successfully." -ForegroundColor Green
            }
            else {
                Write-Host "No other terminal sessions found to close." -ForegroundColor Gray
            }
        }
        else {
            Write-Host "No Windows Terminal processes found." -ForegroundColor Gray
        }
        
        # Also try to close any other PowerShell processes from other sessions
        $allPowerShellProcesses = Get-Process -Name "powershell", "pwsh" -ErrorAction SilentlyContinue
        
        if ($allPowerShellProcesses) {
            Write-Host "Found $($allPowerShellProcesses.Count) PowerShell processes total." -ForegroundColor Gray
            
            # Filter out processes from the current session
            $powerShellProcessesToClose = $allPowerShellProcesses | Where-Object { 
                $_.SessionId -ne $currentSessionId
            }
            
            if ($powerShellProcessesToClose) {
                Write-Host "Found $($powerShellProcessesToClose.Count) PowerShell processes from other sessions to close. Closing them..." -ForegroundColor Yellow
                $powerShellProcessesToClose | ForEach-Object {
                    Write-Host "Closing PowerShell process ID: $($_.Id) from session: $($_.SessionId)" -ForegroundColor Gray
                    try {
                        Stop-Process -Id $_.Id -Force -ErrorAction Stop
                        Write-Host "Successfully closed PowerShell process ID: $($_.Id)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Failed to close PowerShell process ID: $($_.Id): $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
                Write-Host "All other PowerShell processes closed successfully." -ForegroundColor Green
            }
            else {
                Write-Host "No other PowerShell processes found to close." -ForegroundColor Gray
            }
        }
        
        Start-Sleep -Seconds 1
    }
    catch {
        Write-Host "Warning: Could not close all terminal sessions: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Continuing with installation..." -ForegroundColor Gray
    }
}
else {
    Write-Host "`nInstallation cannot proceed without closing other terminal sessions." -ForegroundColor Red
    Write-Host "This is necessary to prevent conflicts during the installation process." -ForegroundColor Yellow
    Write-Host "`nPlease close all other terminal windows manually and run this script again." -ForegroundColor Cyan
    Write-Host "`nApologies for the inconvenience, but this step is required for a successful installation." -ForegroundColor Magenta
    Write-Host "`nPress any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    [System.Environment]::Exit(1)
}

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

# Also set it for current session
$env:POSH_THEMES_PATH = $themesDir

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
try {
    `$ompExe = Get-Command "oh-my-posh.exe" -ErrorAction Stop
    
    # Use POSH_THEMES_PATH environment variable
    `$themesDir = `$env:POSH_THEMES_PATH
    
    # Try to find a theme file
    `$themePath = Join-Path -Path `$themesDir -ChildPath "jandedobbeleer.omp.json"
    if (-not (Test-Path `$themePath)) {
        # If default theme doesn't exist, try to find any available theme
        `$availableThemes = Get-ChildItem -Path `$themesDir -Filter "*.omp.json" -ErrorAction SilentlyContinue
        if (`$availableThemes) {
            `$themePath = `$availableThemes[0].FullName
        }
    }
    
    if (Test-Path `$themePath) {
        oh-my-posh init pwsh --config "`$themePath" | Invoke-Expression
    } else {
        Write-Host "No themes found. Run Update-OMPThemes.ps1 to download themes." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Oh My Posh not available in PATH. Skipping prompt setup." -ForegroundColor Yellow
}

function Set-OMPTheme {
    param([string]`$name)
    
    # Validate parameter
    if ([string]::IsNullOrEmpty(`$name)) {
        Write-Host "Usage: Set-OMPTheme <theme-name> (or theme <theme-name>)" -ForegroundColor Yellow
        Write-Host "Example: Set-OMPTheme jandedobbeleer" -ForegroundColor Gray
        Write-Host "Available themes:" -ForegroundColor Yellow
        
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
        oh-my-posh init pwsh --config "`$themePath" | Invoke-Expression
        `$themeNameWithoutExt = `$name -replace '\.omp\.json$', ''
        Write-Host "Theme switched to: `$themeNameWithoutExt" -ForegroundColor Green
    } else {
        # Show theme name without extension for cleaner error message
        `$themeNameWithoutExt = `$name -replace '\.omp\.json$', ''
        Write-Host "Theme not found: `$themeNameWithoutExt" -ForegroundColor Red
        Write-Host "Available themes:" -ForegroundColor Yellow
        if (Test-Path `$themesDir) {
            Get-ChildItem `$themesDir -Filter "*.omp.json" | ForEach-Object { 
                `$cleanName = `$_.BaseName -replace '\.omp$', ''
                Write-Host "  - `$cleanName" -ForegroundColor Gray 
            }
        } else {
            Write-Host "  Themes directory not found. Run Update-OMPThemes.ps1 first." -ForegroundColor Red
        }
    }
}

# Set alias for theme switching
Set-Alias -Name theme -Value Set-OMPTheme -Scope Global -ErrorAction SilentlyContinue
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

# Step 13: Reload profile
Write-Host "`nStep 13: Reload PowerShell profile" -ForegroundColor Cyan
. $PROFILE
Write-Host "PowerShell profile reloaded." -ForegroundColor Green

# Step 14: Restart terminal
Write-Host "`nStep 14: Restart terminal" -ForegroundColor Cyan
Start-Sleep -Seconds 2
Start-Process wt.exe

# Step 15: Close current terminal
[System.Environment]::Exit(0)