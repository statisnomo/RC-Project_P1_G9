# CPU/AES integration evidence — 27 October 2026

Vivado 2025.2 project-mode simulations use the same saved simulation sets
offered by the GUI. Maintenance runs automate those sets; this is not a
claim that a human has clicked through or observed the board tests.

**Fresh ZIP extraction: all 14 sets passed.** `relocated_gui_summary.txt`,
`relocated_validation.log`, and `relocated_gui_logs/` record that run from
a different folder. The delivered project was opened without any repair
step; every registered source resolved inside the extracted copy. The
source/image hashes match the tested snapshot. Final packaging adds only
documentation, the printable procedure, evidence, and packaging helpers.

- `tb_aes_mmio.log`: **26,632 checks** with one wait edge and **48,264**
  with three. Both run all **284 NIST known-answer blocks**, plus byte
  strobes/access errors, busy writes, continuously asserted VALID, cancelled
  transfers, reset during all eleven AES stages, and recovery. Two added
  boundary cases reject a write completing on the DONE edge and accept
  one completing a clock later, even when captured while BUSY.
- `tb_soc_aes.log`: real CPU/ROM/RAM/AES, one/five wait edges,
  **32 checked healthy blocks**, reset/restart, mismatch, polling timeout,
  and missing-peripheral access-fault checks. It records CPU-visible cycles.
- `tb_aes_board.log`: actual four-block program, restart, heartbeat/LEDs,
  and **13 monitor scenarios**, including deliberately faulty inputs.
- Three `.wdb` files contain the corresponding wave data.
- `build_aes.log` records a completed CPU/AES board build. The reports,
  checkpoint, ROM, and image are in `build/zedboard_aes_demo/`.
- `source_sha256.json` identifies the source, test data, GUI project,
  constraints, build/verification scripts, and programming image.

The board image meets **100 MHz after routing**: **+0.311 ns setup**,
**+0.159 ns hold**, zero timing-failing endpoints. It uses 3,182 total LUTs,
2,084 flip-flops, two RAMB36 blocks, and no DSPs. No internal endpoint is
unconstrained; LED outputs alone have false paths. No latches were inferred.
DRC reports zero errors and the retained PL-only **ZPS7-1** warning.

Image SHA-256:
`da8896a13ce9a9836814bda4454099978e10f2840ffd50488b857f81de19c9f6`.

Earlier negative timing results were investigated before this build.
Registering the request during the existing MMIO wait cycle breaks the
long address/readback path while retaining live completion-edge BUSY
checks. The approved clock, memory map, and bus wait count are unchanged.

The assembly program occupies 880 ROM bytes and 68 RAM bytes; the supplied
ROM is generated directly. GNU linking/C startup and physical board
operation are not claimed. See [the lab procedure](../../docs/lab_2026-10-27.md).
