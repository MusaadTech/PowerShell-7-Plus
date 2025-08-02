# PowerShell 7 + Oh My Posh Environment Setup

> **Automated PowerShell environment setup with modern theming and customization**

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Oh My Posh](https://img.shields.io/badge/Oh%20My%20Posh-Latest-green.svg)](https://ohmyposh.dev/)
[![Windows](https://img.shields.io/badge/Windows-10%2B-red.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## 🙏 Acknowledgments

This project builds upon the excellent work of:

- **[Oh My Posh](https://ohmyposh.dev/)** by [Jan De Dobbeleer](https://github.com/JanDeDobbeleer) - The amazing prompt customization engine that powers beautiful, informative, and highly customizable terminal prompts
- **[PowerShell 7](https://github.com/PowerShell/PowerShell)** by Microsoft - The modern cross-platform shell that brings the power of .NET to command-line automation
- **[Windows Terminal](https://github.com/microsoft/terminal)** by Microsoft - The modern Windows terminal that provides a fast, efficient, and beautiful command-line experience

## Why PowerShell 7 + Oh My Posh?

Transform your terminal into a **modern, powerful development environment**:

### **Enhanced Development Experience**
- **Git Integration**: Real-time Git status, branch info, and commit details
- **Environment Awareness**: Python virtual environments, Node.js versions, and more
- **Smart Path Display**: Folder icons and intelligent path truncation
- **100+ Beautiful Themes**: From minimal to feature-rich, dark to light
- **Performance Optimized**: Fast rendering with minimal startup impact
- **Cross-Platform**: Works on Windows, macOS, and Linux
- **Terminal Auto-Completion**: PowerShell 7 provides intelligent, context-aware auto completion for commands, parameters, file paths, and even custom functions—making it easy to discover available options and dramatically speeding up your workflow

A comprehensive PowerShell automation suite that transforms your Windows terminal into a modern, beautiful, and highly functional development environment. This project automates the complete setup of **PowerShell 7** and **Oh My Posh** with advanced theming capabilities.

## What This Project Adds

This project builds on the foundations of Oh My Posh and PowerShell 7, delivering a fully automated setup and a suite of enhancements for a streamlined, modern terminal experience. Key features include:

### **One-Click Setup**
- **Automated Installation**: Installs PowerShell 7 and Oh My Posh silently.
- **Intelligent Path Detection**: Locates and configures Oh My Posh in your PATH.
- **Profile Management**: Creates and updates your PowerShell profile automatically.
- **Theme Integration**: Installs and manages a local theme collection with dynamic switching.

### **Advanced Theming**
- **100+ Built-in Themes**: Access the full Oh My Posh theme library locally.
- **Dynamic Theme Switching**: Instantly change themes with the `Set-OMPTheme` function.
- **Automatic Updates**: Scheduled updates keep your themes current.
- **Offline Access**: All themes are stored locally for use without an internet connection.

### **System Integration**
- **Windows Terminal Support**: Automatically configures PowerShell 7 as the default profile.
- **File Association**: Sets PowerShell 7 as the default for `.ps1` scripts.
- **Scheduled Tasks**: Automates theme updates using Windows Task Scheduler.
- **Clean Uninstall**: Easily reset your environment with `Reset-OMPEnv.ps1`.

### **Productivity Boost**
- **Powerful Tab Completion**: Take advantage of PowerShell 7's advanced auto-completion for commands, parameters, file paths, and even custom functions like `Set-OMPTheme`. This dramatically speeds up your workflow and reduces errors.

## Quick Start

### Prerequisites
- **Windows 10/11** (64-bit)
- **Internet connection** (for initial download)
- **Administrator privileges** (for installation)

### Installation

1. **Clone or download** this repository:
   ```powershell
   git clone https://github.com/MusaadTech/terminal-customization.git
   cd terminal-customization
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
- ✅ Configure Windows Terminal
- ✅ Launch your new environment

## Theme Management

### Available Themes
Your local theme collection includes **100+ themes** from the official Oh My Posh repository:

```powershell
# List available themes
Get-ChildItem ".\oh-my-posh\themes\" -Filter "*.omp.json" | Select-Object Name
```

### Switching Themes
Use the built-in `Set-OMPTheme` function to switch themes instantly:

```powershell
# Switch to a specific theme (just the name, no extension needed!)
Set-OMPTheme "jandedobbeleer"
Set-OMPTheme "agnoster"
Set-OMPTheme "powerlevel10k_modern"
Set-OMPTheme "dracula"

# You can also use the full filename if preferred
Set-OMPTheme "jandedobbeleer.omp.json"
```

### Popular Theme Examples
- **`jandedobbeleer`** - Clean, modern default
- **`agnoster`** - Classic powerline style
- **`powerlevel10k_modern`** - Feature-rich modern prompt
- **`dracula`** - Dark theme with purple accents
- **`catppuccin_mocha`** - Beautiful dark theme

## Project Structure

```
📂 terminal-customization/
├── 🗒️ Install-OMPEnv.ps1           # Main installer script
├── 🗒️ Reset-OMPEnv.ps1             # Complete uninstaller
├── 🗒️ Update-OMPThemes.ps1         # Theme updater with scheduler
├── 📇 README.md                    # This file
├── ⚖️ LICENSE                      # MIT License
├── 🗒️ .gitignore                   # Git ignore rules
└── 📂 oh-my-posh/
    ├── 📂 themes/                  # Local theme collection (100+ themes)
    ├── 🗒️theme-count.log           # Theme count tracking
    └── 🗒️update.log                # Update history
```

## Scripts Overview

### `Install-OMPEnv.ps1`
**Main installation script** that sets up your complete environment:

- **Step 1**: Install PowerShell 7 via winget
- **Step 2**: Install Oh My Posh via winget
- **Step 3**: Locate and configure Oh My Posh PATH
- **Step 4**: Create PowerShell profile
- **Step 5**: Inject Oh My Posh initialization code
- **Step 6**: Sanitize profile content
- **Step 7**: Run theme updater
- **Step 8**: Configure system defaults
- **Step 9**: Refresh environment variables
- **Step 10**: Reload profile
- **Step 11**: Restart terminal
- **Step 12**: Close current terminal

### `Reset-OMPEnv.ps1`
**Complete uninstaller** that removes everything:

- Removes Oh My Posh themes directory
- Unregisters scheduled tasks
- Removes PowerShell profile
- Uninstalls Oh My Posh and PowerShell 7
- Cleans up PATH entries
- Resets Windows Terminal settings

### `Update-OMPThemes.ps1`
**Theme management script** with smart updates:

- Downloads latest themes from GitHub
- Tracks theme count to avoid unnecessary downloads
- Creates scheduled task for weekly updates
- Provides progress indicators during download

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

### Troubleshooting

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
# Complete reset
.\Reset-OMPEnv.ps1
```

## Scheduled Updates

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
git clone https://github.com/MusaadTech/terminal-customization.git
cd terminal-customization

# Test the installer
.\Install-OMPEnv.ps1

# Test the reset
.\Reset-OMPEnv.ps1
```

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## Project Status

- **Version**: 1.0.0
- **Last Updated**: December 2024
- **PowerShell Version**: 7.0+
- **Windows Version**: 10/11 (64-bit)
- **Oh My Posh Version**: Latest

## Support

- **Issues**: [GitHub Issues](https://github.com/MusaadTech/terminal-customization/issues)
- **Discussions**: [GitHub Discussions](https://github.com/MusaadTech/terminal-customization/discussions)
- **Documentation**: [Oh My Posh Docs](https://ohmyposh.dev/docs/)

---

**Made with ❤️ for the PowerShell community**
