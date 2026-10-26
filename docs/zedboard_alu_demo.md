# First ZedBoard demonstration

This demonstration tests the existing ALU in real FPGA logic. It uses only
the PL clock and eight user LEDs. The CPU pipeline, ARM cores, keypad, and
OLED are not part of this demonstration.

## Verified on October 13, 2026

- Vivado Simulator 2025.2 passed all 16 vectors, result and zero-flag fault
  injection, first-failure retention, reset/rerun, LED mapping, and heartbeat.
- Vivado 2025.2 completed synthesis, placement, routing, and bitstream
  generation for `xc7z020clg484-1`.
- Final routed timing met the 100 MHz target: worst setup slack **+0.790 ns**,
  worst hold slack **+0.095 ns**, and no failing timing endpoints.
- All internal endpoints are constrained. The eight LED output paths are
  intentionally excluded because they have no external receiving clock.
- The design uses 499 LUTs and 121 flip-flops, with no BRAM or DSP blocks.
  The preserved `checked_alu` instance contains 390 LUTs.
- The DRC report contains one warning, `ZPS7-1: PS7 block required`, because
  the ARM processing-system block is absent. It was retained in the report,
  not suppressed. Bitstream generation completed with zero errors.
- **Physical ZedBoard testing is still pending.** The expected LED behavior
  below is the lab acceptance test, not an observation already made.

