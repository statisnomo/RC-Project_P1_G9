# November 3–4 lab: build your own bitstreams, then test the two Pmods

**Today (Nov 3):** do tests 17–20 on the lab PC and generate both bitstreams yourself. **Tomorrow (Nov 4):** test the real keypad and OLED separately. No UART adapter or serial terminal is needed. Tests 1–16 already passed in the lab.

## 1. Start in Vivado — no terminal

1. Extract the **entire weekly ZIP** to a new writable local folder, e.g. `C:\RC_Nov03`. Work in the folder containing this guide. Do not work inside the ZIP. Keep it for tomorrow.
2. Launch the lab's Vivado 2020.x. With no project open, choose **Tools → Run Tcl Script** and select **scripts/create_keypad_board_project.tcl**. This once-only setup creates and opens a project in *your installed version*. It references the RTL in your extracted folder; keep those files together. If the part is missing, have the lab enable **Zynq-7000 → xc7z020clg484-1** device support.
3. Confirm **Design Sources** top `zedboard_keypad_aes`, **Constraints** `zedboard_keypad_aes.xdc`. Under **Simulation Sources**, choose the set listed below (right-click → **Make Active**, or **Settings → Simulation → Simulation set**). Choose **Run Simulation → Run Behavioral Simulation**, then click **Run All**. Copy the final PASS line from the Vivado Tcl Console. Close **only the simulation** between tests.
4. After tests 17–19, build this project as in section 2. Close the project. Choose **Tools → Run Tcl Script → scripts/create_oled_board_project.tcl**. Confirm top `zedboard_oled_pattern` and `zedboard_oled_pattern.xdc`. Run test 20 and build that project too. Tomorrow reopen the same .xpr from **File → Project → Open**. Rerunning a setup script deliberately creates a new numbered folder.

| Done | Test / simulation set | What proves it worked |
|---|---|---|
| [ ] | 17 · `sim_keypad_scanner` | `PASS tb_keypad_scanner:` — all 16 positions, bounce, holds and multi-key rejection. |
| [ ] | 18 · `sim_keypad_mmio` | `PASS tb_keypad_mmio:` — reads retain the first press; CPU acknowledgment frees its slot. |
| [ ] | 19 · `sim_keypad_aes` | `PASS tb_keypad_aes:` — 64 printed digits, 64 ACKs, two ciphertexts checked byte by byte in RAM. |
| [ ] | 20 · `sim_oled_pattern` | `PASS tb_oled_pattern:` — 1,048 SPI bytes checked at the output pins, clear, checkerboard, power sequencing. |

**One useful waveform:** In test 19 expand `tb_keypad_aes → dut`; add `addr`, `v`, `w`, `kr`, `ar` and `led` to Wave. Use **Restart → Run All**. After the 32nd digit, look for a completed write of 1 at **0x40000000** (AES START), followed by reads of **0x40000030–3C**. For input `00112233445566778899AABBCCDDEEFF`, public test key `000102030405060708090A0B0C0D0E0F`, ciphertext in byte order is **69C4E0D86A7B0430D8CDB78070B4C55A**. The four RAM words starting at 0x1020 read **D8E0C469 30047B6A 80B7CDD8 5AC5B470** (little endian). The second block is all zeros with the same key.

## 2. Generate a new .bit on the lab PC, including after edits

1. In the correct board project edit the design file under **Sources → Design Sources** and save it. To practice with a visible change, in the OLED project change only the default `VIEW_CYCLES` from `800000000` to `400000000` (eight seconds → four at 100 MHz). Leave the reset and supply delays alone. Test 20 uses shorter overridden delays; the timed physical observation checks the changed default.
   For firmware changes, edit `fw/src/keypad_aes.S`, then open `fw/build_keypad_aes.py` in Python 3 IDLE and choose **Run → Run Module (F5)** to regenerate `fw/keypad_aes.hex` before synthesis. The supplied ROM and all RTL edits need no Python. The helper supports the instruction forms in the supplied assembly source.
2. Run the affected behavioral test to PASS; close the simulation. Click **Flow Navigator → Program and Debug → Generate Bitstream**. Agree to run synthesis and implementation if prompted. Wait for **Bitstream Generation Completed**. A board need not be connected.
3. After another edit, if Vivado still shows the previous run as complete, open **Design Runs**, right-click **synth_1 → Reset Run**, then **Generate Bitstream** again. Resetting a run discards its generated products; first copy any image/reports you want to retain. Keep the sources.
4. **Open Implemented Design → Reports → Timing → Report Timing Summary**. Require setup **WNS ≥ 0** and hold **WHS ≥ 0** on the 10 ns clock. **Report DRC**: no errors or critical warnings; check I/O Ports against the project's XDC. Save reports from your build. Do not use an image with missing pins or failed timing.
5. The new image is under **vivado/<project>/<project>.runs/impl_1/<top>.bit**, where the project directory is printed as `LAB_BOARD_PROJECT_READY`. In **Design Runs**, right-click **impl_1 → Open Run Directory** to find it. Copy your .bit to a folder named for today's date/edit; record the filename and timestamp. Two projects produce two different images. For comparison the ZIP's **prebuilt/** folder has the locally generated reference images.

If the simulation fails, save the **first Fatal or ERROR**, the simulation set and Vivado version. If synthesis or implementation fails, open the failed run's **Messages** or **runme.log**, and save the first error. A simulation PASS does not supply a bitstream. A generated bitstream does not prove that the module is wired correctly.

## 3. On the ZedBoard: keypad (JA)

- [ ] Bring ZedBoard, its power supply, USB-JTAG data cable, Digilent Pmod KYPD and external Pmod OLED. Power **off** to attach/remove modules. Fit KYPD J1 to **JA**, both rows, pin 1 to pin 1; confirm 3.3 V/GND alignment. Leave OLED detached for this test. Connect USB to **J17**. Power on.
- [ ] **Hardware Manager → Open Target → Auto Connect → xc7z020 → Program Device**. Browse explicitly to **your** `zedboard_keypad_aes.bit`. Clear any stale probes file. Program with all keys released. LD6 should blink; LD7 (CPU fault) should stay off.
- [ ] Press and release **1, 2, A, F, 0** slowly. Read **LD3…LD0**, in that order: **0001, 0010, 1010, 1111, 0000**. **LD4 flips once per accepted key**, including zero or a repeated digit. Release between presses. Hold 5 for one second: one flip only. Press two keys together from idle: a chord seen together produces no digit; release both, then tap 5 again. Human fingers may land separately; test 17 checks exact simultaneity.
- [ ] Reprogram with keys released to start an empty block. Type **00112233445566778899AABBCCDDEEFF** (two taps of each of 0 through F). **LD5 stays off through digit 31, turns on after digit 32** when firmware has stored the ciphertext. Repeat another 32 digits; LD5 turns off. LD6 keeps blinking; LD7 stays off. The LED is a completion marker; compare the actual ciphertext in simulation 19.
- [ ] Save a photo/video showing header JA, key label and LEDs. If heartbeat works but digits are wrong, note printed key → observed four LED bits for 1, A, 0, D. Check pin-1 alignment with power off. Do not reuse the older AES self-test LED legend.

## 4. On the ZedBoard: external OLED (JB)

- [ ] Power off. Disconnect the keypad; fit the **128×32 Digilent Pmod OLED** on **JB**, pin 1 to pin 1. This is the external module, not the display built into the ZedBoard or a Pmod OLEDrgb. Leave other Pmods disconnected.
- [ ] Power on and program **your** `zedboard_oled_pattern.bit` via Hardware Manager. Look immediately: the external display should show a black-and-white **8×8-pixel checkerboard** for about **8 seconds** (4 if you made the suggested edit). **LD0 on** marks the viewing interval.
- [ ] The display then goes dark, followed by **LD1 on** after a further **3.5 seconds** for orderly shutdown. Wait for LD1 before powering off or reprogramming. Reprogram to repeat. If the board reaches LD1 but the display stayed blank, record that as a failed physical display check: LD1 only confirms the controller finished.
- [ ] Save a picture while the pattern is visible and a second one at LD1. If blank, note JB orientation, exact module/revision, LED behavior and image used. This test checks the panel interface. Rendering CPU ciphertext as text is a later build.

Pin references: [Digilent KYPD manual](https://digilent.com/reference/_media/pmod:pmod:pmodKYPD_rm.pdf), [Digilent key layout](https://github.com/Digilent/vivado-library/blob/master/ip/Pmods/PmodKYPD_v1_0/drivers/PmodKYPD_v1_0/examples/main.c), [Digilent external OLED manual](https://digilent.com/reference/_media/reference/pmod/pmodoled/pmodoled_rm.pdf). The project uses ZedBoard PL headers at 3.3 V and a 100 MHz PL clock.

**Bring back:** exact Vivado version, four PASS lines (or first failure), both new .bit filenames, setup/hold slack, and observed key/LED/panel results. Record skipped tests as not run. No new physical result has been claimed in this guide.

