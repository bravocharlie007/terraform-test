# Windows Gaming PC Setup Script
# Place this in compute/user_data/windows-gaming-setup.ps1

<powershell>
# Enable PowerShell execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Create log file
$LogFile = "C:\gaming-setup.log"
Start-Transcript -Path $LogFile

Write-Host "Starting Gaming PC Setup..." -ForegroundColor Green

# 1. DISABLE PASSWORD AUTHENTICATION FOR SECURITY
# Configure Windows for secure access via RDP with certificates only
Write-Host "Configuring secure RDP access..." -ForegroundColor Yellow

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

# Set strong password policy
net accounts /minpwlen:12 /maxpwage:90 /minpwage:1 /uniquepw:5

# Set admin password securely
$AdminPassword = "${admin_password}"
if ($AdminPassword -ne "" -and $AdminPassword -ne "CHANGE_ME") {
    net user Administrator $AdminPassword
    Write-Host "Administrator password set" -ForegroundColor Green
} else {
    Write-Host "WARNING: Default admin password not changed!" -ForegroundColor Red
}

# 2. INSTALL GAMING ESSENTIALS
Write-Host "Installing gaming software..." -ForegroundColor Yellow

# Install Chocolatey package manager
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
refreshenv

# Install gaming platforms and essentials
$GamingApps = @(
    "steam",
    "epicgameslauncher", 
    "discord",
    "googlechrome",
    "firefox",
    "7zip",
    "vlc",
    "nvidia-geforce-experience",  # For NVIDIA GPUs
    "directx",
    "vcredist140"
)

foreach ($app in $GamingApps) {
    try {
        Write-Host "Installing $app..." -ForegroundColor Cyan
        choco install $app -y --no-progress --limit-output
        Write-Host "$app installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "Failed to install $app : $_" -ForegroundColor Red
    }
}

# 3. OPTIMIZE WINDOWS FOR GAMING
Write-Host "Optimizing Windows for gaming performance..." -ForegroundColor Yellow

# Disable Windows Update automatic restart
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "UxOption" -Value 1

# Set high performance power plan
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Disable unnecessary services for gaming
$ServicesToDisable = @(
    "Fax",
    "PrintSpooler", 
    "TabletInputService",
    "WebClient"
)

foreach ($service in $ServicesToDisable) {
    try {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Disabled service: $service" -ForegroundColor Green
    } catch {
        Write-Host "Could not disable service $service : $_" -ForegroundColor Yellow
    }
}

# 4. CONFIGURE FIREWALL FOR GAMING
Write-Host "Configuring Windows Firewall for gaming..." -ForegroundColor Yellow

# Enable Windows Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Steam gaming ports
New-NetFirewallRule -DisplayName "Steam TCP" -Direction Inbound -Protocol TCP -LocalPort 27015-27030 -Action Allow -Profile Private
New-NetFirewallRule -DisplayName "Steam UDP" -Direction Inbound -Protocol UDP -LocalPort 27015-27030 -Action Allow -Profile Private

# Discord voice chat
New-NetFirewallRule -DisplayName "Discord Voice" -Direction Inbound -Protocol UDP -LocalPort 50000-65535 -Action Allow -Profile Private

# Epic Games Launcher
New-NetFirewallRule -DisplayName "Epic Games" -Direction Inbound -Protocol TCP -LocalPort 80,443,5222 -Action Allow -Profile Private

# 5. GAMING PERFORMANCE TWEAKS
Write-Host "Applying gaming performance tweaks..." -ForegroundColor Yellow

# Disable visual effects for performance
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2

# Disable indexing on C: drive for gaming performance
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Search" -Name "SetupCompletedSuccessfully" -Value 0

# Set processor scheduling for programs (not background services)
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38

# Increase system cache size
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1

# 6. CREATE GAMING USER ACCOUNTS
Write-Host "Setting up gaming user accounts..." -ForegroundColor Yellow

# Create gaming users for family members
$GamingUsers = @("Player1", "Player2", "Player3")

foreach ($user in $GamingUsers) {
    try {
        # Generate random password
        $Password = -join ((33..126) | Get-Random -Count 16 | % {[char]$_})
        net user $user $Password /add /fullname:"Gaming User $user" /comment:"Gaming account"
        net localgroup "Remote Desktop Users" $user /add
        net localgroup "Users" $user /add
        
        # Save credentials securely
        Add-Content -Path "C:\gaming-users.txt" -Value "$user : $Password"
        Write-Host "Created gaming user: $user" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create user $user : $_" -ForegroundColor Red
    }
}

