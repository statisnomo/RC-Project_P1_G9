param([string]$VivadoBin = 'D:\VIVADO\2025.2\Vivado\bin')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'build/zedboard_alu_demo'
New-Item -ItemType Directory -Path $out -Force | Out-Null
Push-Location $out
try {
    # Copy to a space-free relative filename for the Vivado batch launcher.
    # The original script's location is needed to resolve the project root,
    # so its full path is passed as a Tcl-braced source command in a local wrapper.
    $sourcePath = (Join-Path $PSScriptRoot 'build_zedboard_demo.tcl').Replace('\', '/')
    Set-Content -LiteralPath 'run_build.tcl' -Value "source {$sourcePath}" -Encoding ascii
    & (Join-Path $VivadoBin 'vivado.bat') -mode batch -source 'run_build.tcl' -log 'build.log' -journal 'build.jou'
    if ($LASTEXITCODE -ne 0) { throw "Vivado build failed: $LASTEXITCODE" }
    if (-not (Test-Path -LiteralPath 'zedboard_alu_demo.bit')) { throw 'No bitstream was generated.' }
    if ((Get-Content -LiteralPath 'build.log' -Raw) -notmatch 'BUILD_PASS:') { throw 'Build completion was not verified.' }
    Write-Host "Bitstream ready: $out/zedboard_alu_demo.bit"
} finally { Pop-Location }
