# Next lab: type a block and read its AES ciphertext on the OLED

**November 5 update:** tests 21–26 and the exact external-OLED ciphertexts
have passed in the lab. This guide remains the working JA/JC reference.
For the new built-in display option, use [the onboard OLED guide](LAB_ONBOARD_OLED.md).
UART hardware and the explicit reliability/own-build evidence remain open.

The November 4 lab passed simulations 17–20 and both independent hardware demos. This visit tests the combined system. Bring the ZedBoard, Pmod KYPD and external Pmod OLED; a UART adapter is optional.

**New wiring: KYPD on JA, OLED on JC.** The keypad obstructs JB. Optional UART TX moves to **JD pin 1**, package V7. The old standalone OLED bitstream used JB; it is not the image for this visit.

## Files you receive

Use the **hardened November 5 kit**, `riscv_soc_hardened_ja_jc_2026-11-05.zip`. It contains the supplied `prebuilt/zedboard_display_ja_jc.bit`, complete Verilog, the ready-to-use `fw/display.hex` ROM, the single `constraints/zedboard_display.xdc`, and six simulation benches (tests 21–26). Use the supplied bitstream first if time is limited. You can also run implementation and generate a bitstream yourself from the same code. Extract into a fresh folder rather than mixing this ROM with an older kit.

The firmware now detects input overflow and has bounded peripheral status waits. An overflow discards the incomplete block through orderly shutdown/restart. A status timeout halts with LD7 on; save the observation and reprogram. These are recovery features, not new physical passes.

## Build your own image in Vivado

1. Extract the complete ZIP to a writable local folder. Start **Create Project → RTL Project** with part **xc7z020clg484-1**. This creates a project native to your installed Vivado version; no setup script is required.
2. **Add Sources → Add or Create Design Sources**: add all `.v` files in `rtl/cpu`, `rtl/mem`, `rtl/crypto`, `rtl/peripherals`, `rtl/soc`, and `rtl/board`, plus `rtl/cpu/cpu_defs.vh`. In this kit the only board top is `zedboard_display`. Right-click it → **Set as Top**. Keep the copied header together with the CPU files or set `rtl/cpu` in the project's Verilog include directories.
3. Add `fw/display.hex` as a **Memory Initialization File** in Design Sources. Confirm its file type in Source File Properties. Add only `constraints/zedboard_display.xdc` to Constraints. Do not add the old demo XDCs.
4. In **Settings → Synthesis**, set **flatten_hierarchy = none**; in **Settings → Implementation**, enable **phys_opt_design**. These match the supplied build. **Run Implementation** and allow Vivado to run synthesis first. Open the implemented design and check **Report Timing Summary**: WNS and WHS must both be nonnegative for the 10 ns clock. Run DRC and resolve any errors/critical warnings before use. The absence of ARM/PS7 produces the known PS7 warning in this PL-only project. Vivado versions can produce different timing; your lab report must pass on its own.
5. Click **Generate Bitstream**. In Design Runs, right-click `impl_1` → **Open Run Directory**. Program your `zedboard_display.bit`. It has the same JA/JC wiring as the supplied image. Save the filename, timestamp, timing report and a copy of your source with it.

## Simulations 21–26 — no board required

In **Add Sources → Add or Create Simulation Sources**, create a separate simulation set for each bench below. Add its `.sv` file, `tb/peripherals/keypad_matrix_model.v`, and `fw/display.hex` (Memory Initialization File). For test 26 also add `tb/internal/display_lab_vectors.mem` as a Memory Initialization File. Make the bench the simulation top. The other RTL remains in Design Sources. Choose **Run Behavioral Simulation → Run All**. Close each simulation before selecting the next one. Full warnings/Fatal text is more useful than a cropped FAIL line. You may add both memory files to every set for consistency.

