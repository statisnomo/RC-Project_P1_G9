# Understanding the RISC V project files

Beginner guide for the custom CPU and cryptographic SoC

13 October 2026

This guide explains the files you are taking to the lab, what each file does, and how to test one part at a time. Start with the four CPU blocks and their simulations. They are the building blocks of the processor we will assemble next.

## What we are building

The final system will read a message from a keypad. Our own RISC-V CPU will send a block of data to an AES encryption circuit. The encrypted result will appear on an OLED display. The design will run in the programmable logic of the ZedBoard.

The CPU pipeline, memories, AES accelerator, and peripheral controllers are still to be built. The current CPU files describe an ALU, a register file, an instruction decoder, and an immediate generator. Passing their tests does not yet mean that a complete CPU can run a program.

## Five words to know

- Module: one hardware block described in Verilog, with named input and output signals.
- RTL: the hardware description. The files inside rtl/ are candidates for implementation in the FPGA.
- Testbench: code that supplies inputs and checks a module in simulation. It acts as test equipment on your computer.
- Clock: a repeating signal. A rising edge is its change from 0 to 1; registers can store new values at that edge.
- Immediate: a number stored inside an instruction, such as the 7 in an instruction that adds 7.

## How the four blocks will work together

For an instruction such as ADDI x5, x1, 7, the decoder identifies an addition with an immediate. The register file supplies x1. The immediate generator supplies 7. The ALU adds the two numbers. Future pipeline control will write the answer into x5 at the correct clock edge.

If x1 contains 10, the expected answer is 17. This one example connects the purpose of all four blocks. The pipeline that schedules these actions is the next CPU integration milestone.

<!-- page -->
## The ALU and register file

### rtl/cpu/alu.v

The Arithmetic Logic Unit is the CPU's calculator. It receives two 32-bit numbers, operand_a and operand_b, and a four-bit control called alu_op. It produces a 32-bit result and a one-bit zero flag.

It can add, subtract, perform AND/OR/XOR, shift bits, and compare two numbers. The control values are 0 ADD, 1 SUB, 2 AND, 3 OR, 4 XOR, 5 SLL, 6 SRL, 7 SRA, 8 SLT, and 9 SLTU. These are internal control codes, not complete RISC-V instructions.

Example: operand_a = 5, operand_b = 7, and alu_op = 0 produce result = 12 and zero = 0. Subtracting 7 from 7 produces result = 0 and zero = 1.

The ALU is combinational: it responds to its current inputs without storing a value or waiting for a clock. Addition wraps at 32 bits. Shifts use only the lowest five bits of operand_b. SRA preserves the sign when shifting right; SLT compares signed numbers and SLTU compares unsigned numbers.

Its matching test file is tb/cpu/tb_alu.v. Tests include ordinary operations, arithmetic boundaries, shifts, comparisons, unsupported controls, and the zero flag.

### rtl/cpu/regfile.v

The register file is a small collection of 32 storage locations named x0 to x31. Each holds 32 bits. Two read ports allow two values to be read at once; one write port stores one value on a rising clock edge.

To write 42 into x5, set we = 1, waddr = 5, and wdata = 42, then supply a rising clock edge. Reading address 5 then returns 42. With we = 0, the stored value stays unchanged.

x0 always reads as zero and ignores writes. The active-high reset is synchronous: rst = 1 clears the registers on a rising edge. Reset takes priority over a write. A read of a register being written sees the old value before the edge and the new value after the write settles.

Its matching test file is tb/cpu/tb_regfile.v. It checks both read ports, every register, x0 protection, write timing, write-enable, and reset behavior.

<!-- page -->
## The decoder and immediate generator

### rtl/cpu/decode.v

The decoder is the instruction translator. It receives a 32-bit instruction and decides which operation the rest of the CPU should perform. It extracts the source register numbers rs1 and rs2 and destination register number rd.

Its control signals select the ALU operation, choose register or immediate operands, request register or memory writes, and identify branches and jumps. The source-use flags tell future dependency logic which register values the instruction actually needs.

The current decoder supports 37 instructions covering arithmetic, comparisons, branches, jumps, and loads/stores. Unsupported instructions set illegal = 1 and disable write, memory, and jump effects. The future CPU must handle that signal; the decoder itself does not halt a processor.

Its matching file is tb/cpu/tb_decode.v. It checks all supported instruction rules and many invalid encodings. It also connects the decoder, immediate generator, and ALU for a few small combined checks. These checks do not run a pipelined CPU.

### rtl/cpu/imm_gen.v

The immediate generator extracts a number from an instruction and expands it to 32 bits. RISC-V places that number in different bit positions for different instruction formats, so the module supports I, S, B, U, and J formats.

Example: an instruction containing -7 must produce the 32-bit representation of -7, not a large positive number caused by missing sign extension. Branch and jump offsets also need their scattered bits put back into the correct positions.

Its matching file is tb/cpu/tb_imm_gen.v. Tests reconstruct values from known original numbers, including negative values, boundaries, and all representable I/S/B offsets.

### rtl/cpu/cpu_defs.vh

This header is the shared dictionary of internal control numbers. It defines ALU operations, immediate formats, operand choices, branch types, memory sizes, and writeback choices.

Take this file with the Verilog modules. The ALU, decoder, and immediate generator include it. In Vivado, add rtl/cpu to the Verilog include directories; the provided test runner already does this. A missing header prevents compilation.

<!-- page -->
## Running and understanding the tests

### tb/run_cpu_tests.ps1

