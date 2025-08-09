# Setup paths
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$ompBaseDir = Join-Path $scriptDir "oh-my-posh"
$themesDir = Join-Path $ompBaseDir "themes"
$countLog = Join-Path $ompBaseDir "theme-count.log"
$logFile = Join-Path $ompBaseDir "update.log"

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

# Create directories
if (-not (Test-Path $ompBaseDir)) {
    New-Item -ItemType Directory -Path $ompBaseDir -Force | Out-Null
}
New-Item -ItemType Directory -Path $themesDir -Force | Out-Null

# GitHub API for themes
$themesApi = "https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/contents/themes"
try {
    $response = Invoke-RestMethod -Uri $themesApi -Headers @{ "User-Agent" = "PowerShell" }
}
catch {
    $errorMsg = "Failed to fetch themes from GitHub API: $($_.Exception.Message)"
    Write-ErrorLog -Script "Update-OMPThemes.ps1" -ErrorType "API_ERROR" -Description $errorMsg
    Write-Host "Failed to fetch themes from GitHub. Check your internet connection." -ForegroundColor Red
    exit 1
}

# Filter valid .omp.json files
$themeFiles = $response | Where-Object { $_.name -like "*.omp.json" }
$currentCount = $themeFiles.Count
$now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# Load previous count (if exists)
$previousCount = if (Test-Path $countLog) {
    Get-Content $countLog | Select-Object -First 1
}
else {
    "0"
}

# Check if update is needed
if ([int]$previousCount -eq $currentCount) {
    $msg = "$now - No new themes. Total count: $currentCount. Skipped download."
    Write-Host $msg -ForegroundColor Yellow
    Add-Content -Path $logFile -Value $msg
    return
}

# Download themes with progress
$total = $themeFiles.Count
$padLength = ($themeFiles | ForEach-Object { $_.name.Length } | Measure-Object -Maximum).Maximum

for ($i = 0; $i -lt $total; $i++) {
    $file = $themeFiles[$i]
    $name = $file.name.PadRight($padLength)
    $themePath = Join-Path $themesDir $file.name
    $completion = [int](($i / $total) * 100)
    $status = "$name - $completion%"

    Write-Progress -Activity "Downloading Oh My Posh Themes" `
        -Status $status `
        -PercentComplete (($i / $total) * 100)

    try {
        Invoke-WebRequest -Uri $file.download_url `
            -OutFile $themePath `
            -UseBasicParsing `
            -Headers @{ "User-Agent" = "PowerShell" }
    }
    catch {
        $errorMsg = "Failed to download theme $($file.name): $($_.Exception.Message)"
        Write-ErrorLog -Script "Update-OMPThemes.ps1" -ErrorType "DOWNLOAD_ERROR" -Description $errorMsg
        Write-Host "Failed to download theme: $($file.name)" -ForegroundColor Red
    }
}

Write-Progress -Activity "Download Complete" -Completed
$currentCount | Out-File $countLog -Encoding ascii -Force

$msg = "$now - Downloaded and updated $currentCount themes."
Write-Host "`n$msg" -ForegroundColor Green
Add-Content -Path $logFile -Value $msg

