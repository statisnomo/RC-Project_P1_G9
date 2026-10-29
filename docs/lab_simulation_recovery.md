# Recover the five lab simulations in Vivado 2020

Lab reports: **27 and 29 October 2026**. Recovery updated **29 October 2026**.
The user confirmed opening the supplied `.xpr` in **Vivado 2020**; its
exact minor version is not yet recorded. That project was generated and
previously tested with **Vivado 2025.2**.

Your ALU, CPU, and CPU/AES **physical board passes remain recorded**.
The failures below are from separate simulations on the lab computer.
For the next visit, start with [the short GUI checklist](../NEXT_LAB.md).

## What the reported errors establish

- **Test 6, CPU:** file-open warnings for the program and reference files,
  followed by `code=1 pc=00000000 value=xxxxxxxx` at 80 ns. The test did
  not obtain a known first instruction. Its printed filenames were garbled.
- **Test 7, minimal SoC:** reported failed on October 29. The user does
  not currently have its error message and will supply it after the next
  run. No specific fault or cause is inferred from that report alone.
- **Test 11, AES core:** `FAIL missing NIST vector 1` at 616 ns. An entry
  in the expected-answer table was uninitialized. This was not a reported
  AES ciphertext mismatch; the earlier directed cases had already run.
- **Test 12, AES MMIO:** `FAIL missing vector` at 14030 ns. Again, a vector
  table entry was uninitialized; the report did not include its index.
- **Test 13, CPU/AES:** `FAIL unexpected halt waiting for firmware status`
  at 90 ns. A missing or wrong firmware image is a likely explanation,
  but that message alone does not identify the CPU fault code.

The supplied excerpts do not establish exactly why the data was unavailable
in that run. Version-specific filename/loading behavior, incomplete files,
or lost simulation-file settings remain possible. Full lab logs and a
Vivado 2020 rerun are needed to confirm the cause and recovery.

## The GUI-only recovery procedure

Download the latest repository using **Code > Download ZIP** on
[GitHub](https://github.com/statisnomo/RC-Project_P1_G9). Keep the working
board pack as a backup. Extract the entire ZIP into a new, short, writable
folder such as `C:\RC_Lab_29Oct`; do not merge it into the old project or
copy only the `.v` files. The dated October 28 recovery ZIP is a historical
snapshot and does not include the new test 7 ROM check.

1. Start the lab's **Vivado 2020**. If a project is open, close its
   simulation and use **File > Project > Close**.
2. Select **Tools > Run Tcl Script**. Browse into the extracted project
   and select **`scripts/create_lab_compat_project.tcl`**. Click **OK**.
   This is a menu action; no terminal or typed commands are needed.
   [AMD documents this menu action](https://docs.amd.com/api/khub/documents/iehzkkbf6tiwy5N7I2dA2g/content).
3. The script checks all **128 data files**, creates the project using
   the Vivado version that is actually running, and leaves it open.
   It registers ROMs/vectors, SystemVerilog testbenches, includes, and
   the `VIVADO_GUI` definition automatically.
4. The first generated project is
   **`vivado/riscv_soc_lab_compat/riscv_soc_lab_compat.xpr`**.
   Repeating the creator uses a numbered folder instead of overwriting
   an earlier project. Next time, open that lab-generated `.xpr`.
5. Select **sim_cpu_core** in **Simulation Settings**. Click
   **Run Simulation > Run Behavioral Simulation**, then **Run All**.
6. Repeat with **sim_soc_minimal**, **sim_aes_core**, **sim_aes_mmio**,
   then **sim_soc_aes**.
   Close the simulation before changing sets. Save each PASS line.
7. If these pass, run the remaining sets using
   [the full Vivado guide](../VIVADO_START_HERE.md). Tick **P15** only after
   observing all five recovery PASS results on the lab computer.

These are the expected results, not new lab observations:

- `tb_cpu_core`: **76 cases / 1,287 retirements**.
- `tb_soc_minimal`: **sum 55, load-use 56, one delayed MMIO write,
  44 retirements**, after all 1,024 DUT ROM words match the program file.
- `tb_aes128_core`: **17,433 checks / 556 completed blocks**.
- `tb_aes_mmio`: **26,632 / 48,264 checks** for the two wait settings.
- `tb_soc_aes`: **32 healthy encrypted blocks**, plus restart/error cases.

The creator saves `setup_report.txt` beside the new `.xpr`. Keep that
file: it records the exact installed Vivado version and generated project.
If the creator stops with `SIM_DATA`, keep its named file and message;
the source pack is incomplete or malformed and simulations should not
be marked passed.

## What changed

The CPU test now constructs each filename as a complete string before
passing it to file I/O. This removes its mixed string/packed-parameter
concatenations, which are a compatibility concern given the garbled names.
CPU and AES memory loads now specify their start/end indices explicitly,
following [AMD's memory-loading guidance](https://docs.amd.com/r/2023.2-English/ug901-vivado-synthesis/Loading-Memory-Contents-With-File-I/O-Tasks).

A simulation-only preflight checks that each expected file opens, contains
known hexadecimal words, and has the expected word count. AES vectors are
also checked immediately after loading. Missing or short data therefore
gets a **`FAIL SIM_DATA`** message before a misleading CPU/AES functional
failure. Testbench acceptance values and coverage are retained.

Test 7 now checks the complete 1,024-word program file and compares it
with the **actual initialized DUT ROM before releasing reset**. The
comparison reads through `$fscanf`, independently of the ROM's `$readmemh`;
it never reloads the DUT or repairs its memory. A discrepancy produces
`FAIL SIM_ROM_LOAD` with the index and actual/expected words. A later CPU
fault now prints its code, PC, and fault value. A final-result failure
prints the observed RAM/register values and transaction count.

The new creator checks hex token widths before creating a fresh project.
It explicitly registers the ROM files in each relevant simulation set.
There are still **16 normal simulation sets**; diagnostic fault-injection
fixtures are maintainer tests, not additional lab tasks.

No hardware RTL, firmware image, active pin assignment, or published
bitstream changes as part of this recovery. A simulation fix does not
require rebuilding your three already-working board images.

## If a test still fails

Save the **first warning/error**, the `SIM_DATA_OK` or `FAIL SIM_DATA`
lines, test 7's `SIM_ROM_LOAD` messages, the final failure, and
`setup_report.txt`. The simulation log is
inside the generated project's `.sim/<simulation-set>/behav/xsim/`
folder, named **`simulate.log`**. Do not report a moving waveform as PASS.
Stop that simulation after a FAIL; fix the reported setup issue and
launch a fresh simulation instead of repeatedly clicking Run All.

Only Vivado **2025.2** is installed on the development machine. Local
verification cannot certify a Vivado **2020** run; that compatibility
check remains the lab retest. The reported failures and the successful
physical board observations are retained separately in the project log.

The October 28 recovery passed **all 16 normal simulations** in a freshly
generated project, plus six data-check scenarios. That result is retained
as [historical evidence](../evidence/lab_sim_recovery_2026-10-28/README.md).
The **October 29 revision passed all 16 normal simulations** in another
fresh project on Vivado 2025.2, plus **eight diagnostic scenarios**.
Test 7 passed the full ROM comparison and its original program checks;
its missing-file and corrupted-ROM cases both stopped at 1 ns, before
CPU execution. See [the current evidence](../evidence/lab_sim_recovery_2026-10-29/README.md).
