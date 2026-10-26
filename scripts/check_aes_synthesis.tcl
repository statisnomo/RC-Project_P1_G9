# Standalone engineering estimate. This is not a routed SoC/board build.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build aes_synthesis]
file mkdir $out
create_project -in_memory -part xc7z020clg484-1
read_verilog [glob [file join $root rtl crypto *.v]]
synth_design -top aes128_core -part xc7z020clg484-1 -mode out_of_context
create_clock -period 10.000 -name aes_clk [get_ports clk]
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -file [file join $out timing_synth.rpt]
report_timing -from [all_registers -clock aes_clk] -to [all_registers -clock aes_clk] -max_paths 10 -file [file join $out register_paths.rpt]
set latches [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]
if {[llength $latches]} { error "Unexpected inferred AES latches: $latches" }
set paths [get_timing_paths -from [all_registers -clock aes_clk] -to [all_registers -clock aes_clk] -max_paths 1]
if {[llength $paths] == 0} { error "No constrained AES register-to-register timing path" }
set slack [get_property SLACK [lindex $paths 0]]
set stream [open [file join $out summary.txt] w]
puts $stream "AES-128 standalone out-of-context synthesis; Vivado [version -short]"
puts $stream "Device: xc7z020clg484-1; clock constraint: 10.000 ns"
puts $stream "Inferred latches: 0"
puts $stream "Estimated worst register-to-register setup slack: $slack ns"
puts $stream "Pre-route estimate only. Top-level I/O delays are intentionally unspecified."
puts $stream "This does not establish routed timing or board operation; CPU/MMIO integration is pending."
close $stream
write_checkpoint -force [file join $out aes128_core_synth.dcp]
puts "AES_SYNTHESIS_COMPLETE: register setup estimate $slack ns; no latches"
close_project
