# First working CPU: a simple guide

Milestone implemented on October 16, 2026.

We now have a CPU that runs a small program in simulation. Previously, each
CPU block was tested separately. This milestone connects those blocks,
gives the CPU instruction and data memory, and checks that instructions
work together in the correct order.

The October 20 follow-up adds a CPU board wrapper and result checker.
See [the CPU lab guide](zedboard_cpu_demo.md) for its build status and LED
checks. The separate ALU LED demonstration remains a useful first board test.

## What the first program does

Read `fw/src/cpu_smoke.S` alongside this explanation:

1. Start a counter at 10 and a sum at zero.
2. Add the counter to the sum, reduce the counter, and repeat until zero.
3. Store the answer, **55**, at RAM address `0x1000`.
4. Load that answer from RAM and add one.
5. Store **56** at RAM address `0x1004`.
6. Send 56 to a simulated peripheral at `0x40000000`.
7. Stay in a small loop so execution does not wander into empty ROM.

The peripheral in this test is testbench code. It deliberately waits five
cycles before replying. It is not an AES implementation, and the write is
not a definition of the future AES START operation.

`fw/cpu_smoke.hex` contains the matching machine instructions. The ROM reads
that file during initialization, so this exercise does not require a RISC-V
compiler. It contains 1,024 lines of eight hexadecimal digits: one 32-bit
instruction per line, starting at address zero. Unused words are zero.

## The three stages

**Fetch** asks the instruction ROM for the instruction at the current program
address. It holds that request until the ROM replies. It can have one request
in progress.

**Decode** identifies the instruction, reads the source registers, and builds
its immediate value. It passes the instruction's address, operands, and
controls together to the next stage.

**Execute / Memory / Writeback** performs the calculation. A load or store
waits here for the data-memory reply. A successful instruction then writes
its register result, if it has one. Branches and jumps select a new fetch
address and discard younger instructions from the old path.

These are three logical pipeline stages, with validity bits indicating
whether each stage contains useful work. This initial implementation is
conservative: a fetch reserves the decode slot before starting, and a waiting
memory access can stall decode. It does not claim one instruction per clock.

If one instruction needs a value produced by the instruction finishing on
the same edge, writeback forwards the new value directly to decode. A load
must complete before a dependent instruction advances. This also applies
to store data, branch operands, and indirect-jump addresses. Writes to x0
are ignored, but loads into x0 still perform their memory access.

## What each new file does

- `rtl/cpu/cpu_core.v`: the pipeline, stage control, forwarding, branches,
  jumps, load/store byte handling, fault reporting, and instruction trace.
- `rtl/mem/instr_rom.v`: 4 KB synchronous instruction ROM at `0x0000–0x0FFF`.
- `rtl/mem/data_ram.v`: 4 KB synchronous RAM at `0x1000–0x1FFF`, with separate
  write enables for the four bytes in a word.
- `rtl/soc/soc_minimal.v`: connects the CPU and memories and routes the four
  approved peripheral address windows to an external MMIO port.
- `fw/src/cpu_smoke.S`: the first program written in readable assembly.
- `fw/cpu_smoke.hex`: the same program already encoded for the ROM.
- `tb/cpu/tb_cpu_core.v`: compares CPU execution and bus transactions with
  independent expected results, including stalls, errors, and reset.
- `tb/cpu/tb_memories.v`: checks synchronous responses, byte writes, address
  boundaries, reset behavior, and consecutive memory requests.
- `tb/cpu/tb_soc_minimal.v`: runs the sum program through the actual CPU,
  instruction-ROM module, and RAM module, with a delayed MMIO test stub.
- `tb/programs/`: generated program images, expected instruction traces,
  expected bus transfers, final registers/RAM, and the test-case list.
- `tb/gen_cpu_programs.py`: regenerates those files using a small independent
  instruction interpreter. It also creates the smoke ROM image. It imports
  no RTL controls; its expectations come from instruction encodings.
- `tb/run_integration_tests.ps1`: runs the three new simulation testbenches.
- `scripts/check_cpu_synthesis.ps1` and `.tcl`: check that Vivado can synthesize
  the design, infer both block memories, and avoid unintended latches.

## Run this on your computer or in the lab

Open PowerShell in the project folder and run:

```powershell
.\tb\run_integration_tests.ps1 -VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'
```

Replace the Vivado path with the lab's installation path. All three benches
must print a line beginning with `PASS`. Compilation or verification errors
stop the script. Logs are saved in `build/cpu_integration/`.

For the easiest first check, run only the complete small program:

```powershell
.\tb\run_integration_tests.ps1 -Test soc_minimal -Waves
```

Add `-VivadoBin` there too if needed. The waveform file is
`build/cpu_integration/tb_soc_minimal.wdb`. In the waveform viewer, inspect
`trace_valid`, `trace_pc`, and `trace_wdata`, then the MMIO signals. Each
`trace_valid` pulse identifies one successfully completed instruction.
`trace_wdata` is a register result only when `trace_rd_we` is set.

Use `-Test cpu_core` for pipeline/error tests or `-Test memories` for the
memory modules. The original block tests remain available through
`tb/run_cpu_tests.ps1`.

For the synthesis check:

```powershell
.\scripts\check_cpu_synthesis.ps1 -VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'
```

This does not program the board or generate a CPU bitstream. Its reports and
checkpoint are in `build/cpu_synthesis/`. A synthesis timing estimate is not
proof of 100 MHz operation; that needs a constrained board build and routed
timing analysis.

Copy the whole source project for this milestone, including `fw/`,
`tb/programs/`, and the new scripts. The test vectors are already generated;
Python is only needed if you change the generator and regenerate them.

## The memory-bus rules

Both instruction and data buses use **completion handshaking**:

- The CPU asserts `valid` with a request and keeps the request unchanged.
- A transfer completes on a rising clock edge where `valid` and `ready`
  are both 1. There is no separate request-acceptance event.
- Read data and `error` are valid on that completion edge. `error=1` means
  the access failed. A failing write must not change peripheral or RAM state.
- A slave must apply write effects and read side effects exactly once, on
  completion. It may prepare its synchronous memory read beforehand.
- There is one outstanding request on each port. Instruction fetches and
  a data access may be in progress at the same time.
- Reset is active-high and synchronous throughout. It cancels requests;
  connected slaves must receive the same reset. It clears CPU registers and
  debug state, but does not erase RAM or reload ROM.

For data transfers, `addr` is the actual byte address. Read replies contain
the aligned 32-bit word containing that byte. The CPU selects the byte or
halfword and performs sign/zero extension. `size` is 0 for byte, 1 for
halfword, or 2 for word. Writes use lane-aligned `wdata` and `wstrb[3:0]`;
reads set `wstrb=0`. For example, a byte store to `0x1001` uses strobe `0010`
and puts its byte in `wdata[15:8]`.

The synchronous memories prepare a reply after the first request edge and
complete at the following edge. RAM writes happen on that completion edge.
RAM contents are unspecified until software writes them. The testbench
reference RAM starts at zero for reproducibility; this is not a CPU or FPGA
reset guarantee.

The minimal system routes `0x40000000–0x400003FF` to its MMIO port. AES,
keypad, OLED, and UART will eventually occupy their approved 256-byte windows.
Other data addresses return an access error. Instruction ROM is only on the
instruction port in this milestone; data loads from address zero do not read
ROM. A future C firmware layout must account for this Harvard organization.

The CPU waits indefinitely if a slave never responds. A bus timeout and
interrupts are not implemented in the core. The board demonstration has an
independent progress watchdog that reports failure without changing CPU behavior.

## Branches, faults, and debug outputs

A taken branch or jump flushes younger decoded work. An already-issued fetch
stays valid until its reply arrives, then its reply is discarded. This also
discards fetch errors from the wrong path. Fetch faults only stop execution
when the corresponding instruction reaches execute in order.

Instructions must be four-byte aligned. Halfword and word data accesses must
be naturally aligned. JALR clears target bit zero before checking alignment.
A not-taken branch does not fault merely because its encoded target would
be misaligned. These rules follow the
[RV32I instruction specification](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html).

On a fault, `halted` stays high until reset. The faulting instruction does
not write a destination register or retire. Younger instructions cannot
write registers or memory. Older completed instructions keep their effects.
This is a project debug-stop policy, not a privileged RISC-V trap handler.

`fault_pc` identifies the instruction that failed. `fault_code` means:

- 1: unsupported instruction; `fault_value` contains its instruction bits.
- 2: instruction-address alignment error; value contains the bad target.
- 3: instruction access error; value contains the inaccessible address.
- 4: misaligned load; value contains the data address.
- 5: misaligned store; value contains the data address.
- 6: load access error; value contains the data address.
- 7: store access error; value contains the data address.

The 37-instruction subset is unchanged. ECALL, EBREAK, FENCE, CSRs, compressed
instructions, and multiply/divide remain unsupported. Many verification
programs deliberately end with a zero instruction to check a precise stop;
the smoke program instead ends in a valid infinite jump loop.

## Verified results

Vivado Simulator 2025.2 passed on October 16, 2026:

- CPU: 25 programs in three response-timing modes, plus a reset/restart run:
  **76 cases and 1,287 checked instruction retirements**. All 37 supported
  instruction types execute. Every data-bus completion is compared with an
  independent expectation, and final registers and RAM are checked.
- Coverage observed: 11 load-forwarding events, 657 cycles with stalled
  decode, and 37 discarded delayed fetch replies. Tests include wrong-path
  fetch errors, all six branch conditions, load/store byte lanes, JAL/JALR,
  invalid instructions, address faults, MMIO read/write side effects, and
  reset cancellation of an outstanding store.
- Memories: **24 checks**, including individual byte lanes, first/last
  addresses, invalid accesses, reset cancellation, and consecutive requests.
- Complete system: sum 55, dependent result 56, exactly one delayed MMIO
  signature write, and 44 retired instructions including five final-loop
  iterations.

These are directed and fixed-seed tests, not formal verification or an
official RISC-V compliance suite. Physical CPU operation and full-SoC timing
are not yet established.

Vivado 2025.2 also synthesized `soc_minimal` for `xc7z020clg484-1`, with the
10 ns clock constraint applied before synthesis. The structural check passed:
one RAMB36E1 for instruction ROM, one for data RAM, and no inferred latches.
That October 16 synthesized smoke-program configuration used 1,301 LUTs and
913 flip-flops. These were synthesis counts for that version and ROM image,
not final routed SoC resources.

**The original October 16 preliminary timing check did not pass.** Worst setup slack was
**-3.098 ns**. This was an estimate
before placement/routing, and external interface timing is not yet constrained
as it would be in a board wrapper. `SYNTH_PASS` only confirms successful
mapping, BRAM inference, and absence of latches; it does not mean timing
passed. The synthesis warnings concern unused opcode
bits in the immediate generator and unused low address bits in the RAM;
there were no synthesis errors or critical warnings.

## October 20 timing and board follow-up

The core now uses dedicated register comparisons for branch decisions,
direct PC-relative and register-relative target additions, and a dedicated
effective address for loads/stores. The memory request enable checks memory
fault conditions independently of branch target alignment. Decode guarantees
that a memory instruction cannot also be a branch or jump.

This removes the general ALU operation mux and zero-detection path from
RAM request control. The standalone ALU and the decoder's control encodings
are unchanged. Instruction behavior, three-stage organization, forwarding,
and completion handshaking are also unchanged.

The complete CPU regression passed again: 76 cases, 1,287 checked retirements,
the same observed hazard coverage, 24 memory checks, and the sum program.
The updated `build/cpu_synthesis/timing_estimate.rpt` reports **+0.940 ns**
worst setup slack, two RAMB36 blocks, and no latches. Synthesis resource use
is now 1,382 LUTs and 913 flip-flops for the smoke-program configuration.

The complete CPU board build meets 100 MHz after routing: **+0.221 ns setup
slack**, **+0.151 ns hold slack**, and zero failing timing endpoints. It
retains both BRAMs and CPU execution logic, and generated the bitstream.
The [CPU board guide](zedboard_cpu_demo.md) records resource counts, the
retained PS7 warning, and the new board-checker simulation, which passed
15 checker scenarios. Its physical lab test remains pending.

## What comes after this

The CPU board build is ready to program; observe its PASS/FAIL result at the
next lab visit. Development can continue with the AES core and published
known-answer vectors, followed by its MMIO wrapper and CPU-driven encryption.
Keypad and OLED controllers can each be tested independently before the final
end-to-end demonstration.
