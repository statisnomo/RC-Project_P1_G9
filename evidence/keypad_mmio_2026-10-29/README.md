# Keypad event mailbox and MMIO acceptance

Local **Vivado 2025.2**, **29 October 2026**, xc7z020clg484-1.

`tb_keypad_mmio.log` records four passing configurations: direct mailbox
with waits 1/4 (122 checks each), and actual scanner plus matrix model
with waits 1/4 (111 checks each). Total **466 checks, 470 completions**;
the four extra completions are continuous-VALID read tests.

Coverage: all 16 positions; read without acknowledgement; held-key ACK
without retrigger; stable release; first-event retention and overflow;
ACK plus press on one edge; clear plus new overflow; byte strobes,
reserved offsets/bits, invalid sizes/alignment, read-only writes,
out-of-window requests, cancellation, live status and reset priority.
Pin-driven tests also cover multi-key/ghost rejection and reset while held.
No scanner internals are forced in the integrated tests.

`tb_keypad_scanner.log` and `tb_soc_minimal.log` preserve passing regressions.
The saved GUI project contains 18 sets. The new tests 17/18 are not yet
reported from the lab; the user has confirmed all original 1–16 passed.

Default-parameter synthesis: **137 LUTs, 83 FFs, no BRAM/DSP/latches**.
Preliminary register setup at 100 MHz is **+4.290 ns**. The 28 constant-zero
upper-RDATA warnings and the out-of-context clock-source estimation warning
are retained in `verify.log`. This is not routed timing or board validation.

M3.3's unit/MMIO engineering gate passes. CPU integration, key-position
translation, physical I/O timing/constraints and the board test remain
future work. The source/artifact manifests identify this local snapshot.
