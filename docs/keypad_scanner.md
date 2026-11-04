# Keypad step 1 — scan and debounce

**November 4 update:** lab tests 17–20 and both independent hardware demos passed. [Saved results](lab_results_2026-11-04.md). Earlier pending-status notes below describe the original increment; use [the combined guide](../NEXT_LAB_COMBINED.md) for the next lab.

This document covers the scanner. The [event mailbox/MMIO wrapper](keypad_mmio.md)
now also passes its independent tests. Hex-character mapping, CPU integration,
and the board demo remain subsequent steps.

**Verified locally in Vivado 2025.2 on October 29:** scanner tests and the
existing minimal-SoC regression passed. Default-parameter synthesis used
86 LUTs and 88 FFs, no latches, with a +4.049 ns preliminary register setup
estimate at 100 MHz. This is not a routed board build. See
[the evidence](../evidence/keypad_scanner_2026-10-29/README.md).

## Contract

`rtl/peripherals/keypad_scanner.v` runs entirely on the main clock.
It synchronizes four row inputs through two flip-flops and selects each
column in turn. `col_drive_low` is a one-hot **enable to drive low**;
a future board top must drive the selected column low and leave all
others high impedance. It is not a four-bit push-pull pin value.

Logical bit 0 means ROW1/COL1, through bit 3 for ROW4/COL4. The documented
Pmod connector order is reversed: COL4..COL1 on pins 1..4 and ROW4..ROW1
on pins 7..10. Row pull-ups and low-active scanning are described in
[Digilent's rev. B reference manual](https://digilent.com/reference/_media/pmod:pmod:pmodKYPD_rm.pdf).
Actual module revision and connector orientation still need confirmation.
No active board pin constraints are added in this step.

Default `COLUMN_CYCLES=25000` gives 250 microseconds per column at 100 MHz,
or one full matrix scan per millisecond. `DEBOUNCE_FRAMES=20` requires
20 identical complete scans before qualifying a press or release.
Parameters require COLUMN_CYCLES >= 4 and DEBOUNCE_FRAMES >= 1. Tests use
shorter scan periods; DB=1 intentionally disables bounce filtering and can
accept partial snapshots when keys change midway through a scan. Use the
default filtering for human input; the DB=1 test checks parameter behavior.

- `press`: one clock pulse for a qualified single key.
- `key_position`: row*4+column, with zero-based indices; retained until
  the next accepted press. It is a physical position, **not yet a hex digit**.
- `key_down`: an accepted key has not yet been followed by stable all-release.
- `release_event`: one clock pulse when that stable all-release occurs.
- `blocked`: multiple keys were observed; clear only after stable all-release.
- `scan_valid` and `scan_keys`: a complete scan pulse and the latest raw
  bitmap, useful for debug. Samples within a scan are taken at different times.

There is no auto-repeat. A different key without a stable empty interval
does not generate another event. Any observed multi-key scan suppresses
new presses until all keys are stably released, including when only one
of those keys remains held. Reset clears events/state and requires a
stable empty keypad before arming, avoiding a phantom press on reset release.
An already accepted key remains down through a chord until all keys release.
As with any sequential matrix scan, transitions during a scan can form
temporary mixed readings; the default stable-scan filter rejects short
ones. This is a single-key entry interface, not an arbitrary chord decoder.

## Small Vivado test

After using the current project creator, select **sim_keypad_scanner**,
top **tb_keypad_scanner**, then **Run Behavioral Simulation > Run All**.
This is **test 17**. It needs no board.

Watch `minimum/keys`, `rows_n`, `col_drive_low`, `press`, `key_position`,
`key_down`, `release_event`, and `blocked`. The testbench models real
switch connections and pull-ups, including ghost paths from a rectangle
of keys. It drives the DUT pins rather than forcing internal scanner state.

The test checks the exact press/release debounce threshold by counting
completed scans at the public outputs. It also exercises all 16 positions,
long holds, release/repress, input
bounce, direct rollover, multiple-key rejection, partial chord release,
ghosting, and reset while held at different scan phases. Three timing
configurations cover the minimum scan period and debounce counts 1/3/5.
Expected final message: **`PASS tb_keypad_scanner`**.

Scanner test 17 emits pulses; [test 18](keypad_mmio.md) now checks persistent
CPU-visible event storage, acknowledgement and overflow. M3.3's engineering
unit/MMIO gate is complete; lab tests 17/18 remain pending.

