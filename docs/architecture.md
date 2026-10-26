# Approved system architecture

This file records the project baseline supplied on October 2, 2026.

## Hardware and datapath

- Target: Digilent ZedBoard with Zynq-7000 programmable logic; the custom
  CPU runs in the PL without using the hard ARM cores.
- Clock target: 100 MHz from the PL oscillator on Y9. The CPU smoke-demo
  routed reports show +0.221 ns setup and +0.151 ns hold slack; this does
  not establish timing for the future complete SoC. Each new build needs
  its own implementation reports.
- CPU: custom RV32I subset, three stages: Fetch, Decode, Execute/Mem/WB.
  The 37-instruction initial subset and decode interface are specified in
  [cpu_isa.md](cpu_isa.md).
- Memory: Harvard BRAM, 4 KB instruction ROM and 4 KB data RAM.
- Interconnect: lightweight memory-mapped bus with valid/ready handshaking.
- Crypto: iterative AES-128 encryption accelerator. The standalone core
  meets the desired 11–14 cycle budget with **11 clock periods from request
  acceptance to completion**, verified in simulation on October 24. It uses
  on-the-fly key expansion; earliest next acceptance is 12 periods later.
  CPU-visible latency and routed integrated timing remain to be measured.
- Peripherals: hardware Pmod KYPD scanner, SPI Pmod OLED controller
  (128x32 SSD1306), and UART TX debugging.
- Debug connections: USB/JTAG and UART.

Board wiring is recorded in [board_io_plan.md](board_io_plan.md), based on
the [uploaded reference library](references/zedboard/README.md). Provisional
connector reservations are JA for KYPD, JB for the external Pmod OLED, and
JC for a future external 3.3 V UART adapter. JA-JD use fixed 3.3 V PL bank
13; JE and the onboard USB-UART are PS connections. The board's built-in
OLED is a separately documented alternative, not a change to the approved
external-Pmod plan. Peripheral constraints are not active yet.

The demonstration enters a message using the keypad, encrypts a 128-bit
block through the CPU-controlled AES peripheral, and displays ciphertext
on the OLED. The selected first demo enters **32 hexadecimal digits** with
a fixed public demonstration key, encrypts automatically after digit 32,
and displays all 32 ciphertext digits. The clear/hex-key mapping and byte
order are recorded in [aes_interface.md](aes_interface.md).

## Address map

- `0x00000000–0x00000FFF`: 4 KB instruction ROM.
- `0x00001000–0x00001FFF`: 4 KB data RAM.
- `0x40000000–0x400000FF`: AES-128 MMIO.
- `0x40000100–0x400001FF`: KYPD controller MMIO.
- `0x40000200–0x400002FF`: OLED controller MMIO.
- `0x40000300–0x400003FF`: UART MMIO.

## AES-128 register offsets

All offsets below are relative to `0x40000000`.

- `0x00`: AES_CTRL, read/write; bit 0 START.
- `0x04`: AES_STAT, read-only; bit 0 BUSY, bit 1 DONE.
- `0x10`, `0x14`, `0x18`, `0x1C`: AES_KEY0 through AES_KEY3, read/write.
- `0x20`, `0x24`, `0x28`, `0x2C`: AES_PT0 through AES_PT3, read/write.
- `0x30`, `0x34`, `0x38`, `0x3C`: AES_CT0 through AES_CT3, read-only.

Before implementing this interface, define AES byte ordering, START pulse
semantics, DONE clearing, writes while BUSY, and behavior for reserved or
misaligned addresses. These details are not implied by the address map.

## Integration status and remaining decisions

The instruction subset is recorded in [cpu_isa.md](cpu_isa.md). The pipeline,
load/store byte lanes, precise debug-stop policy, and synchronous memories
are implemented and simulated as of October 16, 2026. The completion-based
valid/ready contract and first executable program are described in
[cpu_pipeline.md](cpu_pipeline.md). The external MMIO port routes the four
approved windows; its simulation stub is not an AES or peripheral controller.
Define the AES register semantics listed above before attaching the crypto
core and user-interface peripherals. The [paper consultation](paper_notes_mohan_2025.md)
motivates measuring accelerator latency separately from total offload cost.

October 26: [soc_aes](cpu_aes_integration.md) connects the real AES MMIO
window. The other three windows currently return access errors. Four-block
firmware, wait-state tests, reset/restart, and firmware error paths pass.
The older `soc_minimal` signature test remains a separate baseline.
