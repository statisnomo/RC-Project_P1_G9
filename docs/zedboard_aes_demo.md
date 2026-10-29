# CPU plus AES on the ZedBoard

Build record: **27 October 2026**. Follow [the lab walkthrough](lab_2026-10-27.md)
for programming through Vivado's graphical interface.

This image connects the custom CPU, 4 KB ROM, 4 KB RAM, and AES register
interface. The CPU executes `fw/aes_smoke.hex`; the approved memory map is
unchanged. Only the 100 MHz PL clock and eight LEDs connect to board pins.

## What passing means

The firmware encrypts four blocks: the standard `001122...eeff` case,
the same block again with its key retained, a zero key/zero plaintext
case, and a different published key/plaintext case. It compares the
ciphertexts with fixed known answers and stores the four results in RAM.
It writes RAM status before reporting success through x31.

An independent hardware observer also checks all four completed START
writes, all 16 ciphertext reads and their order, access sizes, and the
firmware success report. It checks errors and a timeout and retains the
first failure. It does not compute AES or drive the bus.

This checks the real CPU-to-AES path on the FPGA. It does not yet check
keypad input, OLED output, UART, or the complete final demonstration.

## Image and build results

- Image: `build/zedboard_aes_demo/zedboard_aes_demo.bit`.
- Tool/target: Vivado **2025.2**, **xc7z020clg484-1**.
- Clock: **100 MHz**, 10 ns period.
- Routed setup slack: **+0.311 ns**; hold slack: **+0.159 ns**.
- Resource use: **3,182 total LUTs**, including one shift-register LUT;
  **2,084 flip-flops**, **two RAMB36 blocks**, zero DSPs.
- ROM/RAM remain block RAM; CPU ALU and AES logic remain in the design;
  no latches were inferred.
- No unclocked registers or unconstrained internal endpoints. Only the
  eight human-visible LED outputs are false paths.
- DRC: **zero errors**, one retained **ZPS7-1** warning about absent PS7.
  This is the same documented limitation of the PL-only board demos.

The timing, utilization, DRC, critical-path reports, routed checkpoint,
and build summary are beside the image. The build script refuses to write
an image if setup or hold fails. The first attempts missed timing; request
capture during the existing MMIO wait cycle shortened the response path.
No internal false paths or lower clock target were used to obtain this result.

**Physical PASS reported October 27: 3/3 AES trials**, with LD0 blinking,
LD1 ON, and LD2-LD7 OFF each time. See [the user's lab result](lab_results_2026-10-27.md).

## LED meanings

- **LD0:** heartbeat, about one full blink per second.
- **LD1:** PASS; stays on after all checks finish successfully.
- **LD2:** FAIL; remains on until the design is freshly programmed.
- **LD3:** test running; the healthy test can finish too quickly to see.
- **LD7:LD4:** first failure code, with LD7 the most significant bit.

Healthy result: **LD0 blinking, LD1 on, LD2-LD7 off**. The FPGA configuration
DONE LED is separate from these application LEDs.

If LD2 is on, record the four diagnostic LEDs:

- `0001` through `0111`: CPU fault codes from [the CPU guide](cpu_pipeline.md).
- `1000` (8): completed MMIO transfer reported an error.
- `1001` (9): incorrect ciphertext, read order, or read format.
- `1010` (A): unexpected START or an invalid/premature success report.
- `1011` (B): board checker timeout.
- `1100` (C): firmware reported a ciphertext mismatch.
- `1101` (D): firmware's AES polling timed out.
- `1111` (F): CPU stopped without a nonzero fault code.

## Rebuild and repeat

Use the prepared project's `zedboard_aes_demo` design top,
`zedboard_aes_demo.xdc` constraints, and `aes_smoke.hex` ROM. In Vivado:
**Run Synthesis > Run Implementation**, inspect routed timing/DRC, then
**Generate Bitstream**. A rebuild must pass its own reports; the supplied
image's margins do not establish another build's timing.

The GUI-generated image lives in
`vivado/riscv_soc_lab/riscv_soc_lab.runs/impl_1/zedboard_aes_demo.bit`.
The supplied image in `build/` is a separate recorded artifact.

For a fresh lab run, program the same supplied image again. Startup reset
is automatic. The PROG button removes configuration; it is not an
application reset. No `.ltx` probes file or permanent flash programming
is required.
