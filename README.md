# Custom RISC-V SoC with a Cryptographic Hardware Accelerator

A custom RISC-V CPU and AES-128 accelerator in the ZedBoard programmable
logic, with Pmod KYPD input, Pmod OLED output, and UART debugging.

Project started October 2, 2026. **Confirmed deadline: November 20, 2026.**
The full working demo is targeted for November 15, leaving time for fixes,
results, and rehearsal. Use the [timeline](docs/project_timeline.md),
[master checklist](docs/project_checklist.md), and
[progress log](docs/progress_log.md) to track each small verified step.

**Testing through Vivado's graphical interface?** Start with
[the October 27 lab walkthrough](docs/lab_2026-10-27.md), then
[VIVADO_START_HERE.md](VIVADO_START_HERE.md). Open
`vivado/riscv_soc_lab/riscv_soc_lab.xpr` and select one of its fourteen simulation sets.
[LAB_START_HERE.md](LAB_START_HERE.md) retains the optional script-based workflow.

**Need the programming files from GitHub?** Open [build/](build/README.md)
for the ALU, CPU, and CPU/AES `.bit` files and their verified reports. Use
**Code > Download ZIP** to obtain the project including these builds.

The [board reference library](docs/references/zedboard/README.md) preserves
the four files supplied on October 22. The [I/O plan](docs/board_io_plan.md)
records checked pins, voltage banks, the old manual's JA3 discrepancy,
and future keypad/OLED/UART connections. Current demo pin assignments agree
with the supplied sample XDC and E.1 schematic.

The [learning path](docs/learning_path.md) recommends selected lectures,
practical tutorials, and small exercises for understanding each part of this build.

## Current milestone

**October 27: the real CPU now encrypts through MMIO.** The
[CPU/AES guide](docs/cpu_aes_integration.md) explains the register wrapper,
four-block ROM program, integrated simulations, and LED checker. The
MMIO test passed all 284 NIST vectors with both normal and delayed replies;
CPU integration checked 32 blocks plus reset and error paths. Your personal
Vivado tests are P6-P10 in the [checklist](docs/project_checklist.md).

The October 27 lab pack includes the new CPU/AES board image with passing
routed **100 MHz timing (+0.311 ns setup / +0.159 ns hold)**. All 14 simulation
sets passed from a fresh ZIP extraction. Use the
[printable lab guide](output/pdf/lab-testing-guide-2026-10-27.pdf) and
[board build record](docs/zedboard_aes_demo.md). Physical observations remain pending.

The standalone **AES-128 core is now implemented and simulated**. On October 24,
its primitives passed 1,810 checks and its controller passed 17,433 checks over
556 completed blocks, including 284 published NIST cases and 256 random cases.
Completion takes 11 clock periods; reset cancellation and busy-start behavior
also passed. Read the [simple AES guide and GUI procedure](docs/aes_core.md)
and [interface contract](docs/aes_interface.md). The October 26 milestone
connects this core to the CPU through the approved MMIO registers.

The first three-stage CPU now executes the documented 37-instruction subset
in simulation, using the existing ALU, register file, decoder, and immediate
generator. `soc_minimal.v` connects it to 4 KB instruction ROM, 4 KB data RAM,
and an external MMIO port covering the four approved peripheral windows.
The [CPU milestone guide](docs/cpu_pipeline.md) explains each new file,
the bus rules, and how to run the first assembly program.

On October 20, 2026, the CPU integration tests passed again: 76 cases and 1,287
checked retirements, 24 memory checks, and a complete program that stores
55 in RAM and sends 56 to a delayed simulated peripheral exactly once.
The new [CPU board demonstration](docs/zedboard_cpu_demo.md) adds a result
checker, heartbeat/PASS/FAIL LEDs, simulation, constraints, and build scripts.
Its simulation passed the real CPU program and 15 checker scenarios.
The keypad, OLED, UART controllers, and full demonstration firmware remain to be built.
The [prior lab record](docs/lab_followup_2026-10-27.md) reports a programmed
bitstream and a blinking LED, but does not identify the image or PASS/FAIL
states. The CPU's physical functional result remains unconfirmed.

