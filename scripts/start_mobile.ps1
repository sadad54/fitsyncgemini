param(
  [int]$Port = 8082
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$mobile = Join-Path $root "mobile"
$expo = Join-Path $mobile "node_modules\.bin\expo.cmd"

function Test-PortFree {
  param([int]$CandidatePort)
  $connection = Get-NetTCPConnection -LocalPort $CandidatePort -ErrorAction SilentlyContinue
  return -not $connection
}

function Get-ExpoPort {
  param([int]$StartPort)
  for ($candidate = $StartPort; $candidate -le ($StartPort + 10); $candidate++) {
    if (Test-PortFree -CandidatePort $candidate) {
      return $candidate
    }
  }
  throw "No open Expo port found from $StartPort to $($StartPort + 10)."
}

Set-Location $mobile

$env:EXPO_NO_TELEMETRY = "1"
$env:EXPO_NO_TYPESCRIPT_SETUP = "1"
$env:REACT_NATIVE_PACKAGER_HOSTNAME = "10.20.3.40"
$env:HOME = Join-Path $mobile "expo_home"
$env:USERPROFILE = $env:HOME
$env:EXPO_HOME = $env:HOME

if (-not (Test-Path $env:EXPO_HOME)) {
  New-Item -ItemType Directory -Force -Path $env:EXPO_HOME | Out-Null
}

$expoPort = Get-ExpoPort -StartPort $Port
if ($expoPort -ne $Port) {
  Write-Host "Port $Port is busy. Starting Expo on $expoPort instead."
}

& $expo start --host lan --port $expoPort --clear
