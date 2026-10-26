# Lab pack: everything built so far

Prepared 22 October 2026. Start here after extracting the ZIP.

**Prefer Vivado's menus and buttons?** Use
[VIVADO_START_HERE.md](VIVADO_START_HERE.md) and the GUI project in the newer
GUI ZIP. This document retains the standalone-script procedure.

Test the small pieces first, then the connected CPU, then the FPGA board.
**All nine simulations run without a board.** Only the two physical tests
need a ZedBoard. AES, keypad, OLED, and UART controllers are still future
work; there are no implemented tests for those peripherals yet.

## 1. What to take

Copy the entire extracted `riscv_soc_project` folder to the lab computer.
Keep its subfolders together; do not run scripts inside the ZIP.

- `rtl/`: all implemented hardware.
- `tb/`: nine testbenches, runners, and the complete `programs/` folder.
- `fw/`: assembly smoke program and pre-encoded instruction ROM.
- `constraints/`: clock and pin assignments for each board demo.
- `scripts/`: synthesis and FPGA-build scripts.
- `docs/`: explanations, detailed board guides, and a blank lab record.
- `build/zedboard_alu_demo/` and `build/zedboard_cpu_demo/`: the two ready-built
  bitstreams and matching timing, utilization, and design-rule reports.
- `evidence/`: saved simulation results and existing CPU synthesis reports.
- `PACK_CONTENTS.txt`: the exact inventory of packaged files.
- `SHA256SUMS.txt`: hashes for those files.

The `.hex`, `.trace`, `.bus`, `.regs`, and `.ram` files in `tb/programs/` are
test inputs and expected answers. Keep them all. Generated simulator caches
are excluded and will be regenerated. Vivado itself is not included.

The newer GUI pack includes an `.xpr`; the original script-only ZIP did not.
The scripts below also select source files and top modules for you.
For **programming only**, the two `.bit` files and this
guide are enough. CPU ROM contents are already embedded in its bitstream.
Neither demo needs an ILA or `.ltx` debug-probe file.

## 2. Set up once

Use Windows PowerShell and Vivado with its simulator. Vivado **2025.2** is
the tested version. Rebuilding needs Zynq-7000 support for `xc7z020clg484-1`;
programming needs the lab's USB-JTAG drivers.
No RISC-V compiler or Python installation is needed to run the supplied
tests. Python is only needed if you change and regenerate the CPU vectors.

Open PowerShell **inside the extracted project folder**. Set the actual
Vivado path; this is an example:

```powershell
$VivadoBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
Test-Path (Join-Path $VivadoBin 'xvlog.bat')
Test-Path (Join-Path $VivadoBin 'xelab.bat')
Test-Path (Join-Path $VivadoBin 'xsim.bat')
```

All three should print `True`. Our development computer uses
`D:\VIVADO\2025.2\Vivado\bin`. Keep using the same PowerShell window so
`$VivadoBin` stays defined. If the lab manages script execution policy,
use its approved setup; a blocked script is a setup issue, not an RTL fail.

## 3. One command for every simulation

```powershell
.\tb\run_all_tests.ps1 -VivadoBin $VivadoBin -Waves
```

This runs all nine benches, stops on error, and writes
`build/lab_test_summary.txt`. It does not synthesize or program a board.
Success ends with:

```text
PASS ALL: 9 simulation testbenches completed.
```

Use the individual commands below to learn or diagnose each part. You do
not need to immediately repeat the suite after all tests have passed.

## 4. Test the four CPU building blocks

### Test 1: ALU — can it calculate correctly?

```powershell
.\tb\run_cpu_tests.ps1 -Test alu -Waves -VivadoBin $VivadoBin
```

- Hardware: `rtl/cpu/alu.v`. Testbench: **`tb/cpu/tb_alu.v`**.
- Checks: arithmetic, Boolean operations, shifts, signed/unsigned comparisons,
  zero flag, wraparound, and unsupported controls.
- Expected: `PASS tb_alu: 4142 checks`.
- Log/waveform: `build/cpu_tests/tb_alu.log` and `tb_alu.wdb`.

Small example: `ffffffff + 00000001` must give `00000000` with `zero=1`.
This block is combinational and has no clock.

### Test 2: register file — does it store and retrieve values?

```powershell
.\tb\run_cpu_tests.ps1 -Test regfile -Waves -VivadoBin $VivadoBin
```

- Hardware: `rtl/cpu/regfile.v`. Testbench: `tb/cpu/tb_regfile.v`.
- Checks: two read ports, writes, write enable, synchronous reset, and x0
  remaining zero even when a write to x0 is attempted.
- Expected: `PASS tb_regfile: 2456 port checks`.
- Log/waveform: `build/cpu_tests/tb_regfile.log` and `tb_regfile.wdb`.

Observe a stored value changing after the rising clock edge. Changing a
read address selects the stored value without waiting for a new write.

### Test 3: immediate generator — does it extract instruction constants?

```powershell
.\tb\run_cpu_tests.ps1 -Test imm_gen -Waves -VivadoBin $VivadoBin
```

- Hardware: `rtl/cpu/imm_gen.v`. Testbench: `tb/cpu/tb_imm_gen.v`.
- Checks: bit placement, sign extension, instruction formats, boundaries,
  and unrelated instruction bits.
- Expected: `PASS tb_imm_gen: 14546 checks`.
- Log/waveform: `build/cpu_tests/tb_imm_gen.log` and `tb_imm_gen.wdb`.

Compare `instr`, `imm_sel`, and `imm`. A negative immediate must remain
negative after being extended to 32 bits.

### Test 4: decoder — does an instruction select the right action?

```powershell
.\tb\run_cpu_tests.ps1 -Test decode -Waves -VivadoBin $VivadoBin
```

- Hardware: `rtl/cpu/decode.v`, connected to the ALU and immediate generator.
- Shared definitions: `rtl/cpu/cpu_defs.vh`. Testbench: `tb/cpu/tb_decode.v`.
- Checks: all 37 supported instructions, register/control selection,
  rejected encodings, and 15 connected datapath examples.
- Expected: `PASS tb_decode: 7717 decode checks, all 37 instructions, 15 combinational execution checks`.
- Log/waveform: `build/cpu_tests/tb_decode.log` and `tb_decode.wdb`.

These are decoder/datapath checks; running a CPU program is a separate test.

## 5. Test memory and the connected CPU

### Test 5: ROM/RAM — do reads and writes obey the bus rules?

```powershell
.\tb\run_integration_tests.ps1 -Test memories -Waves -VivadoBin $VivadoBin
```

- Hardware: `rtl/mem/instr_rom.v` and `rtl/mem/data_ram.v`.
- Testbench: `tb/cpu/tb_memories.v`.
- Checks: synchronous replies, byte lanes, first/last addresses, access
  errors, consecutive requests, and reset cancellation.
- Expected: `PASS tb_memories:` reporting **24 checks**.
- Log/waveform: `build/cpu_integration/tb_memories.log` and `tb_memories.wdb`.

RAM is not guaranteed to contain zeros after reset. Software must write
values before relying on them.

### Test 6: CPU — do instructions work when they interact?

```powershell
.\tb\run_integration_tests.ps1 -Test cpu_core -Waves -VivadoBin $VivadoBin
```

- Hardware: `rtl/cpu/cpu_core.v` plus the four CPU building blocks.
- Testbench: `tb/cpu/tb_cpu_core.v`. Expected data: all of `tb/programs/`.
- Checks: arithmetic, dependencies/forwarding, memory stalls, branches,
  jumps, discarded instructions, byte/halfword accesses, faults, MMIO,
  and reset while a store is pending.
- Expected: `PASS tb_cpu_core: 76 cases, 1287 retirements` followed by hazard
  counts and reset-cancellation confirmation.
- Log/waveform: `build/cpu_integration/tb_cpu_core.log` and `tb_cpu_core.wdb`.

A retirement means an instruction completed successfully. The bench compares
execution, bus transfers, final registers, and RAM with independent expectations.

### Test 7: minimal SoC — can the CPU run from ROM and use actual RAM?

```powershell
.\tb\run_integration_tests.ps1 -Test soc_minimal -Waves -VivadoBin $VivadoBin
```

- Connection module: `rtl/soc/soc_minimal.v`.
- Testbench: `tb/cpu/tb_soc_minimal.v`.
- Program: `fw/src/cpu_smoke.S`. Encoded ROM: `fw/cpu_smoke.hex`.
- Expected: `PASS tb_soc_minimal: ROM program, sum=55, load-use=56, one delayed MMIO write, 44 retirements`.
- Log/waveform: `build/cpu_integration/tb_soc_minimal.log` and `tb_soc_minimal.wdb`.

The program sums 1 through 10, stores **55** at `0x1000`, reloads it into x4,
increments it to **56** in x5, and stores 56 at `0x1004`. It writes 56 once
to `0x40000000`, waits for the reply, then loops at PC `0x30`. The checker
observes five final-loop instructions.

This MMIO target is a temporary signature checker. Although `0x40000000`
is the future AES base, the current test does **not** encrypt anything.

## 6. Test the two board checkers in simulation

### Test 8: ALU board checker

```powershell
.\tb\run_board_tests.ps1 -VivadoBin $VivadoBin
```

- Hardware: `rtl/board/alu_selftest.v` and `rtl/board/zedboard_alu_demo.v`.
- Testbench: `tb/board/tb_alu_selftest.v`.
- Checks: 16 fixed ALU vectors, deliberately bad results/zero flags,
  first-failure retention, reset/rerun, LED mapping, and heartbeat.
- Expected: `PASS tb_alu_selftest: 16 vectors, ...`.
- Log: `build/board_tests/selftest.log`.

This runner has no `-Waves` option. Use Test 1 for the ALU waveform exercise.

### Test 9: CPU board checker

```powershell
.\tb\run_cpu_board_tests.ps1 -Waves -VivadoBin $VivadoBin
```

- Hardware: `rtl/board/cpu_smoke_monitor.v` and `rtl/board/zedboard_cpu_demo.v`.
- Testbench: `tb/board/tb_cpu_board.v`.
- Checks: actual CPU/ROM/RAM execution, LED mapping, heartbeat, reset/restart,
  and 15 checker scenarios including bad transactions, duplicates, and timeout.
- Expected: `PASS tb_cpu_board: actual CPU/ROM/RAM, LED mapping, heartbeat, reset/restart, 15 checker scenarios`.
- Log: `build/cpu_board_tests/test.log`. Waves: `build/cpu_board_tests/cpu_board.wdb`.

Testing a checker with deliberately wrong results proves it can detect errors.
It is not enough for a checker to report PASS only on correct input.

## 7. Understand one waveform

In Vivado's Tcl Console, substitute your extracted folder's actual path:

```tcl
open_wave_database {C:/RC_Lab/riscv_soc_project/build/cpu_tests/tb_alu.wdb}
```

Select the testbench in Scopes, choose signals in Objects, and add them to
the Wave window. Use hexadecimal radix for buses, Zoom Fit, then zoom into
one event. A saved waveform is a recording; rerun with `-Waves` after editing.
[AMD's saved-simulation instructions](https://docs.amd.com/r/2025.1-English/ug900-vivado-logic-simulation/Opening-a-Previously-Saved-Simulation-Run)
describe this flow.

Save three useful screenshots:

1. ALU: `operand_a`, `operand_b`, `alu_op`, `result`, `zero`. Show the
   wraparound addition from Test 1. Simulator delays are not board measurements.
2. Register file: `clk`, `rst`, `we`, `waddr`, `wdata`, `raddr1`, `rdata1`.
   Show a write at a rising edge and the stored value being read.
3. SoC: open `build/cpu_integration/tb_soc_minimal.wdb` and select
   `tb_soc_minimal/dut`. Add `clk`, `mmio_valid`, `mmio_ready`, `mmio_write`,
   `mmio_addr`, and `mmio_wdata`. The request stays stable while waiting and
   completes on a rising edge where valid and ready are both high.
   **56 decimal is 38 hexadecimal.**

To follow instructions, add `trace_valid`, `trace_pc`, `trace_rd_we`,
`trace_rd`, and `trace_wdata`. A register result is meaningful when both
`trace_valid` and `trace_rd_we` are high. PASS logs remain required even if
you save waveform screenshots.

## 8. Synthesis and timing

For supplied images used unchanged, inspect the included reports. After
changing RTL, ROM, or constraints, rerun relevant simulations and rebuild.
An old bitstream does not contain your source edits.

Optional CPU structural check:

```powershell
.\scripts\check_cpu_synthesis.ps1 -VivadoBin $VivadoBin
```

Expected: `SYNTH_PASS:` confirming two BRAMs and no latches. Preliminary
synthesis timing is not a substitute for routed timing.

Full board builds:

```powershell
.\scripts\build_zedboard_demo.ps1 -VivadoBin $VivadoBin
.\scripts\build_zedboard_cpu.ps1 -VivadoBin $VivadoBin
```

Both should record `BUILD_PASS:` in their build log. Each output folder
contains its `.bit`, `timing.rpt`, `drc.rpt`, `utilization.rpt`, and `build.log`.
Constraints are `constraints/zedboard_alu_demo.xdc` and
`constraints/zedboard_cpu_demo.xdc`. Keep each PowerShell script and its
same-named Tcl script together.

Saved ALU build, **13 October**, 100 MHz: setup **+0.790 ns**, hold **+0.095 ns**.
Saved CPU build, **20 October**, 100 MHz: setup **+0.221 ns**, hold **+0.151 ns**.
Both have zero failing timing endpoints. The CPU retains two RAMB36 blocks.
These are existing implementation results, not physical-board observations.

Both retain `ZPS7-1: PS7 block required` because the processing system is
absent. The saved builds have no DRC errors. Only the eight LED outputs are
excluded from timing; internal logic is timed. Another Vivado version may
produce different slack/resource counts. Require nonnegative setup/hold
slack and investigate new warnings/errors.

## 9. Physical test A: ALU on the ZedBoard

Use the lab's board power supply and a USB data cable connected to the
USB-JTAG port, **J17**. Confirm board revision and target `xc7z020clg484-1`.

With power off, use the documented JTAG setup: JP7 at GND for cascaded JTAG,
JP8/JP9/JP10 at GND for JTAG boot, and JP11 at GND for PLL use. Identify GND
from the board labels/manual, not guessed jumper orientation. No Pmod is
needed. See [the ZedBoard hardware guide, sections 2.3.3, 2.10, and 4](https://files.digilent.com/resources/programmable-logic/zedboard/ZedBoard_HW_UG_v2_2.pdf).

1. Connect USB-JTAG, power the board, and open Vivado Hardware Manager.
2. Choose **Open Target > Auto Connect**.
3. Select the XC7Z020 device and choose **Program Device**.
4. Select `build/zedboard_alu_demo/zedboard_alu_demo.bit`.
5. Leave the debug-probes file empty and program the device.
6. Observe the user LEDs for at least five seconds.

Expected: **LD0 blinks once per second; LD1 stays ON; LD2 through LD7 stay OFF.**
LD0 changes state every half-second. BUSY is too brief to judge by eye.
This physically tests 16 ALU examples. Save a short LED video and the image
name. A configuration DONE light alone is not the application's PASS.

## 10. Physical test B: CPU on the ZedBoard

Repeat Program Device using `build/zedboard_cpu_demo/zedboard_cpu_demo.bit`.
Expect **LD0 blinking, LD1 ON, and LD2 through LD7 OFF**. Here PASS means
the CPU completed the checked program and one delayed MMIO signature write.

Reprogram the same image and verify the same result to check restart.
The demo resets itself after configuration. PROG clears the FPGA
configuration; it is not a wired demo reset. JTAG loading is temporary
and does not write a boot image to flash.

If LD2/FAIL is on, record all eight LEDs. LD7:LD4 is a binary diagnostic:
CPU codes 1–7 mean CPU faults; 8 bad signature; 9 duplicate; A bad trace;
B timeout; C early final loop; F halt without a fault code.
Details: [CPU board guide](docs/zedboard_cpu_demo.md).
For the ALU demo, those four LEDs instead show failed vector index 0–15:
[ALU board guide](docs/zedboard_alu_demo.md).

**Both physical checks remain pending until you observe them.** The short
CPU board program is one integration check; broader instruction coverage
comes from the separate simulation regression.

## 11. If something fails

- Missing tool: correct `$VivadoBin` and repeat the three `Test-Path` checks.
- Missing ROM/expected-data file: extract the whole project and run the
  supplied script so the working directory is correct.
- Compilation error: inspect `xvlog.log` or `xelab.log` in that test's build
  folder. No PASS means verification has not completed.
- Test FAIL: save the first mismatch and log. Do not change the expected
  answer just to make it pass.
- No hardware target: check power, J17, data cable, JTAG mode, and cable drivers.
- Only LD0 blinks: the heartbeat works, but the application has not shown
  PASS. Record LD1–LD7 and confirm which bitstream you loaded.
- LD2 on: save the diagnostic and compare with the matching demo guide.
- Bitstream generated but timing failed: fix the failing path before
  calling the modified design verified.

## 12. Save evidence before leaving

Fill in [docs/lab_record_template.md](docs/lab_record_template.md).
Keep `build/lab_test_summary.txt`, failure logs if any, selected waveform
screenshots, and one video per board demo. Note Vivado version, board
revision, and the programmed bitstream. Preserve the original ZIP.

This checklist is complete when all nine simulations pass and both board
demos show their expected LEDs. These are directed tests, not exhaustive
verification. Rebuilding is required for design changes; unchanged supplied
images have saved reports.
