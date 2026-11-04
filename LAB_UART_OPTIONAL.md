# Optional UART side test — same combined image

This test checks the real serial output of our PL-only RISC-V SoC. It needs no
extra FPGA build and does not change the JA keypad / JC OLED wiring. It is
optional if the lab has no suitable adapter. A disconnected adapter does not
stop the FPGA transmitting, and the main display demo still works.

## What to borrow

Ask for a **3.3 V logic USB-to-TTL UART adapter**, or a **Digilent PmodUSBUART**,
its USB data cable, and two jumper leads. The DLC9LP in your photo is the JTAG
programmer. The ZedBoard's onboard USB-UART is attached to the ARM/PS side;
this design transmits from the FPGA/PL on **JD pin 1 (FPGA V7)**.

A module named only "Pmod UART" is not enough to identify the wiring: check
its model and pin labels. A PmodRS232 / DB9 RS-232 cable is a different electrical
interface. Do not connect RS-232 levels or 5 V TX signals directly to our pins.

## Wiring — power off while fitting jumpers

For a generic USB-to-TTL adapter with confirmed 3.3 V logic:

- ZedBoard **JD pin 1 → adapter RX/RXD**.
- ZedBoard **JD pin 5 or 11 → adapter GND**.
- Leave adapter **TX, VCC, 5V and 3V3 disconnected** from the ZedBoard.
- Power the ZedBoard from its normal supply and the adapter from USB.

For **Digilent PmodUSBUART revision A**, use jumper wires, not direct insertion
of the module into JD:

- ZedBoard **JD pin 1 → PmodUSBUART J2 pin 2 (RXD)**.
- ZedBoard **JD pin 5 → PmodUSBUART J2 pin 5 (GND)**.
- Set its **JP1 jumper to LCL**, for an independently powered system board.
- Connect the module's micro-USB J1 to the PC. Leave J2 pins 1, 3, 4 and 6
  disconnected from the ZedBoard.

Pin numbers and LCL selection come from the
[Digilent PmodUSBUART rev. A manual](https://digilent.com/reference/_media/reference/pmod/pmodusbuart/pmodusbuart_rm.pdf).
Use that module's pin-1 marking; do not infer orientation from wire colour.
Our TX is on JD1, whereas this adapter receives on J2 pin 2, so plugging the
whole module directly into JD will not connect the required signals.

## Open a serial viewer using its GUI

1. Connect the adapter USB and open **Windows Device Manager → Ports (COM & LPT)**.
   Note the adapter's COM number. If no port appears, ask the lab technician
   for the driver for that exact adapter; do not choose the JTAG device.
2. Open an available serial viewer such as **PuTTY** or **Tera Term**. Choose
   **Serial**, select that COM port, and set **115200 baud, 8 data bits,
   no parity, 1 stop bit, no flow control**. No shell commands are needed.
3. Enable session logging if available. Our firmware sends LF after each
   line; enable "implicit CR in every LF" / LF-to-CRLF display conversion if
   the next line appears indented. This affects the viewer only.
4. Program the combined bitstream, with all keys released. **No boot banner
   is expected.** Output appears only after a complete 32-digit input block.

## Two short checks

- [ ] Enter `00112233445566778899AABBCCDDEEFF` on the keypad. The serial
  viewer must show one complete line:

```text
69C4E0D86A7B0430D8CDB78070B4C55A
```

- [ ] Enter 32 zeros. The next line must be:

```text
C6A13B37878F5B826F4F8162A1C8D879
```

- [ ] Compare each serial line with the two OLED lines joined together.
- [ ] Try a partial block: no new serial line until digit 32.
- [ ] After orderly shutdown and restart, enter another block and confirm
  exactly one new line. If doing the ten-block test, capture all ten lines.

The hardware uses 868 clocks/bit at 100 MHz: about 115207 baud. Each line is
32 uppercase hex characters plus one LF, 33 frames total, 8N1. This is TX-only;
typing into the serial viewer will not send input to the RISC-V program.

## If it does not work

- **OLED correct, serial blank:** confirm COM port, JD1-to-RX mapping, shared
  ground, no flow control, and that a full block was entered after opening
  the viewer. If available, a scope/logic analyzer should see idle high and
  approximately 8.68 microseconds per bit on JD1 during output.
- **Unreadable characters:** check 115200/8N1, 3.3 V logic and the ground.
- **LD7 on:** save a photo and the first failing operation. This is a CPU or
  firmware fault indication, not simply a missing USB adapter. Reprogram
  only after recording the failure; use orderly OLED shutdown first when
  the running firmware can still respond.

Save the adapter model, wiring photo, COM settings and received text. Mark
this test **not run** if no suitable adapter is available; do not block the
keypad/AES/OLED acceptance test on it.
