# November 3 local development checks (Vivado 2025.2)

- The two dedicated projects were generated with the same project setup scripts supplied in the lab kit. Behavioral tests 17–20 passed, with full simulator output in the respective subfolders.
- Test 19 runs the shipped firmware on the real RV32I core, scans the matrix through the top-level column pads, translates all 16 printed keys, acknowledges 64 events, and checks two full ciphertexts in RAM. The independent AES calculation for the FIPS plaintext and zero plaintext used the same public key 00..0F.
- Test 20 decodes the external SPI pins. The 1,048 bytes include initialization, a full 512-byte clear, display on, 512 pattern bytes and display off. Simulation shortens the physical wait periods; the board defaults use the full delays.
- Both projects target xc7z020clg484-1, with a 10 ns PL clock. Routed timing report (WNS/WHS): keypad/CPU/AES +0.075/+0.122 ns; OLED +1.612/+0.190 ns. The lab's version and any edits require their own timing report.
- Both designs omit PS7 by design. Vivado reports its standard ZPS7-1 warning; the keypad image also has RAM optimization advisories in the methodology report. No internal endpoints were unconstrained. The OLED pin constraints bound the output paths independently of the human-visible LEDs.
- These are development results. The new physical keypad and external OLED observations and the lab's own rebuilds are pending. Use LAB_THIS_WEEK.md and the blank lab record.
