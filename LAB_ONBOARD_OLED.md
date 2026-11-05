# Next step: use the ZedBoard's built-in OLED

The existing JA-keypad / JC-Pmod-OLED system passed the user's November 5 lab
tests and displayed the expected ciphertexts. This new variant uses the small
OLED already mounted on the ZedBoard, so the external Pmod OLED is unnecessary.
The CPU, AES accelerator, firmware and keypad behaviour are the same.

## Why this works

The onboard DISP1 is a 128x32 OLED connected to PL bank 13. Its signals are
SDIN AA12, SCLK AB12, D/C U10, reset U9, VBAT control U11 and VDD control U12.
Both supply controls are active low. The board ties OLED CS# to ground, so
there is no FPGA CS output for this variant. The serial controller emits no
extra clocks between bytes and test 27 checks the stream without CS framing.

References: [Digilent master XDC](https://raw.githubusercontent.com/Digilent/digilent-xdc/master/Zedboard-Master.xdc),
[ZedBoard hardware guide](https://files.digilent.com/resources/programmable-logic/zedboard/ZedBoard_HW_UG_v2_2.pdf),
and the archived schematic, sheet 6. The revision-D schematic also lists
the onboard OLED circuit. No ARM software or VADJ jumper change is required.

## Files and wiring

Download [riscv_soc_onboard_oled_2026-11-05.zip](https://github.com/statisnomo/RC-Project_P1_G9/raw/refs/heads/main/deliverables/riscv_soc_onboard_oled_2026-11-05.zip). The supplied image is
`prebuilt/zedboard_display_onboard.bit`.

- Keep **Pmod KYPD on JA**.
- With power off, **remove the external OLED from JC**; use the display
  already mounted on the board. No display wiring or jumper leads are needed.
- Optional UART is still **JD pin 1**, with the same adapter guide.
- Keep the old JA/JC kit as a working backup. Its `.bit` drives the external
  display; this onboard `.bit` drives the built-in display. They are distinct.

## Build it yourself in Vivado

1. Extract this ZIP to a short writable path and create an RTL project for
   **xc7z020clg484-1** in the lab's installed Vivado version.
2. Add all `.v` files from the supplied `rtl` folders and `rtl/cpu/cpu_defs.vh`.
   Both board wrapper files are needed. Set **`zedboard_display_onboard` as top**.
3. Add `fw/display.hex` as a **Memory Initialization File**. Add only
   **`constraints/zedboard_display_onboard.xdc`**. Do not mix it with the
   external-display constraints; the two builds use different display pins.
4. Set synthesis `flatten_hierarchy` to **none** and enable implementation
   **phys_opt_design**. Run Implementation. Check the 10 ns clock, WNS/WHS
   nonnegative and no DRC errors/critical warnings. The known PL-only ZPS7-1
   warning is recorded in the supplied reports.
5. Generate Bitstream. Program the resulting `zedboard_display_onboard.bit`
   in Hardware Manager and save its timing report. No script is required
   for this GUI workflow. The supplied `.bit` is available if lab time is short.

## New small simulation: test 27

Add `tb/internal/tb_display_onboard.sv`,
`tb/peripherals/keypad_matrix_model.v`, and `fw/display.hex` to a simulation
set. Set **`tb_display_onboard`** as simulation top, then
**Run Behavioral Simulation → Run All**. Expected result:

```text
PASS tb_display_onboard: CS tied low, 2095 SPI bytes, two exact ciphertext frames, 66 UART frames at divider 868, power sequencing, partial chord release and restart
```

The test shortens display startup/discharge delays; the hardware keeps its
normal delays. It uses the actual board wrapper and the production UART
divider. Tests 21–26 are included for regression, but their November 5 lab
passes are already recorded; no need to rerun them solely for the record.

## Physical test — one small step at a time

1. Program the onboard image with all keys released. The onboard OLED should
   become blank, LD6 should blink and LD7 should stay off.
2. Enter `00112233445566778899AABBCCDDEEFF`. Expect:

```text
69C4E0D86A7B0430
D8CDB78070B4C55A
```

3. Enter 31 zeros and pause: the previous result should remain. Enter the
   last zero. Expect:

```text
C6A13B37878F5B82
6F4F8162A1C8D879
```

4. Hold **0+D** until the screen is off and LD1 indicates shutdown complete
   (roughly four seconds; LD6 still blinks). Release one key while holding
   the other: it should remain off. Release the last key: it should restart
   blank. Enter the first block again and verify the complete result.
5. Photograph the onboard text and keypad together, noting the bitstream
   filename. If mirrored or upside down, save a photo before changing code.
6. Once the basic test passes, use [the ten-block sheet](docs/lab_ten_blocks.md)
   and record three fresh-start trials. Shut down the OLED before power-off;
   after power-on, reprogram this image before each trial.

LD3–LD0 show the last digit, LD4 toggles per accepted digit, LD5 toggles after
the firmware submits a result and sends the UART line, LD6 is heartbeat,
LD7 is a fault. LD5 alone is not proof of a correct ciphertext: compare all
32 displayed digits. There is no input through the PS reset button.

UART remains a side test using [the adapter instructions](LAB_UART_OPTIONAL.md).
Mark it not run if no suitable adapter is available.

## Record the result

- [ ] Test 27: PASS / FAIL / not run; save the first error if any.
- [ ] Onboard first ciphertext: exact match, photo saved.
- [ ] Partial input and second ciphertext: correct.
- [ ] Shutdown, partial release, restart and another block: correct.
- [ ] Supplied or own-generated image identified; save own-build timing.
- [ ] Ten blocks / three fresh starts: record actual counts, not just "works".
- [ ] Optional UART: pass / fail / not run.

The onboard image's simulation and implementation results are local tests.
Vivado 2025.2 passed all seven included simulations and routed the design at
100 MHz: setup slack **+0.241 ns**, hold slack **+0.106 ns**, no DRC errors
or critical warnings. Utilization is 3,562 LUTs, 2,509 flip-flops and two
36 Kb BRAMs. Your Vivado version may place the design differently, so check
its own timing report after generating a new image.
Its physical pass remains pending until the lab confirms it. The earlier
external-Pmod display pass does not automatically validate this wiring.
