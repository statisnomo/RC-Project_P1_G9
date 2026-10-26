# Synthesis-only check. No pins, placement, bitstream, or timing-closure claim.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build cpu_synthesis]
file mkdir $out
create_project -in_memory -part xc7z020clg484-1
set_property include_dirs [list [file join $root rtl cpu]] [current_fileset]
foreach source {cpu/alu cpu/regfile cpu/decode cpu/imm_gen cpu/cpu_core mem/instr_rom mem/data_ram soc/soc_minimal} {
    read_verilog [list [file join $root rtl ${source}.v]]
}
# Use a local ROM name: Vivado generic parsing is sensitive to spaces in paths.
file copy -force [file join $root fw cpu_smoke.hex] [file join $out cpu_smoke.hex]
set clock_file [file join $out clock.xdc]
set clock_handle [open $clock_file w]
puts $clock_handle {create_clock -name cpu_clock -period 10 [get_ports clk]}
close $clock_handle
read_xdc [list $clock_file]
synth_design -top soc_minimal -part xc7z020clg484-1 -flatten_hierarchy none -generic ROM_FILE=cpu_smoke.hex
report_utilization -hierarchical -file [file join $out utilization.rpt]
report_timing_summary -file [file join $out timing_estimate.rpt]
write_checkpoint -force [file join $out synthesized.dcp]
set rom_brams [get_cells -hierarchical -filter {NAME =~ rom/* && REF_NAME =~ RAMB*}]
set ram_brams [get_cells -hierarchical -filter {NAME =~ ram/* && REF_NAME =~ RAMB*}]
if {[llength $rom_brams] == 0 || [llength $ram_brams] == 0} {
    error "Expected BRAM in both ROM and data RAM; inspect synthesis log"
}
set latches [get_cells -quiet -hierarchical -filter {REF_NAME =~ LD*}]
if {[llength $latches] != 0} { error "Unexpected inferred latches: $latches" }
puts "SYNTH_PASS: ROM BRAMs=[llength $rom_brams], RAM BRAMs=[llength $ram_brams], no inferred latches"
