# Lab simulation results — 29 October 2026

Source: the user supplied the lab's eight PASS messages in the project
chat, headed “Testing 29 Oct”. These are accepted user-reported lab
simulation results, separate from our local development runs and the
October 27 physical board observations.

The lab installation was previously identified as **Vivado 2020**.
Today's pasted report does not repeat its version, identify the source
commit, or include the generated setup report. The exact 2020.x version
and project snapshot remain to be archived; no broader version certification
is implied.

## Reported output

```text
Test 5: PASS tb_memories: 24 checks, byte lanes, boundaries, errors, reset cancellation, back-to-back requests
Test 6: PASS tb_cpu_core: 76 cases, 1287 retirements, load bypass=11, stalled decode cycles=657, drained fetches=37; reset cancellation
Test 7: PASS tb_soc_minimal: ROM program, sum=55, load-use=56, one delayed MMIO write, 44 retirements
Test 11: PASS tb_aes128_core: 17433 checks, 556 completed blocks; 284 NIST, 256 random, 11 reset-abort points; latency=11 clocks, earliest restart=12 clocks
Test 12: PASS tb_aes_mmio: 1/3 wait edges, 284 NIST blocks per mode, byte strobes, access errors, busy writes, held requests, reset cancellation
Test 13: PASS tb_soc_aes: real CPU/ROM/RAM/AES, 1/5 wait edges, 32 checked blocks, restart and firmware error paths
Test 15: PASS tb_uart_tx: 4 dividers, 840 complete frames, 40 reset aborts
Test 16: PASS tb_uart_mmio: waits 1/4, 564 complete frames, 20 reset aborts
```

## What this completes

All five previously failing tests, **6/7/11/12/13**, now have reported
lab PASS results. **P15's functional recovery gate is passed.** Memory
test 5 and both UART tests also passed. The earlier failures remain
historical observations; their exact original cause is not proven by
the successful rerun.

The simulation parts of **P7/P8/P9/P13/P14** are complete. Waveform
learning exercises are tracked separately as **P17**. The user subsequently clarified that **tests 1–4, 8–10, and 14 passed on
October 27**. The earlier assistant statement that these were unreported
was incorrect. Together, all original tests **1–16 have reported lab PASS**
results. Waveform explanations are separate learning tasks, not failed tests.

## Remaining evidence and next build step

**P16** tracks archiving the full logs, `setup_report.txt`, exact Vivado
version/project revision, and test 7's `SIM_ROM_LOAD_OK` line. The pasted
PASS messages are sufficient to record the reported functional success;
missing supplementary files do not erase it. No attachment contents or
waveform observations were supplied in this message.

Next is **M3.3: the keypad scanner**, with a small simulation for key
mapping, debounce, press/release events, and reset before board wiring.
UART-to-CPU integration, physical UART reception, keypad/OLED hardware
operation, and the complete interactive AES demonstration remain future
work. See the [master checklist](project_checklist.md).
