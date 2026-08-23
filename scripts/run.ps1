$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir
$VenvDir = if ($env:VENV_DIR) { $env:VENV_DIR } else { ".venv" }
$Py = Join-Path $VenvDir "Scripts\python.exe"
if (-not (Test-Path $Py)) { Write-Host "Virtual environment not found. Running installer..."; & powershell -ExecutionPolicy Bypass -File scripts\install.ps1 }
if (-not $env:APP_ENV) { $env:APP_ENV = "development" }
if (-not $env:DB_PATH) { $env:DB_PATH = Join-Path $env:TEMP "secure_webapp.db" }
if (-not $env:SESSION_TTL_SECONDS) { $env:SESSION_TTL_SECONDS = "3600" }
if (-not $env:MAX_BODY_BYTES) { $env:MAX_BODY_BYTES = "1048576" }
$HostAddr = if ($env:HOST) { $env:HOST } else { "127.0.0.1" }
$Port = if ($env:PORT) { $env:PORT } else { "8000" }
& $Py -m uvicorn app.main:app --host $HostAddr --port $Port
