# ALU, CPU, and CPU/AES board results

Report received: **27 October 2026**. Source: the user's observations in
the project chat after following the lab testing guide. The exact visit
time was not supplied.

The user confirmed that all three supplied `.bit` files ran successfully
with **LD0 blinking, LD1 ON, and LD2-LD7 OFF**, including **three successful
AES trials**. These are accepted physical functional results.

## Results recorded

- **P4 — ALU: PASS.** Image from the procedure:
  [`zedboard_alu_demo.bit`](../build/zedboard_alu_demo/zedboard_alu_demo.bit).
  The reported LEDs match the automatic ALU self-test's success state.
- **P5 — CPU: PASS.** Image from the procedure:
  [`zedboard_cpu_demo.bit`](../build/zedboard_cpu_demo/zedboard_cpu_demo.bit).
  The reported LEDs match the CPU smoke program and observer's success state.
- **H2 — CPU plus AES: PASS, 3/3 trials.** Image from the procedure:
  [`zedboard_aes_demo.bit`](../build/zedboard_aes_demo/zedboard_aes_demo.bit).
  The reported LEDs match the four-block encryption self-test's success state.

Each AES run executes the CPU firmware that writes key/plaintext through
MMIO, starts AES, polls completion, reads ciphertext into RAM, and compares
it with known answers. Its independent observer also checks the bus
sequence. See [the board checker explanation](zedboard_aes_demo.md).

## Evidence and scope

This record preserves the user's reported observation. Photos, video,
lab-computer logs, and read-back file hashes were not supplied. The image
names above come from the testing procedure the user identified; the
[published hash list](../build/SHA256SUMS.txt) identifies our supplied files.
The exact restart method and repeat count for the standalone ALU/CPU tests
were not separately stated. The three AES trials are recorded as reported,
without assuming power cycles.

No new personal simulation results are inferred. The saved development
simulations and routed timing reports remain separate engineering evidence.
Keypad input, OLED output, and UART are still future physical tests.

The user later supplied four failed simulation reports from the same lab
day and confirmed using the supplied `.xpr` with Vivado 2020. See
[the simulation recovery record](lab_simulation_recovery.md). Those failures
are retained alongside these physical passes; neither replaces the other.

## Next small step

Proceed with **M3: UART, keypad, and OLED**. Start with UART TX and its MMIO
wrapper in Vivado simulation. Confirm the adapter and module labels before
adding peripheral wiring. The [master checklist](project_checklist.md)
tracks these steps; the [progress log](progress_log.md) records this result.
