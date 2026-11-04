# Next lab: type a block and read its AES ciphertext on the OLED

The November 4 lab passed simulations 17–20 and both independent hardware demos. This visit tests the combined system. Bring the ZedBoard, Pmod KYPD and external Pmod OLED; a UART adapter is optional.

**New wiring: KYPD on JA, OLED on JC.** The keypad obstructs JB. Optional UART TX moves to **JD pin 1**, package V7. The old standalone OLED bitstream used JB; it is not the image for this visit.

## Files you receive

The combined ZIP contains the supplied `prebuilt/zedboard_display_ja_jc.bit`, complete Verilog, the ready-to-use `fw/display.hex` ROM, the single `constraints/zedboard_display.xdc`, and three new simulation benches. Use the supplied bitstream first if time is limited. You can also run implementation and generate a bitstream yourself from the same code.

## Build your own image in Vivado

1. Extract the complete ZIP to a writable local folder. Start **Create Project → RTL Project** with part **xc7z020clg484-1**. This creates a project native to your installed Vivado version; no setup script is required.
2. **Add Sources → Add or Create Design Sources**: add all `.v` files in `rtl/cpu`, `rtl/mem`, `rtl/crypto`, `rtl/peripherals`, `rtl/soc`, and `rtl/board`, plus `rtl/cpu/cpu_defs.vh`. In this kit the only board top is `zedboard_display`. Right-click it → **Set as Top**. Keep the copied header together with the CPU files or set `rtl/cpu` in the project's Verilog include directories.
3. Add `fw/display.hex` as a **Memory Initialization File** in Design Sources. Confirm its file type in Source File Properties. Add only `constraints/zedboard_display.xdc` to Constraints. Do not add the old demo XDCs.
4. **Run Implementation** and allow Vivado to run synthesis first. Open the implemented design and check **Report Timing Summary**: WNS and WHS must both be nonnegative for the 10 ns clock. Run DRC and resolve any errors/critical warnings before use. The absence of ARM/PS7 produces the known PS7 warning in this PL-only project.
5. Click **Generate Bitstream**. In Design Runs, right-click `impl_1` → **Open Run Directory**. Program your `zedboard_display.bit`. It has the same JA/JC wiring as the supplied image. Save the filename, timestamp, timing report and a copy of your source with it.

## Three new simulations, if time permits

In **Add Sources → Add or Create Simulation Sources**, create a separate simulation set for each bench below. Add its `.sv` file, `tb/peripherals/keypad_matrix_model.v`, and `fw/display.hex` (Memory Initialization File). Make the bench the simulation top. The other RTL remains in Design Sources. Choose **Run Behavioral Simulation → Run All**. Close each simulation before selecting the next one. Full warnings/Fatal text is more useful than a cropped FAIL line.

- [ ] **21:** `tb/internal/tb_oled_access.sv`, top `tb_oled_access`: register access, cancellation, shutdown/discharge/restart. Expect `PASS tb_oled_access`.
- [ ] **22:** `tb/internal/tb_display_system.sv`, top `tb_display_system`: real CPU, matrix, AES, OLED and UART; two complete ciphertexts and pixel streams. Expect `PASS tb_display_system`.
- [ ] **23:** `tb/internal/tb_display_board.sv`, top `tb_display_board`: the actual board wrapper, startup, key-held-at-boot suppression, open-drain pads and LEDs. Expect `PASS tb_display_board`.

The tests shorten device delays for simulation; hardware uses the full delays. Existing tests 1–20 are already passed and need not be repeated just for the record.

## Physical test

1. With board power **off**, put KYPD J1 on **JA** and OLED J1 on **JC**, pin 1 to pin 1 and both rows aligned. Leave JB free. Use the programming connection that worked in the previous lab. The photographed DLC9LP is a programming cable; no UART adapter is required.
2. Power up; in **Hardware Manager → Open Target → Program Device**, select `zedboard_display_ja_jc.bit` (or your locally generated image). Clear any stale probes file. Keep keys released during configuration. After startup, the OLED should be blank, LD6 blinking and LD7 off.
3. Tap and release each digit of **00112233445566778899AABBCCDDEEFF**. Do not hold two keys together during input. LD3…LD0 show the latest hex digit; LD4 changes once per accepted press. After digit 32, expect these two lines, in order:

```text
69C4E0D86A7B0430
D8CDB78070B4C55A
```

The public demonstration key is `000102030405060708090A0B0C0D0E0F`. LD5 changes after the firmware has submitted the display and sent its UART line; it is not a ciphertext-correctness flag. Compare the screen itself and photograph it.

4. Release between all presses and enter **32 zeros**. Expect:

```text
C6A13B37878F5B82
6F4F8162A1C8D879
```

The first result stays visible while entering the second block. A partial block must not replace it. Check 31 digits first, then enter digit 32.

5. **Shutdown/restart:** press and hold **0 and D together**. Once detected as a chord, input stops, the display goes dark and the controller discharges the panel supply. Keep holding for roughly **4 seconds**, until **LD1 on, LD0/LD2–LD5 off** (LD6 still blinking; LD7 off). You can then power off while holding the keys. Alternatively release both: it restarts with a blank display and an empty input block. Any chord seen by the scanner requests this operation; it is also how to discard a partial block. If your first finger registers before the second, that partial digit is discarded during shutdown.

Optional UART: only with a confirmed **3.3 V logic** USB-to-TTL adapter, connect **JD pin 1 → adapter RX** and a ground pin to adapter GND. Do not connect adapter power or TX. At 115200, 8N1, expect each 32-character ciphertext followed by LF. The ZedBoard's onboard PS UART is not this PL output.

## What to record

- [ ] Exact Vivado version and the bitstream actually programmed: supplied or your build.
- [ ] Tests 21/22/23: PASS, FAIL or not run.
- [ ] First ciphertext exactly matches all 32 characters; photo with both Pmods visible.
- [ ] 31-digit partial input leaves the old result; digit 32 produces the second expected result.
- [ ] Holding 0+D shuts down; releasing restarts blank; another block works after restart.
- [ ] If you generated an image, save WNS/WHS and DRC along with that file.

The internal simulations and routed build do not prove physical text orientation or readability. If characters appear mirrored or upside down, photograph them in the board's normal orientation before changing code. If a key appears wrong, record printed key → LD3…LD0. Slow deliberate entry is intended: the current single-entry keypad mailbox can overrun if input arrives too quickly while firmware is busy; firmware timeouts and overflow recovery remain future work.
