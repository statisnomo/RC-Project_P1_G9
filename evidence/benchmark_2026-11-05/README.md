# Benchmark evidence — run November 5, packaged November 6

Vivado 2025.2 behavioral simulation, same custom RV32I CPU on both paths.
The three test logs cover tests 28–30. They are local results, not user lab
reports or physical measurements. The benchmark has no released board image.

At waits 1: software 24,576 cycles, complete hardware call 213 cycles.
At waits 5: software 24,576 cycles, complete hardware call 234 cycles.
Both implementations matched 413 independent vectors per mode. Inputs include
284 published NIST cases and 129 .NET cases (baseline plus 128 one-bit changes).
The changed-bit population is 47–79, total 8,098 across 128 changes.

`results.json` drives the recorded-results presenter. `source_hashes.json`
binds the packaged RTL, firmware and test inputs with LF-normalized SHA-256.
The firmware manifest records compiler flags, program size and instruction
audit. See `docs/benchmark.md` for exactly what is inside/outside the timing
interval and the baseline's limitations.

Recovery covers timer wrap, cancellation/reset/access errors, aborted software,
reset during hardware AES and a bounded DONE-status timeout followed by retry.
It does not add a bus watchdog for a peripheral that never returns READY.

The presenter's data and control logic passed the Node DOM-stub check for
both timing modes and all 128 bit selections. Visual rendering was not checked:
the browser tool blocked local-file URLs. The layout needs a manual preview.
