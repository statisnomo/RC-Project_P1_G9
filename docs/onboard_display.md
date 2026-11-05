# Onboard OLED variant

`zedboard_display_onboard` wraps the existing `zedboard_display` without
changing the CPU, firmware, AES, keypad, OLED MMIO or UART implementation.
It exposes the same board signals except CS: DISP1 CS# is wired permanently
low on the ZedBoard. The unused internal CS output is left unconnected;
the new XDC maps the remaining display signals to the six dedicated pins.
JA remains the keypad connector; JD1 remains optional UART TX.

The pin map was checked against Digilent's
[master XDC](https://raw.githubusercontent.com/Digilent/digilent-xdc/master/Zedboard-Master.xdc).
The archived E.1 schematic, sheet 6, was rendered and visually checked for
CS tied low and active-low P-channel power switches. The revision-D hardware
guide and the vendor's revision-D schematic identify the same OLED interface;
the actual lab board is Rev D. Digilent's
[reference OLED controller](https://github.com/Digilent/Zedboard-OLED/blob/master/src/hdl/OLEDCtrl.v)
also exposes six OLED signals and describes SSD1306 commands. No vendor HDL
was copied into this wrapper.

Test 27, `tb_display_onboard`, checks the actual wrapper through the physical
pin interface. Its receiver has no CS input: every group of eight SCLK edges
must decode to the expected command or pixel byte, with stable D/C throughout
the byte. It checks both ciphertext frames, two startup clears, orderly
power-off, a partial chord release that must remain off, and a new block after
restart. UART is decoded at the production divider of 868. Only display and
keypad delays are shortened, including a test-only discharge parameter override.

The seven display tests run before implementation in
`scripts/build_display_onboard.tcl`. The script requires positive setup/hold
slack, no DRC errors/critical warnings, no latches and inferred ROM/RAM BRAM.
`scripts/package_onboard_lab.py` checks the implemented pin report against
the onboard constraints and verifies there is no CS output before packaging.
This is a separate image and ZIP; the physically passed external-display
image remains byte-for-byte preserved.

The new physical acceptance procedure is [LAB_ONBOARD_OLED.md](../LAB_ONBOARD_OLED.md).
The November 5 local Vivado 2025.2 run passed all seven simulations and
implementation at 100 MHz: setup +0.241 ns, hold +0.106 ns; 3,562 LUTs,
2,509 flip-flops, two RAMB36s, no DSPs. There are no DRC errors or critical
warnings; the expected PL-only ZPS7-1 warning remains. Reports and source
hashes are in `evidence/display_onboard_2026-11-05/`.
The built-in display has not yet been physically tested with this image.
UART hardware remains untested too. The external Pmod OLED ciphertext pass
on November 5 is recorded separately and is not counted as an onboard pass.
