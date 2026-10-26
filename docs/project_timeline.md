# Build timeline: finish by 20 November 2026

Plan created: **23 October 2026**; status updated **24 October**.
The confirmed deadline is **20 November
2026**, replacing the original December 2 target. Dates use India time.

**Working full-demo target: November 15.** November 16-20 is reserved for
measurements, documentation, fixes, rehearsal, and submission. The aim is
to reach the deadline with a repeatable demonstration, not a first attempt.

Use [project_checklist.md](project_checklist.md) to tick tasks and
[progress_log.md](progress_log.md) to record dated results. The checklist
is the maintained record; this document explains the order and deadlines.

## Where we are now

The CPU, memories, and minimal SoC are implemented. All **nine existing
simulation sets** passed in the saved October 22 Vivado run. The ALU and
CPU board demos have generated bitstreams with passing routed 100 MHz
timing. Board references and current clock/LED constraints are checked.

The standalone AES core passed M1 on October 24: 1,810 primitive checks,
556 completed encryptions, and verified 11-clock latency. See the
[AES acceptance guide](aes_core.md) for logs and early synthesis results.
The project now includes eleven simulation sets.

**Physical board testing is still pending.** AES MMIO integration, real
peripheral controllers, and the full demonstration firmware remain to be built.
The present MMIO signature checker is a test device, not the AES block.

Evidence: [simulation summary](../build/vivado_gui_validation/gui_test_summary.txt),
[ALU build record](zedboard_alu_demo.md), [CPU build record](zedboard_cpu_demo.md),
and [board I/O plan](board_io_plan.md). These are saved results, not tests
rerun while making this schedule.

## What must work at the end

The custom RISC-V CPU runs in the ZedBoard PL, reads an input block from
the keypad, launches the AES-128 MMIO accelerator, reads the ciphertext,
and shows it on the external Pmod OLED. UART TX supplies a simple debug
path. The result matches an independent expected ciphertext. The design
can repeat the operation and restart reliably.

Keep the approved three-stage CPU, lightweight MMIO bus, 4 KB ROM,
4 KB RAM, and 100 MHz target. Keep the user interface small: one 16-byte
block at a time, one fixed public demonstration key initially, and hex
ciphertext. The user selected **32 hexadecimal digits** on October 24.
Automatic start after digit 32 and long-press clear are specified in
[the interface contract](aes_interface.md); keypad/UI implementation is later.

This is a tight plan. Working assumption: **12-16 focused hours per week
plus four lab visits of roughly 2-3 hours**. These are planning estimates,
not booked access or a guarantee. Review the schedule at every milestone.

## M1: October 23-28 — verify the baseline and build AES

**Outcome:** the AES block encrypts correctly on its own.

1. On October 23-24, open the existing Vivado project, personally run a
   small test, and prepare the first board visit. Confirm the November
   lab-access windows and availability of both Pmods and a suitable UART
   adapter. Inspect the actual peripheral manuals before assigning signals.
2. By October 24, write the AES contract: byte/state ordering, key order,
   accepted START edge, reset, BUSY/DONE, output validity, and what happens
   to commands or input changes while busy. Define latency start/end edges.
3. Implement and test the S-box, row shifts, column mixing, round-key
   expansion, and the iterative encryption controller in manageable steps.
4. Run independent known-answer vectors, different keys and plaintexts,
   consecutive operations, and reset during encryption. Make a self-checking
   Vivado testbench that prints a clear PASS or failure.
5. Run an early synthesis/timing check. Measure actual latency; 11-14 cycles
   is the design target, not a result to claim before measurement.

**Gate M1, October 28:** every AES unit/core test passes against independent
expected values; the interface and measured latency are documented.
Physical CPU testing can follow lab availability without blocking AES
simulation. A late board test still stays unchecked.

