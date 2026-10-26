# PL-only CPU smoke demonstration; generates a file, never programs hardware.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build zedboard_cpu_demo]
file mkdir $out
create_project -in_memory -part xc7z020clg484-1
set_property include_dirs [list [file join $root rtl cpu]] [current_fileset]
foreach source {cpu/alu cpu/regfile cpu/decode cpu/imm_gen cpu/cpu_core mem/instr_rom mem/data_ram soc/soc_minimal board/cpu_smoke_monitor board/zedboard_cpu_demo} {
    read_verilog [list [file join $root rtl ${source}.v]]
}
file copy -force [file join $root fw cpu_smoke.hex] [file join $out cpu_smoke.hex]
read_xdc [list [file join $root constraints zedboard_cpu_demo.xdc]]
synth_design -top zedboard_cpu_demo -part xc7z020clg484-1 -flatten_hierarchy none
opt_design
place_design
phys_opt_design
route_design
report_utilization -hierarchical -file [file join $out utilization.rpt]
report_timing_summary -report_unconstrained -file [file join $out timing.rpt]
report_timing -max_paths 10 -file [file join $out critical_paths.rpt]
report_drc -file [file join $out drc.rpt]
write_checkpoint -force [file join $out routed.dcp]
foreach delay_type {max min} {
    set worst [get_timing_paths -delay_type $delay_type -max_paths 1 -nworst 1]
    if {[llength $worst] == 0} { error "No internal $delay_type timing path found" }
    if {[get_property SLACK $worst] < 0} { error "$delay_type timing failed; inspect timing.rpt" }
}
foreach memory {rom ram} {
    set blocks [get_cells -hierarchical -filter "NAME =~ soc/$memory/* && REF_NAME =~ RAMB*"]
    if {[llength $blocks] == 0} { error "Expected $memory BRAM was optimized away" }
}
set alu_cells [get_cells -hierarchical -filter {NAME =~ soc/cpu/execution_alu/*}]
if {[llength $alu_cells] == 0} { error "CPU ALU was optimized away" }
set latches [get_cells -quiet -hierarchical -filter {REF_NAME =~ LD*}]
if {[llength $latches] != 0} { error "Unexpected latches: $latches" }
write_bitstream -force [file join $out zedboard_cpu_demo.bit]
puts "BUILD_PASS: [file join $out zedboard_cpu_demo.bit]"
