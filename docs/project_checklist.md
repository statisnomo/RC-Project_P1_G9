# Project checklist

Deadline: **20 November 2026**. Full-demo target: **15 November**.
Last reviewed: **29 October 2026**, including board passes and the separate
Vivado 2020 simulation failures.

Tick a box only after its stated result is observed. Add the task ID, date,
and evidence location to [progress_log.md](progress_log.md). A future file
or test named below is planned work, not a file claimed to exist today.
Use [the timeline](project_timeline.md) for dates and dependencies.

## Existing verified baseline

These checks refer to saved engineering results, not personal lab completion.

- [x] B1: ALU simulation: 4,142 checks.
- [x] B2: Register-file simulation: 2,456 port checks.
- [x] B3: Immediate-generator simulation: 14,546 checks.
- [x] B4: Decoder simulation: 7,717 checks plus 15 datapath examples.
- [x] B5: ROM/RAM simulation: 24 checks.
- [x] B6: CPU simulation: 76 cases and 1,287 checked retirements.
- [x] B7: Minimal SoC: sum 55, load-use result 56, one completed MMIO write.
- [x] B8: ALU board-wrapper simulation: 16 vectors and fault/reset checks.
- [x] B9: CPU board-wrapper simulation: real program and 15 checker scenarios.
- [x] B10: ALU and CPU bitstreams generated with passing routed 100 MHz timing.
- [x] B11: Vivado GUI project and lab instructions prepared.
- [x] B12: Board references archived and current clock/LED constraints checked.

Evidence: [nine-test summary](../build/vivado_gui_validation/gui_test_summary.txt),
[ALU record](zedboard_alu_demo.md), [CPU record](zedboard_cpu_demo.md),
[reference audit](../build/reference_review/audit.json).

## Personal checks — October 27 / next available lab

Latest result: the user confirmed **all three board images passed**, with
**LD0 blinking, LD1 ON, LD2-LD7 OFF**, including **3/3 AES trials**.
P4/P5/H2 are accepted from that observation; see the
[physical test record](lab_results_2026-10-27.md). The
[earlier lab review](lab_followup_2026-10-27.md) remains a historical record.
Personal simulation checks stay open until reported. Media archiving and
the separate CPU repeat are tracked below rather than hiding the passed tests.

- [ ] P1: Open the `.xpr` in Vivado and run `sim_1` / `tb_alu` to PASS;
  inspect operands, operation, result, and zero in the waveform.
- [ ] P2: Run `sim_soc_minimal` and `sim_cpu_board`; explain what each checks.
- [ ] P3: Record board/device revision, module models, and available lab slots.
  Confirm access to power, USB-JTAG, both Pmods, and a 3.3 V logic UART adapter.
- [x] P4: Program the existing ALU image; observe LD0 blinking, LD1 on,
  LD2-LD7 off. User reported PASS on October 27.
- [x] P5: Program the existing CPU image; observe the same healthy LED
  pattern. User reported PASS on October 27.
- [ ] P6: Small Vivado test, no board needed: select `sim_aes_primitives`
  / `tb_aes_primitives`, then **Run Behavioral Simulation > Run All**.
  Observe `PASS tb_aes_primitives: 1810 checks` and save the PASS message.
- [ ] P7: Small Vivado test, no board needed: select `sim_aes_core`
  / `tb_aes128_core`, then **Run Behavioral Simulation > Run All**.
  Observe `PASS tb_aes128_core: 17433 checks, 556 completed blocks`.
  Inspect 25-135 ns: START accepted, BUSY high, then DONE and ciphertext
  `69c4e0d86a7b0430d8cdb78070b4c55a`. Save the waveform and PASS message.
- [ ] P8: Run `sim_aes_mmio` / `tb_aes_mmio` in Vivado to PASS; inspect a
  completed START write and verify that waiting cycles do not apply writes.
- [ ] P9: Run `sim_soc_aes` / `tb_soc_aes` in Vivado to PASS; find the real
  CPU's START/status/ciphertext accesses and the returned ciphertext in RAM.
- [ ] P10: Run `sim_aes_board` / `tb_aes_board` to PASS; inspect the healthy
  LED pattern before the deliberate fault tests. See [the CPU/AES guide](cpu_aes_integration.md).
- [ ] P11: Archive a photo/video of the board tests with their image names
  for the final report. Functional passes are already recorded.
- [ ] P12: Record a repeat of the standalone CPU image and its restart
  method; only the AES repeat count was explicitly reported so far.
- [ ] P13: Small UART Vivado test: run `sim_uart_tx` / `tb_uart_tx` to PASS;
  inspect the first A frame in `real_baud`, including the full stop bit.
- [ ] P14: Run `sim_uart_mmio` / `tb_uart_mmio` to PASS; observe TX starting
  at bus completion and an expected error for a write while BUSY.
  Follow the [small UART walkthrough](uart_tx.md); no board is needed.
