param([string]$VivadoBin = 'D:\VIVADO\2025.2\Vivado\bin')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'build/cpu_synthesis'
New-Item -ItemType Directory -Path $out -Force | Out-Null
Push-Location $out
try {
    $sourcePath = (Join-Path $PSScriptRoot 'check_cpu_synthesis.tcl').Replace('\','/')
    Set-Content -LiteralPath 'run_synthesis.tcl' -Value "source {$sourcePath}" -Encoding ascii
    & (Join-Path $VivadoBin 'vivado.bat') -mode batch -source 'run_synthesis.tcl' -log 'synthesis.log' -journal 'synthesis.jou'
    if ($LASTEXITCODE -ne 0) { throw "Vivado synthesis failed: $LASTEXITCODE" }
    if ((Get-Content -LiteralPath 'synthesis.log' -Raw) -notmatch '(?m)^SYNTH_PASS:') { throw 'Synthesis checks did not pass.' }
} finally { Pop-Location }
