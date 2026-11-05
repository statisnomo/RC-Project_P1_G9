# Onboard OLED engineering evidence — November 5

Vivado 2025.2, xc7z020clg484-1, 100 MHz PL clock. All seven included display
simulations passed, including the new board wrapper with CS permanently low,
two exact ciphertext frames, 66 UART frames at divider 868 and orderly
shutdown/restart. Logs are named after their simulation tops.

Implementation passed: setup +0.241 ns, hold +0.106 ns; 3,562 LUTs,
2,509 flip-flops, two RAMB36s, zero DSPs and no inferred latches.
No DRC errors or critical warnings; the expected PL-only ZPS7-1 warning
is retained. See timing, utilization, pins and DRC reports.

`source_hashes.json` records canonical LF hashes of source inputs, including
both display constraints. The distributed onboard ZIP retains only entries
for its included inputs. `scripts/release_manifest.py check` verifies them.

The generated image is published separately under
`build/zedboard_display_onboard/`, with its SHA-256 file. The old JA/JC image
and ZIP remain unchanged. These are local engineering results, not a physical
onboard OLED or UART pass. User-reported external-display lab results are in
`docs/lab_results_2026-11-05.md`.
