# Testing one piece at a time

For the Vivado GUI workflow, open [VIVADO_START_HERE.md](../VIVADO_START_HERE.md).
It provides the prepared project, simulation-set selection, Run All, and
waveform inspection using menus and buttons.

The project has individual CPU blocks and an integrated three-stage CPU
with instruction ROM and data RAM. Their self-checking simulations run on
a computer without an FPGA. Start with the ALU below, then follow the
[CPU program guide](cpu_pipeline.md). The standalone [ZedBoard ALU demo](zedboard_alu_demo.md)
provides the first physical board exercise. Both ALU and CPU board images
are now built; physical observation remains pending. For the complete file
pack, ordered commands, and expected results, start with
[the lab checklist](../LAB_START_HERE.md).

## The basic testing loop

For every test, write down the input and expected output before running it.
Drive those inputs, compare the actual output, and save the result. A
testbench is Verilog code that acts as test equipment around a module.
Simulation delays such as `#1` and testbench stimulus do not become the
hardware programmed onto the board.

Start with one ordinary example, then test boundaries, reset, invalid input,
and timing. For example, an ALU should add ordinary numbers correctly, but
also wrap `0xffffffff + 1` to zero. A register file should store values,
but must also ignore writes to x0 and hold data when write-enable is low.

## Run one block now

Open PowerShell and run:

```powershell
Set-Location 'D:\RC Project\riscv_soc_project'
.\tb\run_cpu_tests.ps1 -Test alu -Waves -VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'
```

This compiles only the ALU and its testbench, runs the checks, and saves
`build/cpu_tests/tb_alu.log` and `build/cpu_tests/tb_alu.wdb`. Expect
`PASS tb_alu: 4142 checks` and a final selected-tests PASS message.

Replace `alu` with `regfile`, `decode`, or `imm_gen` to test another block.
The decode bench also uses the ALU and immediate generator. Omit `-Waves`
when you only need the automatic checks. Omit `-Test` to run all four benches.
Adjust `-VivadoBin` if running on a different lab computer.

First exercise: read the first `check(...)` call in `tb/cpu/tb_alu.v`.
Its arguments are operand A, operand B, operation, expected result. The
first case is ADD with `ffffffff`, `00000001`, and expected `00000000`.
Predict both result and zero flag before opening the waveform.

Optional learning exercise: temporarily change that expected result to
`00000001`, rerun just the ALU, and observe the automatic FAIL. Restore
`00000000` and rerun. This demonstrates how the checker catches a mismatch;
it is not an RTL fix.

## Inspect the waveform

Open Vivado. In its Tcl Console, open the recorded ALU simulation:

```tcl
open_wave_database {D:/RC Project/riscv_soc_project/build/cpu_tests/tb_alu.wdb}
```

In the Scopes/Objects panes select `tb_alu` and add `operand_a`, `operand_b`,
`alu_op`, `result`, and `zero` to the Wave window. Create a waveform
configuration if none is open. Use hexadecimal display for the 32-bit values
and zoom into the first few nanoseconds. The first case is applied at time
zero and checked at 1 ns. These are simulator timestamps, not a measured
board delay. The ALU is combinational and has no clock.

For the register file, inspect `clk`, `rst`, `we`, `waddr`, `wdata`,
`raddr1`, and `rdata1`. Observe stored data changing after a rising edge;
asserting synchronous reset between edges does not clear it immediately.
Allow the nonblocking updates to settle when reading a waveform at an edge.

