# Lab record

Date and time:
Student:
Checklist task IDs for this visit:
Computer / Vivado version:
Board revision / device:
Matching schematic revision (uploaded copy is E.1):
Pack: riscv_soc_lab_2026-10-27.zip
Source changed since extraction? If yes, describe:

## Before future peripheral wiring

These entries are not required for the current clock/LED-only demos.
Use [the I/O plan](board_io_plan.md) when adding peripherals.

J18 / VADJ setting, if using buttons or switches:
Keypad module revision / selected PL Pmod / pin-1 orientation:
External Pmod OLED or built-in display / module revision:
UART adapter model / logic voltage / RX and ground pins:
Final design-specific constraint filename:

## Simulations

Mark only after observing PASS in the current run:

- [ ] ALU: 4,142 checks.
- [ ] Register file: 2,456 port checks.
- [ ] Immediate generator: 14,546 checks.
- [ ] Decoder: 7,717 decode checks and 15 datapath examples.
- [ ] ROM/RAM: 24 checks.
- [ ] CPU: 76 cases / 1,287 retirements.
- [ ] Minimal SoC: 55 in RAM, result 56, one MMIO write.
- [ ] ALU board simulation: 16 vectors and fault/reset/LED checks.
- [ ] CPU board simulation: actual program and 15 checker scenarios.
- [ ] AES primitives: 1,810 checks.
- [ ] AES core: 17,433 checks / 556 completed blocks.
- [ ] AES MMIO: 26,632 / 48,264 checks for one/three wait edges.
- [ ] CPU + AES: 32 healthy blocks plus restart/error paths.
- [ ] CPU + AES board wrapper: 13 monitor scenarios plus real program/LEDs.

Summary/log location:
Waveform screenshot locations:
First failure and exact message, if any:

## Build evidence

Used supplied bitstreams or rebuilt?
If rebuilt, Vivado version and build-log location:
ALU setup slack / hold slack:
CPU setup slack / hold slack:
CPU + AES setup slack / hold slack:
DRC errors or new warnings:

## Physical ALU test

Bitstream filename / SHA-256:
LD0 blinking?
LD1:
LD2:
LD3:
LD7:LD4:
Result: NOT TESTED / PASS / FAIL
Photo/video location:

## Physical CPU test

Bitstream filename / SHA-256:
LD0 blinking?
LD1:
LD2:
LD3:
LD7:LD4:
Same result after reprogramming?
Result: NOT TESTED / PASS / FAIL
Photo/video location:

## Physical CPU + AES test

Bitstream filename / SHA-256:
LD0 blinking?
LD1:
LD2:
LD3:
LD7:LD4 (write each LED, even if the code is unfamiliar):
First programming result: NOT TESTED / PASS / FAIL
Second programming result: NOT TESTED / PASS / FAIL
Third programming result: NOT TESTED / PASS / FAIL
Photo/video locations:

## Hardware identification to bring back

Board front/back and revision-label photos:
FPGA marking / device detected by Vivado:
Current jumper-position photo:
Keypad model/revision / key legends / pin-1 photo:
OLED model/revision / external Pmod or built-in / pin-1 photo:
Matching manuals/schematics or adapter pinouts supplied by lab:

## Next action

What passed:
What needs investigation:
Exact change to try next:
