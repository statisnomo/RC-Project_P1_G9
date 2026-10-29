# Run your CPU on the ZedBoard

This is the next lab exercise after the standalone ALU demonstration. The
FPGA contains our three-stage RISC-V CPU, instruction ROM, data RAM, and a
small result checker. The program calculates an answer and the checker
reports PASS or FAIL on the board's LEDs.

The ARM cores, keypad, OLED, and AES accelerator are not needed for this
exercise. The clock comes from the board's 100 MHz PL oscillator.

## What the program and checker do

The ROM contains `fw/cpu_smoke.hex`, matching `fw/src/cpu_smoke.S`.

1. The CPU adds the numbers 1 through 10 to get **55**.
2. It writes 55 into data RAM at `0x1000`, then loads it back into x4.
3. The next instruction adds one, producing **56** in x5.
4. It writes 56 into RAM at `0x1004` and to the demonstration's MMIO register.
5. It stays in a valid final loop at instruction address `0x30`.

The hardware observer checks the retired load into x4 and increment into x5,
the MMIO write's address/data/size/byte enables, and five passes through the
final loop. It delays the MMIO response by five clocks to exercise waiting.
It counts a write only when valid and ready meet on a clock edge.
The ready response depends on the registered wait count, so request-valid
logic does not feed straight back through ready into CPU control.

The result checker temporarily uses address `0x40000000`, which is reserved
for AES in the final SoC. This is a board-test configuration. Sending 56 to
that location is not an AES command. The checker will be replaced when AES
is connected.

The board checker observes execution through the CPU's trace signals and
MMIO port. The simulation additionally checks both actual RAM locations.
Passing this short program does not test all 37 instructions on hardware;
the separate CPU regression exercises the broader instruction subset.

## What changed in the CPU

The original timing bottleneck passed through the general ALU, its zero
result, branch/fault selection, and finally RAM control. The revised core
uses direct register comparisons for branches and a dedicated addition for
load/store addresses and JALR targets. PC-relative targets also have a
direct addition path. Memory requests check the faults relevant to a
memory instruction without waiting for branch-target decisions.

These changes preserve the three logical pipeline stages, instruction
subset, MMIO protocol, and clock target. There is no additional pipeline
stage or reduced clock frequency. The standalone ALU still implements all
of its original operations and zero flag.

## Files added for this milestone

- `rtl/board/cpu_smoke_monitor.v`: waits for and checks the expected results;
  detects bad writes, duplicates, CPU faults, missing progress, and bad trace values.
- `rtl/board/zedboard_cpu_demo.v`: connects the CPU system and checker,
  creates a 16-clock startup reset, and drives the heartbeat/status LEDs.
- `constraints/zedboard_cpu_demo.xdc`: assigns the existing clock/LED pins
  and constrains the design to a 10 ns clock period.
- `tb/board/tb_cpu_board.v`: tests the complete board wrapper and deliberately
  gives the checker incorrect results. It also checks reset and restart.
- `tb/run_cpu_board_tests.ps1`: runs that simulation and optionally saves waves.
- `scripts/build_zedboard_cpu.ps1` and `.tcl`: build the FPGA image, check
  routed setup/hold timing, and check that CPU logic and both BRAMs remain.

The core optimization is in `rtl/cpu/cpu_core.v`. The ROM program is unchanged.

## Simulate on your computer

From the `riscv_soc_project` directory:

```powershell
.\tb\run_cpu_board_tests.ps1 -Waves
```

Expect a line beginning `PASS tb_cpu_board:`. The log and waveform are in
`build/cpu_board_tests/test.log` and `build/cpu_board_tests/cpu_board.wdb`.
The test shortens the heartbeat divider so it can check blinks quickly.
The normal board heartbeat still toggles every half-second.

To run the broader CPU and memory checks:

```powershell
.\tb\run_integration_tests.ps1
```

All commands default to `D:\VIVADO\2025.2\Vivado\bin`. On a lab machine,
add `-VivadoBin 'C:\path\to\Vivado\bin'` with its actual installation path.

## Build the FPGA image

```powershell
.\scripts\build_zedboard_cpu.ps1
```

The output directory is `build/zedboard_cpu_demo/`. A successful build
produces `zedboard_cpu_demo.bit`, `routed.dcp`, `timing.rpt`,
`critical_paths.rpt`, `utilization.rpt`, `drc.rpt`, `build.log`, and
`bitstream.sha256`. The hash helps identify the exact bitstream you copy.

The script removes only its previous bitstream before rebuilding and stops
if setup or hold timing fails. It does not program a connected board.
Only the eight human-visible LED output paths are excluded from timing;
the internal CPU, RAM, and checker paths remain constrained.

Use a fresh build when changing the ROM program. This is a compiled FPGA
demonstration, and a different program also requires updating the checker's
expected addresses and results.

## What to take to the lab

For programming the existing image, take `zedboard_cpu_demo.bit` and this
guide. Keep `bitstream.sha256` and `timing.rpt` with them to identify the
verified build. No `.ltx` file is required because this demo has no ILA.

