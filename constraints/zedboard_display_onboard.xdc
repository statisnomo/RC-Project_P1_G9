# Onboard DISP1 demo: KYPD JA, built-in OLED, optional UART JD1.
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

# JA1..4 = COL4..1; JA7..10 = ROW4..1. Module provides row pull-ups.
set_property PACKAGE_PIN Y11 [get_ports {cols_n[3]}]
set_property PACKAGE_PIN AA11 [get_ports {cols_n[2]}]
set_property PACKAGE_PIN Y10 [get_ports {cols_n[1]}]
set_property PACKAGE_PIN AA9 [get_ports {cols_n[0]}]
set_property PACKAGE_PIN AB11 [get_ports {rows_n[3]}]
set_property PACKAGE_PIN AB10 [get_ports {rows_n[2]}]
set_property PACKAGE_PIN AB9 [get_ports {rows_n[1]}]
set_property PACKAGE_PIN AA8 [get_ports {rows_n[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cols_n[*] rows_n[*]}]
# No external clock: human switch inputs feed only the first synchronizer stage.
set_false_path -from [get_ports {rows_n[*]}] -to [get_cells -hier -filter {NAME =~ *rows_meta_reg*}]
set_false_path -to [get_ports {cols_n[*]}]

set_property PACKAGE_PIN AA12 [get_ports {mosi}]
set_property PACKAGE_PIN AB12 [get_ports {sclk}]
set_property PACKAGE_PIN U10 [get_ports {dc}]
set_property PACKAGE_PIN U9 [get_ports {res_n}]
set_property PACKAGE_PIN U11 [get_ports {vbat_n}]
set_property PACKAGE_PIN U12 [get_ports {vdd_n}]
set_max_delay -datapath_only 15 -from [all_registers -clock pl_clock] -to [get_ports {mosi sclk dc res_n vbat_n vdd_n}]
set_property IOSTANDARD LVCMOS33 [get_ports {mosi sclk dc res_n vbat_n vdd_n tx}]
set_property PACKAGE_PIN V7 [get_ports tx]
set_max_delay -datapath_only 15 -from [all_registers -clock pl_clock] -to [get_ports tx]


