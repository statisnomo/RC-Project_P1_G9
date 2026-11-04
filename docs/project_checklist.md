# Project checklist

Deadline: **20 November 2026**. Full-demo target: **15 November**.
Last reviewed: **29 October 2026**, including eight reported lab simulation
passes and the previously reported board passes.

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
Tests **1–4/8–10/14 passed October 27**, clarified by the user.
On October 29, tests **5/6/7/11/12/13/15/16** also passed in the lab;
see [the simulation result record](lab_results_2026-10-29.md).
Waveform learning and evidence archiving are tracked separately below.

- [x] P1: Run `sim_1` / `tb_alu` to PASS. User confirms October 27 PASS;
  waveform exercise is tracked separately in P17.
- [x] P2: Run `sim_soc_minimal` and `sim_cpu_board` to PASS.
  Minimal SoC passed October 29; CPU board-wrapper simulation passed October 27.
  Explaining the waveforms remains a learning exercise in P17.
- [ ] P3: Record board/device revision, module models, and available lab slots.
  Confirm access to power, USB-JTAG, both Pmods, and a 3.3 V logic UART adapter.
- [x] P4: Program the existing ALU image; observe LD0 blinking, LD1 on,
  LD2-LD7 off. User reported PASS on October 27.
- [x] P5: Program the existing CPU image; observe the same healthy LED
  pattern. User reported PASS on October 27.
- [x] P6: Small Vivado test, no board needed: select `sim_aes_primitives`
  / `tb_aes_primitives`, then **Run Behavioral Simulation > Run All**.
  Observe `PASS tb_aes_primitives: 1810 checks` and save the PASS message.
- [x] P7: Small Vivado test, no board needed: select `sim_aes_core`
  / `tb_aes128_core`, then **Run Behavioral Simulation > Run All**.
  Observe `PASS tb_aes128_core: 17433 checks, 556 completed blocks`.
  PASS reported October 29; waveform exercise moved to P17.
- [x] P8: Run `sim_aes_mmio` / `tb_aes_mmio` in Vivado to PASS.
  PASS reported October 29; waveform exercise moved to P17.
- [x] P9: Run `sim_soc_aes` / `tb_soc_aes` in Vivado to PASS.
  PASS reported October 29; waveform exercise moved to P17.
- [x] P10: Run `sim_aes_board` / `tb_aes_board` to PASS.
  User confirms October 27 PASS; waveform exercise is P17. See [the CPU/AES guide](cpu_aes_integration.md).
- [ ] P11: Archive a photo/video of the board tests with their image names
  for the final report. Functional passes are already recorded.
- [ ] P12: Record a repeat of the standalone CPU image and its restart
  method; only the AES repeat count was explicitly reported so far.
- [x] P13: Small UART Vivado test: run `sim_uart_tx` / `tb_uart_tx` to PASS.
  PASS reported October 29; waveform exercise moved to P17.
- [x] P14: Run `sim_uart_mmio` / `tb_uart_mmio` to PASS.
  PASS reported October 29; waveform exercise moved to P17.
  Follow the [small UART walkthrough](uart_tx.md); no board is needed.
- [x] P15: Lab functional recovery: rerun `sim_cpu_core`,
  `sim_soc_minimal` (test 7), `sim_aes_core`, `sim_aes_mmio`, and
  `sim_soc_aes` to PASS. All five PASS messages reported October 29.
  The lab was previously identified as Vivado 2020. Setup/evidence follow-up
  is P16; see [the lab result](lab_results_2026-10-29.md).
- [ ] P16: Archive the full lab logs, `setup_report.txt`, exact Vivado
  version and source revision, and test 7's `SIM_ROM_LOAD_OK` line.
  The pasted PASS messages are already saved; this is supplementary evidence.
- [ ] P17: Complete the waveform exercises originally grouped with
  P7/P8/P9/P13/P14: AES START/BUSY/DONE and known ciphertext;
  MMIO START at completion; CPU status/ciphertext reads and RAM results;
  UART's first A frame/full stop bit; UART bus completion and busy-write error.
  Also inspect ALU/register-file and board-wrapper signals and explain the
  minimal-SoC versus CPU board-wrapper tests. Save useful waveform views.
