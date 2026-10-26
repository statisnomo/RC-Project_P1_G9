# CPU subset and decode interface

Subset decision: October 10, 2026. Decode and immediate generation were the
first milestone. As of October 16, the [three-stage CPU](cpu_pipeline.md)
executes this subset in simulation; the interfaces below remain unchanged.

## Supported subset

The first CPU targets these 37 RV32I instructions:

- Register arithmetic: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND.
- Immediate arithmetic: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI.
- Upper immediate: LUI, AUIPC.
- Jumps: JAL, JALR.
- Branches: BEQ, BNE, BLT, BGE, BLTU, BGEU.
- Loads: LB, LH, LW, LBU, LHU.
- Stores: SB, SH, SW.

FENCE/FENCE.I, ECALL/EBREAK, CSRs, compressed instructions, multiply/divide,
atomics, floating point, and custom instructions are unsupported in this
milestone. This is an educational RV32I subset, not a claim of full RV32I
compliance. Audit generated firmware for unsupported instructions before
running it; `-march=rv32i` alone does not enforce this smaller subset.

Architectural reference: [RISC-V RV32I specification, version 2.1](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html)
and [official instruction encodings](https://github.com/riscv/riscv-opcodes/tree/master/extensions).
Project-specific controls below are our own interface decisions.

## Combinational module interfaces

`decode` accepts `instr[31:0]` and produces:

- Raw register fields: `rs1[4:0]`, `rs2[4:0]`, `rd[4:0]`.
- Operand-use flags: `rs1_used`, `rs2_used`.
- `alu_op[3:0]`, using the existing ALU encodings.
- `alu_a_sel[1:0]`: 0 = rs1 data, 1 = instruction PC, 2 = zero.
- `alu_b_imm`: 0 = rs2 data, 1 = generated immediate.
- `imm_sel[2:0]`: 0 = none, 1 = I, 2 = S, 3 = B, 4 = U, 5 = J.
- `reg_write` and `wb_sel[1:0]`: 0 = ALU result, 1 = load result,
  2 = instruction PC + 4.
- `mem_read`, `mem_write`, `mem_size[1:0]`: 0 = byte, 1 = halfword,
  2 = word, and `mem_unsigned` for LBU/LHU.
- `branch_op[2:0]`: 0 = none, 1 = EQ, 2 = NE, 3 = LT, 4 = GE,
  5 = LTU, 6 = GEU.
- `jump`: either jump instruction; `jalr`: select indirect jump handling.
- `illegal`: encoding is unsupported by this subset.

`imm_gen` accepts `instr[31:0]` and `imm_sel[2:0]` and emits `imm[31:0]`.
None and reserved selectors produce zero. All immediate formats are
reconstructed at byte scale. The I-format output for SRAI retains the
encoding's upper immediate bits; the ALU consumes only the low five shift
bits. SLTIU still receives a sign-extended immediate.

Internal constants live in `rtl/cpu/cpu_defs.vh`. Include that directory
when compiling the RTL. No clocks or reset ports are required for either
combinational module.

## Control contract

For R-type operations, both source-use flags are set. For I-type arithmetic
and loads only rs1 is used. Stores and branches use both sources. LUI,
AUIPC, and JAL do not use register sources; JALR uses rs1. The flags indicate
operand roles even for x0. Hazard logic must separately ignore dependencies
on x0.

LUI selects zero plus the U immediate. AUIPC selects instruction PC plus
the U immediate. Loads/stores select rs1 plus the I/S immediate; store data
comes from rs2 independently of ALU operand B. Loads select memory writeback.
Other arithmetic selects ALU writeback. `reg_write` describes the instruction
even for rd=x0; the register file discards that write. A load with rd=x0 must
still perform its memory access.

Branches select register comparisons: SUB for EQ/NE, SLT for LT/GE, and
SLTU for LTU/GEU. Their target needs a separate PC+immediate calculation
in the execution stage. JAL uses PC+J immediate; JALR uses rs1+I
immediate and requires clearing target bit zero. Both select PC+4 writeback.

Full funct7 validation is required for R-type arithmetic and shift-immediate
instructions. Immediate bits of other I-type instructions are data and must
not be constrained as funct7. JALR requires funct3=000. Reserved load/store
and branch funct3 values are rejected.

An illegal encoding has `illegal=1`; all effect/use flags, branch/jump
controls, immediate selector, ALU operation, operand selectors, and writeback
selector return to their default zero values. `mem_size` defaults to WORD
(2), and raw register fields remain extracted for diagnostics. All outputs
are assigned for every path; unsupported encodings cannot request writes.

## Pipeline policy

Plan for reset PC=0, little-endian memory, four-byte instruction alignment,
and natural alignment for halfword/word data accesses. Detect address faults
in execution, not decode. On an unsupported instruction or address fault,
the first CPU should latch a debug fault and stop without committing that
instruction. A privileged trap handler and CSR bank remain outside scope.
This stop behavior is now implemented in `cpu_core.v`; the combinational
decoder only reports illegal encodings.

The pipeline carries instruction PC, controls, register data, and immediate
together and gates effects with stage validity. Its forwarding, stalls,
flushes, synchronous memory timing, and exactly-once MMIO contract are defined
in [cpu_pipeline.md](cpu_pipeline.md). The original decode tests below remain
block tests; the new integration suite verifies execution separately.

## Verified baseline — October 10, 2026

Vivado Simulator 2025.2 compiled the four production modules in Verilog mode
and the testbenches in SystemVerilog mode. `tb/run_cpu_tests.ps1` completed
successfully with exit code zero:

- ALU: 4,142 checks passed.
- Register file: 2,456 port checks passed.
- Decoder: 7,717 decode checks passed, covering all 37 instruction rules,
  plus 15 combinational execution checks.
- Immediate generator: 14,546 checks passed.

The decoder oracle uses literal instruction masks and numeric control
expectations independently of `cpu_defs.vh`. Coverage includes all R-type
and OP-IMM funct7/funct3 combinations, malformed encodings, unsupported
major opcodes, raw register fields, source-use flags, and rd=x0 behavior.
Immediate tests exhaust all I/S/B offsets and add J/U boundaries and fixed-seed
random vectors. Fifteen checks connect decode, immediate generation, and ALU
to testbench operand/target/writeback logic.

These are functional block simulations. They do not validate actual pipeline
execution, memory transactions, load-data extension, fault handling, FPGA
resource use, or timing closure. Logs are local generated output in
`build/cpu_tests/tb_decode.log` and `build/cpu_tests/tb_imm_gen.log`, alongside
the ALU/register-file logs.
