# November 4 lab results

The user reports both supplied-image hardware demos passed: keypad/CPU/AES and the external OLED checkerboard/startup/shutdown. Tests 17–20 also passed. Together with the October results, all original lab simulations 1–20 have now passed.

Exact supplied messages:

```text
PASS tb_keypad_aes: 64 printed digits, 64 ACKs, 2 ciphertexts in RAM, open-drain columns and chord rejection
PASS tb_keypad_scanner: 3 timing configurations, all positions, bounce, holds, rollover, chords, ghosting and reset
PASS tb_keypad_mmio: mailbox and real scanner, waits 1/4, 16 positions, ACK/event races, overflow, invalid/cancelled accesses and reset
PASS tb_oled_pattern: 1048 SPI bytes, full clear, checkerboard, power-up and timed shutdown
```

The user did **not** generate new bitstreams on the lab PC. P22 remains open; these are passes of the supplied demos. No new lab synthesis/timing result is claimed.

Five original photos are preserved in [the evidence folder](../evidence/lab_2026-11-04/). They show the keypad attached, the external Pmod OLED checkerboard, and the panel dark afterward. The board silkscreen reads **REV D**; earlier reference documents include E.1. The board's built-in OLED is distinct from the external display used in these tests. The programming device is labeled **Platform Cable USB, Model DLC9LP**, with JTAG signals; this photograph does not confirm a USB-to-TTL UART adapter.

The four supplied `.wcfg` paths under `C:/Users/anand/Downloads/vivado2020_1/` could not be found on this machine when checked. Their attachment names are recorded, but the files have not been archived. Waveform configuration files store signal selection/layout, not recorded waveform samples; the pasted PASS messages are the available simulation-result evidence. Folder naming suggests 2020.1 but the exact version was not established from an About dialog.

Files named by the user: `tb_keypad_aes_behav.wcfg`, `tb_keypad_mmio_behav.wcfg`, `tb_keypad_scanner_behav.wcfg`, `tb_oled_pattern_behav.wcfg`.

The combined ciphertext-text display remains a separate development milestone. These photos do not establish a physical pass for that combined image or for UART reception.
