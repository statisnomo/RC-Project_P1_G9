# Internal development: ciphertext display

The CPU reads 32 keypad digits as one 16-byte input, starts AES-128 with the fixed public demo key 00…0F, and saves the ciphertext at RAM 0x1020. It copies those four words into the OLED registers, waits for the display to be idle, and submits one frame. It also sends the same bytes as 32 uppercase hex characters followed by LF on UART TX. The external display and serial adapter are not needed for simulation.

This integration is separate from the November 3–4 lab projects and images. The candidate top is `soc_display` and its firmware is `fw/src/display.S` (`fw/display.hex`).

## OLED registers at 0x40000200

- **+0x00 STATUS (read only):** bit 0 = idle and ready to draw; bit 1 = powered off; both zero while starting, drawing or shutting down.
- **+0x04 CONTROL:** reads as zero. Write exactly 1 to draw, or 2 to shut down, while idle. Write 4 while powered off to restart and clear the panel. Commands inappropriate to the current state return a bus error.
- **+0x10, +0x14, +0x18, +0x1C DATA0…3 (read/write):** staging words. Byte 0 of DATA0 is the first displayed byte, high hex digit first. Staging writes are accepted during an existing frame; drawing takes an atomic snapshot on the successful command completion edge.
- The interface accepts aligned **32-bit** accesses only (write strobes 1111; read strobes 0000). Reserved offsets, wrong size, bad strobes and unaligned accesses report error and change nothing. Request decoding, write data and read-register selection are captured while waiting. Keep request signals stable until valid and ready coincide on a rising edge. An abandoned request has no effect.

The display receives one clear during startup and 512 data bytes per update. In horizontal address mode with columns 0–127 and pages 0–3, the address wraps to the first column after each full frame. Pages 1 and 2 show 16 uppercase hex digits each, with the top and bottom pages blank. Each cell is 8 pixels wide and 8 high. The 5×7 glyph occupies the left five columns. The framebuffer is rendered from the immutable 16-byte snapshot. No 512-byte pixel RAM is needed.

The hardware defaults use the lab controller's reset/settle delays, a 100 ms panel power delay, 2.5 MHz SPI and a 3.5 second discharge before logic power is disabled. The explicit shutdown command sends display-off first. The synchronous system reset is a cold-start control; asserting it mid-operation is **not** the orderly power-down protocol. Soft shutdown blanks the physical display; it does not erase RAM, staging registers or the CPU’s copy of the ciphertext.

## Reproduce the internal checks

In development Vivado run `scripts/verify_display_internal.tcl` in batch mode from the source tree. It creates an isolated project under `build/display_internal`; it does not modify the two November lab projects. The shipped ROM is sufficient. To rebuild it, use `python fw/build_display.py --prefix <GNU-RISC-V-tool-prefix>`; the development run used Vivado's riscv64-unknown-elf tools with RV32I/ILP32 and relaxation disabled.

The MMIO test checks access errors, cancellation, busy control commands and power sequencing through shutdown and restart. The system bench drives keypad switches, samples every SPI byte and UART bit, and checks two known AES ciphertexts including every glyph and blank pixel column. It tests that typing only 31 digits produces no submit and that the second result can be staged while the first is still on the wire.

The diagnostic firmware polls the peripherals and transmits one line per block. It does not implement a fault timeout or keypad overflow recovery; sufficiently fast input while firmware is polling or sending a line can overrun the single-key mailbox. The new board wrapper uses KYPD on JA, OLED on JC and optional UART TX on JD1. Any detected keypad chord requests orderly shutdown; holding it keeps the panel off, releasing it restarts with an empty input block. See NEXT_LAB_COMBINED.md for the upcoming physical trial.


