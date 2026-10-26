# Test the project using Vivado's graphical interface

Updated 26 October 2026. This is the main guide for the GUI lab pack.

Project deadline: **20 November 2026**. The
[timeline](docs/project_timeline.md) and [checklist](docs/project_checklist.md)
set the order of work; this guide supplies the existing test procedures.
You can follow it using Vivado menus and buttons. The testbench drives
inputs automatically and prints its result in Vivado.

## Open the ready-made project

1. Extract the entire GUI ZIP into a short writable folder, for example
   `C:\RC_Lab`. Keep `rtl`, `tb`, `fw`, and `vivado` together.
2. Start **Vivado 2025.2**.
3. Click **Open Project**.
4. Browse inside the extracted folder to
   **`riscv_soc_project/vivado/riscv_soc_lab/riscv_soc_lab.xpr`**.
5. Open it. The project already contains the hardware, testbenches, header
   files, ROM image, and CPU test data, with the file types configured.

The target is `xc7z020clg484-1`. A ZedBoard board-definition entry is not
required because the project selects the FPGA part directly. Vivado needs
that Zynq-7000 device family installed.

The updated project starts with **`sim_aes_primitives`**, whose simulation
top is **`tb_aes_primitives`**. For your first ALU lesson, select **`sim_1`**,
top **`tb_alu`**, using Simulation Settings as described below.
The synthesis top is separately set to `zedboard_aes_demo`. A testbench is
simulation-only; do not make `tb_alu` or another `tb_*` the synthesis top.

## Your first test: the ALU

First select `sim_1` / `tb_alu` in **Simulation Settings**. For the newest
AES tests, use the [AES step-by-step guide](docs/aes_core.md).

1. In **Flow Navigator**, click **Run Simulation > Run Behavioral Simulation**.
2. Wait for the simulator and waveform window to open. This project starts
   at **0 ns** so that you can choose signals before running.
3. In **Scopes**, select **`tb_alu`**.
4. In **Objects**, select `operand_a`, `operand_b`, `alu_op`, `result`, and
   `zero`. Right-click and choose **Add to Wave Window** if they are missing.
5. Click **Run All** on the simulation toolbar. Hover over buttons to check
   their labels; do not confuse it with the fixed-duration Run button.
6. Read the output in Vivado's **Tcl Console** pane. You are reading the
   automatic result there; you do not need to type a command.
7. Find **`PASS tb_alu: 4142 checks`**. The simulation stops automatically.
8. Click **Zoom Fit**, then zoom into the first few nanoseconds.

For the first input, `operand_a=ffffffff` and `operand_b=00000001`.
The expected ADD result is `00000000` with `zero=1`.
Right-click bus values and select **Radix > Hexadecimal** to make them
easier to read. The ALU has no clock because it is combinational.

A moving waveform is not, by itself, a test pass. Read the explicit PASS
line. A `$finish` message after PASS is the normal end of this test.

## Switch to the next test

1. Close the current simulation using **File > Close Simulation**.
2. In Flow Navigator, right-click **Simulation** and select
   **Simulation Settings**.
3. Change the **Simulation set** dropdown to the next set listed below.
4. Confirm its **Simulation top module name** matches the listed testbench.
   These names are already configured; leave the other settings intact.
5. Click **OK**, then **Run Simulation > Run Behavioral Simulation**.
6. Select the signals you want and click **Run All**.
7. Record the PASS line before moving to the next test.

You can also select a simulation set in the Sources pane and use its
**Make Active** option when shown. The Settings dropdown provides the
explicit way to choose the set.
[AMD documents the simulation-set and top-module settings here](https://docs.amd.com/r/2025.2-English/ug900-vivado-logic-simulation/Using-Simulation-Settings).

## The fourteen tests to run

### 1. ALU

- Simulation set: **`sim_1`**. Top: **`tb_alu`**.
- Files: `rtl/cpu/alu.v` and `tb/cpu/tb_alu.v`.
- Checks arithmetic, logic, shifts, comparisons, zero, and unsupported controls.
- Expected: **4,142 checks**.
- Watch: `operand_a`, `operand_b`, `alu_op`, `result`, `zero`.

### 2. Register file

- Set: **`sim_regfile`**. Top: **`tb_regfile`**.
- Files: `rtl/cpu/regfile.v` and `tb/cpu/tb_regfile.v`.
- Checks both read ports, writes, write enable, reset, and writes to x0.
- Expected: **2,456 port checks**.
- Watch: `clk`, `rst`, `we`, `waddr`, `wdata`, `raddr1`, `rdata1`,
  `raddr2`, `rdata2`. Stored values change after a rising edge; x0 reads zero.

### 3. Immediate generator

- Set: **`sim_imm_gen`**. Top: **`tb_imm_gen`**.
- Files: `rtl/cpu/imm_gen.v` and `tb/cpu/tb_imm_gen.v`.
- Checks instruction constant extraction, bit placement, and sign extension.
- Expected: **14,546 checks**.
- Watch: `instr`, `imm_sel`, `imm`. A negative immediate remains negative
  after extension to 32 bits.

### 4. Decoder

- Set: **`sim_decode`**. Top: **`tb_decode`**.
- Files: `rtl/cpu/decode.v` and `tb/cpu/tb_decode.v`; it also connects the ALU
  and immediate generator. `rtl/cpu/cpu_defs.vh` contains shared encodings.
- Expected: **7,717 decode checks**, all **37 instructions**, and **15**
  combinational execution checks.
- Watch: `instr`, `rs1`, `rs2`, `rd`, `alu_op`, `reg_write`, `illegal`.

### 5. Instruction ROM and data RAM

- Set: **`sim_memories`**. Top: **`tb_memories`**.
- Files: `rtl/mem/instr_rom.v`, `rtl/mem/data_ram.v`, `tb/cpu/tb_memories.v`.
- Checks synchronous replies, byte writes, boundaries, errors, and reset.
- Expected: **24 checks**.
- Under `tb_memories/ram` watch `clk`, `rst`, `valid`, `ready`, `write`,
  `addr`, `wdata`, `wstrb`, `rdata`, and `error`.
- A transfer completes on a rising edge with valid and ready both high.

### 6. CPU pipeline

- Set: **`sim_cpu_core`**. Top: **`tb_cpu_core`**.
- Files: `rtl/cpu/cpu_core.v`, the four building blocks, `tb/cpu/tb_cpu_core.v`,
  and the files in `tb/programs/`.
- Checks instructions interacting: forwarding, stalls, branches/jumps,
  wrong-path cancellation, byte/halfword access, faults, and delayed MMIO.
- Expected: **76 cases and 1,287 retirements**.
- Under `tb_cpu_core/dut` watch `clk`, `rst`, `trace_valid`, `trace_pc`,
  `trace_instr`, `trace_rd_we`, `trace_rd`, `trace_wdata`, and `halted`.
- Some programs deliberately trigger faults; the bench checks that they
  happen correctly. A temporary `halted=1` during this regression is not
  by itself a test failure.

### 7. Complete CPU + ROM + RAM

- Set: **`sim_soc_minimal`**. Top: **`tb_soc_minimal`**.
- Files: `rtl/soc/soc_minimal.v`, CPU/memory blocks, `tb/cpu/tb_soc_minimal.v`.
- Program: `fw/src/cpu_smoke.S`; encoded image: `fw/cpu_smoke.hex`.
- Expected: **sum=55, load-use=56, one delayed MMIO write, 44 retirements**.
- Under `tb_soc_minimal/dut` watch the trace signals and `mmio_valid`,
  `mmio_ready`, `mmio_write`, `mmio_addr`, `mmio_wdata`.
- Look for address **`40000000`** and data **`00000038`** (56 decimal).
  The CPU holds the request stable while the response is delayed.

The program stores 55 at RAM address `0x1000`, reloads it, increments to 56,
stores that at `0x1004`, performs the MMIO write, and loops at PC `0x30`.
The current MMIO checker is a temporary test device, not AES.

### 8. ALU board wrapper

- Set: **`sim_alu_board`**. Top: **`tb_alu_selftest`**.
- Files: `rtl/board/alu_selftest.v`, `rtl/board/zedboard_alu_demo.v`,
  `tb/board/tb_alu_selftest.v`.
- Expected: **16 vectors**, result/zero fault injection, sticky failure,
  reset/rerun, board LEDs, and heartbeat.
- Select the board wrapper in Scopes and watch its `led[7:0]`.
  The bench deliberately injects errors into a separately tested checker.
  Use the final PASS result to judge the complete simulation.

### 9. CPU board wrapper

- Set: **`sim_cpu_board`**. Top: **`tb_cpu_board`**.
- Files: `rtl/board/cpu_smoke_monitor.v`, `rtl/board/zedboard_cpu_demo.v`,
  `tb/board/tb_cpu_board.v`.
- Expected: actual CPU/ROM/RAM execution, LED mapping, heartbeat,
  reset/restart, and **15 checker scenarios**.
- Under `tb_cpu_board/board` watch `led` and the CPU trace/MMIO signals.
  This bench also deliberately tests faults and restarts.

### 10. AES round operations

- Set: **`sim_aes_primitives`**. Top: **`tb_aes_primitives`**.
- Files: `rtl/crypto/` and `tb/crypto/tb_aes_primitives.v`.
- Expected: **1,810 checks** of the S-box, row/column operations, round
  keys, and ordinary/final rounds.
- Watch: `byte_in`, `byte_out`, `state_in`, `shifted`, `mixed`, `rounded`.

### 11. Complete standalone AES-128

- Set: **`sim_aes_core`**. Top: **`tb_aes128_core`**.
- Files: `rtl/crypto/`, `tb/crypto/tb_aes128_core.v`, the reference header,
  and both files in `tb/crypto/vectors/`.
- Expected: **17,433 checks, 556 completed blocks**, including 284 NIST
  cases and 256 random cases. Latency: **11 clock periods**.
- Watch: `clk`, `rst`, `start`, `key`, `plaintext`, `busy`, `done`,
  `ciphertext`; under `dut`, `round_index`, `state`, `round_key`.
- The [AES guide](docs/aes_core.md) walks through the first block and
  explains each file, control test, and synthesis result.

The standalone AES tests remain independent. The original CPU smoke test
still uses its signature checker; `soc_aes` connects the real AES registers.

### 12. AES registers and bus rules

- Set: **`sim_aes_mmio`**. Top: **`tb_aes_mmio`**.
- Expected: **`PASS tb_aes_mmio`** after normal/delayed-response tests,
  284 NIST blocks per mode, strobes, invalid accesses, busy writes, and reset.
- Watch under `normal_bus`: `valid`, `ready`, `write`, `addr`, `wdata`,
  `rdata`, `error`, `busy`, and `done`.

### 13. CPU encrypts through MMIO

- Set: **`sim_soc_aes`**. Top: **`tb_soc_aes`**.
- Expected: **`PASS tb_soc_aes`**, 32 checked healthy blocks across normal
  and delayed bus modes, plus firmware/error/reset tests.
- Watch the MMIO and trace signals under `normal_bus/dut`.
- ROM: `fw/aes_smoke.hex`. See [the CPU/AES guide](docs/cpu_aes_integration.md).

### 14. CPU/AES board wrapper

- Set: **`sim_aes_board`**. Top: **`tb_aes_board`**.
- Expected: **`PASS tb_aes_board`**, four actual CPU-driven blocks,
  reset/restart, LED/heartbeat checks, and 13 monitor scenarios.
- Watch `board/led`, `board/ab`, `board/ad`, and `board/monitor`.
- The bench deliberately injects faults after checking healthy operation.

## Save evidence in Vivado

For each test, capture the PASS message and one useful waveform event.
Use **Save Waveform Configuration** to save your chosen signals as a
`.wcfg` file; that stores the viewing layout. The generated `.wdb` stores
the recorded signal changes.

Vivado saves each set's simulation output under:

```text
vivado/riscv_soc_lab/riscv_soc_lab.sim/<simulation-set>/behav/xsim/
```

The result log is `simulate.log`. These are GUI-project output locations;
they differ from the older standalone-script `build/cpu_tests/` paths.
Fill in `docs/lab_record_template.md` after observing each result.

If you edit RTL or a testbench, save it and **Relaunch Simulation** so
Vivado recompiles. Restart alone resets the already-compiled model.
If you add waveform signals late, click Restart and Run All again to
inspect from time zero.

## Program the ZedBoard through Vivado

The uploaded board manuals and sample constraints are saved under
`docs/references/zedboard/`. Read [the I/O plan](docs/board_io_plan.md)
before adding physical peripherals. Our current clock/LED assignments
match the supplied sample and E.1 schematic; keep the existing active
demo XDC. Do not add the reference `constr.xdc` or the commented template
to the active project.

The GUI pack includes the existing verified ALU and CPU bitstreams.
You can program them without running synthesis again.

1. Use the lab's documented power, JTAG-boot jumper setup, and USB-JTAG
   data connection. See `docs/zedboard_alu_demo.md` for hardware details.
2. Click **Open Hardware Manager > Open Target > Auto Connect**.
3. Select the XC7Z020 device and choose **Program Device**.
4. First select `build/zedboard_alu_demo/zedboard_alu_demo.bit`.
5. Leave the debug-probes file empty. Click **Program**.
6. Expect **LD0 blinking, LD1 ON, and LD2 through LD7 OFF**.
7. Repeat with `build/zedboard_cpu_demo/zedboard_cpu_demo.bit` and expect
   the same LED pattern.
8. Reprogram the CPU image once to check restart. Record each image name
   and a short video.

LD0 is only the heartbeat; LD1 is the application PASS indication. The
configuration DONE light is separate. Physical board results remain
pending until observed in the lab.

## If you want to rebuild CPU-plus-AES in the GUI

The project uses `zedboard_aes_demo` as its design top,
`zedboard_aes_demo.xdc` as active constraints, and `aes_smoke.hex` as its ROM.

1. Confirm the tests pass.
2. Click **Run Synthesis**, then **Run Implementation**.
3. Open the implemented design. Use **Reports > Timing > Report Timing
   Summary** and **Reports > Report DRC**.
4. Check that setup and hold slack are nonnegative and no DRC errors remain.
   The saved builds retain the documented `ZPS7-1` warning because PS7 is
   absent; investigate new warnings.
5. Click **Generate Bitstream**.
6. The project-mode CPU/AES image is
   `vivado/riscv_soc_lab/riscv_soc_lab.runs/impl_1/zedboard_aes_demo.bit`.
   Program that new image if you intend to test your source changes.

Supplied images in `build/` remain their earlier verified artifacts;
GUI builds do not replace them. Judge a rebuild by its own timing/DRC
reports, not another design's saved results.

## Common problems

- **No PASS and time is still 0 ns:** click Run All.
- **Simulation stopped at 1,000 ns:** the default duration was used.
  Run All to reach the bench's automatic finish.
- **Wrong test appears:** close the simulation and change the Simulation
  set in Simulation Settings, not the design/synthesis top.
- **Red/missing source files:** extract the whole project and retain its
  folder structure. Do not copy the `.xpr` alone.
- **Missing ROM/test data:** use this GUI pack's project and updated
  testbenches. Its data-file registration and `VIVADO_GUI` simulation define are
  required; do not combine them with the previous ZIP's older benches.
- **SystemVerilog syntax error:** the prepared project marks the benches as
  SystemVerilog even though their filenames end in `.v`. If adding one
  manually, check its File Properties.
- **All X values before reset:** look after the reset clock edges. For
  this register file reset is synchronous.
- **FAIL in output:** save the first mismatch and log before changing files.

## Verification of this GUI pack

On 24 October, both new AES sets passed in Vivado 2025.2 project mode, and
the existing CPU board test passed again. Results, source hashes, and wave
databases are in `evidence/aes_m1_2026-10-24/`. These runs use the saved
simulation sets supplied in the GUI project. AES standalone synthesis is
an early estimate; the existing board bitstreams do not contain AES.
The AES sets and CPU board test also passed from a freshly extracted copy
in another folder, with all source files resolving inside that copy and
without a project-repair step. See `relocated_gui_summary.txt` in the
same evidence folder. The October 24 ZIP includes these results.

On 22 October 2026, all nine simulation sets passed in Vivado 2025.2 project
mode after copying the project and sources to a different folder. The
memory, CPU, and complete-system benches also passed with their original
standalone defaults. Saved results are in `evidence/gui_simulations_2026-10-22/`.
No hardware RTL changed for the GUI setup; the supplied bitstreams and
their earlier routed reports remain the same files. Physical checks remain
pending.

## Optional: create only the ALU project manually

To learn Vivado's setup process from scratch:

1. Create Project > RTL Project; choose part `xc7z020clg484-1`.
2. Add **Design Sources**: `rtl/cpu/alu.v` and `rtl/cpu/cpu_defs.vh`.
3. Add **Simulation Sources**: `tb/cpu/tb_alu.v`.
4. Set that testbench's File Type to **SystemVerilog** in File Properties.
5. Under Simulation Sources, right-click `tb_alu` > **Set as Top**.
6. Run Behavioral Simulation > Run All, then inspect the PASS line.

No board constraints are needed for this standalone behavioral simulation.
For the CPU/memory tests, use the prepared project so that data files and
the simulation define are registered correctly.
[AMD's Add Simulation Sources instructions](https://docs.amd.com/r/2025.2-English/ug900-vivado-logic-simulation/Adding-or-Creating-Simulation-Source-Files)
explain the separate simulation-source category.