AMD documents [opening recorded simulations](https://docs.amd.com/r/2025.1-English/ug900-vivado-logic-simulation/Opening-a-Previously-Saved-Simulation-Run)
and [opening a waveform database](https://docs.amd.com/r/2021.2-English/ug835-vivado-tcl-commands/open_wave_database).
Use the same installed Vivado version for generating and viewing the WDB.

## Small milestones as the project grows

1. **Current blocks:** ALU arithmetic/zero; register writes/reset/x0;
   decoder controls/illegal instructions; immediate signs and bit placement.
2. **Connected datapath:** a decoded ADDI with source 10 and immediate -7
   must select the ALU result 3. Some combinational checks already exist in
   `tb_decode.v`; they do not execute a CPU program.
3. **CPU:** the [pipeline milestone](cpu_pipeline.md) now runs tiny programs
   with known final registers and RAM using `tb/run_integration_tests.ps1`.
   First straight-line arithmetic, then a dependency, then a load/store,
   then one branch/jump. Check that flushed instructions cannot write anything.
   Add a timeout so a hung CPU fails automatically.
4. **MMIO:** use a simple test peripheral before AES. Delay its response on
   purpose. Verify one accepted transfer per access, stable stalled requests,
   correct addresses/data, and correct return values under the bus contract.
5. **AES:** use published known-answer vectors and compare all 128 output
   bits. Check byte ordering, BUSY/DONE, reset, and repeated blocks. Check the
   AES core alone, then its MMIO wrapper, then CPU-driven encryption.
6. **Peripherals:** test keypad events and a fixed OLED pattern independently.
   Connect the full keypad-to-encryption-to-display flow last.

## Use short lab visits for physical checks

Prepare one small board top-level and its `.xdc` pin/clock constraints before
each visit. Synthesize, implement, review DRC and timing results, and generate
the bitstream in advance. A successful bitstream generation does not by
itself establish that timing requirements are met.

Useful first board tests, in order:

1. A slow LED blink driven by a counter using the PL oscillator.
2. A switch controlling an LED; then a button/reset check with proper input
   synchronization and debouncing where required. Keep the oscillator as
   the clock; use a clock-enable for manual stepping.
3. A small ALU test wrapper using fixed input vectors with explicit PASS/FAIL
   LEDs. This makes block testing possible before the CPU exists.
4. The [CPU smoke demonstration](zedboard_cpu_demo.md): a ROM program computes
   55, reads it from RAM, produces 56, and sends one delayed MMIO signature.
   Simulate it with `.\tb\run_cpu_board_tests.ps1 -Waves` before programming.
5. Keypad presses producing observable key codes, followed by an OLED showing
   a fixed pattern and then fixed text.

The ALU checker, heartbeat, and CPU smoke wrappers are implemented.
Switch/button, keypad, and OLED exercises are still future work.
The [local board references](references/zedboard/README.md) and
[I/O plan](board_io_plan.md) record the checked pin mapping, the old
manual's JA3 discrepancy, and the fixed-3.3 V versus VADJ distinction.
Check the physical board revision and selected Pmod connector against its
manual before assigning pins. ZedBoard has a 100 MHz PL oscillator and PL
user switches/LEDs, so early tests can operate without the ARM cores.
Its onboard USB-UART bridge connects to the PS UART. For our PL UART,
plan a compatible external UART connection on PL pins or use JTAG/ILA for
early observation; do not assume the onboard USB-UART is a direct PL port.
[Source: ZedBoard hardware guide, sections 2.3.2, 2.5, 2.7, and 2.9](https://files.digilent.com/resources/programmable-logic/zedboard/ZedBoard_HW_UG_v2_2.pdf).

An Integrated Logic Analyzer (ILA) is an FPGA debug core that captures
internal signals for viewing through Vivado Hardware Manager. It is useful
when LEDs cannot explain a failed transaction. It must be included in the
implemented design. [AMD ILA documentation](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/run_hw_ila).

For each visit, bring the bitstream and matching constraints/source snapshot;
bring its matching `.ltx` probe file if using ILA. Record test input, expected
result, actual result, and evidence such as a photo, waveform, or serial log.
Leave with one small test that passes and can be reproduced.

## What a pass means

Simulation establishes behavior for the cases checked. Synthesis/implementation
establish whether the design maps onto the target and meets the analyzed
constraints. Board tests establish physical behavior for the connected setup.
Keep these results separate. A programmed board or a lit DONE LED alone does
not establish that the application works.