- [x] P18: Run keypad scanner test 17, `sim_keypad_scanner` /
  `tb_keypad_scanner`, to PASS in the lab; observe one pulse per press,
  stable release, and multiple-key lockout. See [the scanner guide](keypad_scanner.md).
- [x] P19: Run keypad MMIO test 18, `sim_keypad_mmio` / `tb_keypad_mmio`,
  to PASS in the lab. Inspect pending data surviving reads, ACK freeing
  the slot, and OVERFLOW preserving the first key. See [the MMIO guide](keypad_mmio.md).

- [x] P20: On lab Vivado run test 19: 64 keypad digits through CPU to two checked ciphertexts.
- [x] P21: Run test 20: capture the external OLED startup, checkerboard and shutdown.
- [ ] P22: Generate both bitstreams in the lab GUI; save the timing reports and exact .bit names.
- [x] P23: On JA verify real keypad labels, one press per hold and the 32nd digit block indicator.
- [x] P24: On JB photograph the external OLED pattern; record automatic shutdown and LD1.

November 4: P18–P21 and P23–P24 passed, reported by the user with photos. P22 was not performed. See [the lab record](lab_results_2026-11-04.md).

- [ ] P25: Run combined tests 21–23 on lab Vivado; save PASS lines.
- [ ] P26: Program the combined JA/JC image; compare both full ciphertexts on the external OLED.
- [ ] P27: Confirm chord shutdown, release/restart, and a new block afterward.
- [ ] P28: Run implementation and generate the combined image on the lab PC from its source.

Next: [combined demo guide](../NEXT_LAB_COMBINED.md).

Use the [November 3–4 lab sheet](../LAB_THIS_WEEK.md) for P18–P24.
For older waveform and evidence follow-ups, see
[the remaining tests and preparation checklist](remaining_lab_tasks.md).

P15 follows the reported failures in tests **6/7/11/12/13** on
Vivado 2020; test 7 was reported on October 29 without an error excerpt.
Use [the next-lab checklist](../NEXT_LAB.md). The October 29 revision passed
all 16 sets and eight diagnostic scenarios locally in 2025.2; see
[the evidence](../evidence/lab_sim_recovery_2026-10-29/README.md).
The user subsequently reported all five recovery tests passing in the lab
on October 29. P15 is complete; supplementary setup evidence is P16.
Physical P4/P5/H2 remain passed separately.

P6/P10 passed October 27; P7/P8/P9 passed October 29. All original
16 simulation tests have now passed in the lab; waveform learning is P17.
Follow the [small AES test walkthrough](aes_core.md); no terminal
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
- [x] M3.3: Keypad unit/MMIO tests pass: all keys, bounce, held key,
  release/repress, event acknowledgement, multiple-key policy, and reset.
  Scanner and mailbox passed locally October 29, including all 16 positions,
  ACK/event races and overflow. See [the MMIO evidence](../evidence/keypad_mmio_2026-10-29/README.md).
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
The current source adds scanner test 17 and keypad MMIO test 18; the published recovery snapshot
has 16 sets. M3.3's engineering tests pass; P18/P19 are the new lab checks.
Adapter availability is assumed for planning;
its actual model/logic voltage still needs checking before wiring. UART
CPU integration, routed board build, and H3.1 remain open.

## M4 — whole system — due November 12

- [ ] M4.1: Connect all four approved MMIO windows and check response routing,
  invalid addresses, byte strobes, and wait-state behavior.
- [ ] M4.2: Finish input -> AES -> display firmware, including clear/start,
  length tracking, timeout/error handling, and the next input block.
- [x] M4.3: Pass system simulation using modeled key presses and captured
  OLED/UART traffic; compare actual ciphertext and displayed values.
- [ ] M4.4: Pass repeated inputs, reset/restart, incomplete input, and stalled
  peripheral cases; no lost key events or duplicate bus side effects.
- [ ] M4.5: Measure code, constants, buffers, and stack use within 4 KB ROM /
  4 KB RAM. Run all existing and new simulation sets to PASS.
- [x] M4.6: Complete full-system implementation; review 100 MHz routed
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




