Write-Host "WARNING: This script will completely remove your PowerShell 7 + Oh My Posh environment!" -ForegroundColor Red
Write-Host "This action is IRREVERSIBLE and will delete:" -ForegroundColor Yellow
Write-Host "  * All Oh My Posh themes and configurations" -ForegroundColor Red
Write-Host "  * Your PowerShell profile with customizations" -ForegroundColor Red
Write-Host "  * PowerShell 7 installation" -ForegroundColor Red
Write-Host "  * Oh My Posh installation" -ForegroundColor Red
Write-Host "  * Windows Terminal profile settings" -ForegroundColor Red
Write-Host "  * Scheduled theme updates" -ForegroundColor Red
Write-Host ""

# Get user confirmation
$confirmation = Read-Host "Are you absolutely sure you want to continue? Type 'YES' to confirm"
if ($confirmation -ne "YES") {
    Write-Host "`nReset cancelled. Your environment remains unchanged." -ForegroundColor Green
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    [System.Environment]::Exit(0)
}

Write-Host "`nUser confirmed. Proceeding with complete environment reset..." -ForegroundColor DarkRed
Write-Host "Resetting PowerShell + Oh My Posh environment..." -ForegroundColor DarkRed

# Get script directory
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ompDir = Join-Path $scriptDir "oh-my-posh"

# Error logging function
function Write-ErrorLog {
    param(
        [string]$Script,
        [string]$ErrorType,
        [string]$Description
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Script] [$ErrorType] - $Description"
    $errorLogFile = Join-Path $scriptDir "errors.log"
    
    # Create file with header if it doesn't exist
    if (-not (Test-Path $errorLogFile)) {
        $header = @"
# Terminal Customization - Error Log
# This file tracks errors and issues encountered during installation or usage
# Format: [TIMESTAMP] [SCRIPT] [ERROR_TYPE] - [DESCRIPTION]
# Created: $timestamp

"@
        Set-Content -Path $errorLogFile -Value $header -Encoding UTF8
    }
    
    Add-Content -Path $errorLogFile -Value $logEntry
    Write-Host "Error logged: $Description" -ForegroundColor Red
}

# Step 1: Delete oh-my-posh directory
Write-Host "`nStep 1: Delete oh-my-posh directory" -ForegroundColor Yellow
if (Test-Path $ompDir) {
    Remove-Item -Path $ompDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Deleted directory: $ompDir" -ForegroundColor Red
}

# Step 2: Unregister scheduled task
Write-Host "`nStep 2: Unregister scheduled task" -ForegroundColor Yellow
$taskName = "Update Oh My Posh Themes"
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Removed scheduled task: $taskName" -ForegroundColor Red
}

# Step 3: Remove PowerShell profile
Write-Host "`nStep 3: Remove PowerShell profile" -ForegroundColor Yellow
if (Test-Path $PROFILE) {
    Remove-Item -Path $PROFILE -Force -ErrorAction SilentlyContinue
    Write-Host "Removed PowerShell profile: $PROFILE" -ForegroundColor Red
}

# Step 4: Uninstall Oh My Posh
Write-Host "`nStep 4: Uninstall Oh My Posh" -ForegroundColor Yellow
Write-Host "Uninstalling Oh My Posh via winget..." -ForegroundColor Red
try {
    winget uninstall JanDeDobbeleer.OhMyPosh -e --silent | Out-Null
}
catch {
    $errorMsg = "Failed to uninstall Oh My Posh: $($_.Exception.Message)"
    Write-ErrorLog -Script "Reset-OMPEnv.ps1" -ErrorType "UNINSTALL_ERROR" -Description $errorMsg
}

# Step 5: Remove Oh My Posh entries from user PATH
Write-Host "`nStep 5: Remove Oh My Posh entries from user PATH" -ForegroundColor Yellow
$envPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$paths = $envPath -split ";"
$filtered = $paths | Where-Object { $_ -notmatch "oh-my-posh" }
$newPath = ($filtered -join ";").TrimEnd(";")
[Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
Write-Host "Removed oh-my-posh from PATH (User scope)." -ForegroundColor Red

# Step 6: Uninstall PowerShell 7
Write-Host "`nStep 6: Uninstall PowerShell 7" -ForegroundColor Yellow
Write-Host "Uninstalling PowerShell 7 via winget..." -ForegroundColor Red
try {
    winget uninstall Microsoft.PowerShell -e --silent | Out-Null
}
catch {
    $errorMsg = "Failed to uninstall PowerShell 7: $($_.Exception.Message)"
    Write-ErrorLog -Script "Reset-OMPEnv.ps1" -ErrorType "UNINSTALL_ERROR" -Description $errorMsg
}

# Step 7: Reset default profile in Windows Terminal settings
Write-Host "`nStep 7: Reset default profile in Windows Terminal settings" -ForegroundColor Blue
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json"
$profileJson = Get-ChildItem -Path $settingsPath -ErrorAction SilentlyContinue | Select-Object -First 1
if ($profileJson) {
    $settings = Get-Content $profileJson.FullName -Raw | ConvertFrom-Json
    $settings.defaultProfile = $null
    $settings | ConvertTo-Json -Depth 99 | Set-Content -Path $profileJson.FullName -Encoding UTF8
    Write-Host "Reset Windows Terminal default profile." -ForegroundColor Green
}

# Step 8: Restart terminal
Write-Host "`nStep 8: Restart terminal" -ForegroundColor Yellow
Write-Host ""
Write-Host "Reset complete. Restarting Windows Terminal..." -ForegroundColor Green
Start-Sleep -Seconds 2
Start-Process wt.exe

# Step 9: Close current terminal
[System.Environment]::Exit(0)