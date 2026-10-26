# Lab record

Date and time:
Student:
Checklist task IDs for this visit:
Computer / Vivado version:
Board revision / device:
Matching schematic revision (uploaded copy is E.1):
Pack: 22 October 2026
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

Summary/log location:
Waveform screenshot locations:
First failure and exact message, if any:

## Build evidence

Used supplied bitstreams or rebuilt?
If rebuilt, Vivado version and build-log location:
ALU setup slack / hold slack:
CPU setup slack / hold slack:
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

## Next action

What passed:
What needs investigation:
Exact change to try next:
