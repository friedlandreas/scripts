
#Exchange Server Install-Script
#Sripted by: Andreas Friedl
#Creation Date: 10.07.2025
#Version: 0.9

function Test-InstalledProgram {
    param (
        [string]$DisplayName
    )
    $key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $keyWow = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $keys = Get-ChildItem $key, $keyWow -ErrorAction SilentlyContinue
    foreach ($k in $keys) {
        $name = (Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue).DisplayName
        if ($name -like "*$DisplayName*") {
            return $true
        }
    }
    return $false
}

clear

#Willkommenstext
Write-Host "Exchange-Installationsscript"
Write-Host ""
Write-Host "Version 0.9 (10/2025)" -ForegroundColor White
Write-Host ""
write-host ""


# Suche nach dem ersten Laufwerk, das Exchange-Setup enthält
Write-Host "Exchange ISO Pfad wird gesucht..." -ForegroundColor Cyan
$exchangeDrive = Get-PSDrive -PSProvider FileSystem | Where-Object {
    (Test-Path "$($_.Root)Setup.exe") -and (Test-Path "$($_.Root)UCMARedist")
} | Select-Object -First 1

if ($exchangeDrive) {
     $isoPath = $exchangeDrive.Root
    Write-Host "Exchange ISO gefunden auf Laufwerk: $isoPath" -ForegroundColor Green
} else {
    Write-Host "Exchange ISO konnte nicht automatisch gefunden werden. Bitte mounten und Script erneut starten." -ForegroundColor Red
    Write-Host "Script wird abgebrochen" -ForegroundColor Red
    pause
    break
}

# Windows Features
Write-Host "Installation der nötigen Windows Features..." -ForegroundColor Cyan
Install-WindowsFeature Server-Media-Foundation, NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation, RSAT-ADDS -IncludeManagementTools
Write-Host "Windows Features installation abgeschlossen!" -ForegroundColor Green

# Optional:  Windows Defender temporär ausschalten
Write-Host "Windows Defender temporär deaktivieren..." -ForegroundColor Yellow
Set-MpPreference -DisableRealtimeMonitoring $true

# UCMA 4.0 von der Exchange ISO
$ucmaPath = "$isoPath\UCMARedist\setup.exe"
if (Test-Path $ucmaPath) {
    if (-not (Test-InstalledProgram -DisplayName "Microsoft Unified Communications Managed API 4.0, Runtime")) {
        Write-Host "Installation UCMA 4.0..." -ForegroundColor Cyan
        Start-Process $ucmaPath -ArgumentList "/quiet" -Wait
        Write-Host "UCMA 4.0 Installation abgeschlossen!" -ForegroundColor Green
    } else {
    Write-Host "UCMA 4.0 ist schon installiert..." -ForegroundColor Gray
}
} else {
    Write-Host "UCMA 4.0 setup.exe wrude unter $isoPath\UCMARedist\setup.exe nicht gefunden!" -ForegroundColor Red
}

# Download und Installation Visual C++ Redistributables und URL Rewrite Module
$tempDir = "$env:TEMP\ExchangeSetupDownloads"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

$downloads = @(
    @{ Name = "Visual C++ 2012"; Url = "https://download.microsoft.com/download/1/6/b/16b06f60-3b20-4ff2-b699-5e9b7962f9ae/VSU_4/vcredist_x64.exe"; File = "$tempDir\vcredist2012.exe" },
    @{ Name = "Visual C++ 2013"; Url = "https://download.visualstudio.microsoft.com/download/pr/10912036/b519cb85bab02255e6e00e4562942748/vcredist_x64.exe"; File = "$tempDir\vcredist2013.exe" },
    @{ Name = "IIS-URL-Rewrite-Modul 2"; Url = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_de-DE.msi"; File = "$tempDir\urlrewrite.msi" }
)

foreach ($item in $downloads) {
    if (-not (Test-InstalledProgram -DisplayName $item.Name)) {
        Write-Host "Download von $($item.Name)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $item.Url -OutFile $item.File
        Write-Host "Installation von $($item.Name)..." -ForegroundColor Cyan
        if ($item.File -like "*.msi") {
            Start-Process "msiexec.exe" -ArgumentList "/i `"$($item.File)`" /quiet /norestart" -Wait
        } else {
            Start-Process $item.File -ArgumentList "/quiet /norestart" -Wait
        }
        Write-Host "$($item.Name) Installation abgeschlossen!" -ForegroundColor Green
    } else {
        Write-Host "$($item.Name) ist schon installiert..." -ForegroundColor Gray
    }
}


# Exchange Setup
$exchangeSetup = "$isoPath\Setup.exe"
if (Test-Path $exchangeSetup) {
    Write-Host "Start des Exchange Server Setups..." -ForegroundColor Cyan
    Start-Process $exchangeSetup -Wait
    Write-Host "Exchange Server installation abgeschlossen!" -ForegroundColor Green
} else {
    Write-Host "Exchange Setup.exe wurde unter $isoPath\Setup.exe nicht gefunden!." -ForegroundColor Red
}