- [ ] **21:** `tb/internal/tb_oled_access.sv`, top `tb_oled_access`: register access, cancellation, shutdown/discharge/restart. Expect `PASS tb_oled_access`.
- [ ] **22:** `tb/internal/tb_display_system.sv`, top `tb_display_system`: real CPU, matrix, AES, OLED and UART; three complete ciphertexts, all pixels, and a full block after restart. Expect `PASS tb_display_system`.
- [ ] **23:** `tb/internal/tb_display_board.sv`, top `tb_display_board`: the actual board wrapper, startup, key-held-at-boot suppression, open-drain pads and LEDs. Expect `PASS tb_display_board`.
- [ ] **24:** `tb/internal/tb_display_recovery.sv`, top `tb_display_recovery`: a real mailbox overflow, discarded partial block, recovery ciphertext, six injected status timeouts and reset recovery. Expect `PASS tb_display_recovery`. The bench shortens timeout counters after loading the production ROM; hardware retains its full budgets.
- [ ] **25:** `tb/internal/tb_display_bus.sv`, top `tb_display_bus`: four MMIO windows, invalid addresses, byte strobes, response routing and reset cancellation at waits 1/5. Expect `PASS tb_display_bus`.
- [ ] **26:** `tb/internal/tb_display_repeat.sv`, top `tb_display_repeat`: ten varied inputs at each of two bus delays, RAM/OLED snapshots and 660 decoded UART frames. Expect `PASS tb_display_repeat`. The expected values come from an independent .NET AES implementation.

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

Optional UART: follow [the separate UART side-test guide](LAB_UART_OPTIONAL.md). It covers a generic 3.3 V USB-to-TTL adapter and a Digilent PmodUSBUART, jumper wiring, GUI serial settings, expected lines and troubleshooting. Use the same combined image. Do not insert an unidentified UART module directly into JD.

## Extra physical tests — in this order

The first two known-answer blocks above are the priority. Then work through:

- [ ] **H1 — held key:** after shutdown/restart, hold the first `0` of the
  FIPS input for about two seconds. LD4 must change once, and must not keep
  changing while held. Release, then enter the remaining 31 digits
  `0112233445566778899AABBCCDDEEFF`. Expect the first ciphertext above.
- [ ] **H2 — partial input:** enter only 31 zeros. Wait two seconds; the old
  ciphertext and LD5 must remain unchanged. The 32nd zero must produce the
  second expected ciphertext. Release between every digit.
- [ ] **H3 — abandon a partial block:** enter `12345`, hold `0+D` until the
  shutdown-complete LED pattern, then release. The screen must restart blank.
  Enter the FIPS input from its first digit and compare all 32 output digits.
- [ ] **H4 — partial chord release:** during shutdown hold both `0+D`, then
  release only one key. Keep the other held for one second: the display must
  remain off. Release the last key: it should restart blank without accepting
  that held key as the first digit of a new block.
- [ ] **H5 — ten consecutive blocks:** follow the [ten-block reference sheet](docs/lab_ten_blocks.md)
  without resetting between blocks. Compare the full ciphertext each time.
  Leave a visible pause after each result, record PASS/FAIL per trial, and
  capture a short video showing both Pmods and the screen.
- [ ] **H6 — three fresh starts:** first do orderly shutdown and wait for LD1.
  For each trial power off, wait five seconds, power on, program the image
  with keys released and run the FIPS block. Record three results. Programming
  is volatile: power cycling alone does not guarantee that this image reloads.
- [ ] **H7 — your own build:** repeat the first known-answer block using your
  lab-generated bitstream, saving its timing report and exact filename.
- [ ] **U1 — optional UART:** capture the two reference lines and compare
  them with the OLED. Mark "not run — adapter unavailable" if needed.

Do not deliberately try to overflow the keypad by extremely fast entry in the
lab. Test 24 injects this condition reproducibly. If the screen unexpectedly
goes through shutdown and restarts blank, re-enter the entire block slowly and
record the observation; never assume that an incomplete block was preserved.

For a short visit, do tests 22/24 and the two physical reference blocks first,
then H1–H4. Keep H5–H7 and the optional UART check for the remaining time or
the next slot. Before final acceptance, finish all mandatory checks.

## What to record

- [ ] Exact Vivado version and the bitstream actually programmed: supplied or your build.
- [ ] Tests 21–26 and H1–H7/U1: PASS, FAIL or not run.
- [ ] First ciphertext exactly matches all 32 characters; photo with both Pmods visible.
- [ ] 31-digit partial input leaves the old result; digit 32 produces the second expected result.
- [ ] Holding 0+D shuts down; releasing restarts blank; another block works after restart.
- [ ] If you generated an image, save WNS/WHS and DRC along with that file.

The internal simulations and routed build do not prove physical text orientation or readability. If characters appear mirrored or upside down, photograph them in the board's normal orientation before changing code. If a key appears wrong, record printed key → LD3…LD0. Slow deliberate entry is intended: the single-entry mailbox can still overrun, but firmware now discards that incomplete block and restarts instead of silently continuing with missing digits. Status timeouts cover completed MMIO reads reporting busy forever; there is no watchdog for a bus that never returns READY. Save the first failure before reprogramming.
