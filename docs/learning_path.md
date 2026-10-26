# Learn the RISC-V + AES SoC you are building

Prepared on 16 October 2026 for this project's custom three-stage CPU,
4 KB instruction ROM, 4 KB data RAM, completion-based MMIO bus, AES-128
accelerator, ZedBoard, Pmod KYPD, Pmod OLED, and UART TX.

The aim is to understand and test every part of your own machine. Use one
main architecture course, a practical FPGA introduction, and selected AES
lessons. Treat the other resources as help when you reach a particular topic.
You do not need to finish several entire university courses before building.

These recommendations come from checking official course indexes, syllabi,
selected video pages, accompanying code, and vendor documentation. I have
not watched every lecture end to end. Some video and training players could
not be inspected by the research browser; the official course indexes are
included as the dependable starting points. Rankings express fit to this
project, rather than a claim that one teacher is universally best.

## Your shortest useful route

1. **Write and test little circuits:** Shawn Hymel's FPGA series, parts 3–8;
   practise alongside it on HDLBits.
2. **Understand our CPU:** Harris & Harris, RISC-V edition, selected lessons
   from chapters 3–7. Make this your main architecture course.
3. **Understand the FPGA build:** AMD's Vivado lessons on simulation,
   synthesis, implementation, pins, and constraints.
4. **Understand AES:** Christof Paar's lectures 7 and 8, then 9 for the
   distinction between a block cipher and encryption of messages.
5. **Turn AES into hardware:** the opening AES/S-box material in Debdeep
   Mukhopadhyay's Hardware Security course, followed by small simulations.
6. **Connect the system:** Harris chapter 9, Hymel part 12, the handshake
   reference, and the manuals for our exact peripherals.

Learn and build in parallel. After each lesson, spend time drawing a circuit,
predicting a waveform, or testing a small example. Watching the next video
should not replace checking whether the previous idea makes sense.

## 1. Best practical starting series: Shawn Hymel / DigiKey

