# CPU block contract

Both RTL files use synthesizable Verilog-2005. Their port names, widths,
and directions match the approved module shells.
The decoder and immediate generator are documented in [cpu_isa.md](cpu_isa.md).
ALU encodings are now shared with the decoder through `rtl/cpu/cpu_defs.vh`;
the test runner supplies that include directory.

## ALU

The ALU is combinational. The following four-bit encodings are the contract
with the decoder; these are internal controls, not instruction opcodes.

- `4'h0` ADD: `operand_a + operand_b`.
- `4'h1` SUB: `operand_a - operand_b`.
- `4'h2` AND: bitwise AND.
- `4'h3` OR: bitwise OR.
- `4'h4` XOR: bitwise XOR.
- `4'h5` SLL: logical left shift.
- `4'h6` SRL: logical right shift, filling with zeros.
- `4'h7` SRA: arithmetic right shift, replicating `operand_a[31]`.
- `4'h8` SLT: signed two's-complement less-than, yielding 32-bit zero or one.
- `4'h9` SLTU: unsigned less-than, yielding 32-bit zero or one.
- `4'hA` through `4'hF`: reserved, yielding 32-bit zero.

ADD and SUB wrap modulo 2^32. No carry or overflow flag is exposed.
All shifts use only `operand_b[4:0]`; for example a shift operand of 32
means a shift by zero. Signedness is applied explicitly for SRA and SLT.
Every control value assigns the result, so no latch is needed.

`zero` is always derived from `result == 0`. SUB can therefore implement
the equality test used by BEQ/BNE. SLT and SLTU provide the comparison
result in bit zero for signed and unsigned relational branches. The
branch control must also check the decoded branch instruction: a zero
result alone never authorizes a branch. Reserved ALU operations also
assert `zero`; the decoder remains responsible for rejecting unsupported
instructions.

## Register file

There are 32 registers of 32 bits. Both read ports are combinational and
independent. Reads of x0 always return zero and writes to x0 are ignored.
Writes to x1 through x31 occur on the rising edge when `we` is high.

Reset is **active-high and synchronous**. A rising edge with `rst` high
clears all registers, even when `we` is also high. Assert reset across at
least one rising edge before relying on the values in x1 through x31.
Changing reset between edges does not immediately change stored values.
This is the reset convention to carry into future synchronous RTL; an
external board reset will need appropriate conditioning at the top level.

On a simultaneous read and write of the same nonzero address, the read
shows the old stored value before the rising edge and the new stored
value after the nonblocking write settles. There is no combinational
write-through path from `wdata`. The pipeline implements forwarding and
stalls explicitly, as described in [cpu_pipeline.md](cpu_pipeline.md).

The asynchronous read ports and full reset favor flip-flop storage rather
than synchronous block RAM. The separate 4 KB `data_ram.v` uses BRAM;
it is not this register file.

## Verification scope

Self-checking simulations exercise each ALU operation, 32-bit arithmetic
boundaries, signedness, shift masking, reserved operations, and the zero
flag. Register-file simulations check both read ports, all addresses, x0
protection, write-enable gating, clocked write visibility, synchronous reset,
and reset priority. Randomized vectors supplement directed edge cases.

Passing these simulations establishes block-level functional behavior.
It does not establish pipeline correctness, FPGA resource use, or timing
closure at the system's 100 MHz target.

## Verified baseline — October 2, 2026

Ran `tb/run_cpu_tests.ps1` using Vivado Simulator 2025.2 on Windows.
Production RTL compiled in Verilog mode; testbenches compiled in
SystemVerilog mode to support `$fatal`.

- `PASS tb_alu: 4142 checks` — directed edges plus 4,096 deterministic
  randomized operation/vector checks.
- `PASS tb_regfile: 2456 port checks` — directed sequences plus 512
  deterministic randomized cycles and a final full-register scan.
- The runner completed successfully with exit code zero.

The ALU random model uses iterative one-bit shifts and explicit sign-bit
comparison to check the DUT's variable shifts and signed comparison.
The register-file model checks reads against an independent scoreboard
before and after writes. Local simulation logs are retained in the ignored
`build/cpu_tests/tb_alu.log` and `build/cpu_tests/tb_regfile.log` files.
