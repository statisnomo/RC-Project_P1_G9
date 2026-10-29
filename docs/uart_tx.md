# UART: our next small Vivado test

Status: **UART transmitter and MMIO simulations passed on 27 October 2026**.
The ALU, CPU, and CPU/AES board passes are recorded in
[the lab results](lab_results_2026-10-27.md). UART is the next independent
piece of the machine. This step needs **Vivado only; no board or adapter**.

## What these files do

The CPU will write one character to a register. The UART turns that byte
into a timed sequence of high and low levels on one wire. A USB serial
adapter will turn that sequence back into readable characters on the PC.

- [`uart_tx.v`](../rtl/peripherals/uart_tx.v) sends the bits and keeps BUSY
  high until the character's stop bit finishes.
- [`uart_mmio.v`](../rtl/peripherals/uart_mmio.v) gives the CPU a TXDATA
  register at `0x40000300` and a status register at `0x40000304`.
  Firmware waits for idle, then writes its next byte.
- [`tb_uart_tx.v`](../tb/peripherals/tb_uart_tx.v) exercises the transmitter,
  including every possible byte, real baud timing, busy starts, and reset.
- [`tb_uart_mmio.v`](../tb/peripherals/tb_uart_mmio.v) acts as a bus master
  to test writes, reads, waits, rejected accesses, cancellation, and reset.
- [`uart_line_checker.v`](../tb/peripherals/uart_line_checker.v) independently
  checks the actual TX wire against the expected character and bit duration.
  It does not read the transmitter's internal shift register or counter.

The complete [interface contract](uart_interface.md) explains byte lanes,
register errors, timing, and reset. There is no receive logic or FIFO in
this first version. The existing CPU/AES board image still uses its original
top; connecting UART to the CPU and generating a UART board image are later steps.

## Test 1: send the letter A

1. Open the current `vivado/riscv_soc_lab/riscv_soc_lab.xpr` in Vivado.
   This revision has **16 simulation sets**. The older, original October 27
   lab ZIP has 14; use the new UART-step ZIP or the updated project for this test.
2. Open **Simulation Settings**. Select **sim_uart_tx**, top **tb_uart_tx**.
3. Click **Run Simulation > Run Behavioral Simulation**.
4. In **Scopes**, expand `tb_uart_tx` and select **real_baud**. In **Objects**,
   select `clk`, `rst`, `start`, `data`, `tx`, `busy`, and `done`; right-click
   and choose **Add to Wave Window**. Set `data` to hexadecimal radix.
5. Click **Run All**. Read the automatic result in the Tcl Console pane;
   you do not type commands. Expect:

   `PASS tb_uart_tx: 4 dividers, 840 complete frames, 40 reset aborts`

6. Zoom to **0-90 microseconds** in `real_baud`. START accepts `data=41`
   (the letter A) at **45 ns**. TX goes low for the start bit. Then it sends
   **1, 0, 0, 0, 0, 0, 1, 0**, followed by the high stop bit.
   Each bit lasts **8.68 microseconds**. At **86.845 microseconds**, BUSY
   clears and DONE pulses for one 10 ns clock.
7. Save the PASS line and waveform. Tick **P13** in the master checklist.

The test deliberately changes DATA and asserts START while BUSY. Those
changes must not corrupt A. Other instances run faster divisors to cover
all byte values quickly. The complete test runs about 3.1 ms of simulated
time, so use **Run All**, not just the fixed-duration Run button.

## Test 2: send through the CPU-style bus

1. Close the simulation and select **sim_uart_mmio**, top **tb_uart_mmio**.
2. Run **Behavioral Simulation**, then select `tb_uart_mmio/short_wait`.
3. Add `valid`, `ready`, `write`, `addr`, `wdata`, `wstrb`, `size`,
   `rdata`, `error`, `busy`, and `tx` to the waveform.
4. Click **Run All**. Expect:

   `PASS tb_uart_mmio: waits 1/4, 564 complete frames, 20 reset aborts`

5. Inspect the first TXDATA write: `addr=40000300`, `wdata=00000041`.
   TX must start only on the rising clock edge where VALID and READY are
   both high. A later attempted B write while BUSY returns an error and
   does not replace A. Status reads as `1` while busy and `2` while idle.
6. Save the PASS line and waveform. Tick **P14** in the checklist.

This test uses eight clocks per serial bit to run quickly; Test 1 also
checks the real divider of 868. An `error=1` in the deliberate invalid
access tests is expected. The overall PASS line decides the test result.

## Saved engineering result

Both tests passed in Vivado 2025.2. The CPU and CPU/AES board simulations
were rerun successfully after adding the UART simulation sets. See
[saved logs, waves, and source hashes](../evidence/uart_m3_2026-10-27/README.md).

Standalone synthesis of UART plus MMIO used **55 LUTs, 37 flip-flops,
zero BRAM/DSP, and zero latches**. Its register-to-register setup estimate
is **+6.368 ns** for a 10 ns clock. This is a pre-route estimate; it does
not establish a routed UART board design or physical serial reception.

## What to ask for at the lab

Ask for **a USB-to-TTL UART adapter with 3.3 V logic, RX and GND pins,
plus jumper wires**. It may look like a small USB board or a cable ending
in labeled wires. [FTDI's 3.3 V UART cable](https://ftdichip.com/products/ttl-232r-3v3/)
is one example of the device class, not a requirement to buy that model.

The planned receive-only hookup is our FPGA TX to adapter RX, plus a
common ground. We will check the actual adapter's model, signal voltage,
and labels before wiring. Its availability is assumed for planning, as
requested. See [the interface connection notes](uart_interface.md#physical-connection-boundary).

The next controller is the **keypad scanner**: it will produce exactly
one key event for a press, including bounce and held-key tests. UART,
keypad, and OLED each get an independent test before full integration.
