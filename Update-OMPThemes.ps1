function Update-Themes {
    # Setup paths
    $scriptDir = $env:TERMINAL_CUSTOMIZATION_PATH
    if (-not $scriptDir) {
        # Fallback for direct execution, though not the primary method
        $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    }
    $ompBaseDir = Join-Path $scriptDir "oh-my-posh"
    $themesDir = Join-Path $ompBaseDir "themes"
    $countLog = Join-Path $ompBaseDir "theme-count.log"
    $logFile = Join-Path $ompBaseDir "update.log"

    # Error logging function
    function Write-ErrorLog-Themes {
        # Renamed to avoid conflict if sourced
        param(
            [string]$Script,
            [string]$ErrorType,
            [string]$Description
        )
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Script] [$ErrorType] - $Description"
        $errorLogFile = Join-Path $scriptDir "errors.log"
        
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
        Write-ErrorLog-Themes -Script "Update-OMPThemes.ps1" -ErrorType "API_ERROR" -Description $errorMsg
        return # Exit function on failure
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
        Add-Content -Path $logFile -Value $msg
        return
    }

    # Download themes
    foreach ($file in $themeFiles) {
        $themePath = Join-Path $themesDir $file.name
        try {
            Invoke-WebRequest -Uri $file.download_url `
                -OutFile $themePath `
                -UseBasicParsing `
                -Headers @{ "User-Agent" = "PowerShell" }
        }
        catch {
            $errorMsg = "Failed to download theme $($file.name): $($_.Exception.Message)"
            Write-ErrorLog-Themes -Script "Update-OMPThemes.ps1" -ErrorType "DOWNLOAD_ERROR" -Description $errorMsg
        }
    }

    $currentCount | Out-File $countLog -Encoding ascii -Force
    $msg = "$now - Downloaded and updated $currentCount themes."
    Add-Content -Path $logFile -Value $msg
}

# Allow script to be executed directly
if ($null -eq $MyInvocation.MyCommand.CommandType) {
    Update-Themes
}
