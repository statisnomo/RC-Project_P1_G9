# Keypad scanner increment

Verified locally on **29 October 2026**, **Vivado 2025.2**.

- `tb_keypad_scanner.log`: three accelerated configurations (column
  periods 4/7/11 clocks, debounce counts 3/1/5). Each passes 16 position
  checks, exact debounce thresholds, hold/release/repress, rollover,
  coherent chords, ghosting, reset, and recovery. Bounce filtering is
  checked only with debounce enabled. Each reports 30 presses and 26
  releases; four accepted presses per instance are cancelled by reset.
- `tb_soc_minimal.log`: existing CPU/ROM/RAM regression still passes.
- `utilization.rpt`: default-parameter synthesis uses **86 LUTs, 88 FFs,
  zero BRAM/DSP**. No inferred latches.
- `register_paths.rpt`: preliminary 100 MHz register setup **+4.049 ns**.
  This is out-of-context synthesis, not routed timing. The clock-source
  estimation warning is retained in `verify.log`; there are no board
  I/O delays or physical keypad claims in this step.
- The saved GUI project has **17 simulation sets**, with all registered
  source paths present in the source tree. The lab still needs to run
  the new test 17 using its installed version.

An initial test assumed that disabling debounce would still reject a
mid-scan partial chord. That expectation was corrected: coherent chords
are established before scanning, while DB=1 is documented as unable to
filter temporary partial readings. The exact threshold checks use public
scan outputs, not the DUT debounce counter. A synthesis-script path-list
quoting issue was also corrected before the final successful run.

The source and artifact manifests identify this local snapshot. Event
storage/acknowledgement, hex-label mapping, MMIO, CPU integration, and
physical wiring/tests remain subsequent steps. M3.3 is only partially
complete. See [the scanner guide](../../docs/keypad_scanner.md).
