# Project progress log

Deadline: **20 November 2026**. Use India time for dates.
Task IDs refer to [project_checklist.md](project_checklist.md).

## 23 October 2026 — plan established

- Deadline updated to November 20; working full-demo target November 15. 
- Existing nine-test summary, board build records, and reference audit reviewed.
- B1-B12 reflect saved verified results. They are not fresh test runs today.
- Physical board observations remain pending. M1-M7 are planned work.
- Next development action: M1.2, AES interface and byte-order contract.
- Next lab action: P4/P5, observe the existing ALU and CPU demos.
- Lab reservations and exact submission time remain to be confirmed.

## 24 October 2026 — standalone AES accepted

- Tasks **M1.1-M1.6 and G1 passed**. User selected 32 hexadecimal digits;
  fixed demo key, clear behavior, and display format recorded in the contract.
- Added six AES hardware modules, an independent mathematical reference,
  two testbenches, and original NIST known-answer files with hash manifest.
- Vivado `sim_aes_primitives`: **1,810 checks passed**.
- Vivado `sim_aes_core`: **17,433 checks / 556 completed blocks passed**,
  including 284 published NIST answers, 256 random cases, and eleven
  reset-abort locations with recovery. Verified 11-clock latency and
  earliest next acceptance after 12 clocks.
- Existing `sim_cpu_board` rerun: **15 checker scenarios passed**.
- Standalone synthesis: **1,314 LUTs, 390 FFs, zero BRAM/DSP/latches**.
  Estimated register setup slack **+4.976 ns** at a 10 ns clock constraint.
  Out-of-context synthesis does not establish routed/physical timing.
- Evidence: `evidence/aes_m1_2026-10-24/`; synthesis reports/checkpoint in
  `build/aes_synthesis/`. GUI project now has eleven simulation sets.
- Fresh ZIP extraction: both AES sets and the CPU board test passed again
  without repairing the saved project. The October 24 lab ZIP contains
  the references, source, tests, wave databases, reports, and updated plan.
- Next development action: **M2.1**, define AES MMIO access and command
  semantics, then verify the wrapper before CPU integration.
- Next lab action remains **P4/P5**, observe the existing ALU/CPU images.
  AES board-image creation and all physical observations remain pending.

## 26-27 October 2026 — CPU/AES integration and lab pack

- Tasks **M2.1-M2.6 and G2 passed**. Added AES MMIO register semantics,
  wrapper, CPU integration, four-block ROM firmware, independent LED
  observer, three simulations, and an AES board top using existing LED pins.
- MMIO passed **26,632 / 48,264 checks** with one/three wait edges.
  Both include 284 NIST answers, busy/reset/access-error cases, and
  acceptance checks at the encryption-completion boundary.
- CPU/AES simulation passed **32 healthy blocks**, reset/restart, and
  mismatch, timeout, and missing-peripheral fault paths. The real board
  wrapper and **13 observer scenarios** also passed.
- Firmware uses **880 ROM bytes / 68 RAM bytes**. Corrected status ordering:
  RAM status is committed before x31 announces success. GNU linking and
  C startup are not claimed; the ready ROM is generated from checked encodings.
- Initial board routes missed 100 MHz. Capturing MMIO requests during the
  existing wait cycle fixed the long CPU-address-to-response path. The
  final route passes **+0.311 ns setup / +0.159 ns hold**, with no internal
  unconstrained endpoints. DRC has zero errors and the retained ZPS7-1 warning.
- Generated `build/zedboard_aes_demo/zedboard_aes_demo.bit`; 3,182 LUTs,
  2,084 flip-flops, two RAMB36 blocks, zero DSPs and no inferred latches.
- Added personal Vivado tasks **P6-P10**, the October 27 lab walkthrough,
  and a record sheet for three separate board tests. Personal observations
  and **H2 remain unchecked** until the user performs them.
- Evidence: `evidence/aes_m2_2026-10-27/`; board reports are beside the image.
- Fresh extraction of the lab ZIP passed **all 14 simulation sets** with
  every registered source inside the extracted copy, without project repair.
  Added a three-page printable guide and visually checked all pages.
- Next development stage: **M3**, UART/keypad/OLED unit tests and exact
  module identification before wiring. No new peripheral pins are enabled.

## 27 October 2026 — previous lab conversation reviewed

- Source: [shared lab conversation](https://chatgpt.com/share/6ae05561-14e0-83ee-b1e8-a38ddfce4c4d).
  Actual visit date is not confirmed; this is the review date.
- User reported PowerShell script execution being blocked, then moving to
  Vivado GUI and finding no `.xpr` in the lab copy. The other assistant's
  missing-`cases.vh` comment concerned the files uploaded to that chat.
- User reported programming a bitstream and a blinking LED. Recorded as
  **reported board activity**, with exact image and functional result
  unconfirmed. No explicit simulation PASS or LD1/LD2 observation was supplied.
- Follow-up answer: the user remembers only an LED blinking. The earlier
  image and PASS/FAIL states remain unknown; no functional gate is closed.
- Inspected the current ZIP: `.xpr`, 14 simulation sets, `cases.vh`, 126 CPU
  program-data files, shared definitions, ROMs and AES vectors are present.
  Existing fresh-extraction evidence records 14 passing development tests.
- Added [lab follow-up notes](lab_followup_2026-10-27.md). P1/P2/P4/P5/H2
  remain open. Next personal check: identify the programmed image and
  record heartbeat, PASS/FAIL LEDs, and a video; use the prepared GUI project.

## Copy for each session or lab visit

Date / start-end time:
Session type: learning / design / simulation / implementation / lab / report
Task IDs:
One intended result:

What changed:
Source/firmware snapshot or file revision:
Vivado simulation set or programmed bitstream:
Expected result:
Observed result:
Evidence file(s), screenshot(s), or video:
Status: not started / in progress / passed / blocked

First failing observation, if any:
Next smallest action:
Lab access needed for that action? Yes / No
Milestone date still achievable? Yes / Replan needed

Only after evidence is saved: update the corresponding checklist boxes.
For a blocked task, retain the partial result and exact failure instead of
marking it complete. An old pack remains a snapshot; keep this live log in
the project and include its latest copy in the next pack.
