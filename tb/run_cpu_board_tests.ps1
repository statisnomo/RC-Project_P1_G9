param(
    [string]$VivadoBin = 'D:\VIVADO\2025.2\Vivado\bin',
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
$out = Join-Path $root 'build/cpu_board_tests'
New-Item -ItemType Directory -Path $out -Force | Out-Null
$sources = @('cpu/alu','cpu/regfile','cpu/decode','cpu/imm_gen','cpu/cpu_core','mem/instr_rom','mem/data_ram','soc/soc_minimal','board/cpu_smoke_monitor','board/zedboard_cpu_demo')
$rtl = @($sources | ForEach-Object { Join-Path $root "rtl/$_.v" })
Push-Location $out
try {
    Copy-Item -LiteralPath (Join-Path $root 'fw/cpu_smoke.hex') -Destination 'cpu_smoke.hex' -Force
    Run-Tool 'xvlog' (@('--include', (Join-Path $root 'rtl/cpu')) + $rtl)
    Run-Tool 'xvlog' @('--sv', (Join-Path $root 'tb/board/tb_cpu_board.v'))
    Run-Tool 'xelab' @('--debug','typical','tb_cpu_board','--snapshot','cpu_board_tests')
    if (Test-Path -LiteralPath 'test.log') { Remove-Item -LiteralPath 'test.log' }
    if ($Waves) {
        Copy-Item -LiteralPath (Join-Path $root 'tb/capture_waves.tcl') -Destination 'capture_waves.tcl' -Force
        Run-Tool 'xsim' @('cpu_board_tests','--log','test.log','--wdb','cpu_board.wdb','--onfinish','stop','--tclbatch','capture_waves.tcl')
    } else { Run-Tool 'xsim' @('cpu_board_tests','--runall','--log','test.log') }
    $result = Get-Content -LiteralPath 'test.log' -Raw
    if ($result -match '\bFAIL\b' -or $result -notmatch '(?m)^PASS tb_cpu_board:') {
        throw 'CPU board simulation did not pass. Inspect build/cpu_board_tests/test.log.'
    }
} finally { Pop-Location }
