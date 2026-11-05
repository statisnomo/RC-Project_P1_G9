# Software AES versus hardware AES — development increment

The custom RV32I CPU now runs a complete C implementation of AES-128 and
compares its result with the existing MMIO accelerator. Both paths are
executed by the same CPU and checked against independent expected answers.
This increment is simulation-verified. It is not in the current display
bitstream and is not a new physical benchmark result.

## What was measured

At AES wait setting 1, software takes **24,576 cycles** and the hardware path
takes **213 cycles**, a ratio of **115.38x**. At wait setting 5, the counts are
24,576 and 234, a ratio of 105.03x. All 413 vectors in each configuration had
these counts. These are complete firmware-function measurements between two
counter snapshots, not a comparison of software with the bare 11-cycle core.

The software path includes input/key reads, all rounds and per-block key
expansion, and result stores to RAM. Hardware includes input/key RAM reads,
all eight input-register writes, START, status polling, ciphertext reads and
result stores. Both include function call/return and timer-read overhead.
Startup/S-box initialization, comparing results, keypad input, display and
UART are outside the measured interval. No round keys are precomputed.

The baseline is compact, byte-oriented C compiled with GCC 13.4.0 `-Os`.
It is not the fastest possible RV32I AES, not a constant-time software
library and not a general speedup claim for every application. An optimized
software baseline or repeated blocks with reused expanded keys is a different
experiment. Reference algorithm: [NIST FIPS 197](https://csrc.nist.gov/pubs/fips/197/final).

## Files and interfaces

- `fw/src/aes_software.c`: standalone software encryption; no hardware calls.
- `fw/src/benchmark.c`: measures both paths and compares results.
- `fw/build_benchmark.py`: GNU compilation, S-box startup generation,
  instruction audit, ready-to-use `benchmark.hex` and compiler/source manifest.
- `fw/linker/benchmark.ld`: Harvard code/data separation; rejects initialized
  C data or unexpected BSS. S-box initialization uses instructions because
  instruction ROM is not data-readable.
- `rtl/peripherals/benchmark_timer.v`: free-running 32-bit cycle counter,
  word read at **0x40000380**, snapshot on request capture, reset to zero.
  This address is reserved only in `soc_benchmark`; the display SoC's UART
  interface is unchanged. Writes, byte accesses and other addresses error.
- `rtl/soc/soc_benchmark.v`: real CPU/ROM/RAM/AES plus timer; separate from
  `soc_display`. It has no keypad/OLED interface yet.

RAM contains key at 0x1000, input at 0x1010, software result at 0x1020,
hardware result at 0x1030, status at 0x1040, command at 0x1044, match at
0x1048, software cycles at 0x104c and hardware cycles at 0x1050. Status is
1=initial ready, 0=working, 2=completed, 3=hardware status timeout. Command
1 requests one block; firmware clears it before publishing completion.
The simulation host writes inputs only while the CPU is waiting for a command.

S-box occupies 0x1100–0x11ff. Stack grows down from 0x2000; compiler stack
reports show 48 bytes for main plus 64 bytes for software AES, 112 total.
The ROM uses **2,060 / 4,096 bytes**. No multiplication/division, CSR,
compressed, floating-point or crypto instructions appear in the audited code.
Counter differences use unsigned arithmetic, including modulo wrap.

## Vivado GUI tests 28–30

Keep the working lab project intact. Create a separate RTL project for
`xc7z020clg484-1`. These are behavioral tests; no XDC or bitstream is needed.

1. Add all Verilog from `rtl/cpu`, `rtl/mem` and `rtl/crypto`, plus
   `rtl/cpu/cpu_defs.vh`, `rtl/soc/soc_minimal.v`,
   `rtl/soc/soc_benchmark.v`, and `rtl/peripherals/benchmark_timer.v`.
2. Add `fw/benchmark.hex` as a Memory Initialization File. Set design top
   `soc_benchmark`. Ensure `rtl/cpu` is in the Verilog include path.
3. Add the three `.sv` testbenches below as simulation sources, plus
   `tb/internal/benchmark_vectors.mem` as a Memory Initialization File.
4. Select each simulation top in turn, **Run Behavioral Simulation → Run All**.
   The longer benchmark reaches about 103 ms of simulated time; do not stop
   at Vivado's default 1 us. Close the simulation before changing top.

- **28 / `tb_benchmark_timer`**: request snapshots, invalid accesses,
  held requests, cancellation, reset and wrap.
- **29 / `tb_aes_benchmark`**: 284 published NIST vectors plus one FIPS baseline
  and 128 one-bit changes, each at waits 1/5. Both outputs must match the
  reference, and CPU timer differences must match an independent clock count.
  Also aborts software encryption with reset and checks a fresh successful run.
- **30 / `tb_benchmark_recovery`**: hides hardware DONE to exercise the bounded
  polling timeout, then retries; resets during AES and checks recovery;
  checks software measurement across counter wrap.

Each prints `PASS` followed by its top name. For test 29, also save both
`BENCHMARK_CASE_PASS` lines. A test failure invalidates that run's metrics.
The setup helper `scripts/verify_benchmark.tcl` is optional for maintainers;
the GUI procedure above does not require terminal use.

## Evidence and next step

`evidence/benchmark_2026-11-05/` contains all three logs, generated results,
source hashes and firmware manifest. The vectors combine the existing
published NIST data with independent .NET AES ciphertexts; they are not
calculated from the RTL under test.

For the selected key and baseline, 128 one-bit changes produced 47–79 changed
ciphertext bits, mean 63.265625. This is an observed diffusion demonstration,
not a requirement that every input change must change exactly half the bits.

The next engineering step is an OLED text/status view and firmware that takes
the keypad input through both paths, shows MATCH, software/hardware cycles,
and optionally a single-bit-change comparison. It needs integration tests,
routed timing and physical acceptance before replacing a working demo image.
