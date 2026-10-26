param(
    # Omit when the Vivado tools are already on PATH or XILINX_VIVADO is set.
    [string]$VivadoBin = '',
    [ValidateSet('all', 'alu', 'regfile', 'decode', 'imm_gen')]
    [string]$Test = 'all',
    [switch]$Waves
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Find-SimTool {
    param([string]$Name)
    if ($VivadoBin) {
        $candidate = Join-Path $VivadoBin ($Name + '.bat')
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "Missing simulator tool: $candidate"
        }
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    throw "Cannot find $Name. Pass -VivadoBin with the Vivado bin directory."
}

function Invoke-SimTool {
    param([string]$Tool, [string[]]$ToolArguments)
    & $Tool @ToolArguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Tool failed with exit code $LASTEXITCODE."
    }
}

if (-not $VivadoBin -and $env:XILINX_VIVADO) {
    $VivadoBin = Join-Path $env:XILINX_VIVADO 'bin'
}
$xvlog = Find-SimTool 'xvlog'
$xelab = Find-SimTool 'xelab'
$xsim = Find-SimTool 'xsim'
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildDirectory = Join-Path $projectRoot 'build/cpu_tests'
New-Item -ItemType Directory -Path $buildDirectory -Force | Out-Null

# Select only the requested block and its dependencies. A broken unrelated
# module should not prevent a beginner from testing the ALU in isolation.
$dependencies = @{
    alu = @('alu')
    regfile = @('regfile')
    decode = @('alu', 'decode', 'imm_gen')
    imm_gen = @('imm_gen')
}
$selectedTests = if ($Test -eq 'all') {
    @('alu', 'regfile', 'decode', 'imm_gen')
} else {
    @($Test)
}
$rtlNames = @($selectedTests | ForEach-Object { $dependencies[$_] } | Select-Object -Unique)
$rtlFiles = @($rtlNames | ForEach-Object { Join-Path $projectRoot "rtl/cpu/$_.v" })
$benchFiles = @($selectedTests | ForEach-Object { Join-Path $projectRoot "tb/cpu/tb_$_.v" })

Push-Location $buildDirectory
try {
    # Compile production RTL as Verilog; only the benches need $fatal support.
    Invoke-SimTool $xvlog (@('--include', (Join-Path $projectRoot 'rtl/cpu')) + $rtlFiles)
    Invoke-SimTool $xvlog (@('--sv') + $benchFiles)
    if ($Waves) {
        # XSim's generated Tcl launcher can split absolute script paths with
        # spaces on Windows. Use a local filename inside the build directory.
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'capture_waves.tcl') -Destination 'capture_waves.tcl' -Force
    }

    foreach ($testName in $selectedTests) {
        $bench = 'tb_' + $testName
        $snapshot = $bench + '_snapshot'
        $simulationLog = $bench + '.log'
        Invoke-SimTool $xelab @('--debug', 'typical', $bench, '--snapshot', $snapshot)
        if (Test-Path -LiteralPath $simulationLog) {
            Remove-Item -LiteralPath $simulationLog
        }
        if ($Waves) {
            Invoke-SimTool $xsim @(
                $snapshot, '--log', $simulationLog, '--wdb', ($bench + '.wdb'),
                '--onfinish', 'stop',
                '--tclbatch', 'capture_waves.tcl'
            )
        } else {
            Invoke-SimTool $xsim @($snapshot, '--runall', '--log', $simulationLog)
        }
        # Some simulator releases can return zero after a fatal HDL error.
        # Require a fresh explicit PASS marker as well as a successful exit.
        $logText = Get-Content -LiteralPath $simulationLog -Raw
        if ($logText -match '\bFAIL\b' -or $logText -notmatch "(?m)^PASS ${bench}:") {
            throw "Self-check did not pass: $bench. See $buildDirectory/$simulationLog"
        }
        if ($Waves) {
            Write-Host "Waveform saved: $buildDirectory/$bench.wdb"
        }
    }
    Write-Host "PASS: selected CPU block simulations completed ($($selectedTests -join ', '))."
}
finally {
    Pop-Location
}
