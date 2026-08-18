$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend_v2"
$venvPython = Join-Path $backend "venv\Scripts\python.exe"

Set-Location $backend

if (Test-Path $venvPython) {
  & $venvPython -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
} else {
  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
}