- [ ] P15: In lab Vivado 2020, use **Tools > Run Tcl Script** with
  `scripts/create_lab_compat_project.tcl`. Rerun `sim_cpu_core`,
  `sim_soc_minimal` (test 7), `sim_aes_core`, `sim_aes_mmio`, and
  `sim_soc_aes` to PASS. For test 7, also save `SIM_ROM_LOAD_OK`. Save
  `setup_report.txt` and logs. See [the recovery guide](lab_simulation_recovery.md).

P15 follows the reported failures in tests **6/7/11/12/13** on
Vivado 2020; test 7 was reported on October 29 without an error excerpt.
Use [the next-lab checklist](../NEXT_LAB.md). The October 29 revision passed
all 16 sets and eight diagnostic scenarios locally in 2025.2; see
[the evidence](../evidence/lab_sim_recovery_2026-10-29/README.md).
The lab-version retest is still required. Physical P4/P5/H2
remain passed and do not need to be repeated solely for this setup change.

P6-P10 are your personal observations and remain unchecked until you run
them. Follow the [small AES test walkthrough](aes_core.md); no terminal
commands or physical board are needed.

Procedure: [next-lab checklist](../NEXT_LAB.md), followed by the
[full Vivado GUI guide](../VIVADO_START_HERE.md).

## M1 — AES on its own — due October 28

- [x] M1.1: Decide a simple keypad input format, clear/start behavior,
  fixed demo key, and ciphertext layout. Record the decision by October 24.
- [x] M1.2: Write the AES interface contract, byte/key ordering, reset,
  START/BUSY/DONE behavior, busy-input policy, and latency boundaries.
- [x] M1.3: Implement and independently verify round operations and key expansion.
- [x] M1.4: Implement the iterative AES-128 encryption controller and add
  its self-checking testbench to the Vivado GUI project.
- [x] M1.5: Pass published known-answer cases and varied keys/plaintexts;
  check repeated blocks, start while busy, and reset during operation.
- [x] M1.6: Record measured cycle latency and early synthesis/timing results.
- [x] G1: AES core acceptance passed; logs, waveform, and contract saved.

Passed October 24: [AES guide](aes_core.md), [contract](aes_interface.md),
[evidence](../evidence/aes_m1_2026-10-24/README.md), and
[early synthesis](../build/aes_synthesis/summary.txt). This accepts the
standalone core. Integrated timing and the physical CPU/AES test have
since passed under M2 below.

## M2 — CPU controls AES — due November 2

- [x] M2.1: Define all AES MMIO register semantics, byte strobes, reserved/
  misaligned accesses, read-only writes, START acceptance, and DONE clearing.
- [x] M2.2: Verify the register wrapper under waits, held requests, repeated
  commands, reset, and writes while busy. Side effects occur exactly once.
- [x] M2.3: Prepare a checked ROM program that writes key/plaintext, starts,
  polls with timeout, and reads ciphertext into RAM.
- [x] M2.4: Check assembly instruction compatibility, reset entry/stack,
  and ROM/RAM fit. Supply ready `.hex` and documented linker layout.
  GNU linking and a C startup runtime remain future work.
- [x] M2.5: Pass CPU-to-AES integration for several blocks/keys and reset;
  rerun affected baseline tests.
- [x] M2.6: Build a CPU-plus-AES self-test image and check routed timing/DRC.
- [x] G2: CPU obtains independently verified ciphertext through MMIO;
  the board self-test image and evidence are ready.
- [x] H2: Observe the CPU-plus-AES self-test passing on the physical board
  in three trials. User reported 3/3 PASS on October 27; media is tracked by P11.

