#Requires -Version 5.1

<#
   .SYNOPSIS
    Configuration-Script for Windows Event Forwarding
   .PARAMETER LogSize
    Defines the size of the LogFile, if not set Default is 500mb
   .EXAMPLE
    ./Configure-DSWindowsEventForwarding.ps1 -LogSize 50mb
    Configures WEFS and the associated log-file to 50MB
    ny logfil generes.
   .Notes
    Name:       Configure-DSWindowsEventForwarding.ps1
    Author:     Tom Stryhn (@dotStryhn)
   .Link
    https://github.com/dotStryhn/DSEventLogManagement
    http://dotstryhn.dk
#>
param(
    [int]$LogSize = 500mb
)

Set-PSDebug -Strict
$ErrorActionPreference = 'Stop'

# Define Drive-letter & Paths
$SystemDrive = "D:"
$DirLog = "Logs"
$DirSystem = "System"
$DirService = "WEFS"
$FileLogName = "forwardedevents.evtx"

# Generates Paths from Variables
$PathSystem = Join-Path $SystemDrive $DirSystem
$PathService = Join-Path $PathSystem $DirService
$PathLog = Join-Path $PathService $DirLog

# Verifies path and creates
if (-not (Test-Path $PathSystem)) { New-Item -Name $DirSystem -Path $SystemDrive -ItemType Directory }
if (-not (Test-Path $PathService)) { New-Item -Name $DirService -Path $PathSystem -ItemType Directory }
if (-not (Test-Path $PathLog)) { New-Item -Name $DirLog -Path $PathService -ItemType Directory }

# Creates Share with "Event Log Readers" rigths
New-SmbShare -Name $DirLog -Path $PathLog -ReadAccess "Event Log Readers" -Description "Windows Eventforwarding Logs"

# Sets 'Windows Remote Management Command Line Tool'-Path & Args
$WRMCLT = "C:\Windows\System32\winrm.cmd"
$WinRMArg = "qc -q"

# Verifies WinRM is set to 'Automatic Startup' or sets it
if (((Get-Service -Name WinRM).StartType) -ne "Automatic") { Set-Service -Name WinRM -StartupType Automatic }

# Starts WinRM with Args
$winrm = Start-Process $WRMCLT -ArgumentList $WinRMArg -NoNewWindow -PassThru -Wait
if ($winrm.ExitCode -eq 0) {
    Write-Host "WinRM: Configured"
}
else {
    Write-Host "WinRM ExitCode:" $winrm.ExitCode
}

# Defines Forwarded Events Log Path
$WEFLogPath = Join-Path $PathLog $FileLogName

# Sets 'Windows Events Command Line Utility'-Path & Args
$WECLU = "C:\Windows\System32\wevtutil.exe"
$wevtutilArg0 = "sl forwardedevents /rt:true /ab:true"
$wevtutilArg1 = " /ms:" + $LogSize
$wevtutilArg2 = " /lfn:" + $WEFLogPath
$wevtutilArgFull = $wevtutilArg0 + $wevtutilArg1 + $wevtutilArg2

# Starts wevtutil with args and reports
$wevtutil = Start-Process $WECLU -ArgumentList $wevtutilArgFull -NoNewWindow -PassThru -Wait
if ($wevtutil.ExitCode -eq 0) {
    Write-Host "WEVTUTIL: Configured"
}
else {
    Write-Host "WEVTUTIL Exitcode:" $wevtutil.ExitCode
}

# Sets 'Windows Event Collecter Utility'-Path & Args
$WECU = "C:\Windows\System32\wecutil.exe"
$wecutilArg = "qc -q"

# Start wecutil with args and reports
$wecutil = Start-Process $WECU -ArgumentList $wecutilArg -NoNewWindow -PassThru -Wait
if ($wecutil.ExitCode -eq 0) {
    Write-Host "WECUTIL: Configured"
}
else {
    Write-Host "WECUTIL Exitcode:" $wecutil.ExitCode
}
