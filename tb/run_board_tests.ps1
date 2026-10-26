param([string]$VivadoBin = 'D:\VIVADO\2025.2\Vivado\bin')
$ErrorActionPreference = 'Stop'
function Run-Tool {
    param([string]$Name, [string[]]$ToolArguments)
    & (Join-Path $VivadoBin ($Name + '.bat')) @ToolArguments
    if ($LASTEXITCODE -ne 0) { throw "$Name failed: $LASTEXITCODE" }
}
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'build/board_tests'
New-Item -ItemType Directory -Path $out -Force | Out-Null
Push-Location $out
try {
    Run-Tool 'xvlog' @('--include', (Join-Path $root 'rtl/cpu'),
        (Join-Path $root 'rtl/cpu/alu.v'),
        (Join-Path $root 'rtl/board/alu_selftest.v'),
        (Join-Path $root 'rtl/board/zedboard_alu_demo.v'))
    Run-Tool 'xvlog' @('--sv', (Join-Path $root 'tb/board/tb_alu_selftest.v'))
    Run-Tool 'xelab' @('--debug', 'typical', 'tb_alu_selftest', '--snapshot', 'board_tests')
    if (Test-Path -LiteralPath 'selftest.log') { Remove-Item -LiteralPath 'selftest.log' }
    Run-Tool 'xsim' @('board_tests', '--runall', '--log', 'selftest.log')
    $result = Get-Content -LiteralPath 'selftest.log' -Raw
    if ($result -match '\bFAIL\b' -or $result -notmatch '(?m)^PASS tb_alu_selftest:') {
        throw 'Board simulation did not pass. Inspect build/board_tests/selftest.log.'
    }
} finally { Pop-Location }
