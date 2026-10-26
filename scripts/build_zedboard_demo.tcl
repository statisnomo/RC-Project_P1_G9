# Run with Vivado in batch mode. This builds a bitstream; it does not program a board.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build zedboard_alu_demo]
file mkdir $out
create_project -in_memory -part xc7z020clg484-1
set_property include_dirs [list [file join $root rtl cpu]] [current_fileset]
read_verilog [list [file join $root rtl cpu alu.v] \
                   [file join $root rtl board alu_selftest.v] \
                   [file join $root rtl board zedboard_alu_demo.v]]
read_xdc [list [file join $root constraints zedboard_alu_demo.xdc]]
synth_design -top zedboard_alu_demo -part xc7z020clg484-1 -flatten_hierarchy none
opt_design
place_design
phys_opt_design
route_design
report_utilization -hierarchical -file [file join $out utilization.rpt]
report_timing_summary -report_unconstrained -file [file join $out timing.rpt]
report_drc -file [file join $out drc.rpt]
write_checkpoint -force [file join $out routed.dcp]
# Fail on violated internal setup/hold constraints before generating the file.
foreach delay_type {max min} {
    set worst [get_timing_paths -delay_type $delay_type -max_paths 1 -nworst 1]
    if {[llength $worst] == 0} { error "No internal $delay_type timing path found" }
    if {[get_property SLACK $worst] < 0} { error "$delay_type timing failed; inspect timing.rpt" }
}
set alu_cells [get_cells -hierarchical -filter {NAME =~ *checked_alu/*}]
if {[llength $alu_cells] == 0} { error "ALU logic was optimized away" }
write_bitstream -force [file join $out zedboard_alu_demo.bit]
puts "BUILD_PASS: [file join $out zedboard_alu_demo.bit]"