This PowerShell script is the test launcher for a Windows computer with Vivado installed. It compiles the required RTL and testbench, builds a simulation, runs it, and checks for a PASS message. It stops if compilation or a test fails.

Open PowerShell in riscv_soc_project. On our current computer, run:

```powershell
.\tb\run_cpu_tests.ps1 -Test alu -Waves `
  -VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'
```

The backtick continues the command on the next line. On a lab computer, change the Vivado path to its actual installation. Replace alu with regfile, decode, or imm_gen to select another block. Omit -Test to run all four. Omit -Waves if you only need the automatic result.

### tb/capture_waves.tcl

This small Tcl script tells the simulator to record signal changes from time zero, run the test, and finish. The PowerShell launcher uses it when you select -Waves. The recording is a .wdb waveform file.

### What to look for

The ALU test currently reports PASS tb_alu: 4142 checks. Its first check adds hexadecimal ffffffff and 00000001 and expects 00000000. The zero flag should be 1. The result wraps because it is stored in 32 bits.

The check calls in tb_alu.v use four arguments: operand A, operand B, operation, and expected result. The testbench compares what the module produces with that expectation. A FAIL message identifies the input and mismatch.

All four CPU testbenches passed in Vivado Simulator 2025.2 on October 10: ALU 4,142 checks; register file 2,456 port checks; decoder 7,717 checks plus 15 combined checks; immediate generator 14,546 checks.

### Viewing the recording

Generated files are saved under build/cpu_tests/. For the ALU, open tb_alu.wdb in Vivado and inspect operand_a, operand_b, alu_op, result, and zero. The step-by-step commands are in docs/testing_guide.md. A waveform shows what happened over time; automatic checks decide whether the tested expectations were met.

<!-- page -->
## The other files in your lab copy

### README.md and .gitignore

README.md is the project's starting page: current progress, directory layout, and test commands. .gitignore tells Git which generated files to exclude from version control. It does not affect Verilog compilation or automatically exclude files when you copy a folder.

### The documents in docs

- testing_guide.md explains small simulations, waveforms, and a sequence of lab exercises. Read this when you want to run a test.
- cpu_blocks.md gives the detailed ALU and register-file contracts, including operation codes and reset timing.
- cpu_isa.md lists the supported instructions and decoder controls. It also records the current test coverage and future pipeline obligations.
- architecture.md records the approved CPU, memory sizes, MMIO addresses, and AES register map.
- paper_notes_mohan_2025.md records the accessible IEEE findings and how we plan to compare software and hardware encryption costs.
- references.bib holds the paper citation in BibTeX form for use in your report.
- project_guide.md is the editable plain-text source of this beginner guide. project_guide.docx is the Word version to read or print.

### Folders for later stages

rtl/mem will hold instruction and data memory. rtl/crypto will hold AES hardware. rtl/peripherals will hold keypad, OLED, and UART controllers. fw/src will contain the software our CPU runs; fw/linker will contain rules that place that software in memory.

The .gitkeep files are empty placeholders that preserve these folders in Git. They are not hardware or firmware. The build/ directory contains generated simulations, logs, and recordings; it can be regenerated from the source files.

### A reliable lab copy

Preserve the directory structure. Copy rtl/, tb/, docs/, README.md, and .gitignore. For the present CPU simulations, all five files in rtl/cpu and all four testbench files in tb/cpu should travel together with the two test scripts.

Use the lab's Vivado installation to rerun the tests. A green PASS result from your own lab run is useful evidence that the copy and software setup work. Save the exact source version and test log used for each demonstration.

<!-- page -->
## Moving from simulation to the FPGA

Simulation checks behavior using a model of the circuit. Synthesis converts RTL into FPGA logic. Implementation places and connects that logic and checks timing. A bitstream is the generated .bit file that programs the board.

The original CPU files alone do not identify board pins. A board demonstration also needs a top-level module that connects the blocks to physical signals, plus an .xdc file that assigns those signals to pins and describes the clock.

## The first practical board milestone

The next exercise is a standalone ALU demonstration. A counter will make a heartbeat LED blink. A small hardware checker will apply fixed inputs to the ALU and show PASS or FAIL on other LEDs. This allows a useful lab test before the full CPU exists.

The demo will use the ZedBoard PL clock and LEDs. It will not require the keypad, OLED, or ARM cores. Test the demo in simulation, then review its implementation timing and program its bitstream. Follow the separate board-demo instructions added with that build for the exact LED meanings and programming steps.

The heartbeat demonstrates that the design is running. A PASS light indicates that the selected test cases matched their expected results. Neither result proves every ALU input combination or validates the future complete SoC.

## After the first board demonstration

The next CPU task is to connect Fetch, Decode, and Execute/Mem/WB into a three-stage pipeline with instruction and data memories. Start with a tiny program whose final registers and memory values are known. Then test dependencies, branches, loads/stores, and delayed memory replies separately.

Add a simple MMIO test peripheral before the AES block. Verify AES against known plaintext/key/ciphertext examples before connecting the keypad and display. Keep each passing test available so later changes can be checked against it.

## References for the board work

The board pin assignments and electrical details must match the ZedBoard. Consult the Digilent ZedBoard hardware guide and master XDC before wiring or changing constraints. Its onboard USB-UART bridge connects to the processing system; our PL UART will need a suitable external connection.

Hardware guide: https://files.digilent.com/resources/programmable-logic/zedboard/ZedBoard_HW_UG_v2_2.pdf

Pin reference: https://github.com/Digilent/digilent-xdc/blob/master/Zedboard-Master.xdc
