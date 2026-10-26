# ZedBoard I/O plan

Reviewed on 22 October 2026 against the four files in
[the board reference library](references/zedboard/README.md). This plan
records board wiring now so later peripheral work uses checked pins.
Physical board revision and peripheral module revisions remain to be
recorded at the lab.

## The current demos need no pin changes

The ALU, CPU, and October 26 CPU/AES demos use the same nine external signals:

- `clk_100mhz`: package pin **Y9**, bank 13, LVCMOS33.
- `led[0]` through `led[7]`: **T22, T21, U22, U21, V22, W22, U19, U14**,
  respectively, bank 33, LVCMOS33. A high signal turns an LED on.

These match the uploaded sample XDC and E.1 schematic sheets 3 and 9.
The current demo constraints also set a **10.000 ns clock period** and
configuration voltage. Their timing exception applies only to the
human-visible LEDs; do not copy it to an entire future peripheral bus.

The supplied XDC only locates pins and sets their electrical standard.
Locating a clock pin does not tell Vivado its frequency. Keep the
`create_clock` line in our demo XDC files.

No functional RTL or active constraint commands changed during this review.
Existing simulation and routed timing reports still describe the same
design. The review itself is not a new simulation, timing run, or physical
board test.

## Which connectors we can use

The four **JA, JB, JC, and JD** Pmod headers connect to **PL bank 13**,
which is fixed at **3.3 V**. They suit our custom RISC-V peripherals using
LVCMOS33. The **JE** header connects to **PS MIO**, so it is outside the
current PL-only design. Source: schematic sheets 3, 9-11 and guide
section 2.9.2.

Each Pmod has signal positions **1, 2, 3, 4, 7, 8, 9, 10**. Positions
**5 and 11 are ground**; **6 and 12 supply 3.3 V**. These physical header
positions are different from FPGA package pin names such as Y11.
Use the header's pin-1 mark to establish orientation.

The following are provisional connector reservations, not implemented
peripheral wiring:

- **JA:** reserve eight signals for the Pmod KYPD.
- **JB:** reserve signals for the external Pmod OLED in the approved plan.
- **JC:** reserve a signal and ground for future UART TX observation.
- **JD:** leave available for later debug or expansion.

The corresponding FPGA pins, in signal-position order
**1, 2, 3, 4, 7, 8, 9, 10**, are:

- **JA:** Y11, AA11, **Y10**, AA9, AB11, AB10, AB9, AA8.
- **JB:** W12, W11, V10, W8, V12, W10, V9, V8.
- **JC:** AB7, AB6, Y4, AA4, R6, T6, T4, U4.
- **JD:** V7, W7, V5, V4, W6, W5, U6, U5.

JC/JD use paired P/N net names in the schematic. The sequence above is
the physical connector order from sheet 3, not the row order of the old
guide's differential-net table. JA3 uses **Y10**, correcting the old
guide's Y19 entry for the E.1 wiring.

[The commented XDC reference](../constraints/templates/zedboard_pl_io_reference.xdc)
contains these mappings with placeholder port names. It is not loaded
into the Vivado project. Before enabling a peripheral, check its own
module manual and map its rows/columns or SPI/control signals onto the
chosen header positions. The uploaded board documents do not establish
the external module's signal order, scan timing, or display initialization.

## There are two different OLED wiring options

The approved project uses an **external Pmod OLED**, provisionally on JB.
That remains the plan. The ZedBoard also has a **built-in 128x32 OLED**,
which could be used later if we explicitly choose that option.

The built-in display has these separate bank-13 connections:

- Serial data: **AA12**.
- Serial clock: **AB12**.
- Data/command: **U10**.
- Active-low reset: **U9**.
- Logic-supply switch control: **U12**, low enables the supply.
- Panel/DC-DC supply switch control: **U11**, low enables the supply.

Its chip select is tied low on the board. The U11/U12 signals drive
P-channel power-switch gates; they are control signals, not power outputs
from the FPGA. Source: schematic sheets 6 and 9; guide Table 11.
Power sequencing and reset delays still require the display's own
controller documentation before implementation. Do not apply these
built-in-display pins to an external Pmod OLED.

## UART debugging needs a PL connection

The onboard USB-UART connector **J14** connects through the bridge and
level shifter to **PS MIO48/49**, not directly to PL GPIO. Assigning those
package pins to our Verilog UART is not the connection we need. Source:
guide section 2.3.2; schematic sheets 7 and 10.

For the future PL UART TX, reserve **JC position 1 / package AB7** as a
candidate. A compatible external **3.3 V logic USB-UART adapter** would
receive this signal on its **RX**, with a common ground. TX-only debug
does not require an adapter TX connection. Confirm the adapter's logic
voltage and pin labels before wiring; RS-232 voltage levels are unsuitable
for a direct FPGA connection. No UART pin is active in the current demos.

The programming/debug USB-JTAG connector is **J17**, as stated in guide
section 2.3.3. JTAG programming remains the current board-test path.

## Buttons and switches use a different supply

Buttons and switches use banks 34/35, powered by **VADJ**. They do not
inherit the Pmods' fixed 3.3 V setting. Check J18 on the actual board
before choosing LVCMOS18, LVCMOS25, or LVCMOS33 for those banks.

- PL buttons: centre P16, up T18, down R16, left N15, right R18;
  all are in bank 34. They read high when pressed.
- Switches SW0-SW7: F22, G22, H22, F21, H19, H18, H17, M15.
  SW0-SW6 are in bank 35; SW7 is in bank 34.

Source: schematic sheets 3, 9, and 11; guide Tables 12-13.
Future external inputs need synchronization and button/keypad debouncing.
Keep the current automatic startup reset until a conditioned user reset
is implemented and tested. PROG is a configuration control, not our CPU's
synchronous reset input.

## FPGA resources and architecture

DS190 Table 1, PDF page 3, lists the Z-7020 with **53,200 LUTs, 106,400
flip-flops, 140 blocks of 36 Kb RAM, and 220 DSP slices**. This describes
available silicon resources, not the resources our design has already used.
Our memories remain 4 KB instruction ROM plus 4 KB data RAM in PL BRAM.
The board's external DDR3 and the ARM processing system are not added to
the custom CPU's memory map by importing these references.

DS190 also lists boot/configuration security features. Our AES-128 block
is a separate custom PL accelerator; those device
features are not a substitute for that milestone.

## Use this in Vivado

For the current tests, open the existing `.xpr` and follow
[VIVADO_START_HERE.md](../VIVADO_START_HERE.md). Keep only
`zedboard_aes_demo.xdc` in the updated GUI project's active constraints set.
The separate ALU and CPU builds retain their own XDC files.

When a new peripheral's top-level ports and unit test are ready:

1. Check the lab board revision and the module's connector orientation.
2. Copy only the required lines from the commented reference into the
   new top-level design's own XDC. Rename the placeholder ports to match
   the Verilog ports, then uncomment those selected lines.
3. In Vivado, use **Add Sources > Add or Create Constraints** to add the
   new design's XDC. Keep only the intended constraint file enabled.
4. Use **Open Elaborated Design** and the **I/O Planning** layout to inspect
   the port names, directions, package pins, banks, and I/O standards.
5. After simulation passes, run synthesis and implementation. Review DRC,
   unconstrained paths, and setup/hold timing before generating a bitstream.

Do not add the uploaded sample XDC or the entire reference template to
the active project. Interface timing constraints will be added when the
corresponding controller's real timing is defined.