[YouTube series](https://www.youtube.com/watch?v=lLg1AgA2Xoo&list=PLEBQazB0HUyT1WmMONxRZn9NmQ_9CIKhb)
· [Creator's examples, challenges, and written lesson index](https://github.com/ShawnHymel/introduction-to-fpga)

**Why I chose it:** short practical steps, example code, and a challenge with
each video. It gives you a manageable entrance to writing circuits and
checking them.

Start with parts **3–8**: Verilog, clocked logic, state machines, reusable
modules, simulation, and memory. Return to **10** for external-input timing
and **12** when connecting a custom peripheral. Part 11 helps explain using
a soft processor, but does not teach the construction of our particular CPU.

The demonstrations use Lattice iCE40 hardware and an open tool flow. Follow
the circuit ideas using our existing Vivado setup. Its pin assignments,
device primitives, and programming instructions need adaptation for the
ZedBoard. [Part 7's written lesson](https://www.digikey.com/en/maker/projects/introduction-to-fpga-part-7-verilog-testbenches-and-simulation/1b741d1b8b864afeacbe28075b1427cd)
is especially useful for your earlier question about testing individual parts.

**Project exercise:** read `rtl/cpu/alu.v` and `tb/cpu/tb_alu.v` together.
Pick five inputs, work out the expected outputs on paper, then inspect the
same results in simulation. Include a negative arithmetic shift, a signed
comparison, and an unsupported ALU operation.

**You understand this stage when:** you can explain what drives each input,
what the testbench compares, and why a testbench is not loaded onto the FPGA.

## 2. Main course: Harris & Harris, Digital Design and Computer Architecture — RISC-V Edition

[Official chapter-by-chapter video index](https://pages.hmc.edu/harris/ddca/ddcarv/ddcarv_videos.html)

**Why I chose it:** its progression closely follows our build, from digital
logic through instruction execution and peripherals. Use the **RISC-V
edition**; the authors also have editions based on other instruction sets.

My selected route through the index:

- Chapter 3: parts 5, 7–16 for clocked state, FSMs, and timing.
- Chapter 4: introductory HDL material, then parts 5–9; finish with testing.
- Chapter 5: parts 6–8 and 13–16 for arithmetic and memory blocks.
- Chapter 6: parts 1–6 and 8–21 for instructions, assembly, encoding, and software.
- Chapter 7: parts 1–6b, then 13–16. Use parts 7–12 if multicycle control
  still feels unclear.
- Chapter 9: parts 3, 4, 8, and 9 when studying peripheral access.

Useful direct lessons:

- [ALU construction](https://www.youtube.com/watch?v=WXMf0y4NoBw)
- [Data dependencies in a pipeline](https://www.youtube.com/watch?v=zuegcg6ZSFQ)
- [Branches and control hazards](https://www.youtube.com/watch?v=VcnwVxD4LAc)
- [Memory-mapped I/O](https://www.youtube.com/watch?v=eq7XDJEq_k8)

The HDL lessons use SystemVerilog; our RTL uses Verilog. Learn the hardware
meaning behind constructs such as `logic`, `always_comb`, and `always_ff`
before translating examples. Our pipeline has three logical stages and a
specific stall/forwarding policy, so textbook pipeline diagrams are
conceptual references rather than exact pictures of `cpu_core.v`.

**Project exercises:**

- After the arithmetic lessons, explain the signed/unsigned choices in our ALU.
- After instruction encoding, decode one instruction from `fw/cpu_smoke.hex`
  and compare it with `fw/src/cpu_smoke.S`.
- After pipeline lessons, trace `addi x1,x0,5` followed by `add x2,x1,x1`.
  Mark the point at which x2 can receive the new x1 value.
- Trace a load followed by an instruction using its result. Then trace a
  taken branch and identify which younger instructions must be discarded.

**You understand this stage when:** you can draw our Fetch → Decode →
Execute/Memory/Writeback path and explain stalls, forwarding, and flushing
using actual signals in the waveform.

The local companion is `docs/cpu_pipeline.md`. It describes the implemented
core, including its conservative throughput and memory interface.

## 3. Learn the lab tools: AMD Vivado, with selected ZedBoard tutorials

[AMD's official Vivado learning hub](https://www.amd.com/en/developer/resources/vivado.html)
· [Official video playlist](https://www.youtube.com/playlist?list=PLx15eYqzJifeh6Gq0n9B7gZcpFISoNLh-)

Use the hub's courses on project setup, behavioral simulation, RTL coding,
synthesis/implementation/bitstream generation, and I/O planning. Then use
its linked **Using Constraints** tutorial. This is where to learn how a
design becomes a programmed FPGA and how the tools check its timing.

**Why this matters in our project:** on October 16, CPU simulation passed
while preliminary synthesis missed 100 MHz with **−3.098 ns setup slack**.
After simplifying branch and memory-address paths, the October 20 CPU board
build meets 100 MHz after routing with **+0.221 ns setup slack** and
**+0.151 ns hold slack**. See the [CPU lab guide](zedboard_cpu_demo.md) for
the verified build and the physical check that remains.

**Project exercise:** open the CPU timing report. Identify the start register,
end register, required arrival time, actual arrival time, and slack of its
worst setup path. Explain the relationship between 100 MHz and a 10 ns period.
Do not alter timing constraints simply to hide a real synchronous path.

[Pete Johnson's ZedBoard tutorial series](https://www.beyond-circuits.com/wordpress/tutorial/)
is a useful written companion. Start with **1–3**, then **9–11** for button
bounce and debouncing. It uses older Vivado screens and different Pmods.
Use the current project instructions for pin assignments and tool setup.
The later ARM/Linux material is outside our present PL-only architecture.
Its timing tutorial uses a different clock-domain example; use AMD's
constraints material for decisions about our CPU timing.

**Lab checkpoint:** follow `docs/zedboard_alu_demo.md` and explain the
heartbeat, PASS, and FAIL outputs before programming the existing demo.
You can do the simulation and report-reading exercises without board access.

## 4. Understand the cipher: Christof Paar, Introduction to Cryptography

[Author's course and slides](https://www.cryptography-textbook.com/online-course/)
· [English lecture channel](https://www.youtube.com/channel/UC1usFRN4LCMcfIV7UjHNuQg)

**Why I chose it:** it develops the mathematics behind the cipher, which is
what makes an AES datapath understandable rather than a collection of
copied equations. The author describes the introductory course as requiring
high-school mathematics.

Select **lecture 7** on finite fields, **lecture 8** on AES, and **lecture 9**
on block-cipher modes. Start with lecture 1 if keys, plaintext, and ciphertext
are unfamiliar. The [university resource index](https://ocw.uc3m.es/mod/page/view.php?id=3347&lang=en)
also lists these lecture numbers. You do not need the entire RSA/ECC/DES
sequence for this build.

**Project exercise:** draw the 16-byte AES state, then explain where each
byte moves during one round. Explain what the key schedule produces and
what changes in the final round. Keep a separate drawing showing how our
four 32-bit MMIO words will map into those 16 bytes; that mapping must be
documented and tested when the accelerator is implemented.

For the exact algorithm, use [NIST FIPS 197](https://csrc.nist.gov/pubs/fips/197/final).
For debugging, use the [NIST AES-128 worked example](https://csrc.nist.gov/CSRC/media/Projects/Cryptographic-Standards-and-Guidelines/documents/examples/AES_Core128.pdf),
which supplies intermediate values. Compare intermediate steps as well as
the final ciphertext.

**You understand this stage when:** you can explain SubBytes, ShiftRows,
MixColumns, AddRoundKey, and round-key generation without opening RTL.
Lecture 9 provides the next step toward understanding multi-block messages;
our first accelerator milestone is a block-encryption engine.

## 5. Translate crypto into circuits: NPTEL Hardware Security

[Official course — Prof. Debdeep Mukhopadhyay, IIT Kharagpur](https://nptel.ac.in/courses/106105194)
· [Official syllabus](https://archive.nptel.ac.in/content/syllabus_pdf/106105194.pdf)

**Why I chose it:** this fills the gap between knowing AES equations and
understanding hardware implementation. Begin after the previous section and
after you are comfortable with FSMs and registers.

The published syllabus places finite fields, AES hardware, and S-boxes in
**week 1**, with algorithm-to-hardware material in **week 2**. Select those
topics first; the rest of week 2 and week 3 move into ECC. Later, week 4's
side-channel introduction helps with the security discussion in your report.
This is an advanced course, so the entire twelve-week sequence is optional.

**Project exercise:** sketch two candidate AES datapaths. In one, reuse a
small amount of logic across several cycles; in the other, process more
bytes in parallel. Mark the state register, round-key storage/generation,
round counter, and controller. Estimate the work done each cycle.

Our proposed **11–14 cycles per block is a design target**. Ten AES rounds
do not automatically imply ten clock cycles: the schedule must account for
the initial key addition, key generation, round datapath, and interface.
We will verify both latency and timing once those choices are implemented.

[Secworks' AES implementation](https://github.com/secworks/aes) is useful
optional code reading after you have drawn your own design. Its documented
word-oriented datapath uses four S-boxes and shares them with key expansion.
That makes it a useful comparison for resource reuse, but its organization
and timing are not specifications for our accelerator.

**Small tests to plan:** all 256 S-box inputs; selected finite-field multiply
cases; one round against an independent reference; key expansion; complete
known-answer blocks; then START/BUSY/DONE and reset behavior. Functional
correctness and resistance to physical side channels are separate evaluation
questions; the latter is future study rather than an already-tested feature.

## 6. Connect software and hardware: From Blinker to RISC-V

[Bruno Levy's step-by-step Verilog tutorial](https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/README.md)
· [Its pipeline continuation](https://github.com/BrunoLevy/learn-fpga/blob/master/FemtoRV/TUTORIALS/FROM_BLINKER_TO_RISCV/PIPELINE.md)

**Why I chose it:** it shows a processor growing through small changes and
connects that hardware to real assembly and C programs. It is a written
build-along resource, not a lecture series.

Use it after the basic Harris CPU lessons. Read the instruction-execution
sections alongside our decoder. Later, **steps 20 and 21** introduce the
assembly/C tool flow; **step 24** expands the linker/startup discussion.
Use the pipeline continuation for a second view of hazards when needed.

The tutorial uses its own boards, memory layout, processor choices, and
toolchain. Our Harvard memories and 37-instruction subset require our own
linker/startup arrangement and compiler settings. Do not transplant its
memory map or assume all of its examples execute on our core unchanged.

**Project exercise:** explain the journey from an assembly instruction to
a word in the ROM image. Before C firmware is introduced, explain `.text`,
`.data`, `.bss`, and the stack, and show where each belongs in our memories.

## 7. Learn MMIO and peripherals at the point of use

For connecting registers to a CPU, return to Harris chapter 9 and
[Hymel's custom-peripheral lesson](https://www.digikey.com/en/maker/projects/introduction-to-fpga-part-12-risc-v-custom-peripheral/148dba8ecafe49a1ac7e13641088af4c).
Read [Charles Eric LaForest's handshake guide](https://fpgacpu.ca/fpga/handshake.html)
for valid/ready behavior, delayed handshakes, and avoiding lost transfers.

Our actual contract is in `docs/cpu_pipeline.md`: a rising edge with
`valid && ready` completes one access. During a wait, the CPU keeps the
request stable; read data/error must be valid at completion. This is our
custom bus, not the separate request/response channels of AXI.

Also distinguish **completion of an MMIO register write** from **completion
of AES encryption**. A START register write can finish while the accelerator
continues working; software then checks its status registers.

**Project exercise:** inspect the five-cycle delayed peripheral in
`tb/cpu/tb_soc_minimal.v`. Explain why it records one write, not a write on
every cycle that valid is high. Predict what changes if the delay is longer.

For the three physical interfaces:

- **UART:** [Nandland's UART explanation, Verilog, and testbench](https://nandland.com/uart-serial-port-module/).
  Focus on the transmitter first. Draw the frame for byte `0x55` and check
  its start bit, data order, stop bit, and bit duration in simulation.
- **Keypad:** use [Digilent's Pmod KYPD resource page](https://digilent.com/reference/pmod/pmodkypd/start)
  and its reference manual, alongside the debounce lessons above. First
  identify one row/column combination, then test all keys, a held key,
  release, and simulated bouncing. Decide how multiple simultaneous presses
  should be handled before writing that behavior.
- **OLED:** use [Digilent's Pmod OLED resource page](https://digilent.com/reference/pmod/pmodoled/start),
  its manual, and [Digilent's initialization-driver source](https://github.com/Digilent/vivado-library/blob/master/ip/Pmods/PmodOLED_v1_0/drivers/PmodOLED_v1_0/src/OledDriver.c)
  as protocol references. Harris chapter 9 part 9 introduces SPI. Build up
  from a checked serial byte to display initialization, a fixed pattern,
  one character, and finally hexadecimal ciphertext.

Some Digilent reference pages returned access errors to the research tool;
use the resource-center/manual links in a normal browser. The OLED driver
source was accessible. Its C code is useful for understanding the command
sequence, even though our controller will be custom hardware.

Use the exact Pmod OLED model's command/data, reset, and power-control
requirements. A generic SSD1306 example may assume a different connector
or bus. Likewise, our PL UART needs its planned PL pin connection; the
ZedBoard's onboard USB UART is connected to the ARM processing system;
see section 2.3.2 of the [ZedBoard hardware manual](https://files.digilent.com/resources/programmable-logic/zedboard/ZedBoard_HW_UG_v2_2.pdf).
Board connection details belong in the hardware integration check before
the UART lab exercise, not in the generic UART tutorial.

## Practice and optional deeper courses

**HDLBits — use throughout.** [Open the exercises](https://hdlbits.01xz.net/wiki/Main_Page).
It checks submitted Verilog against simulated reference results. Begin with
vectors and muxes, then arithmetic, flip-flops, counters, and FSMs. Solve a
few exercises after each relevant lecture. Try your own explanation before
looking up a solution. FPGA hardware is unnecessary for these exercises.

**Ripes — make instruction execution visible.**
[Project and documentation](https://github.com/mortbopet/Ripes)
· [Browser version](https://ripes.dk/).
Use it to step through a small assembly program and observe dependencies.
Its chosen processor model is an educational comparison, not a simulator
for our Verilog or an exact prediction of our three-stage cycle counts.

**NPTEL Hardware Modeling using Verilog — slower, formal foundation.**
[Prof. Indranil Sengupta's official course](https://nptel.ac.in/courses/106105165).
Choose this if short tutorials leave the language feeling unclear. Focus
on combinational/sequential modeling, procedural assignments, testbenches,
and FSMs. Use it as an alternative foundation or targeted reference; it
need not become another full course to complete alongside the build.

**Onur Mutlu, ETH Digital Design and Computer Architecture — deeper CPU study.**
[Instructor's course index](https://people.inf.ethz.ch/omutlu/lecture-videos.html)
· [2025 undergraduate lecture series](https://www.youtube.com/playlist?list=PL5Q2soXY2Zi9Eo29LMgKVcaydS7V1zZW3).
Choose the undergraduate DDCA course and look for the processor datapath,
pipelining, and hazard lessons. Use it when you want a fuller explanation
after Harris. Advanced out-of-order execution and large cache hierarchies
can wait until after this SoC milestone.

**RISC-V specification — look up exact behavior.**
[Official RV32I chapter](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html).
Keep it beside `docs/cpu_isa.md` when an instruction's signedness, immediate,
branch behavior, or encoding is uncertain. Our document defines which
instructions the project implements; the ISA chapter describes a broader
base architecture.

The Mohan/Das/Mai eFPGA paper becomes useful advanced reading after you
understand CPU execution, acceleration, and integration overhead. Our
existing `docs/paper_notes_mohan_2025.md` explains its relationship to this
project. It is not the starting tutorial for our MMIO AES engine.

## Your next three study sessions

**Session 1 — one combinational block.** Watch Hymel part 3 and the Harris
ALU lesson. Read our ALU and its testbench. Predict five cases, then run:

```powershell
.\tb\run_cpu_tests.ps1 -Test alu -Waves
```

**Session 2 — stored state.** Watch Hymel parts 4 and 7. Read `regfile.v`
and `tb_regfile.v`. Explain clock-edge writes, combinational reads,
synchronous reset, and why x0 remains zero. Run the register-file test.

**Session 3 — instructions working together.** Start the selected Harris
instruction/datapath lessons. Read `fw/src/cpu_smoke.S`, then run:

```powershell
.\tb\run_integration_tests.ps1 -Test soc_minimal -Waves
```

Run these commands from the project root. If Vivado is not found, add
`-VivadoBin 'D:\VIVADO\2025.2\Vivado\bin'`, replacing that path for the lab
machine. Existing `docs/testing_guide.md` explains waveform viewing.

For session 3, locate the sum **55**, its increment to **56**, and the
single write of 56 to the simulated peripheral. That peripheral is a test
stub, not an implemented AES controller.

At the end of each session, write four short answers:

1. What information goes into this block?
2. What work happens immediately, and what waits for a clock?
3. What result should come out, and when?
4. What small test would catch an incorrect implementation?

That gives us a concrete basis for reviewing your understanding as the
project grows.
