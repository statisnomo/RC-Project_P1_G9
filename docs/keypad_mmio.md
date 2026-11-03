# Keypad events and MMIO

Base **0x40000100**, using the approved completion-based valid/ready bus.
This contract was defined before testing the implementation. The standard
Digilent Pmod KYPD and Pmod OLED are confirmed module targets; the UART
adapter is still unknown. No new physical pins or board image are enabled.

Verified locally on October 29 with Vivado 2025.2: **466 bus checks**, normal
and delayed replies, plus scanner and minimal-SoC regressions. Default
synthesis uses 137 LUTs and 83 FFs, no latches; preliminary 100 MHz register
setup is +4.290 ns. This is not routed timing or a physical keypad test.
See [the saved evidence](../evidence/keypad_mmio_2026-10-29/README.md).

- **0x00 STAT (read-only):** bit 0 PENDING, bit 1 KEY_DOWN, bit 2 BLOCKED,
  bit 3 OVERFLOW. Other bits zero. KEY_DOWN/BLOCKED are live scanner state.
- **0x04 DATA (read-only):** bits 3:0 contain the saved physical key
  position, row*4+column with zero-based logical ROW1/COL1 first. Empty
  reads return zero; check PENDING to distinguish empty from position 0.
  This is not yet the printed hex label; firmware translation follows.
- **0x08 CTRL:** reads zero. Write one to bit 0 to acknowledge the pending
  event; write one to bit 1 to clear OVERFLOW. Zero bits do nothing.
  Other enabled bits are reserved and must be zero.

The scanner generates a one-clock press pulse. `keypad_event_mmio` stores
it until software acknowledges it. Reads and key release do not consume it.
There is one slot: if another press arrives while full, the first event
is retained and sticky OVERFLOW is set. Firmware must notice overflow
and restart entry rather than silently encrypting incomplete input.

Side effects occur only at a successful VALID && READY rising edge.
Requests must remain stable until completion. Address/data/control are
captured while waiting, following the project's existing bus convention.
STAT/DATA reflect the state before the completion edge; a simultaneous
new press appears on the next read. Continuous VALID permits subsequent
transactions, with a response gap between completions.

Priorities on the same clock edge:

1. Reset clears everything, including an incomplete request.
2. ACK consumes the old event; a simultaneous press replaces it without loss.
3. A new overflow beats an OVERFLOW-clear command on that edge.

Word/halfword alignment, byte strobes, reserved addresses, and sizes follow
the UART contract. Reads require zero strobes. CTRL effects require lane 0;
zero-strobe and zero-valued upper-lane writes are no-ops. Writes to STAT or
DATA always error. Invalid or cancelled requests do not acknowledge events.
WAIT_CYCLES must be >= 1. Reset is synchronous and active high.

`keypad_mmio` connects the actual scanner to this mailbox. It is not yet
connected to `soc_aes`; CPU integration follows. Scanner test 17 remains
separate. **Test 18: sim_keypad_mmio / tb_keypad_mmio**, then Run Behavioral
Simulation > Run All. Expected final result: `PASS tb_keypad_mmio`.
