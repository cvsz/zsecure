$ErrorActionPreference = "Stop"
$RootDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path); Set-Location $RootDir
$VenvDir = if ($env:VENV_DIR) { $env:VENV_DIR } else { ".venv" }; $Py = Join-Path $VenvDir "Scripts\python.exe"
if (-not (Test-Path $Py)) { throw "Virtual environment not found. Run scripts\install.ps1 first." }
Write-Host "[1/5] Updating installer tooling..."; & $Py -m pip install --upgrade pip setuptools wheel
Write-Host "[2/5] Reinstalling declared dependencies..."; & $Py -m pip install --upgrade -r requirements-dev.txt
Write-Host "[3/5] Auditing dependencies..."; & $Py -m pip_audit -r requirements.txt --strict
Write-Host "[4/5] Running tests and static analysis..."; & $Py -m ruff check .; & $Py -m pytest -q; & $Py -m bandit -q -r app -x tests
Write-Host "[5/5] Regenerating SBOM..."; & $Py -m cyclonedx_py requirements requirements.txt --output-file sbom.json
Write-Host "Upgrade verification completed successfully."