This demo takes its clock directly from the board oscillator on PL pin Y9;
it does not request clocks or signals from the processing system. A PL-only
design with independent clocking is described in
[Trenz Electronic's Zynq guidance](https://wiki.trenz-electronic.de/display/PD/ZYNQ%2BDesign%2Bnot%2Busing%2BA9%2BCores).
Use the board's documented JTAG boot setup for the lab exercise; do not
assume this bitstream supplies a standalone boot image for flash or SD.

The clock and LED assignments were cross-checked against the files
supplied on October 22; no active constraint changes were needed. See the
[local reference library](references/zedboard/README.md) and
[future I/O plan](board_io_plan.md) before adding peripherals.

## What each new file does

- `rtl/board/alu_selftest.v` applies 16 predetermined ALU test vectors. It
  loads each input on one clock edge and checks the result on the next.
  A mismatch sets a failure flag and records the first failing test number.
- `rtl/board/zedboard_alu_demo.v` connects the checker to the board. It
  generates a startup reset for 16 clocks, divides the clock for a heartbeat,
  and assigns status to the LEDs. This is the synthesis top-level module.
- `constraints/zedboard_alu_demo.xdc` assigns the clock and LEDs to physical
  pins and sets the 100 MHz clock constraint. It uses fixed 3.3 V banks 13
  and 33; the adjustable-voltage switch/button banks are unused.
- `tb/board/tb_alu_selftest.v` simulates healthy operation and deliberately
  corrupts ALU results and the zero flag. It checks first-failure retention,
  reset and rerun behavior, LED mapping, and heartbeat frequency.
- `tb/run_board_tests.ps1` compiles and runs this simulation using Vivado.
- `scripts/build_zedboard_demo.ps1` launches the FPGA build on Windows.
- `scripts/build_zedboard_demo.tcl` synthesizes, places, routes, checks timing,
  and writes the bitstream. It also verifies that ALU logic remains present.

The ALU instance and operand registers are preserved during synthesis so
this fixed-vector demonstration retains the ALU hardware. This preservation
is specific to the demonstration and is not an optimization policy for the
future CPU.

## Simulate before visiting the lab

Open PowerShell inside `riscv_soc_project`:

```powershell
.\tb\run_board_tests.ps1 -VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'
```

Use the actual Vivado path on the lab computer. Expect a line beginning
`PASS tb_alu_selftest:`. The log is `build/board_tests/selftest.log`.
The heartbeat divider is shortened in simulation so the test runs quickly.

## Build the FPGA bitstream

The installed Vivado must include support for Zynq-7000, specifically
`xc7z020clg484-1`. Run:

```powershell
.\scripts\build_zedboard_demo.ps1 -VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'
```

The output directory is `build/zedboard_alu_demo/`. A successful run produces:

- `zedboard_alu_demo.bit`: the file to program onto the board.
- `routed.dcp`: the implemented design checkpoint for inspection in Vivado.
- `timing.rpt`: timing results against the 10 ns clock period.
- `utilization.rpt`: the FPGA resources used, with the ALU hierarchy.
- `drc.rpt`: design-rule results.
- `build.log`: the complete build output, ending with `BUILD_PASS:`.

The script stops on a setup/hold timing failure and does not suppress
bitstream DRC errors. LED output paths have no external receiving clock and
are explicitly excluded from timing; the internal synchronous logic remains
timed. Results apply to this small demo, not the future full SoC.

## Program the board in the lab

1. Confirm that the lab board is a ZedBoard with the matching XC7Z020 part.
   Use its documented power supply and USB-JTAG connection.
2. Open Vivado Hardware Manager, then Open Target and Auto Connect.
3. Select the FPGA device and choose Program Device.
4. Select `zedboard_alu_demo.bit`. This demo has no ILA, so no `.ltx` probes
   file is needed. Program the device.
5. Observe the user LEDs by their printed LD labels. Reprogram the same
   bitstream to restart the test. The PROG button clears configuration; it
   is not this demo's reset input.

JTAG programming is a temporary configuration. This build does not update
the board's boot flash.

## What the LEDs mean

- LD0: heartbeat. It toggles every half-second, giving one full blink per second.
- LD1: PASS. It stays on after all 16 checks finish with no mismatch.
- LD2: FAIL. It stays on after any mismatch and remains set until reconfiguration.
- LD3: BUSY. It is on while tests run, which is too brief to observe by eye.
- LD7 through LD4: the first failing test number in binary, with LD7 as the
  most significant bit. They are off when no failure occurred.

Expected healthy result: **LD0 blinks, LD1 is on, LD2 and LD3 are off, and
LD7 through LD4 are off.** A DONE configuration LED alone is not a test pass.

## Fixed test vectors

Test numbers are zero-based. Expected results below are hexadecimal unless
written as a simple decimal equation.

- 0: ADD, 5 + 7 = 12.
- 1: SUB, 7 - 7 = 0; zero flag asserted.
- 2: AND, F0 and 0F = 0.
- 3: OR, F0 or 0F = FF.
- 4: XOR, AA55 xor 0F0F = A55A.
- 5: SLL, 1 shifted left by 31 = 80000000.
- 6: SRL, 80000000 shifted right by 31 = 1.
- 7: SRA, 80000000 shifted right by 31 = FFFFFFFF.
- 8: SLT, signed -1 is less than 1, so result = 1.
- 9: SLTU, unsigned FFFFFFFF is not less than 1, so result = 0.
- 10: ADD, FFFFFFFF + 1 wraps to 0.
- 11: SUB, 0 - 1 wraps to FFFFFFFF.
- 12: SLL, a shift operand of 32 means shift by zero; result = 12345678.
- 13: SRA, 80000001 shifted right by 1 = C0000000.
- 14: SLT, signed 80000000 is less than 7FFFFFFF, so result = 1.
- 15: reserved ALU control F produces 0.

Every vector checks both the 32-bit result and zero flag. These are small
demonstration checks; the existing ALU simulation covers many more vectors.

## Files to take

Copy the project sources, including the new `constraints/`, `scripts/`,
`rtl/board/`, and `tb/board/` directories, plus the beginner Word guide.
Also take the generated `.bit` file and matching reports from
`build/zedboard_alu_demo/` if the build succeeded. This bitstream is an
intentional exception to the earlier advice to leave generated build files
behind. Keep a photo or short video of the LED result alongside the build log.

## Pin references

Pin assignments were checked against the [Digilent master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Zedboard-Master.xdc).
Clock, voltage-bank, and LED details are in the [ZedBoard hardware guide](https://files.digilent.com/resources/programmable-logic/zedboard/ZedBoard_HW_UG_v2_2.pdf).
