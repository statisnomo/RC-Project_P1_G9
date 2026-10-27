# Follow-up to the previous lab attempt

Reviewed **27 October 2026**. The actual lab date is not established by
the shared record, so this is the review date, not an assigned visit date.

Source: the user's shared conversation,
[PowerShell Script Fix](https://chatgpt.com/share/6ae05561-14e0-83ee-b1e8-a38ddfce4c4d).
The observations below distinguish the user's reports from advice given
by the assistant in that conversation. Uploaded file contents and original
lab screenshots/logs were not available for independent inspection.

## What the record establishes

1. The lab computer blocked `run_all_tests.ps1` with a PowerShell
   `PSSecurityException` / `UnauthorizedAccess` message. The runner did
   not execute through that attempt; this does not establish an RTL failure.
2. The user requested Vivado GUI testing. They reported finding no `.xpr`
   in the project copy they were using. The record does not identify which
   distribution archive was taken to the lab.
3. Design files and then nine testbench files were uploaded to the other
   chat. Its assistant identified `cases.vh` as absent from those uploads.
   That is not evidence that the file was absent from the original project.
4. The user reported loading a bitstream and seeing an LED blink. The
   bitstream filename, LED number, LD1/LD2 states, device/revision, and
   repeated-start result were not recorded.

The record contains no explicit simulation PASS lines or identified
ALU/CPU/AES board PASS result. The general statement that setup was fine
does not establish that every simulation completed successfully.

## Status we can record

**Board programming and blinking activity: reported by the user.**
The exact tested design and its functional outcome remain unconfirmed.
When asked in this project chat, the user confirmed that they remember
only an LED blinking. No image filename or additional LED state is known.

In our three board demos, LD0 is driven by a heartbeat counter independently
of the functional test. LD1 lights only after the checker finishes without
failure; LD2 indicates failure. A reported blink, without the image and
other LEDs, is insufficient to close P4, P5, or H2. These gates remain open.

## What is already fixed in the current delivery

The October 27 GUI ZIP was inspected again during this review. It contains:

- `vivado/riscv_soc_lab/riscv_soc_lab.xpr`, with **14 simulation sets**.
- `tb/programs/cases.vh`, all **126 CPU program-data files**, and
  `rtl/cpu/cpu_defs.vh`.
- Both CPU/AES firmware ROM images and the AES known-answer data file.
- Saved evidence that all 14 sets passed from a fresh extraction.

These are development/packaging results, separate from personal lab tests.
Use the prepared project rather than reconstructing its sources by hand.
The GUI procedure does not require running PowerShell scripts or changing
the lab computer's execution policy.

## Next smallest lab checks

1. Extract the complete October 27 GUI ZIP and open its prepared `.xpr`.
   Select `sim_1` / `tb_alu`, then **Run Behavioral Simulation > Run All**.
   Save the `PASS tb_alu: 4142 checks` result. Repeat with
   `sim_soc_minimal` and `sim_cpu_board` when time permits.
2. In Hardware Manager, program the explicitly named ALU image and record
   **LD0 blinking, LD1 ON, LD2-LD7 OFF**, plus the filename and a short video.
3. Repeat with the CPU image, then the CPU/AES image. Record each separately;
   reprogram the AES image three times as specified in the lab guide.
4. The user currently recalls only blinking. Record the filename and all
   eight user LEDs during the next run; an earlier photo/log may also
   establish the previous result if one is later found.

Use [the lab walkthrough](lab_2026-10-27.md),
[record sheet](lab_record_template.md), and [master checklist](project_checklist.md).
No hardware change is indicated solely by the script-policy error or blink report.
