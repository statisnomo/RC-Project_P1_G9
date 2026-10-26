# Builds an image only; never connects to or programs hardware.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build zedboard_aes_demo]
file mkdir $out
cd $out
create_project -in_memory -part xc7z020clg484-1
set_property include_dirs [list [file join $root rtl cpu]] [current_fileset]
foreach source {cpu/alu cpu/regfile cpu/decode cpu/imm_gen cpu/cpu_core mem/instr_rom mem/data_ram soc/soc_minimal soc/soc_aes board/aes_smoke_monitor board/zedboard_aes_demo} {
    read_verilog [list [file join $root rtl ${source}.v]]
}
read_verilog [glob [file join $root rtl crypto *.v]]
file copy -force [file join $root fw aes_smoke.hex] [file join $out aes_smoke.hex]
read_xdc [list [file join $root constraints zedboard_aes_demo.xdc]]
synth_design -top zedboard_aes_demo -part xc7z020clg484-1 -flatten_hierarchy none
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
    if {[llength $worst]==0} {error "No internal $delay_type timing path"}
    set slack($delay_type) [get_property SLACK $worst]
    if {$slack($delay_type)<0} {error "$delay_type timing failed; inspect timing.rpt"}
}
foreach memory {rom ram} {
    if {[llength [get_cells -hier -filter "NAME =~ soc/system/$memory/* && REF_NAME =~ RAMB*"]]==0} {
        error "Expected $memory BRAM missing"
    }
}
foreach block {soc/system/cpu/execution_alu soc/aes/core} {
    if {[llength [get_cells -hier -filter "NAME =~ $block/*"]]==0} {error "Expected hardware missing: $block"}
}
if {[llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]} {error "Unexpected inferred latches"}
write_bitstream -force [file join $out zedboard_aes_demo.bit]
set stream [open [file join $out summary.txt] w]
puts $stream "CPU + AES, Vivado [version -short], xc7z020clg484-1, 100 MHz"
puts $stream "Routed setup slack: $slack(max) ns; hold slack: $slack(min) ns"
puts $stream "ROM/RAM BRAM, CPU ALU and AES hardware retained; no latches."
puts $stream "See drc.rpt for warnings. Physical board observation remains pending."
close $stream
puts "BUILD_PASS: [file join $out zedboard_aes_demo.bit]"
