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
