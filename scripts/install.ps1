$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $RootDir
$PythonBin = if ($env:PYTHON_BIN) { $env:PYTHON_BIN } else { "python" }
$VenvDir = if ($env:VENV_DIR) { $env:VENV_DIR } else { ".venv" }
Write-Host "[1/6] Checking Python..."
& $PythonBin -c "import sys; assert sys.version_info >= (3,14), f'Python 3.14+ required; found {sys.version.split()[0]}'; print('Python:', sys.version.split()[0])"
Write-Host "[2/6] Creating virtual environment..."; & $PythonBin -m venv $VenvDir
$Py = Join-Path $VenvDir "Scripts\python.exe"; if (-not (Test-Path $Py)) { throw "Virtual environment creation failed." }
Write-Host "[3/6] Upgrading installer tooling..."; & $Py -m pip install --upgrade pip setuptools wheel
Write-Host "[4/6] Installing application and security tooling..."; & $Py -m pip install -r requirements-dev.txt
Write-Host "[5/6] Running automated security verification..."; & $Py -m ruff check .; & $Py -m pytest -q; & $Py -m bandit -q -r app -x tests; & $Py -m pip_audit -r requirements.txt --strict
Write-Host "[6/6] Generating SBOM..."; & $Py -m cyclonedx_py requirements requirements.txt --output-file sbom.json
Write-Host "Installation complete."
