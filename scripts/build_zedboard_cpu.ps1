param([string]$VivadoBin = 'D:\VIVADO\2025.2\Vivado\bin')
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'build/zedboard_cpu_demo'
New-Item -ItemType Directory -Path $out -Force | Out-Null
Push-Location $out
try {
    # Remove only the old output file, so a failed rebuild cannot look successful.
    if (Test-Path -LiteralPath 'zedboard_cpu_demo.bit') { Remove-Item -LiteralPath 'zedboard_cpu_demo.bit' }
    $sourcePath = (Join-Path $PSScriptRoot 'build_zedboard_cpu.tcl').Replace('\', '/')
    Set-Content -LiteralPath 'run_build.tcl' -Value "source {$sourcePath}" -Encoding ascii
    & (Join-Path $VivadoBin 'vivado.bat') -mode batch -source 'run_build.tcl' -log 'build.log' -journal 'build.jou'
    if ($LASTEXITCODE -ne 0) { throw "Vivado CPU build failed: $LASTEXITCODE" }
    if (-not (Test-Path -LiteralPath 'zedboard_cpu_demo.bit')) { throw 'No CPU bitstream was generated.' }
    if ((Get-Content -LiteralPath 'build.log' -Raw) -notmatch '(?m)^BUILD_PASS:') { throw 'Build completion was not verified.' }
    (Get-FileHash -LiteralPath 'zedboard_cpu_demo.bit' -Algorithm SHA256).Hash |
        Set-Content -LiteralPath 'bitstream.sha256' -Encoding ascii
    Write-Host "Bitstream ready: $out/zedboard_cpu_demo.bit"
} finally { Pop-Location }