Dedicated branch comparisons and memory-address addition improved the
preliminary 100 MHz setup slack from **-3.098 ns to +0.940 ns**. Synthesis
confirms two block RAMs and no inferred latches. The complete CPU board build
also meets **100 MHz after routing**, with **+0.221 ns setup slack** and
**+0.151 ns hold slack**. Its ready-to-program image is
`build/zedboard_cpu_demo/zedboard_cpu_demo.bit`. The CPU board guide records
the retained PS7 warning, verification results, and physical lab checks.

All four block testbenches passed in Vivado Simulator 2025.2 on October 10,
2026. [Verification details](docs/cpu_isa.md#verified-baseline--october-10-2026)
include the coverage and limits of this result.

Read [the ALU/register-file contract](docs/cpu_blocks.md),
[the instruction subset and decode interface](docs/cpu_isa.md), and
[the approved architecture](docs/architecture.md) before pipeline integration.
The [Mohan et al. reference notes](docs/paper_notes_mohan_2025.md) record the
accessible IEEE findings and the planned end-to-end AES benchmark.

For an October 13 snapshot explaining each original lab file, read the
[beginner guide](docs/project_guide.docx) or its [plain-text version](docs/project_guide.md).
The first [ZedBoard ALU demonstration](docs/zedboard_alu_demo.md) adds an
automatic 16-vector checker, heartbeat and PASS/FAIL LEDs, pin constraints,
and simulation/build scripts. Its simulation and FPGA build passed in
Vivado 2025.2 on October 13, 2026; routed timing met 100 MHz and the `.bit`
file is in `build/zedboard_alu_demo/`. The lab guide records the retained
PS7 warning and full results. Physical board testing is still required.

## Repository layout

```text
riscv_soc_project/
  rtl/
    cpu/             Three-stage CPU and its four constituent blocks
    soc/             CPU, memories, and external MMIO port
    board/           ALU and CPU smoke checkers with ZedBoard LED wrappers
    mem/             Instruction ROM and data RAM
    crypto/          Verified AES datapath/control and MMIO registers
    peripherals/     Keypad, OLED, and UART
  tb/
    cpu/             Self-checking CPU block simulations
    board/           ALU and CPU board simulations with injected failures
    crypto/          AES primitive/core benches and published test vectors
    programs/        CPU test programs and independent expected results
  constraints/       Active demo pin/clock assignments; templates/ is reference only
  scripts/           Reproducible Vivado FPGA build
  fw/
    linker/          Linker scripts
    src/             First assembly program; C firmware comes later
    cpu_smoke.hex    Pre-encoded instruction ROM image
  docs/              Architecture, interfaces, verification notes, and I/O plan
    references/zedboard/  Original uploaded PDFs/XDC and their hash manifest
    references/aes/       Original NIST vectors, archive, and hash manifest
```

## Run the CPU tests

From the project directory in PowerShell, use the installed Vivado tools:

```powershell
.\tb\run_cpu_tests.ps1 -VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'
```

On another machine, adjust that path or omit `-VivadoBin` when the tools
are on `PATH` or `XILINX_VIVADO` is set. Generated output stays in
`build/cpu_tests/`. All four benches must print their `PASS` line; compilation,
elaboration, simulator, and self-check failures stop the script.

To learn one block at a time, add `-Test alu`, `-Test regfile`,
`-Test decode`, or `-Test imm_gen`. Add `-Waves` to record all signals in a
per-test `.wdb` file. The [testing guide](docs/testing_guide.md) walks through
the first ALU check, waveform viewing, and small tests for future lab visits.

## Run the integrated CPU

```powershell
.\tb\run_integration_tests.ps1 -VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'
```

For the shortest first exercise, add `-Test soc_minimal -Waves` and inspect
the program that sums 1 through 10. See the [milestone guide](docs/cpu_pipeline.md)
for the expected results and synthesis check. Keep `tb/programs/` and
`fw/cpu_smoke.hex` in your lab copy.

## Next integration step

Simulate the CPU board wrapper with `.\tb\run_cpu_board_tests.ps1 -Waves` and
build it with `.\scripts\build_zedboard_cpu.ps1`. Use the CPU lab guide for
timing results and the expected LED pattern before programming.

Observe the CPU result in the lab: LD0 should blink, LD1 should stay on, and
the other user LEDs should be off. CPU-to-AES MMIO integration now passes.
The next peripheral milestone builds UART, keypad, and OLED independently;
confirm exact module revisions and wiring before enabling their I/O pins.
The existing ALU board demonstration remains an independent first physical
lab check.
