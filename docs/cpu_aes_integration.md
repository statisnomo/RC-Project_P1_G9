# The CPU now controls AES

Integration work: **26-27 October 2026**. The CPU runs a real instruction
program that writes AES registers, starts encryption, polls for completion,
and copies the returned ciphertext into RAM. It checks four blocks using
three keys, including a repeated block without rewriting its key.

## New files in plain language

- `rtl/crypto/aes_mmio.v`: the register interface between CPU loads/stores
  and the existing encryption core. It implements the approved AES window.
- `rtl/soc/soc_aes.v`: connects that interface to the CPU/ROM/RAM system.
  Unimplemented keypad, OLED, and UART windows currently return an error.
- `fw/src/aes_smoke.S`: the readable assembly program.
- `fw/aes_smoke.hex`: the same program ready for Vivado's instruction ROM.
- `fw/aes_smoke.lst`: every instruction's address, machine word, and assembly.
- `fw/build_aes_smoke.py`: generates those files together. It emits supported
  instruction encodings and copies known expected ciphertexts; it does not
  compute AES. You do not need Python or a RISC-V compiler in the lab.
- `fw/aes_smoke_manifest.json`: program size, labels, cases, and RAM layout.
- `rtl/board/aes_smoke_monitor.v`: independently compares all 16 returned
  words and the operation count before permitting the board PASS indication.
- `rtl/board/zedboard_aes_demo.v`: clock/startup reset, heartbeat, integrated
  system, checker, and LED assignments. It uses no external peripheral pins.

The [register contract](aes_mmio.md) defines byte strobes, errors, ordering,
and START/DONE rules. The [standalone core](aes_core.md) remains unchanged.

## Three new small tests in Vivado

Open the project, close the current simulation, choose the set in
**Simulation Settings**, then **Run Behavioral Simulation > Run All**.

1. **`sim_aes_mmio` / `tb_aes_mmio`:** checks the CPU-facing registers
   without the CPU. Expected prefix: `PASS tb_aes_mmio`. Both one-wait-edge
   and three-wait-edge modes encrypt all 284 NIST cases. It also tests all
   byte strobe combinations, invalid requests, busy writes, continuous VALID,
   and reset/cancellation. The two modes passed 26,632 and 48,264 checks.
2. **`sim_soc_aes` / `tb_soc_aes`:** runs the actual CPU and firmware.
   Expected prefix: `PASS tb_soc_aes`. One/five wait-edge modes check 32
   healthy blocks in total, reset during encryption, repeated runs, injected
   ciphertext mismatch, firmware poll timeout, and absent-peripheral faults.
3. **`sim_aes_board` / `tb_aes_board`:** checks the real board wrapper plus
   deliberately faulty checker inputs. Expected prefix: `PASS tb_aes_board`;
   **13 monitor scenarios**, LED/heartbeat checks, and reset/restart.

Deliberate fault injection is part of these tests. Judge the final PASS,
not a temporary error signal during an intentionally failing scenario.

Useful signals for the CPU test: under `normal_bus/dut`, add `mmio_valid`,
`mmio_ready`, `mmio_write`, `mmio_addr`, `mmio_wdata`, `mmio_rdata`,
`aes_busy`, `aes_done`, and the trace signals. Hexadecimal radix makes the
addresses readable. Find a completed write of 1 to `40000000`, followed
by reads at `40000004` and `40000030` through `4000003c`.

## Program memory and results

The final program uses **880 of 4,096 ROM bytes**, with a 1,024-word padded
ROM file. It uses **68 RAM bytes** at `0x1000-0x1043`: four ciphertext
blocks followed by a status word. Startup sets x2 to the aligned stack top
`0x2000`; this leaf program uses no stack bytes. Constants are loaded by
instructions because data loads cannot read our Harvard instruction ROM.

Status at `0x1040` and in x31: 0 running, 1 pass, 2 mismatch, 3 poll timeout.
The program writes the RAM status before publishing the nonzero x31 flag.
Successful execution remains in a loop. No unsupported halt instruction
is needed. The poll count is bounded at 100 status reads.

`fw/linker/aes_smoke.ld` documents a compatible future assembler/linker
layout. The delivered ROM is generated directly; a GNU toolchain link and
C startup runtime have not been tested. The layout rejects initialized
data until a Harvard-memory loader is implemented.

## Measurements and their limits

For one wait edge, the interval from the first completed operand write to
the last ciphertext read is **150 clocks with key loading**, or **114 clocks
when reusing the key**. START completion to the last ciphertext read is
**81 clocks**. With five wait edges those values are 192, 144, and 99 clocks.
These are simulation measurements of this checking program, which also
compares and stores words between reads. They are not software-AES speedups.
The AES calculation itself still takes **11 clocks**.

The wrapper now captures request fields during its existing wait cycle.
This removes the long CPU-address-to-AES-readback path without adding a
bus wait edge. BUSY is still evaluated at completion, so a command during
encryption is rejected according to the documented contract.

Logs are saved under `evidence/aes_m2_2026-10-27/`. A board build must pass
its own routed timing and DRC before programming; simulation alone does
not establish 100 MHz operation. Physical board tests remain pending.
