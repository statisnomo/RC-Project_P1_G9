# Test 7 and lab recovery verification

Verified **29 October 2026**, **Vivado 2025.2**, target **xc7z020clg484-1**.
The lab uses Vivado **2020**; that version is not installed here. These
results do not certify the pending lab run or diagnose its unseen test 7 error.

The runner `scripts/verify_lab_recovery.tcl` created a fresh project using
the same `scripts/create_lab_compat_project.tcl` entry point as the lab
GUI procedure. All registered source paths resolved inside the source tree.
All **16 normal simulation sets passed**. The sixteen `tb_*.log` files
and `summary.txt` contain the actual results.

Test 7 (`tb_soc_minimal.log`) first confirmed that all **1,024 DUT ROM
words** matched `cpu_smoke.hex`, independently read with `$fscanf`.
It then ran the real CPU and memories: **sum 55, load-use result 56,
one delayed MMIO write, 44 retirements**. The ROM was not reloaded or
repaired by the testbench. CPU, AES, firmware, and pin constraints are
unchanged by the recovery; the earlier UART addition remains separate.

Eight diagnostic scenarios were also verified:

- `diagnostic_0.log`: valid input accepted.
- `diagnostic_1.log` through `diagnostic_5.log`: missing, short, malformed,
  unknown, and extra data rejected with the expected specific messages.
- `soc_rom_diagnostic_0.log`: test 7 with a missing program file stops
  with `FAIL SIM_DATA` at **1 ns**, before CPU reset is released.
- `soc_rom_diagnostic_1.log`: the correct file is present, but the last
  DUT ROM word is deliberately changed. Test 7 reports `FAIL SIM_ROM_LOAD`
  for **word 1023**, actual `00000001`, expected `00000000`, at **1 ns**.

The FAIL messages in those seven negative diagnostic logs are intentional.
They are not normal lab simulation sets; the runner checks the expected
messages. None of the sixteen normal test logs contains a FAIL.

`source_sha256.json` records the **224 local source files** used for this
run (RTL, benches, data, firmware, constraints, Tcl helpers, and development
project). `artifact_sha256.json` records the logs and summary. These are
byte hashes of the local verification snapshot; Git text newline conversion
can change source hashes without changing their contents as Verilog/Tcl.

Follow [NEXT_LAB.md](../../NEXT_LAB.md). Checklist **P15 stays open** until
tests **6/7/11/12/13** pass in lab Vivado 2020 and the logs/setup report
are saved. The previously reported physical ALU/CPU/CPU-AES passes remain
separate observations.
