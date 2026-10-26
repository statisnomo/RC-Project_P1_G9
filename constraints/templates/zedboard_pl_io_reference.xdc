# REFERENCE ONLY. Every constraint below is intentionally commented out.
# Source: docs/references/zedboard/zedboard-schematic-rev-e1-public.pdf
# E.1 sheets 3, 6, 9, 11. See docs/board_io_plan.md for decisions/limitations.
# This file is NOT in the Vivado project's active constraints set.
# Check the physical board revision and module manual before using any group.
# Copy selected lines to a new design-specific XDC; rename placeholder ports
# to the real top-level ports, then uncomment only the selected constraints.
# The existing demos already constrain the Y9 clock and eight user LEDs.

# JA / bank 13 / fixed 3.3 V. ja[0:7] follows header positions 1,2,3,4,7,8,9,10.
# JA3 is Y10 on E.1 sheet 9. The 2012 guide's Table 16 prints Y19 incorrectly
# for this wiring; Y19 is VGA-VS in the E.1 schematic.
# set_property PACKAGE_PIN Y11  [get_ports {ja[0]}]
# set_property PACKAGE_PIN AA11 [get_ports {ja[1]}]
# set_property PACKAGE_PIN Y10  [get_ports {ja[2]}]
# set_property PACKAGE_PIN AA9  [get_ports {ja[3]}]
# set_property PACKAGE_PIN AB11 [get_ports {ja[4]}]
# set_property PACKAGE_PIN AB10 [get_ports {ja[5]}]
# set_property PACKAGE_PIN AB9  [get_ports {ja[6]}]
# set_property PACKAGE_PIN AA8  [get_ports {ja[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {ja[*]}]

# JB / bank 13 / fixed 3.3 V. Header positions 1,2,3,4,7,8,9,10.
# set_property PACKAGE_PIN W12 [get_ports {jb[0]}]
# set_property PACKAGE_PIN W11 [get_ports {jb[1]}]
# set_property PACKAGE_PIN V10 [get_ports {jb[2]}]
# set_property PACKAGE_PIN W8  [get_ports {jb[3]}]
# set_property PACKAGE_PIN V12 [get_ports {jb[4]}]
# set_property PACKAGE_PIN W10 [get_ports {jb[5]}]
# set_property PACKAGE_PIN V9  [get_ports {jb[6]}]
# set_property PACKAGE_PIN V8  [get_ports {jb[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {jb[*]}]

# JC / bank 13 / fixed 3.3 V. Header positions 1,2,3,4,7,8,9,10.
# Nets: JC1_P, JC1_N, JC2_P, JC2_N, JC3_P, JC3_N, JC4_P, JC4_N.
# set_property PACKAGE_PIN AB7 [get_ports {jc[0]}]
# set_property PACKAGE_PIN AB6 [get_ports {jc[1]}]
# set_property PACKAGE_PIN Y4  [get_ports {jc[2]}]
# set_property PACKAGE_PIN AA4 [get_ports {jc[3]}]
# set_property PACKAGE_PIN R6  [get_ports {jc[4]}]
# set_property PACKAGE_PIN T6  [get_ports {jc[5]}]
# set_property PACKAGE_PIN T4  [get_ports {jc[6]}]
# set_property PACKAGE_PIN U4  [get_ports {jc[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {jc[*]}]

# JD / bank 13 / fixed 3.3 V. Header positions 1,2,3,4,7,8,9,10.
# Nets: JD1_P, JD1_N, JD2_P, JD2_N, JD3_P, JD3_N, JD4_P, JD4_N.
# set_property PACKAGE_PIN V7 [get_ports {jd[0]}]
# set_property PACKAGE_PIN W7 [get_ports {jd[1]}]
# set_property PACKAGE_PIN V5 [get_ports {jd[2]}]
# set_property PACKAGE_PIN V4 [get_ports {jd[3]}]
# set_property PACKAGE_PIN W6 [get_ports {jd[4]}]
# set_property PACKAGE_PIN W5 [get_ports {jd[5]}]
# set_property PACKAGE_PIN U6 [get_ports {jd[6]}]
# set_property PACKAGE_PIN U5 [get_ports {jd[7]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {jd[*]}]

# On each Pmod: 5/11 = GND, 6/12 = 3.3 V. Never assign these as FPGA signals.
# JE is PS MIO; it is excluded from our PL-only peripheral mapping.
# Provisional UART TX candidate: JC pin 1 / AB7 -> 3.3 V adapter RX.
# If naming AB7 uart_tx instead of jc[0], replace that mapping; do not add both.

# BUILT-IN OLED ONLY: these pins do not connect to the external Pmod OLED.
# Bank 13 / fixed 3.3 V. CS is tied low on board; no FPGA CS port exists.
# Power switch controls are active low; sequencing is still required.
# set_property PACKAGE_PIN AA12 [get_ports oled_sdin]
# set_property PACKAGE_PIN AB12 [get_ports oled_sclk]
# set_property PACKAGE_PIN U10  [get_ports oled_dc]
# set_property PACKAGE_PIN U9   [get_ports oled_res_n]
# set_property PACKAGE_PIN U12  [get_ports oled_vdd_en_n]
# set_property PACKAGE_PIN U11  [get_ports oled_vbat_en_n]
# set_property IOSTANDARD LVCMOS33 [get_ports {oled_sdin oled_sclk oled_dc oled_res_n oled_vdd_en_n oled_vbat_en_n}]

# Optional PL buttons: BANK 34 / VADJ, active high when pressed.
# IOSTANDARD intentionally NOT supplied: inspect J18 and match VADJ first.
# set_property PACKAGE_PIN P16 [get_ports btn_c]
# set_property PACKAGE_PIN T18 [get_ports btn_u]
# set_property PACKAGE_PIN R16 [get_ports btn_d]
# set_property PACKAGE_PIN N15 [get_ports btn_l]
# set_property PACKAGE_PIN R18 [get_ports btn_r]

# Optional switches: SW0-SW6 bank 35, SW7 bank 34; both banks use VADJ.
# IOSTANDARD intentionally NOT supplied: inspect J18 and match VADJ first.
# set_property PACKAGE_PIN F22 [get_ports {sw[0]}]
# set_property PACKAGE_PIN G22 [get_ports {sw[1]}]
# set_property PACKAGE_PIN H22 [get_ports {sw[2]}]
# set_property PACKAGE_PIN F21 [get_ports {sw[3]}]
# set_property PACKAGE_PIN H19 [get_ports {sw[4]}]
# set_property PACKAGE_PIN H18 [get_ports {sw[5]}]
# set_property PACKAGE_PIN H17 [get_ports {sw[6]}]
# set_property PACKAGE_PIN M15 [get_ports {sw[7]}]

# This is a pin reference, not a timing-complete peripheral constraint file.
# Add interface-specific timing only after the controller timing is defined.
