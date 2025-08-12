# PowerShell 7 + Oh My Posh Environment Setup

> **Automated PowerShell environment setup with modern theming and customization**

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Oh My Posh](https://img.shields.io/badge/Oh%20My%20Posh-Latest-green.svg)](https://ohmyposh.dev/)
[![Windows](https://img.shields.io/badge/Windows-10%2B-red.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

R## What You Get

Transform your terminal into a **modern, powerful development environment**:

### **Enhanced Development Experience**
- **Git Integration**: Real-time Git status, branch info, and commit details
- **Environment Awareness**: Python virtual environments, Node.js versions, and more
- **Smart Path Display**: Folder icons and intelligent path truncation
- **100+ Beautiful Themes**: From minimal to feature-rich, dark to light
- **Performance Optimized**: Fast rendering with minimal startup impact
- **Cross-Platform**: Supports Windows, macOS, and Linux commands
- **Terminal Auto-Completion**: PowerShell 7 provides intelligent, context-aware auto completion for commands, parameters, file paths, and even custom functions—making it easy to discover available options and dramatically speeding up your workflow

### **One-Click Setup**
- **Automated Installation**: Installs PowerShell 7 and Oh My Posh silently
- **Intelligent Path Detection**: Locates and configures Oh My Posh in your PATH
- **Profile Management**: Creates and updates your PowerShell profile automatically
- **Theme Integration**: Installs and manages a local theme collection with dynamic switching

### **Advanced Theming**
- **100+ Built-in Themes**: Access the full Oh My Posh theme library locally
- **Dynamic Theme Switching**: Instantly change themes with the `Set-OMPTheme` function or `theme` alias for simplicity
- **Automatic Updates**: Scheduled updates keep your themes current
- **Offline Access**: All themes are stored locally for use without an internet connection

### **System Integration**
- **Windows Terminal Integration**: Installs and configures PowerShell 7 for use in Windows Terminal. User retain full control—set PowerShell 7 as your default profile in Windows Terminal settings whenever you prefer.
- **File Association**: Sets PowerShell 7 as the default for `.ps1` scripts
- **Scheduled Tasks**: Automates theme updates using Windows Task Scheduler
- **Clean Uninstall**: Easily reset your environment with `Reset-OMPEnv.ps1`

## Quick Start

### Prerequisites
- **Windows 10/11** (64-bit)
- **Internet connection** (for initial download)
- **Administrator privileges** (for installation)

### Installation

1. **Clone or download** this repository:
   ```powershell
   git clone https://github.com/MusaadTech/PowerShell-7-Plus.git
   cd PowerShell-7-Plus
   ```

2. **Run the installer**:
   ```powershell
   # Set execution policy (if needed)
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   
   # Run the installer
   .\Install-OMPEnv.ps1
   ```

3. **Enjoy your new terminal!**

The script will:
- ✅ Install PowerShell 7 (if not present)
- ✅ Install Oh My Posh via winget
- ✅ Configure your PowerShell profile
- ✅ Set up theme management
- ✅ Install PowerShell 7 (user can set default profile manually)
- ✅ Launch your new environment

## Scripts Overview

### `Install-OMPEnv.ps1`
**Main installation script** that sets up your complete environment:

- **Step 1**: Install PowerShell 7 via winget
- **Step 2**: Install Oh My Posh via winget
- **Step 3**: Locate and configure Oh My Posh PATH
- **Step 4**: Configure POSH_THEMES_PATH environment variable
- **Step 5**: Create oh-my-posh themes directory
- **Step 6**: Create PowerShell profile
- **Step 7**: Inject Oh My Posh initialization code
- **Step 8**: Sanitize profile content
- **Step 9**: Run theme updater
- **Step 10**: Configure system defaults
- **Step 11**: Refresh environment variables
- **Step 12**: Reload PowerShell profile
- **Step 13**: Restart terminal
- **Step 14**: Close current terminal

### `Reset-OMPEnv.ps1`
**Complete uninstaller** with safety confirmation that removes everything:

- **Safety First**: Requires typing 'YES' to confirm (prevents accidental execution)
- **Complete Cleanup**: Removes Oh My Posh themes directory
- **System Reset**: Unregisters scheduled tasks and removes PowerShell profile
- **Software Removal**: Uninstalls Oh My Posh and PowerShell 7
- **Path Cleanup**: Removes Oh My Posh entries from user PATH

### `Update-OMPThemes.ps1`
**Theme management script** with smart updates:

- **Smart Downloads**: Downloads latest themes from GitHub
- **Efficient Updates**: Tracks theme count to avoid unnecessary downloads
- **Automated Scheduling**: Creates scheduled task for weekly updates
- **Progress Tracking**: Provides progress indicators during download

## Installation Details

The installer automatically handles all the complex setup:

> **Note**: The installer no longer automatically sets PowerShell 7 as the default profile in Windows Terminal. Users can manually configure this through Windows Terminal settings if desired.

### **PowerShell 7 Installation**
- Uses winget for silent installation
- Sets as default for `.ps1` script execution
- Configures Windows Terminal integration

### **Oh My Posh Setup**
- Automatic PATH detection and configuration
- Sets up POSH_THEMES_PATH environment variable
- Creates local themes directory structure

### **Profile Configuration**
- Creates PowerShell profile if it doesn't exist
- Injects Oh My Posh initialization code
- Adds theme switching function and alias
- Sanitizes profile content for optimal performance

### **Windows Terminal Integration**
- Installs PowerShell 7 profile (user can set as default manually)
- Configures automatic profile loading
- Ensures new terminals load Oh My Posh automatically

#### Manual Default Profile Configuration
If you want PowerShell 7 as your default profile in Windows Terminal:
1. Open Windows Terminal
2. Go to Settings (Ctrl+,)
3. Select "PowerShell 7" from the profiles list
4. Click "Set as default"

## Theme Management

### Available Themes
Your local theme collection includes **100+ themes** from the official Oh My Posh repository:

```powershell
# List available themes
Get-ChildItem ".\oh-my-posh\themes\" -Filter "*.omp.json" | Select-Object Name
```

### Switching Themes
Use the built-in `Set-OMPTheme` function or the `theme` alias to switch themes instantly:

```powershell
# Switch themes using the new 'theme' alias (recommended)
theme jandedobbeleer
theme agnoster
theme powerlevel10k_modern
theme dracula

# Or use the full function name
Set-OMPTheme "jandedobbeleer"

# You can also use the full filename if preferred
theme "jandedobbeleer.omp.json"
```

### Popular Theme Examples
- **`jandedobbeleer`** - Clean, modern default
- **`agnoster`** - Classic powerline style
- **`powerlevel10k_modern`** - Feature-rich modern prompt
- **`dracula`** - Dark theme with purple accents
- **`catppuccin_mocha`** - Beautiful dark theme

## Troubleshooting & Error Handling

### Common Issues

#### "Oh My Posh not available in PATH"
```powershell
# Check if Oh My Posh is installed
Get-Command oh-my-posh.exe -ErrorAction SilentlyContinue

# If not found, re-run the installer
.\Install-OMPEnv.ps1
```

#### "Theme not found"
```powershell
# List available themes (just the names)
Get-ChildItem ".\oh-my-posh\themes\" -Filter "*.omp.json" | ForEach-Object { $_.BaseName }

# Or use the Set-OMPTheme function which will show available themes
Set-OMPTheme "nonexistent-theme"

# Update themes if needed
.\Update-OMPThemes.ps1
```

#### Reset Everything
```powershell
# Complete reset (with safety confirmation)
.\Reset-OMPEnv.ps1
```

### Error Logging

The project includes comprehensive error logging to help with troubleshooting:

#### Error Log File
- **Location**: `errors.log` (in project root)
- **Format**: `[TIMESTAMP] [SCRIPT] [ERROR_TYPE] - [DESCRIPTION]`
- **Auto-generated**: Created automatically when the first error occurs
- **Header**: Includes descriptive header when first created
- **Encoding**: UTF-8 format for proper character support

#### Error Types Tracked
- **`WINGET_ERROR`** - Package installation failures
- **`PATH_ERROR`** - Oh My Posh PATH detection issues
- **`INSTALLATION_ERROR`** - General installation problems
- **`API_ERROR`** - GitHub API connection issues
- **`DOWNLOAD_ERROR`** - Theme download failures
- **`THEME_UPDATE_ERROR`** - Theme update script issues
- **`UNINSTALL_ERROR`** - Uninstallation problems
- **`MISSING_FILE`** - Required files not found

#### Viewing Error Logs
```powershell
# View recent errors
Get-Content errors.log -Tail 10

# Search for specific error types
Select-String -Path errors.log -Pattern "WINGET_ERROR"

# Clear error log (if needed)
Clear-Content errors.log
```

## Advanced Usage

### Manual Theme Updates
```powershell
# Update themes manually
.\Update-OMPThemes.ps1
```

### Custom Theme Configuration
```powershell
# Edit your PowerShell profile
notepad $PROFILE

# The profile contains:
# - Oh My Posh initialization
# - Set-OMPTheme function
# - Your custom configurations
```

### Scheduled Updates Management

The installer can set up automatic theme updates:

- **Frequency**: Weekly (Sundays at 10:00 AM)
- **Task Name**: "Update Oh My Posh Themes"
- **Scope**: User-level scheduled task
- **Requires**: Administrator privileges for setup

To manage scheduled tasks:
```powershell
# View scheduled task
Get-ScheduledTask -TaskName "Update Oh My Posh Themes"

# Remove scheduled task
Unregister-ScheduledTask -TaskName "Update Oh My Posh Themes" -Confirm:$false
```

## Project Structure

```
📂 PowerShell-7-Plus/
├── 🗒️ Install-OMPEnv.ps1           # Main installer script
├── 🗒️ Reset-OMPEnv.ps1             # Complete uninstaller
├── 🗒️ Update-OMPThemes.ps1         # Theme updater with scheduler
├── 📇 README.md                    # This file
├── ⚖️ LICENSE                      # MIT License
├── 🗒️ .gitignore                   # Git ignore rules
├── 📄 errors.log                   # Error tracking log (auto-generated)
└── 📂 oh-my-posh/
    ├── 📂 themes/                  # Local theme collection (100+ themes)
    ├── 🗒️theme-count.log           # Theme count tracking
    └── 🗒️update.log                # Update history
```

## Contributing

We welcome contributions! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup
```powershell
# Clone the repository
git clone https://github.com/MusaadTech/PowerShell-7-Plus.git
cd PowerShell-7-Plus

# Test the installer
.\Install-OMPEnv.ps1

# Test the reset
.\Reset-OMPEnv.ps1
```

## Support

- **Issues**: [GitHub Issues](https://github.com/MusaadTech/PowerShell-7-Plus/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MusaadTech/PowerShell-7-Plus/discussions)
- **Documentation**: [Oh My Posh Docs](https://ohmyposh.dev/docs/)

## Project Status

- **Version**: 1.0.0
- **Last Updated**: December 2024
- **PowerShell Version**: 7.0+
- **Windows Version**: 10/11 (64-bit)
- **Oh My Posh Version**: Latest

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

This project builds upon the excellent work of:

- **[Oh My Posh](https://ohmyposh.dev/)** by [Jan De Dobbeleer](https://github.com/JanDeDobbeleer) - The amazing prompt customization engine that powers beautiful, informative, and highly customizable terminal prompts
- **[PowerShell 7](https://github.com/PowerShell/PowerShell)** by Microsoft - The modern cross-platform shell that brings the power of .NET to command-line automation
- **[Windows Terminal](https://github.com/microsoft/terminal)** by Microsoft - The modern Windows terminal that provides a fast, efficient, and beautiful command-line experience

---

**Made with ❤️ for the PowerShell community**
