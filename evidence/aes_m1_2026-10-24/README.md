# AES milestone M1 evidence — 24 October 2026

Vivado Simulator 2025.2, saved project-mode simulation sets:

- `tb_aes_primitives.log`: 1,810 checks passed.
- `tb_aes128_core.log`: 17,433 checks, 556 complete encryptions passed.
- `tb_cpu_board.log`: existing CPU board regression passed, 15 scenarios.

The two `.wdb` files record the AES simulation signals. The GUI project
generates fresh wave databases when its simulation sets are rerun.
`source_manifest.json` hashes the AES RTL, testbenches/reference model,
vector files, and synthesis script used for these results.

The 284 published expected answers and original NIST archive are in
`docs/references/aes/` and `tb/crypto/vectors/`. Their provenance manifest
is separate from the tested-source manifest here.

Standalone synthesis reports are in `build/aes_synthesis/`. They show
1,314 LUTs, 390 FFs, no inferred latches, and +4.976 ns estimated worst
register setup slack under a 10 ns clock constraint. This is pre-route
out-of-context timing; external I/O timing and clock skew are not modeled.

No AES physical-board observation or integrated AES bitstream is claimed.
The CPU/ALU bitstreams in the pack retain their original behavior.

`relocated_gui_summary.txt` records an additional successful run of both AES
sets and the CPU board set from a freshly extracted copy of the ZIP,
without source-project repair. All project source paths were checked to
resolve inside that copy. `relocated_run.log` contains the complete tool log.