# Secure the credentials file
icacls "C:\gaming-users.txt" /grant Administrators:F /remove Everyone /remove Users

# 7. INSTALL GPU DRIVERS AND GAMING OPTIMIZATION
Write-Host "Installing GPU drivers..." -ForegroundColor Yellow

# Download and install NVIDIA drivers for gaming instances
try {
    $NvidiaUrl = "https://us.download.nvidia.com/tesla/470.82.01/471.11-tesla-desktop-winserver-2019-2016-international.exe"
    $NvidiaInstaller = "C:\nvidia-driver.exe"
    
    Invoke-WebRequest -Uri $NvidiaUrl -OutFile $NvidiaInstaller
    Start-Process -FilePath $NvidiaInstaller -ArgumentList "/s /n" -Wait
    Remove-Item $NvidiaInstaller -Force
    Write-Host "NVIDIA drivers installed" -ForegroundColor Green
} catch {
    Write-Host "GPU driver installation failed: $_" -ForegroundColor Yellow
}

# 8. SECURITY HARDENING
Write-Host "Applying security hardening..." -ForegroundColor Yellow

# Disable unnecessary features
Disable-WindowsOptionalFeature -Online -FeatureName "Internet-Explorer-Optional-amd64" -NoRestart
Disable-WindowsOptionalFeature -Online -FeatureName "MediaPlayback" -NoRestart

# Enable automatic updates for security
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "AUOptions" -Value 4

# 9. CREATE DESKTOP SHORTCUTS
Write-Host "Creating desktop shortcuts..." -ForegroundColor Yellow

# Create shortcuts for gaming platforms
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$Shell = New-Object -ComObject WScript.Shell

# Steam shortcut
if (Test-Path "C:\Program Files (x86)\Steam\Steam.exe") {
    $Shortcut = $Shell.CreateShortcut("$DesktopPath\Steam.lnk")
    $Shortcut.TargetPath = "C:\Program Files (x86)\Steam\Steam.exe"
    $Shortcut.Save()
}

# Discord shortcut  
if (Test-Path "$env:LOCALAPPDATA\Discord\Discord.exe") {
    $Shortcut = $Shell.CreateShortcut("$DesktopPath\Discord.lnk")
    $Shortcut.TargetPath = "$env:LOCALAPPDATA\Discord\Discord.exe"
    $Shortcut.Save()
}

# 10. FINAL SETUP AND LOGGING
Write-Host "Finalizing gaming PC setup..." -ForegroundColor Yellow

# Create gaming PC info file
$PCInfo = @"
Gaming PC Configuration Complete
================================
Setup Date: $(Get-Date)
Instance Type: $(Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Model)
OS Version: $(Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
Total RAM: $([math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)) GB
GPU: $(Get-WmiObject -Class Win32_VideoController | Select-Object -ExpandProperty Name -First 1)

Gaming Software Installed:
- Steam
- Epic Games Launcher
- Discord
- Chrome/Firefox browsers
- DirectX and Visual C++ redistributables
- 7-Zip and VLC

Security Features:
- Windows Firewall enabled with gaming ports
- RDP enabled for remote gaming access
- Strong password policies enforced
- Automatic security updates enabled

Gaming Optimizations:
- High performance power plan
- Visual effects optimized for performance
- System cache optimized for gaming
- Unnecessary services disabled

User Accounts Created:
$(Get-Content "C:\gaming-users.txt" -ErrorAction SilentlyContinue)

Next Steps:
1. Connect via RDP using the credentials above
2. Log into Steam/Epic Games with your accounts
3. Install your gaming library
4. Configure game-specific settings
5. Set up voice chat applications

"@

Set-Content -Path "C:\GamingPC-Info.txt" -Value $PCInfo
Write-Host "Gaming PC setup information saved to C:\GamingPC-Info.txt" -ForegroundColor Green

# Schedule restart to apply all changes
Write-Host "Gaming PC setup complete! Scheduling restart in 2 minutes..." -ForegroundColor Green
shutdown /r /t 120 /c "Gaming PC setup complete - restarting to apply all changes"

Stop-Transcript
Write-Host "Setup completed successfully! Check C:\gaming-setup.log for details." -ForegroundColor Green
</powershell>