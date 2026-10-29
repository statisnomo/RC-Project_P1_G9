# UART TX interface and register contract

Defined **27 October 2026**, before implementation. This peripheral uses
the approved UART window at **0x40000300-0x400003ff**. It sends debug bytes
from the PL to a computer through an external serial adapter.

## Serial format

- **115200 baud, 8 data bits, no parity, one stop bit (8N1).**
- Idle is high. Each frame is a low start bit, data bits 0 through 7,
  then a high stop bit. There is no RX or hardware flow control.
- One clock domain: the 100 MHz PL clock. A clock-enable counter holds
  each bit for **868 clocks**, giving 115207.37 baud (about +0.0064%).
  A ten-bit frame takes **8680 clocks / 86.8 microseconds**.
- `CLKS_PER_BIT` is a positive integer parameter, default 868; use short
  values in accelerated tests. It does not configure the clock frequency.

The framing follows [Microchip's USART frame description](https://onlinedocs.microchip.com/oxy/GUID-173AD72D-41FE-4760-A93C-7078A02BD908-en-US-7.1.1/GUID-585072A2-2328-4EDD-B24F-E2E7672632B5.html).
The divider and register choices are our project conventions.

## Transmitter ports

`uart_tx` takes `clk`, synchronous active-high `rst`, `start`, and an
eight-bit `data` byte. It produces `tx`, `busy`, and a one-clock `done` pulse.

A rising edge with START high and BUSY low captures the byte, drives the
start bit, and raises BUSY. Later changes to DATA cannot alter that frame.
START while BUSY is high is ignored, including the edge that finishes the
stop bit. There is no queue. BUSY clears and DONE pulses only after the
complete stop-bit duration. A new byte can be accepted on the next edge.
Holding START high therefore requests another byte whenever idle.

Reset wins over START and completion. It aborts a frame, drives TX high,
and clears BUSY/DONE. A receiver may see a partial character during reset;
firmware must send a new complete message afterwards.

## CPU-visible registers

`uart_mmio` has the same completion-based bus ports and size encodings as
[AES MMIO](aes_mmio.md), plus `tx` and `busy` outputs.

- **Offset 0x00, TXDATA:** reads zero. A successful write with byte lane 0
  enabled sends `wdata[7:0]`. Nonzero reserved bits 31:8 in enabled lanes
  are errors. A zero-strobe write or a zero write only to upper lanes is
  a no-op. Sending the byte zero is a real transmission.
- **Offset 0x04, STAT:** read-only. Bit 0 is BUSY; bit 1 is READY (the
  inverse of BUSY). Bits 31:2 are zero. Idle/reset reads as `0x00000002`;
  transmitting reads as `0x00000001`. Reads have no side effects.
- All other offsets are reserved and return errors.

Firmware polls STAT bit 0 until clear, then stores a byte to TXDATA.
There is one transmitter and no FIFO. A nonempty TXDATA write while busy
completes with an error and sends nothing, even on the final stop-bit edge.
No-op writes remain successful while busy. A new write can succeed once
BUSY is low at its completion edge.

Requests are held stable until VALID and READY are both high on a rising
edge. That edge alone can start a frame. `WAIT_CYCLES`, at least one,
adds fixed response wait edges; it does not stretch a transfer until the
UART is idle. Address, data, and access checks are registered during the
wait. BUSY is evaluated live at completion. Continuous VALID can carry a
new transaction after each completion; it is not deduplicated.

Reads return the containing 32-bit register word; the CPU selects the
requested byte/halfword. Halfword/word alignment, access-size/strobe rules,
cancel-before-completion, and reset priority match AES. Out-of-window
addresses, invalid sizes/strobes, misalignment, reserved offsets/bits,
and all STAT writes are errors. Failed accesses return zero and cannot
start a frame. Read data/error are meaningful only at completion.

## Physical connection boundary

Planning assumes an adapter is obtainable, as agreed with the user.
Its exact model and logic voltage remain unconfirmed. Ask for a
**USB-to-TTL UART adapter with 3.3 V logic, RX and GND pins**, plus jumper
wires. For an example of that device class, see
[FTDI's 3.3 V UART cable](https://ftdichip.com/products/ttl-232r-3v3/).
Check signal voltage, not just a pin labelled 3V3 or a power jumper.

The future connection is FPGA TX to adapter RX, and board ground to
adapter GND. The board uses its own supply; do not connect adapter VCC
or TX for this transmit-only test. The candidate PL pin is JC1/AB7,
subject to the [board I/O plan](board_io_plan.md) and actual adapter check.
This step enables no new board pins and supplies no UART bitstream.