Engineering gate passed October 27: [CPU/AES guide](cpu_aes_integration.md),
[board build](zedboard_aes_demo.md), [evidence](../evidence/aes_m2_2026-10-27/README.md).
Routed 100 MHz setup/hold: +0.311/+0.159 ns. H2 passed from the
[user's physical observations](lab_results_2026-10-27.md).

## M3 — UART, keypad, and OLED — due November 8

- [ ] M3.1: Check exact peripheral manuals, module revisions, connector
  positions, bank voltages, and final signal assignments before wiring.
- [x] M3.2: UART unit/MMIO tests pass: framing, baud timing, byte order,
  consecutive bytes, busy behavior, and reset.
- [ ] M3.3: Keypad unit/MMIO tests pass: all keys, bounce, held key,
  release/repress, event acknowledgement, multiple-key policy, and reset.
- [ ] M3.4: OLED unit/MMIO tests pass: power/reset ordering, SPI, command/data,
  flow control, pixel/text formatting, and full ciphertext display.
- [ ] M3.5: Add tests to the GUI project and prepare separate board images
  with their own checked pin/timing constraints and implementation reports.
- [ ] G3: All three peripheral simulations pass; independent board tests ready.
- [ ] H3.1: On the board, receive the correct UART test string via the PL adapter.
- [ ] H3.2: On the board, observe correct codes for all 16 keys without
  unintended duplicate events from bounce or a held key.
- [ ] H3.3: On the board, display a fixed pattern, text, and a 32-digit
  sample ciphertext. Target all H3 checks by November 10.

UART engineering tests passed October 27: [guide](uart_tx.md),
[contract](uart_interface.md), and [evidence](../evidence/uart_m3_2026-10-27/README.md).
The GUI project has 16 sets. Adapter availability is assumed for planning;
its actual model/logic voltage still needs checking before wiring. UART
CPU integration, routed board build, and H3.1 remain open.

## M4 — whole system — due November 12

- [ ] M4.1: Connect all four approved MMIO windows and check response routing,
  invalid addresses, byte strobes, and wait-state behavior.
- [ ] M4.2: Finish input -> AES -> display firmware, including clear/start,
  length tracking, timeout/error handling, and the next input block.
- [ ] M4.3: Pass system simulation using modeled key presses and captured
  OLED/UART traffic; compare actual ciphertext and displayed values.
- [ ] M4.4: Pass repeated inputs, reset/restart, incomplete input, and stalled
  peripheral cases; no lost key events or duplicate bus side effects.
- [ ] M4.5: Measure code, constants, buffers, and stack use within 4 KB ROM /
  4 KB RAM. Run all existing and new simulation sets to PASS.
- [ ] M4.6: Complete full-system implementation; review 100 MHz routed
  setup/hold, unconstrained paths, DRC, and resource use; generate bitstream.
- [ ] G4: Complete simulated demonstration and a checked full-system image ready.

## M5 — complete physical demo — due November 15

- [ ] M5.1: Complete P4/P5, H2, and H3 physical checks, or resolve their failures.
- [ ] M5.2: Enter the known-answer input on the keypad; match every displayed
  ciphertext byte against the independent expected value.
- [ ] M5.3: Run at least ten consecutive encryptions with varied input;
  check input clearing, start behavior, full output, and next-block entry.
- [ ] M5.4: Pass three fresh-start trials; record whether each used
  reprogramming or power-cycle followed by reprogramming.
- [ ] M5.5: Capture a readable demo video and save board/module revisions,
  source snapshot, firmware, bitstream identity, and implementation reports.
- [ ] G5: Complete physical demonstration passed. Freeze features;
  preserve a working backup before any later fix.

## M6 — results and package — due November 18

- [ ] M6.1: Record AES-only latency and complete CPU-visible encryption
  cycles separately, with clock and key-reuse policy stated.
- [ ] M6.2: Record final resources, routed timing, tests and limits; link
  every measured claim to the exact design/image and saved evidence.
- [ ] M6.3: Finish architecture/block diagrams, register/interface notes,
  report/slides required by the course, and the demo script.
- [ ] M6.4: Create the final pack with source, testbenches, firmware, XDC,
  GUI project, references, reports, bitstream, and expected outputs.
- [ ] M6.5: Extract elsewhere; open the project and rerun acceptance
  simulations. Check file paths, ROM contents, and a second backup.
- [ ] G6: Submission package and evidence are complete and reproducible.

Optional only after G5: same-CPU software-AES speedup comparison; key entry;
more elaborate UI. None may displace correctness or final verification.

## M7 — rehearsal and submission — November 19-20

- [ ] M7.1: Confirm the exact deadline time, submission format, and required
  report/demo contents. Use the recovery lab slot if required.
- [ ] M7.2: Rehearse opening Vivado, programming, entering input, explaining
  the CPU/AES interaction, and repeating the demonstration.
- [ ] M7.3: Recheck the packaged bitstream and backup video; submit the
  required deliverables and record confirmation.
- [ ] G7: Submission and required demonstration complete by November 20.

## Repeat at each work session

Copy this short section into a new progress entry; do not reuse old ticks.

- [ ] Pick one unfinished task ID and one observable result for this session.
- [ ] Read the interface and explain the block's inputs/outputs before editing.
- [ ] Make the small change; run the relevant Vivado simulation to PASS.
- [ ] After an RTL/interface change, rerun affected integration tests.
  Before programming a changed design, check its new implementation reports.
- [ ] Save the log/waveform or board evidence and update the task's status.
- [ ] Write the first failing observation, if any, and the next smallest test.

## Repeat at each lab visit

- [ ] Bring the full current pack, known expected outputs, and required hardware.
- [ ] Check board revision and planned wiring against [board_io_plan.md](board_io_plan.md).
- [ ] Identify the exact bitstream being programmed; use Vivado Hardware Manager.
- [ ] Test one block at a time before the integrated demo; record observed results.
- [ ] Save the video/photo and error details before leaving the lab.
- [ ] Append the visit record and choose the next test that can run without the board.

Use a fresh copy of [lab_record_template.md](lab_record_template.md) for each visit.