References for the AES work: [NIST FIPS 197](https://csrc.nist.gov/pubs/fips/197/final)
and [NIST known-answer vectors](https://csrc.nist.gov/projects/cryptographic-algorithm-validation-program/block-ciphers).
Use AES-128 encryption cases from the vector set; these are functional
project checks, not a claim of formal NIST certification.

## M2: October 29-November 2 — connect CPU and AES

**Outcome:** a ROM program encrypts a block through the approved MMIO registers.

1. Add the AES register wrapper at `0x40000000`. Define byte strobes,
   reserved/misaligned accesses, writes while busy, START acceptance, and
   DONE clearing. A completed valid/ready transfer must act exactly once.
2. Test the wrapper independently, including held requests, waits, reset,
   attempted writes to read-only registers, and repeated START requests.
3. Connect CPU, ROM/RAM, bus decoding, and AES. Run a small program that
   writes key/plaintext, starts encryption, polls with a timeout, and reads
   all ciphertext words into RAM for comparison.
4. Prepare firmware early: retain a checked assembly image first; establish
   the linker/startup and code-generation path before depending on C. Check
   every emitted instruction against our supported subset. Deliver the ROM
   `.hex` ready for Vivado; no terminal testing is required from the user.
5. Test several transactions and recovery from reset, rerun affected CPU
   tests, and create a CPU-plus-AES LED self-test bitstream after timing/DRC.

**Gate M2, November 2:** the real CPU obtains correct ciphertext through
MMIO, the saved image fits memory, and a board self-test is ready to program.

## M3: November 3-8 — test each peripheral alone

**Outcome:** three small peripherals work separately before full integration.

1. **UART TX:** verify baud timing, start/data/stop bits, back-to-back bytes,
   and its MMIO handshake. Send a fixed debug string on the board through
   the planned PL connection and 3.3 V adapter.
2. **Keypad:** model every key, synchronization, debounce, long holds,
   release/repress, and the chosen multiple-key policy. Define its MMIO
   event/acknowledge behavior. On the board, see one event per intended
   press, for all 16 keys.
3. **OLED:** verify the module's actual reset/power sequence, SPI timing,
   command/data control, and MMIO flow control. Start with a fixed pixel
   pattern, then a short label, then all 32 ciphertext hex digits.
4. Register each new test in the Vivado GUI project. Review the actual
   header orientation, bank voltages, and new XDC before programming.

**Gate M3, November 8:** all three unit/MMIO simulations pass and their
individual board images are ready. Aim to observe them during lab visit C
by November 10. Record board checks separately; a simulation pass does not
complete the hardware check.

Manual review and pin planning may start during M1/M2. Do not wait for
lab access to write these simulations.

## M4: November 9-12 — run the entire path in simulation

**Outcome:** keypad input reaches the OLED through the CPU and AES.

1. Connect all four MMIO windows, with one unambiguous response and error
   behavior for unmapped addresses. Test transactions under wait states.
2. Add firmware for input assembly, clear/start, AES timeout/error handling,
   ciphertext formatting, display, and the next input block.
3. Use a system testbench to model key presses and observe display/debug
   output. Check exact ciphertext, input length, repeated blocks, reset,
   and stalled peripherals. Compare actual device traffic, not just a
   firmware completion flag.
4. Measure ROM and RAM use, including stack, constants, and display storage.
   The 4 KB ROM / 4 KB RAM limit is an acceptance check, not an assumption.
5. Run the full regression. Build the full top-level and inspect routed
   100 MHz setup/hold timing, DRC, and unconstrained paths.

**Gate M4, November 12:** complete simulation passes, firmware fits, and
the full-system bitstream has acceptable implementation reports.

## M5: November 13-15 — prove the complete demo on the board

**Outcome:** the full project works physically, repeatedly.

1. Run a known input/key example and compare all ciphertext bytes.
2. Enter several different inputs, exercise clear/start and display
   transitions, and run at least ten consecutive encryptions.
3. Repeat after three fresh starts. Record whether each start was a JTAG
   reprogram or power-cycle followed by reprogramming. Flash boot is not
   assumed; this project currently uses temporary JTAG loading.
4. Capture a readable video showing the keypad, OLED, and result. Save the
   source/firmware version, programmed bitstream, reports, and board revision.
5. Fix failures and rerun the affected tests. Preserve the last known
   working image before making changes.

**Gate M5, November 15:** the complete physical demo passes, with saved
evidence. Freeze features at this point; later changes are fixes and must
be rechecked.

## M6: November 16-18 — measure, explain, and package

**Outcome:** results and submission files accurately describe the working build.

1. Measure accelerator latency separately from total CPU-visible offload
   cycles. State the clock, key policy, and timing boundaries. Keep keypad
   and OLED activity outside the crypto measurement window.
2. Record final LUT/FF/BRAM use, routed timing, test coverage, and limitations.
   A software-AES comparison is a stretch item after the full demo works;
   claim speedup only with a checked same-CPU, same-input comparison.
3. Finish the architecture diagram, register map, simple block explanations,
   screenshots, report/slides as required, and a short demo script.
4. Package source, testbenches, firmware image, constraints, Vivado project,
   references, reports, and the final bitstream. Include GUI instructions.
5. Extract the package into another folder and check the project resolves
   its files. Run its acceptance tests and preserve a second backup.

**Gate M6, November 18:** final package opens cleanly and all reported
results point to evidence from the packaged design.

## M7: November 19-20 — rehearse and submit

**Outcome:** a confident demonstration and a complete submission.

- November 19: rehearse from opening Vivado through programming and input,
  without depending on remembered setup steps. Use the recovery lab slot
  if needed. Confirm the actual submission time and required file formats.
- November 20: demonstrate/submit the checked package and record submission
  confirmation. Keep the working image and video available as backups.

**Gate M7, November 20:** the submission and required demonstration are
complete. No deadline hour has been assumed by this plan.

## Lab visits: use each slot for a prepared test

These are target windows, not reservations. All simulation and build steps
use the Vivado GUI described in [VIVADO_START_HERE.md](../VIVADO_START_HERE.md).

- **Visit A, October 23-26:** record board revision; program the ALU and CPU
  images; check LD0 heartbeat, LD1 PASS, other LEDs off; repeat after reprogramming.
- **Visit B, October 30-November 3:** program the CPU-plus-AES self-test
  once M2 is ready; compare the known-answer result. Check wiring for visit C.
- **Visit C, November 7-10:** UART fixed string, all keypad keys, OLED pattern
  and text. Bring separate bitstreams so one failure is easy to isolate.
- **Visit D, November 13-15:** complete keypad-to-ciphertext demonstration,
  repeated inputs, restart checks, and video.
- **Recovery slot, November 18-19:** fix/recheck a remaining physical issue
  or rehearse. Try to arrange this before depending on it.

Bring the latest entire project pack, power/JTAG cables, peripherals and
adapter, expected outputs, and a copy of [lab_record_template.md](lab_record_template.md).
Check what passed before leaving the lab; save the photo/video and exact
failure message while the board is available.

## How we review progress

At the end of each work session, tick only tasks supported by evidence,
append a short progress entry, and write the next smallest test.
Review the milestone dates on **October 28, November 2, 8, 12, 15, and 18**.
These are manual checkpoints, not automatic reminders.

Use this order for every new block: **interface -> implementation -> unit
simulation -> integration simulation -> implementation/timing -> physical test**.
A missed date is a signal to replan, not permission to skip the checks.

If we slip, cut optional work first: configurable keys, decryption,
multi-block modes, fancy text entry, animations, custom instructions, AXI,
and a software speedup comparison. Keep the core keypad -> CPU -> AES ->
OLED demonstration. If it is still blocked by November 12, explicitly
review the remaining scope; a fixed-input AES/LED demo is useful evidence
but does not satisfy the complete project's acceptance condition.

The very next development step is **M1.2: write the AES interface and byte
ordering contract**, while the first lab slot validates the existing demos.
