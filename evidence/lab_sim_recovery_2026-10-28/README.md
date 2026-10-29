# Lab simulation recovery evidence

Verified **28 October 2026**, using **Vivado 2025.2**. The lab uses
**Vivado 2020**; the user confirmed opening the supplied `.xpr` there.
No Vivado 2020 installation is available on the development machine.

The final run created a fresh project through
`scripts/create_lab_compat_project.tcl`, the same entry point used by
the lab GUI procedure. All registered sources resolved inside this
project's source tree. All **16 normal simulations passed**, including
the four affected benches: CPU, AES core, AES MMIO, and CPU/AES.
`summary.txt` and the sixteen `tb_*.log` files preserve those results.

Six extra scenarios exercise the simulation-only data preflight:

- `diagnostic_0.log`: a valid two-word file is accepted.
- `diagnostic_1.log`: a nonexistent file is rejected by name.
- `diagnostic_2.log`: a short file is rejected with its actual/expected count.
- `diagnostic_3.log`: malformed hexadecimal input is rejected.
- `diagnostic_4.log`: unknown digits are rejected.
- `diagnostic_5.log`: extra words are rejected.

**FAIL messages in diagnostic logs 1-5 are the expected test results.**
The normal simulation logs contain no FAIL. The runner verifies the
specific expected diagnostic in each fault case.

An earlier diagnostic-runner attempt resumed after a time-zero fatal
error and repeatedly accessed an invalid handle. That run was stopped.
The final version starts these checks after the time-zero GUI launch
and returns explicitly from each error path. The final six scenarios
completed without invalid-handle loops.

`source_sha256.json` identifies the current RTL, benches, data, firmware,
constraints, Tcl helpers, and supplied development `.xpr`.
`artifact_sha256.json` identifies the saved logs and summary. The native
lab project is generated afresh by the creator, using the installed
Vivado version; no 2025.2-generated project is represented as a 2020 build.

The [reported lab failures and recovery procedure](../../docs/lab_simulation_recovery.md)
remain the source for the lab retest. Checklist P15 is open until the user
observes those four tests passing in Vivado 2020. The earlier physical
ALU/CPU/AES passes remain recorded separately.
