# Next lab: combined keypad → AES → OLED

**November 5 results:** tests 21–26 and the combined ciphertext display passed
in the lab. Next, try [the built-in OLED variant](LAB_ONBOARD_OLED.md), which
needs only the KYPD on JA. UART hardware is still an optional follow-up.
The existing external-OLED kit below remains the physically verified backup.

Download [the hardened source + bitstream ZIP](https://raw.githubusercontent.com/statisnomo/RC-Project_P1_G9/main/deliverables/riscv_soc_hardened_ja_jc_2026-11-05.zip). Use [the JA/JC guide](NEXT_LAB_COMBINED.md) for simulations 21–26, held-key/partial-input/restart checks and ten physical reference blocks. KYPD stays on JA; OLED uses JC. The [optional UART side test](LAB_UART_OPTIONAL.md) uses JD1 and the same image. Tests 1–20 and both separate physical demos have passed. The earlier lab instructions are archived below.

---

# This week's lab: November 3–4
Download [the November lab ZIP](https://raw.githubusercontent.com/statisnomo/RC-Project_P1_G9/main/deliverables/riscv_soc_lab_2026-11-03.zip) and extract it on the lab PC. Start with [the two board projects and GUI lab tests](LAB_THIS_WEEK.md). Run tests 17–20, generate both bitstreams on the lab PC, then test the keypad and external OLED on the ZedBoard. Tests 1–16 have already passed in the lab.

The older recovery procedure follows for reference.
## October archive: recover tests 6, 7, 11, 12, and 13

**All original tests 1–16 passed across October 27 and 29.**
On October 29, tests **5/6/7/11/12/13/15/16**
were reported PASS. See [the recorded results](docs/lab_results_2026-10-29.md).
P15's functional recovery is complete. Keep the procedure below for reruns;
remaining evidence and waveform exercises are P16/P17 in the checklist.
For what to do now, use [the remaining-test checklist](docs/remaining_lab_tasks.md).
The new scanner increment adds [test 17](docs/keypad_scanner.md) in the
current source; the published recovery snapshot still has sixteen tests.

Updated **29 October 2026**. Use Vivado's menus; no terminal commands are needed.
The lab reported **Vivado 2020**. The development installation is **2025.2**,
with the reported lab rerun recorded above. No FPGA board is needed for these simulations.

## 1. Download and create the project

1. On [the GitHub repository](https://github.com/statisnomo/RC-Project_P1_G9),
   select **Code > Download ZIP**. Extract the complete ZIP into a new,
   writable folder, for example `C:\RC_Lab_29Oct`. Keep the old lab folder.
2. Open the extracted folder that contains `rtl`, `tb`, `fw`, and `scripts`.
   GitHub usually calls this folder `RC-Project_P1_G9-main`.
3. Start the lab's Vivado. Record the full version from **Help > About Vivado**.
   Close any running simulation and use **File > Project > Close** if needed.
4. Select **Tools > Run Tcl Script**, browse to
   **`scripts/create_lab_compat_project.tcl`**, and click **OK**.
   Use this creator for Vivado 2020; the bundled development `.xpr` uses 2025.2.
5. Wait for **`SIM_DATA_FILES_OK: 128 hex files`** and
   **`LAB_COMPAT_PROJECT_READY`**. The new project opens automatically.
   If creation reports an error, save that first message before proceeding.

The script creates `vivado/riscv_soc_lab_compat/riscv_soc_lab_compat.xpr`,
or a numbered variant if that folder exists. It selects FPGA part
`xc7z020clg484-1`; no ZedBoard board-definition entry is needed. Save
the **`setup_report.txt`** beside this new `.xpr`. For a later session,
reopen this lab-generated project.

## 2. Run the small tests in order

For each item below:

1. In Flow Navigator, right-click **Simulation > Simulation Settings**.
2. Choose its **Simulation set**, confirm the named top, and click **OK**.
3. Click **Run Simulation > Run Behavioral Simulation**. It starts at 0 ns.
4. Click **Run All**. Read the printed result in the **Tcl Console** pane;
   you do not need to type anything there.
5. Save the PASS line, then use **File > Close Simulation** before switching sets.

The boxes below reflect the user's October 29 lab PASS report:

- [x] **Test 5 — memory check:** `sim_memories` / `tb_memories`.
  Expected `PASS tb_memories: 24 checks`.
- [x] **Test 6 — CPU:** `sim_cpu_core` / `tb_cpu_core`.
  Expected `PASS tb_cpu_core: 76 cases, 1287 retirements`.
- [x] **Test 7 — CPU + ROM + RAM:** `sim_soc_minimal` / `tb_soc_minimal`.
  First expect `SIM_DATA_OK 'cpu_smoke.hex': 1024 words` and
  `SIM_ROM_LOAD_OK 'cpu_smoke.hex': all 1024 DUT words match file`.
  Then expect `PASS tb_soc_minimal: ROM program, sum=55, load-use=56, one delayed MMIO write, 44 retirements`.
- [x] **Test 11 — AES core:** `sim_aes_core` / `tb_aes128_core`.
  Expected `PASS tb_aes128_core: 17433 checks, 556 completed blocks`.
- [x] **Test 12 — AES registers/bus:** `sim_aes_mmio` / `tb_aes_mmio`.
  Expected `PASS tb_aes_mmio: 1/3 wait edges, 284 NIST blocks per mode`.
- [x] **Test 13 — CPU runs AES:** `sim_soc_aes` / `tb_soc_aes`.
  Expected `PASS tb_soc_aes: real CPU/ROM/RAM/AES, 1/5 wait edges, 32 checked blocks`.

These are prefixes of the full PASS messages. A `$finish` after PASS is normal.
A moving waveform or a successful compile alone is not a PASS.
Update **P15** in [the master checklist](docs/project_checklist.md) after
tests **6, 7, 11, 12, and 13** all pass in the lab.

If time remains, run **test 15 `sim_uart_tx`** and **test 16 `sim_uart_mmio`**
using [the UART walkthrough](docs/uart_tx.md). They need no serial adapter
or board. The [full GUI guide](VIVADO_START_HERE.md) covers all sixteen sets.

## 3. If something fails

Stop that simulation. Do not keep clicking Run All after a Fatal message.
Save the **first warning/error**, any `SIM_DATA` / `SIM_ROM_LOAD` lines,
and the final FAIL line. The full log is:

`vivado/<generated-project>/<generated-project>.sim/<simulation-set>/behav/xsim/simulate.log`

For test 7, the new messages separate two setup problems:

- **`FAIL SIM_DATA`**: the file cannot be read or is incomplete/malformed.
- **`FAIL SIM_ROM_LOAD`**: the file can be read, but the actual CPU ROM
  differs. The message names the word and actual/expected values.

If both checks pass and the CPU later halts, save its **code, PC, and value**
from the new fault message. Test 7's original error was unavailable, so
its exact lab cause remains unconfirmed. See [the recovery notes](docs/lab_simulation_recovery.md).

## 4. Bring back the evidence

- [ ] Full Vivado version, generated project name, and `setup_report.txt`.
- [ ] The six simulation PASS messages above, or the first failure and full log.
- [ ] One test 7 waveform showing the MMIO write with value **56**.
- [ ] Updated [lab record](docs/lab_record_template.md) and checklist P15 status.

Your reported ALU, CPU, and CPU/AES board passes remain recorded. The same
three working `.bit` files are in [build/](build/README.md); this simulation
recovery does not require rebuilding or reprogramming them. If the lab has
the peripheral hardware, also record the KYPD/OLED module models and the
3.3 V USB-to-TTL adapter model for the next wiring step.



