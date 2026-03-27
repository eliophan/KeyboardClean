param(
  [string]$Repo = "eliophan/cleaning-keyboard",
  [string]$Ref = "main",
  [string]$InstallDir = "$env:LOCALAPPDATA\cleaning-keyboard"
)

$baseUrl = "https://raw.githubusercontent.com/$Repo/$Ref"
$scriptUrl = "$baseUrl/scripts/clean-keyboard-windows.ps1"
$scriptPath = Join-Path $InstallDir "clean-keyboard.ps1"
$cmdPath = Join-Path $InstallDir "clean-keyboard.cmd"

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Invoke-WebRequest -Uri $scriptUrl -OutFile $scriptPath

$cmdContent = @"
@echo off
set "SECONDS=%~1"
if "%SECONDS%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "$scriptPath"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "$scriptPath" -Seconds %SECONDS%
)
"@

Set-Content -Path $cmdPath -Value $cmdContent -Encoding Ascii

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -eq $userPath) {
  $userPath = ""
}

$normalizedPath = ";" + $userPath.TrimEnd(";") + ";"
if ($normalizedPath -notlike "*;$InstallDir;*") {
  if ([string]::IsNullOrWhiteSpace($userPath)) {
    $newPath = $InstallDir
  } else {
    $newPath = "$userPath;$InstallDir"
  }

  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
  Write-Output "Added $InstallDir to User PATH."
}

Write-Output "Installed clean-keyboard for Windows."
Write-Output "Open a new terminal, then run: clean-keyboard 60"
