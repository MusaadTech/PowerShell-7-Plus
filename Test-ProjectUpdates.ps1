function Test-ProjectUpdates {
  [CmdletBinding()]
  param(
    [switch]$Silent
  )
    
  try {
    $scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    $versionFile = Join-Path $scriptDir "version.txt"
        
    $currentVersion = if (Test-Path $versionFile) { Get-Content $versionFile } else { "1.0.0" }
        
    $repoApi = "https://api.github.com/repos/MusaadTech/terminal-customization/releases/latest"
    $latestRelease = Invoke-RestMethod -Uri $repoApi -Headers @{ "User-Agent" = "PowerShell" }
    $latestVersion = $latestRelease.tag_name -replace '^v', ''
        
    if ([Version]$latestVersion -gt [Version]$currentVersion) {
      if (-not $Silent) {
        Add-Type -AssemblyName System.Windows.Forms
        $message = @"
A new version of Terminal Customization is available!

  - Your Version: v$currentVersion
  - Latest Version: v$latestVersion

Changelog:
$($latestRelease.body)

Would you like to download and install the update now?
"@
        $caption = "🎉 New Update Available"
        $buttons = [System.Windows.Forms.MessageBoxButtons]::YesNo
        $icon = [System.Windows.Forms.MessageBoxIcon]::Information
        $result = [System.Windows.Forms.MessageBox]::Show($message, $caption, $buttons, $icon)

        if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
          Update-Project -DownloadUrl $latestRelease.zipball_url -Version $latestVersion -ScriptDir $scriptDir
        }
        else {
          Write-Host "User declined the update." -ForegroundColor Yellow
        }
      }
    }
    else {
      if (-not $Silent) {
        Write-Host "✅ You're running the latest version (v$currentVersion)" -ForegroundColor Green
      }
    }
  }
  catch {
    # Fail silently in silent mode
    if (-not $Silent) {
      Write-Host "❌ Failed to check for updates: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
}

function Update-Project {
  [CmdletBinding()]
  param(
    [string]$DownloadUrl,
    [string]$Version,
    [string]$ScriptDir
  )
    
  Write-Host "`n🔄 Starting safe update process..." -ForegroundColor Cyan

  # 1. Save current theme
  $currentTheme = $null
  try {
    $profileContent = Get-Content $PROFILE -Raw
    $themeMatch = [regex]::Match($profileContent, 'oh-my-posh init pwsh --config "([^"]+)"')
    if ($themeMatch.Success) {
      $currentTheme = Split-Path $themeMatch.Groups[1].Value -Leaf
      Write-Host "✅ Current theme saved: $currentTheme" -ForegroundColor Green
    }
  }
  catch {
    Write-Host "⚠️ Could not determine current theme. Will default to 'jandedobbeleer'." -ForegroundColor Yellow
  }

  # 2. Smart backup
  $backupDir = Join-Path $ScriptDir "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
  New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
  Copy-Item -Path (Join-Path $ScriptDir "oh-my-posh") -Destination $backupDir -Recurse -Force
  Copy-Item -Path (Join-Path $ScriptDir "errors.log") -Destination $backupDir -ErrorAction SilentlyContinue
  Write-Host "✅ User data backed up to: $backupDir" -ForegroundColor Green

  # 3. Download and extract to temp location
  $tempDir = Join-Path $env:TEMP "omp-update-$(New-Guid)"
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
  $zipPath = Join-Path $tempDir "update.zip"
  Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipPath
  Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
    
  # Find the extracted folder name (it's usually dynamic)
  $extractedDir = Get-ChildItem -Path $tempDir -Directory | Select-Object -First 1
  if (-not $extractedDir) {
    Write-Host "❌ Could not find extracted folder in temp directory." -ForegroundColor Red
    return
  }

  # 4. Clean old script files
  Get-ChildItem -Path $ScriptDir -File -Exclude "*.log", "version.txt" | Remove-Item -Force
  Write-Host "✅ Old script files removed." -ForegroundColor Green

  # 5. Copy new files from temp
  Copy-Item -Path (Join-Path $extractedDir.FullName "*") -Destination $ScriptDir -Recurse -Force
  Write-Host "✅ New version files copied." -ForegroundColor Green

  # 6. Restore user data
  Copy-Item -Path (Join-Path $backupDir "oh-my-posh") -Destination $ScriptDir -Recurse -Force
    
  # 7. Re-apply theme
  if ($currentTheme) {
    # This assumes the new profile has the Set-OMPTheme function.
    # A more robust solution might edit the profile file directly.
    . (Join-Path $ScriptDir "Install-OMPEnv.ps1") # Load functions
    # This is tricky because we can't just call Set-OMPTheme here.
    # The best way is to modify the profile file to set the theme.
    $newProfileContent = Get-Content $PROFILE -Raw
    $newProfileContent = $newProfileContent -replace 'Set-OMPTheme "\w+"', "Set-OMPTheme `"$($currentTheme.Replace('.omp.json',''))`""
    Set-Content -Path $PROFILE -Value $newProfileContent -Encoding UTF8
    Write-Host "✅ User theme '$currentTheme' restored in profile." -ForegroundColor Green
  }
    
  # 8. Update version file
  Set-Content -Path (Join-Path $ScriptDir "version.txt") -Value $Version

  # 9. Cleanup
  Remove-Item -Path $tempDir -Recurse -Force
    
  Write-Host "✅ Update completed successfully!" -ForegroundColor Green
  Write-Host "Please restart your terminal to apply changes." -ForegroundColor Yellow
}

# Allow script to be executed directly
if ($null -eq $MyInvocation.MyCommand.CommandType) {
  Test-ProjectUpdates
}
