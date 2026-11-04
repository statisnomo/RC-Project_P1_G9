# Hardened combined image evidence

Vivado 2025.2, xc7z020clg484-1, 100 MHz. All six `tb_*.log` files end in PASS.
The original 20-test regression is under `../release_regression_2026-11-05/`.
The six-test extracted-copy rerun is under `../release_extract_2026-11-05/`.

`source_hashes.json` records source content with CRLF normalized to LF.
`summary.txt`, `timing.rpt`, `drc.rpt`, `pins.rpt` and `utilization.rpt` belong
to the successfully routed hardened image. Public bitstream identity is in
`../../build/zedboard_display/bitstream.sha256`; the lab ZIP contains its own
exact-byte file hashes. Do not substitute the earlier candidate's ROM.

Test 24 shortens only the CPU's remaining poll count after the production
budget has loaded. It verifies the same ROM's decrement/branch/store/halt
paths for all six failure codes. It injects busy status, not a permanently
nonresponding bus. Overflow is produced by real matrix presses while a
status read is stalled, rather than by directly setting the overflow bit.

Test 25 isolates CPU execution and drives requests through the actual SoC
address selection and response mux. CPU instruction-level alignment/error
handling remains covered by the baseline CPU and memory tests.

The image has not been physically validated. User-reported hardware passes
in `../lab_2026-11-04/` belong to the separate keypad/AES and OLED pattern demos.
`cleanup.json` records only removed ignored compiler caches, not source.