For changing, simulating, or rebuilding it, copy the entire project source
folder, including `rtl/`, `constraints/`, `scripts/`, `tb/`, `fw/`, and `docs/`.
Keep the original ALU demonstration as an independent first board check.

## Program and observe

1. Use the lab's ZedBoard power and USB-JTAG setup, with the board's documented
   JTAG boot configuration. The target part is `xc7z020clg484-1`.
2. In Vivado Hardware Manager, select Open Target, Auto Connect, then Program Device.
3. Choose `build/zedboard_cpu_demo/zedboard_cpu_demo.bit`.
4. Observe the user LEDs by their printed LD numbers.
5. Reprogram the same bitstream to restart the demonstration.

This uses the same PL pin mapping as the ALU demo: Y9 for the clock and
the eight fixed-voltage LED pins. The adjustable-voltage button/switch banks
are unused. JA-JD Pmods instead use fixed 3.3 V bank 13, also unused by this
demo. The [local reference library](references/zedboard/README.md) and
[I/O plan](board_io_plan.md) record the October 22 cross-check. Also see the
[Digilent master constraints](https://github.com/Digilent/digilent-xdc/blob/master/Zedboard-Master.xdc)
and [ZedBoard hardware guide](https://files.digilent.com/resources/programmable-logic/zedboard/ZedBoard_HW_UG_v2_2.pdf).

JTAG programming is temporary; this flow does not write boot flash or make
an SD boot image. The PROG button clears the FPGA configuration; it is not
a reset input to this demonstration.

Expected healthy behavior:

- **LD0 blinks:** the PL clock and heartbeat counter are running.
- **LD1 stays on:** the program produced the checked results.
- **LD2 is off:** no detected failure.
- **LD3 is off:** the short smoke test has finished. Its initial busy period
  is too brief to judge by eye.
- **LD7 through LD4 are off:** no failure code.

The heartbeat runs independently of the CPU. A blinking LD0 alone does not
prove the CPU is executing correctly. Likewise, the FPGA's configuration
DONE light is not the program's PASS indication.

## If FAIL lights up

LD7–LD4 show the first diagnostic in binary, with LD7 as the most significant bit:

- **1–7:** the CPU's fault code, defined in `docs/cpu_pipeline.md`.
- **8:** the signature write has an incorrect address, value, direction,
  access size, or byte enables.
- **9:** a second signature write occurred, including after PASS.
- **A (1010):** the observed load/increment wrote an incorrect register or value.
- **B (1011):** the result did not arrive within 1,000,000 clocks, about 10 ms.
- **C (1100):** the program reached the final loop without the required earlier results.
- **F (1111):** the CPU reported a halt without a nonzero fault code.

The first error stays visible until reconfiguration. The observer continues
checking CPU faults and duplicate writes after PASS, but does not impose a
new progress timeout once the smoke test has completed.

Record the LED pattern and whether the heartbeat is blinking. Do not change
the expected result to make an unexplained failure disappear.

## Verification record — October 20, 2026

Vivado Simulator 2025.2 passed the CPU regression: **76 cases, 1,287 checked
retirements**, the existing forwarding/stall/branch-fault coverage, and
**24 memory checks**. The integrated program again produced 55 and 56 with
one delayed MMIO write.

The new board simulation passed the actual CPU/ROM/RAM program, LED mapping,
heartbeat, reset/restart, and **15 checker scenarios** including deliberately
incorrect transactions and trace values, timeout, premature completion,
and sticky failure behavior.

The separate synthesis check retained two RAMB36 blocks and no latches.
Its preliminary setup slack improved from **−3.098 ns to +0.940 ns** at
100 MHz. It uses 1,382 LUTs and 913 flip-flops in the smoke-program
configuration.

The full CPU board build also passed placement, routing, and bitstream
generation for `xc7z020clg484-1` at **100 MHz**:

- Worst setup slack: **+0.221 ns**.
- Worst hold slack: **+0.151 ns**.
- Zero failing setup, hold, or pulse-width endpoints.
- Zero unconstrained internal endpoints and zero combinational/latch loops.
- 1,382 LUTs, 892 flip-flops, and two RAMB36 blocks; CPU ALU logic is retained.

These are results for this CPU smoke-test configuration. AES and the other
peripherals will require a new timing check when integrated.

Vivado retained one design-rule warning, **ZPS7-1: PS7 block required**,
because this PL-only build does not instantiate the processing system.
The warning is recorded in `drc.rpt`, not suppressed. There were no DRC
errors, and bitstream generation completed successfully. The physical
test result is recorded below.

The generated image is `build/zedboard_cpu_demo/zedboard_cpu_demo.bit`.
Its SHA-256 matches the saved `bitstream.sha256`:

```text
5B29D73D06769742961419AD243E45CF884AFF1B1A5101B8531726B1830556AD
```

**Physical PASS reported October 27:** LD0 blinking, LD1 ON, LD2-LD7 OFF.
See [the user's lab result](lab_results_2026-10-27.md); the standalone CPU
repeat count was not separately stated.
