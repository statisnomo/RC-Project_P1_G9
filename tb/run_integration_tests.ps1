param(
    [string]$VivadoBin = 'D:\VIVADO\2025.2\Vivado\bin',
    [ValidateSet('all','cpu_core','memories','soc_minimal')][string]$Test = 'all',
    [switch]$Waves
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Run-Tool {
    param([string]$Name, [string[]]$ToolArguments)
    & (Join-Path $VivadoBin ($Name + '.bat')) @ToolArguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed: $LASTEXITCODE" }
}
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'build/cpu_integration'
New-Item -ItemType Directory -Path $out -Force | Out-Null
$selected = if ($Test -eq 'all') { @('cpu_core','memories','soc_minimal') } else { @($Test) }
$sources = @('cpu/alu','cpu/regfile','cpu/decode','cpu/imm_gen','cpu/cpu_core','mem/instr_rom','mem/data_ram','soc/soc_minimal')
$rtl = @($sources | ForEach-Object { Join-Path $root "rtl/$_.v" })
$benches = @($selected | ForEach-Object { Join-Path $root "tb/cpu/tb_$_.v" })
Push-Location $out
try {
    Run-Tool 'xvlog' (@('--include', (Join-Path $root 'rtl/cpu')) + $rtl)
    Run-Tool 'xvlog' (@('--sv','--include',(Join-Path $root 'tb/programs')) + $benches)
    if ($Waves) { Copy-Item -LiteralPath (Join-Path $root 'tb/capture_waves.tcl') -Destination 'capture_waves.tcl' -Force }
    foreach ($name in $selected) {
        $bench = "tb_$name"
        Run-Tool 'xelab' @('--debug','typical',$bench,'--snapshot',"${bench}_snapshot")
        $log = "$bench.log"
        if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log }
        if ($Waves) {
            Run-Tool 'xsim' @("${bench}_snapshot",'--log',$log,'--wdb',"$bench.wdb",'--onfinish','stop','--tclbatch','capture_waves.tcl')
        } else { Run-Tool 'xsim' @("${bench}_snapshot",'--runall','--log',$log) }
        $result = Get-Content -LiteralPath $log -Raw
        if ($result -match '\bFAIL\b' -or $result -notmatch "(?m)^PASS ${bench}:") { throw "Integration test failed: $bench" }
    }
} finally { Pop-Location }
