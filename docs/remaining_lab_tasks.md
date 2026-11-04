# What you can do while the keypad is being built

**November 4 update:** lab tests 17–20 and both independent hardware demos passed. [Saved results](lab_results_2026-11-04.md). Earlier pending-status notes below describe the original increment; use [the combined guide](../NEXT_LAB_COMBINED.md) for the next lab.

All original tests **1–16 have passed in the lab** across October 27 and 29.
The user clarified that the eight tests listed below passed on October 27.
My earlier description of them as unreported was incorrect. No repeat is
required solely to complete the record. The list is retained as a reference;
check counts are the guide expectations, not newly supplied October 27 logs.

For each: select the simulation set in **Simulation Settings**, click
**Run Behavioral Simulation > Run All**, save its PASS message, and
close the simulation before choosing the next set.

- [x] **1 ALU:** `sim_1`, top `tb_alu`; 4,142 checks.
- [x] **2 Register file:** `sim_regfile`, top `tb_regfile`; 2,456 checks.
- [x] **3 Immediate generator:** `sim_imm_gen`, top `tb_imm_gen`; 14,546 checks.
- [x] **4 Decoder:** `sim_decode`, top `tb_decode`; 7,717 checks plus
  15 datapath examples.
- [x] **8 ALU board wrapper:** `sim_alu_board`, top `tb_alu_selftest`;
  16 vectors plus intentional fault/reset/LED checks.
- [x] **9 CPU board wrapper:** `sim_cpu_board`, top `tb_cpu_board`;
  actual program plus 15 checker scenarios.
- [x] **10 AES primitives:** `sim_aes_primitives`, top `tb_aes_primitives`;
  1,810 checks.
- [x] **14 CPU/AES board wrapper:** `sim_aes_board`, top `tb_aes_board`;
  actual encryption plus 13 monitor scenarios.

The board-wrapper simulations deliberately inject errors to test the
failure LEDs, so inspect their final PASS, not just an intermediate LED.
Your earlier three physical board passes remain recorded separately.

## Useful learning and lab preparation

- **ALU waveform:** find `ffffffff + 1 = 0` and explain the zero flag.
- **Register file:** explain why writes to x0 do not change its reads.
- **CPU/AES waveform:** find a START write, BUSY polling, and ciphertext reads.
- **UART waveform:** find the start bit, eight LSB-first bits for `A`
  (`0x41`), and the full stop bit. At the default divider, each bit lasts
  868 clocks or 8.68 microseconds at 100 MHz.
- Save `setup_report.txt`, the exact Vivado version and project revision,
  and the October 29 logs while they are still on the lab computer (P16).
- Photograph the keypad's front/back, model/revision and pin-1 marking;
  do the same for the OLED. The standard Digilent Pmod KYPD and Pmod OLED are now confirmed;
  record orientation before wiring rather than reconfirming the product names.
- Identify the available USB-to-TTL adapter's model and logic voltage
  for the later UART hardware test. No UART board image is ready yet.

The scanner's new [test 17](keypad_scanner.md) is a separate next increment.
The older GitHub lab snapshot has only 16 tests until the new files are
published. Tests 17/18 are the next new lab checks after publication; the original
  tests above do not need repeating unless affected by a later change.

