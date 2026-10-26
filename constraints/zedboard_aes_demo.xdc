# CPU-plus-AES demo: same fixed-voltage clock/LED pins as the original demos.
# https://github.com/Digilent/digilent-xdc/blob/master/Zedboard-Master.xdc
# Rechecked 2026-10-22 against the user's constr.xdc and E.1 schematic,
# sheets 3, 9, 11. Originals: docs/references/zedboard/; no pin changes.
# Future I/O: docs/board_io_plan.md. Do not load the sample XDC alongside this.
set_property PACKAGE_PIN Y9 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]
create_clock -name pl_clock -period 10.000 [get_ports clk_100mhz]
set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property PACKAGE_PIN U14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[*]}]
# Only human-visible outputs lack a receiving clock; CPU/RAM paths remain timed.
set_false_path -to [get_ports {led[*]}]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
