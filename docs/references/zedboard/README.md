# Board reference library

Imported from the user's Downloads folder on 22 October 2026. These four
files are preserved byte for byte; `manifest.json` records their original
names, source paths, sizes, and SHA-256 hashes. They are reference material,
not additional Vivado design sources.

## What each file is for

- [024608Xilinx Zynq-7000 SOC.pdf](024608Xilinx%20Zynq-7000%20SOC.pdf):
  **DS190, version 1.11.1, 2 July 2018**, 25 pages. Describes the Zynq device
  family, PS/PL structure, and device resources. Use the **Z-7020** column,
  especially Table 1 on PDF pages 2-3. It is not a board wiring guide or a
  complete electrical/timing data sheet.
- [zedboard_ug.pdf](zedboard_ug.pdf): **Hardware User's Guide, version 1.1,
  August 2012**, 38 PDF pages. Explains the board's connectors, clock,
  LEDs, OLED, power, and jumpers. Its printed page numbers are one less
  than the PDF viewer's page numbers. It describes early hardware and
  contains discrepancies discussed below.
- [constr.xdc](constr.xdc): sample pin assignments for `clk_100mhz` and
  `led[7:0]`. All nine package pins and their LVCMOS33 settings agree with
  our current demos. It has no `create_clock` timing constraint. Use the
  project's existing demo XDC when building; do not also add this sample.
- [zedboard-schematic-rev-e1-public.pdf](zedboard-schematic-rev-e1-public.pdf):
  **Digilent ZED schematic, revision E.1, 6 October 2020**, 17 sheets.
  Shows actual signal wiring, connector pin numbers, FPGA package pins,
  power rails, and component connections for that board revision.

## Pages we will use repeatedly

- Clock and LED constraints: guide section 2.5 (PDF page 20), Table 14
  (PDF page 22); schematic sheets 3, 9, and 11.
- PL Pmod pin numbers: schematic sheet 3 maps connector positions to
  signal names; sheet 9 maps those signals to FPGA package pins.
- Onboard OLED: guide Table 11 (PDF page 20); schematic sheets 6 and 9.
- USB-UART versus USB-JTAG: guide sections 2.3.2-2.3.3 (PDF pages 13-14);
  schematic sheets 7 and 10 establish the UART-to-PS connection.
- Buttons/switches and bank voltages: guide PDF pages 21 and 35;
  schematic sheets 3, 9, and 11.

## Discrepancies and how we handle them

1. **JA3:** guide Table 16, PDF page 25, prints **Y19**. Schematic E.1,
   sheet 9, shows **Y10** for JA3; Y19 is VGA-VS. Our planning reference
   uses **Y10**, based on the schematic. The original PDF remains intact.
2. **Package naming:** the old guide names a CSG484 CES device. The E.1
   schematic names XC7Z020CLG484. The current Vivado project targets
   `xc7z020clg484-1`; this import does not change that target. Record the
   lab board revision and confirm its actual device before programming.
3. **VADJ default:** guide section 3.1 says 2.5 V, while its jumper table
   lists 1.8 V. Neither establishes the setting on the lab board. Read
   its actual J18 setting before assigning an I/O standard to banks 34/35.
4. **Configuration voltage:** the early guide's jumper description is
   not the E.1 wiring. E.1 sheet 11 shows bank 0 supplied by VCC3V3 and
   CFGBVS tied high through R187. Our existing `CFGBVS VCCO` and
   `CONFIG_VOLTAGE 3.3` settings agree with that schematic.

For E.1 wiring, use the E.1 schematic to resolve these conflicts. A file
named E.1 does not prove that the physical lab board is E.1. Check the
board marking during the next lab visit; obtain a matching schematic if
needed before enabling new I/O.

See [the project I/O plan](../../board_io_plan.md) for the practical
consequences and the commented constraint reference. The original manuals'
example designs and tool instructions do not replace our approved PL-only
RISC-V architecture or our Vivado GUI testing procedure.
