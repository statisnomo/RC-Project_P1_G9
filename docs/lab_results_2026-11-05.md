# November 5 lab results

The user supplied PASS messages for tests 21–26 and reported that the combined
keypad/CPU/AES/external-Pmod-OLED demo renders the expected ciphertext sequences
correctly. All lab simulation tests 1–26 have therefore now been reported PASS.
The combined input-to-ciphertext-display function has a physical pass from the
user's observation. This is the existing JA keypad / JC Pmod OLED build, not
the new onboard OLED variant.

```text
PASS tb_oled_access: 20 bus operations, cancellation, busy/invalid writes, discharge and restart
PASS tb_display_system: 96 digits, 3 AES ciphertexts, 1536 pixel bytes, 99 UART characters, overlap, partial input, chord shutdown and full block after restart
PASS tb_display_board: startup reset, physical pad drive, CPU digit LEDs and hold suppression
PASS tb_display_recovery: real mailbox overflow, discarded partial block, recovery ciphertext, six bounded status faults, diagnostic codes and reset recovery
PASS tb_display_bus: waits 1/5, 44 routed accesses, four windows, boundaries, invalid addresses, byte strobes and reset cancellation
PASS tb_display_repeat: waits 1/5, 20 blocks from independent .NET AES vectors, 660 UART frames, RAM and OLED snapshots, CPU-visible cycle measurements
```

Six waveform configurations were found in the restored
`C:/Users/anand/Downloads/rercnovember5` folder. Five were named in the upload;
`tb_display_system_behav.wcfg` was also present and has been archived with them
under [the lab evidence folder](../evidence/lab_2026-11-05/wave_configs/).
All six parse as XML `wave_config` and the copied SHA-256 values match the
originals. These are signal/layout files, not recorded waveform samples.

UART hardware testing was explicitly **not performed** and remains optional
for the next visit. The actual programmed bitstream identity, exact Vivado
minor version, own-build timing report, number of consecutive physical blocks,
three cold-start trials and a combined-demo video were not supplied in this
message. Keep those evidence fields open rather than inferring their values.

Next development: reuse the same SoC and firmware with the onboard DISP1 OLED.
That variant needs its own pin constraints, implementation and physical pass.
