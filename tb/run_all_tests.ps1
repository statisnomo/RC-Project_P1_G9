param(
    [Parameter(Mandatory = $true)]
    [string]$VivadoBin,
    [switch]$Waves
)

# Run all currently implemented simulations. No synthesis or board programming.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'build'
New-Item -ItemType Directory -Path $out -Force | Out-Null
$summary = Join-Path $out 'lab_test_summary.txt'
$started = [DateTimeOffset]::UtcNow.ToString('u')
@("Lab simulation run started (UTC): $started", 'Status: IN PROGRESS') |
    Set-Content -LiteralPath $summary -Encoding utf8

try {
    foreach ($tool in @('xvlog', 'xelab', 'xsim')) {
        $path = Join-Path $VivadoBin ($tool + '.bat')
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Cannot find $path. Set -VivadoBin to the installed Vivado bin folder."
        }
    }

    Write-Host '1/4: ALU, register file, decoder, immediate generator'
    & (Join-Path $PSScriptRoot 'run_cpu_tests.ps1') -VivadoBin $VivadoBin -Waves:$Waves
    Write-Host '2/4: CPU pipeline, memories, complete ROM program'
    & (Join-Path $PSScriptRoot 'run_integration_tests.ps1') -VivadoBin $VivadoBin -Waves:$Waves
    Write-Host '3/4: ALU board checker simulation'
    & (Join-Path $PSScriptRoot 'run_board_tests.ps1') -VivadoBin $VivadoBin
    Write-Host '4/4: CPU board checker simulation'
    & (Join-Path $PSScriptRoot 'run_cpu_board_tests.ps1') -VivadoBin $VivadoBin -Waves:$Waves

    $checks = @(
        @{ Log = 'cpu_tests/tb_alu.log'; Bench = 'tb_alu' },
        @{ Log = 'cpu_tests/tb_regfile.log'; Bench = 'tb_regfile' },
        @{ Log = 'cpu_tests/tb_decode.log'; Bench = 'tb_decode' },
        @{ Log = 'cpu_tests/tb_imm_gen.log'; Bench = 'tb_imm_gen' },
        @{ Log = 'cpu_integration/tb_cpu_core.log'; Bench = 'tb_cpu_core' },
        @{ Log = 'cpu_integration/tb_memories.log'; Bench = 'tb_memories' },
        @{ Log = 'cpu_integration/tb_soc_minimal.log'; Bench = 'tb_soc_minimal' },
        @{ Log = 'board_tests/selftest.log'; Bench = 'tb_alu_selftest' },
        @{ Log = 'cpu_board_tests/test.log'; Bench = 'tb_cpu_board' }
    )
    $lines = @("Lab simulation run started (UTC): $started", "Vivado bin: $VivadoBin")
    foreach ($check in $checks) {
        $logPath = Join-Path $out $check.Log
        $logText = Get-Content -LiteralPath $logPath -Raw
        $pattern = '(?m)^PASS ' + [regex]::Escape($check.Bench) + ':.*$'
        $pass = [regex]::Match($logText, $pattern)
        if ($logText -match '\bFAIL\b' -or -not $pass.Success) {
            throw "Missing PASS or failure in $logPath"
        }
        $lines += $pass.Value.Trim()
    }
    $lines += 'PASS ALL: 9 simulation testbenches completed.'
    $lines += 'Physical ALU and CPU board checks: not performed by this script.'
    $lines | Set-Content -LiteralPath $summary -Encoding utf8
    Write-Host 'PASS ALL: 9 simulation testbenches completed.'
    Write-Host "Summary: $summary"
}
catch {
    @("Lab simulation run started (UTC): $started", 'Status: FAILED', $_.Exception.Message) |
        Set-Content -LiteralPath $summary -Encoding utf8
    throw
}
