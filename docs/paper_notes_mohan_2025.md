# Mohan, Das, and Mai (2025): project reference

Consulted October 10, 2026.

P. Mohan, S. Das, and K. Mai, "A RISC-V SoC With Reconfigurable Custom
Instructions on a Synthesized eFPGA Fabric in 22nm FinFET," IEEE Solid-State
Circuits Letters, vol. 8, pp. 321–324, 2025.
[DOI: 10.1109/LSSC.2025.3618942](https://doi.org/10.1109/LSSC.2025.3618942).
The bibliographic entry is also saved in `references.bib`.

## Access and verified findings

The full four-page letter was not retrieved. This consultation uses IEEE's
public abstract excerpt and its own editorial spotlight. Details of the
datapath, instruction encoding, workloads, measurement methodology, and
figures require the full paper before they can be reviewed.

The design combines a RISC-V CPU with a synthesized embedded FPGA in a
22nm FinFET SoC to implement reconfigurable custom instructions.
[Source: IEEE SSCS publication listing](https://sscs.ieee.org/tag/central-processing-unit/).

IEEE's editorial spotlight reports peak INT8 efficiency of 748 GOPS/W,
compute density of 22.3 GOPS/mm², and throughput/energy improvements of one
to two orders of magnitude over the CPU for accelerated applications.
[Source: IEEE SSCS editorial spotlight](https://www.linkedin.com/posts/ieee-solid-state-circuits-society_articlespotlight-sscl-editorspick-activity-7411764266875265024-MYUc).
These published metrics are not evidence for AES performance on our board.

## Application to this build — our engineering interpretation

The useful connection is CPU-controlled hardware acceleration. Our approved
implementation uses a fixed AES peripheral reached through load/store MMIO.
The paper's reconfigurable instruction subsystem is a different integration
choice. Retain the MMIO baseline for the first working ZedBoard demonstration;
record custom-instruction attachment as a possible later experiment once
there is a correct CPU, accelerator, and repeatable baseline.

A custom opcode alone would not reproduce the paper's eFPGA architecture.
It would also need a defined operand/result interface, busy/completion
protocol, pipeline stalls, and software support. No custom opcode is added
to the current decoder, and unknown instructions are rejected.

## Benchmark contract for the later AES milestone

Compare software AES and MMIO hardware AES on the same custom CPU, same
input blocks, and same key policy. Validate ciphertext correctness first.
Record the exact firmware revision, clock frequency, and measured cycles.

Report three distinct quantities:

1. Accelerator latency, with its start and done edges explicitly defined.
2. CPU-visible hardware path: key/plaintext writes, command launch, polling
   until completion, and ciphertext reads into CPU-visible storage.
3. Software path producing the same ciphertext into CPU-visible storage.

Measure first-block cost with key setup included and repeated-block cost
with an unchanged key separately. Give both sides the same key-reuse
opportunity. Keep keypad input and OLED rendering outside the crypto timing
window and report demonstration responsiveness separately if desired.

Use total software cycles divided by total hardware-path cycles for speedup.
For N blocks in C measured cycles at frequency f Hz, payload throughput is
128*N*f/C bits/s. Use identical scope when comparing paths. Resource use and
post-implementation timing belong alongside speedup; energy claims require
power measurements with a stated measurement boundary.

The proposed 11–14-cycle AES target covers the accelerator only. It cannot
be used as the CPU-visible encryption cost because MMIO transfers and
software control also consume cycles. No speedup, throughput, or energy
measurement has been made in this project yet.
