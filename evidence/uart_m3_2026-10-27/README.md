# UART M3 simulation and synthesis evidence

Recorded **27 October 2026**, Vivado **2025.2**, target **xc7z020clg484-1**.
This accepts checklist **M3.2** (UART unit/MMIO tests). UART's physical
test H3.1 and full CPU/peripheral integration remain open.

- `tb_uart_tx.log`: PASS; dividers **1, 2, 7, 868**, **840 complete frames**,
  **40 reset aborts**. All 256 bytes at the three small dividers; 16 broad
  data patterns plus directed/reset cases at the real divider of 868.
- `tb_uart_mmio.log`: PASS; waits **1 and 4**, **1,454 / 1,457 bus checks**,
  **564 complete frames**, **20 reset aborts**. Includes all bytes, byte
  strobes, invalid/reserved accesses, continuous VALID, cancellation,
  reset at bus completion, and live BUSY at the final-stop boundary.
- The pin checker compares every clock's TX level and BUSY to an expected
  frame built from test requests. The core test also checks DONE duration.
  It reads no DUT internal state. Test coordination uses the independent
  checker's elapsed time for precisely scheduled boundary accesses.
- `tb_cpu_board.log` and `tb_aes_board.log`: both existing board simulations
  rerun to PASS with the updated GUI project. These are simulations;
  [reported physical ALU/CPU/AES passes](../../docs/lab_results_2026-10-27.md)
  are recorded separately.
- `synthesis/`: **55 LUTs, 37 FFs, zero BRAM/DSP/latches**. Estimated worst
  register setup slack **+6.368 ns** for 100 MHz. Out-of-context synthesis
  leaves external I/O timing and clock insertion unspecified; routed
  implementation and board reception are not claimed. Constant-zero
  upper RDATA bits are expected and are reported as synthesis warnings.

The two UART `.wdb` files are saved waveform databases. `source_sha256.json`
identifies the tested new RTL, benches, GUI helper scripts, and project.
`artifact_sha256.json` identifies the copied logs, waves, and reports.
The maintainer runners are `scripts/verify_uart_gui.tcl` (read-only project
validation) and `scripts/check_uart_synthesis.tcl`. Lab users follow
[the GUI walkthrough](../../docs/uart_tx.md), with no terminal commands.
