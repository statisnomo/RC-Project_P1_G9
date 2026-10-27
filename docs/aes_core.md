# AES on its own: what we built and how to test it

**Milestone M1 — verified 24 October 2026, Vivado 2025.2.**

The AES core takes a 16-byte plaintext and a 16-byte key. It produces a
16-byte ciphertext. For now, a testbench supplies the inputs. The CPU will
control these same inputs through registers in the next milestone.

## What each file does

All six hardware files are in `rtl/crypto/`:

- **`aes_sbox.v`** changes one byte using AES's fixed substitution table.
- **`aes_shift_rows.v`** rearranges the 16 bytes by rotating the state rows.
- **`aes_mix_columns.v`** mixes the four bytes in each column using AES arithmetic.
- **`aes_key_expand.v`** calculates the next round's key from the current key.
- **`aes_round.v`** joins substitution, row shifting, column mixing, and key
  addition. It skips column mixing in the final round, as AES requires.
- **`aes128_core.v`** stores the current block/key and controls the sequence.
  It reuses the round circuit ten times instead of building ten copies.

The three main verification files are in `tb/crypto/`:

- **`tb_aes_primitives.v`** checks the individual operations before integration.
- **`tb_aes128_core.v`** checks complete encryption and the control signals.
- **`aes_reference.vh`** is a simulation-only mathematical model. It computes
  the S-box from finite-field arithmetic instead of copying the hardware's
  lookup table. Its full-block answers are also checked against NIST.

`vectors/aes128_kat.mem` contains the published expected answers, and
`vectors/aes128_vector_count.vh` gives their count. Keep both in the project.
The [reference folder](references/aes/README.md) preserves the original
archive and explains the optional offline conversion script.

## Run the two tests with Vivado buttons

No board is needed for these tests. Open the whole saved project:
`vivado/riscv_soc_lab/riscv_soc_lab.xpr`.

1. Close any running simulation with **File > Close Simulation**.
2. In Flow Navigator, right-click **Simulation > Simulation Settings**.
3. Select simulation set **`sim_aes_primitives`**. Its top must read
   **`tb_aes_primitives`**. Click **OK**.
4. Select **Run Simulation > Run Behavioral Simulation**, then **Run All**.
5. Find **`PASS tb_aes_primitives: 1810 checks`** in the Tcl Console pane.
   You only read the output there; no command needs to be typed.
6. Close that simulation. Select **`sim_aes_core`**, top **`tb_aes128_core`**.
7. Run Behavioral Simulation, then Run All. Expect:

```text
PASS tb_aes128_core: 17433 checks, 556 completed blocks; 284 NIST, 256 random, 11 reset-abort points; latency=11 clocks, earliest restart=12 clocks
```

A `$finish` message after PASS is normal. Compilation success or a moving
waveform alone does not mean the test passed. Save the first FAIL if one appears.
The core test finishes at **85,576 ns** of simulated time.

## Understand one encryption in the waveform

Select `tb_aes128_core` in **Scopes**. Add `clk`, `rst`, `start`, `key`,
`plaintext`, `busy`, `done`, and `ciphertext` from **Objects** to the wave
window. Under `dut`, also add `round_index`, `state`, and `round_key`.
Choose hexadecimal radix for the wide buses.

Zoom to **0–170 ns**. The first block is deliberately easy to recognize:

```text
Key:        000102030405060708090a0b0c0d0e0f
Plaintext:  00112233445566778899aabbccddeeff
Ciphertext: 69c4e0d86a7b0430d8cdb78070b4c55a
```

At the rising edge at **25 ns**, START is accepted: BUSY rises and the
operands are captured. At **35 ns**, the original key is XORed into the
plaintext. The next ten rising edges perform rounds 1–10. At **135 ns**,
BUSY falls, DONE rises, and the expected ciphertext appears. This is
**11 clock periods**, or 110 ns with the testbench's 10 ns clock.

The test intentionally changes the input pins and pulses START while busy.
The captured block must still finish correctly. Later it deliberately
resets during encryption. These activities are tests, not accidental glitches.
DONE and the result stay available until reset or a new accepted START.
An immediately following block can be accepted at the next edge, E12.

See [aes_interface.md](aes_interface.md) for the exact edge and byte-order
contract. Core latency excludes CPU register writes, polling, and reads.

## What has actually passed

- Primitives: **1,810 checks**, including all 256 S-box values, basis-bit
  tests, ten published round keys, and varied normal/final rounds.
- Core: **17,433 checks over 556 completed blocks**: 284 NIST cases,
  256 deterministic random cases, three familiar examples, eleven
  post-reset recovery blocks, and two held-START/restart blocks.
- Reset cancellation at **11 different points**, including the edge that
  would otherwise publish the result; START and reset asserted together.
- Captured operands, ignored busy requests, sticky DONE/output, output
  clearing on acceptance, and exact latency checked throughout.
- Existing CPU board simulation rerun: **15 checker scenarios passed**.

Saved logs and wave databases are in
`evidence/aes_m1_2026-10-24/`. That folder's source hashes identify the tested
files. Vivado also generates fresh logs/waves under each simulation set's
`behav/xsim` directory when you run the tests yourself.

## Early FPGA estimate

Standalone out-of-context synthesis for **xc7z020clg484-1** used **1,314 LUTs,
390 flip-flops, zero BRAM, and zero DSPs**. No latches were inferred.
With a 10 ns clock constraint, the estimated worst register-to-register
setup slack was **+4.976 ns**.

Reports are in `build/aes_synthesis/`: `utilization.rpt`, `timing_synth.rpt`,
`register_paths.rpt`, and `summary.txt`. The synthesized checkpoint is
`aes128_core_synth.dcp`; Vivado can open it for schematic inspection.

This is an early synthesized estimate, before placement and routing.
The standalone run intentionally has no external I/O delays or assigned
clock-buffer location; Vivado reports `Timing 38-242` because clock skew
cannot yet be estimated. Timing closure must be checked after integration.
The 110 ns figure above is simulated timing, not a board measurement.

## Later integration update — October 27

M2 has added the register wrapper at **`0x40000000`** and a CPU program that
writes the key/plaintext, starts encryption, polls DONE with a timeout, and
reads the ciphertext into RAM. The [CPU/AES guide](cpu_aes_integration.md)
explains three new simulations and their results. Follow the
[October 27 lab procedure](lab_2026-10-27.md) for the current pack.

The current ALU and CPU `.bit` files still test their original designs.
The separate [CPU/AES board record](zedboard_aes_demo.md) covers its build.
Keypad, OLED, and UART remain later milestones. Physical board observations
are still pending.
