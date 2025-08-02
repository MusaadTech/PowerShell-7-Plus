Write-Host "Setting up PowerShell 7 + Oh My Posh environment..." -ForegroundColor DarkRed

# Define script and theme paths (relative to script location)
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ompBaseDir = Join-Path $scriptDir "oh-my-posh"
$themesDir = Join-Path $ompBaseDir "themes"

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
    winget install JanDeDobbeleer.OhMyPosh --source winget --silent
    Start-Sleep -Seconds 2
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
        Write-Host "Failed to install or locate Oh My Posh. Please install manually:" -ForegroundColor Red
        Write-Host "1. Run: winget install JanDeDobbeleer.OhMyPosh --source winget" -ForegroundColor Yellow
        Write-Host "2. Or download from: https://ohmyposh.dev/docs/installation/windows" -ForegroundColor Yellow
        Write-Host "3. Then re-run this script." -ForegroundColor Yellow
        exit 1
    }
}

# Step 4: Create PowerShell profile if not exists
Write-Host "`nStep 4: Create PowerShell profile" -ForegroundColor Cyan
if (-not (Test-Path -Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "Created PowerShell profile: $PROFILE" -ForegroundColor Green
}

# Step 5: Inject dynamic Oh My Posh init logic into profile
Write-Host "`nStep 5: Append OMP init + theme switcher to profile" -ForegroundColor Cyan

$initBlock = @"
# BEGIN: Oh My Posh init block
try {
    \$ompExe = Get-Command "oh-my-posh.exe" -ErrorAction Stop
    \$themePath = Join-Path -Path "$themesDir" -ChildPath "jandedobbeleer.omp.json"
    oh-my-posh init pwsh --config "`\$themePath" | Invoke-Expression
} catch {
    Write-Host "Oh My Posh not available in PATH. Skipping prompt setup." -ForegroundColor Yellow
}

function Set-OMPTheme {
    param([string]\$name)
    
    # Auto-append .omp.json if not provided
    if (-not \$name.EndsWith('.omp.json')) {
        \$name = "\$name.omp.json"
    }
    
    \$themePath = Join-Path "$themesDir" \$name
    if (Test-Path \$themePath) {
        oh-my-posh init pwsh --config "\$themePath" | Invoke-Expression
        Write-Host "Theme switched to: \$name" -ForegroundColor Green
    } else {
        Write-Host "Theme not found: \$name" -ForegroundColor Red
        Write-Host "Available themes:" -ForegroundColor Yellow
        Get-ChildItem "$themesDir" -Filter "*.omp.json" | ForEach-Object { Write-Host "  - \$(\$_.BaseName)" -ForegroundColor Gray }
    }
}
# END: Oh My Posh init block
"@

# Avoid duplicate injection
if (-not (Select-String -Path $PROFILE -Pattern "BEGIN: Oh My Posh init block" -Quiet)) {
    Add-Content -Path $PROFILE -Value "`n$initBlock"
    Write-Host "Injected Oh My Posh logic into profile." -ForegroundColor Green
}
else {
    Write-Host "Oh My Posh logic already exists in profile." -ForegroundColor Gray
}

# Step 6: Sanitize profile
Write-Host "`nStep 6: Sanitize PowerShell profile" -ForegroundColor Cyan
$content = Get-Content $PROFILE -Raw
$fixed = $content -replace 'param\([^\)]*\)', ''
$fixed = $fixed -replace '(\r?\n){3,}', "`r`n`r`n"
Set-Content -Path $PROFILE -Value $fixed -Encoding UTF8
Write-Host "Profile sanitized." -ForegroundColor Green

# Step 7: Run Update-OMPThemes.ps1
Write-Host "`nStep 7: Run Update-OMPThemes.ps1" -ForegroundColor Cyan
$updateScript = Join-Path $scriptDir "Update-OMPThemes.ps1"
if (Test-Path $updateScript) {
    Write-Host "Running Update-OMPThemes.ps1..." -ForegroundColor Yellow
    & $updateScript
}
else {
    Write-Host "Update-OMPThemes.ps1 not found. Skipping." -ForegroundColor DarkYellow
}

# Step 8: Set PowerShell 7 as default shell
Write-Host "`nStep 8: Set PowerShell 7 as default shell" -ForegroundColor Cyan

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

# Configure Windows Terminal to use PowerShell 7 as default (if available)
try {
    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json"
    $wtProfile = Get-ChildItem -Path $wtSettingsPath -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($wtProfile) {
        $settings = Get-Content $wtProfile.FullName -Raw | ConvertFrom-Json
        
        # Find PowerShell 7 profile GUID
        $pwsh7Profile = $settings.profiles.list | Where-Object { $_.name -eq "PowerShell 7" -or $_.source -eq "Windows.Terminal.PowershellCore" }
        if ($pwsh7Profile) {
            $settings.defaultProfile = $pwsh7Profile.guid
            $settings | ConvertTo-Json -Depth 99 | Set-Content -Path $wtProfile.FullName -Encoding UTF8
            Write-Host "Set PowerShell 7 as default in Windows Terminal (GUID: $($pwsh7Profile.guid))" -ForegroundColor Green
        }
        else {
            Write-Host "PowerShell 7 profile not found in Windows Terminal" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Windows Terminal not found, skipping default profile setting" -ForegroundColor Gray
    }
}
catch {
    Write-Host "Could not configure Windows Terminal default profile" -ForegroundColor Yellow
}

# Step 9: Refresh environment variables
Write-Host "`nStep 9: Refresh environment variables" -ForegroundColor Cyan
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

# Step 10: Reload profile
Write-Host "`nStep 10: Reload PowerShell profile" -ForegroundColor Cyan
. $PROFILE
Write-Host "PowerShell profile reloaded." -ForegroundColor Green

# Step 11: Restart terminal
Write-Host "`nStep 11: Restart terminal" -ForegroundColor Cyan
Start-Sleep -Seconds 2
Start-Process wt.exe

# Step 12: Close current terminal
[System.Environment]::Exit(0)