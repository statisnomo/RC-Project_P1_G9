# Preliminary resource/latch check; not a routed board timing result.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build uart_synthesis]
file mkdir $out
create_project -in_memory -part xc7z020clg484-1
read_verilog [list [file join $root rtl peripherals uart_tx.v] \
                   [file join $root rtl peripherals uart_mmio.v]]
synth_design -top uart_mmio -part xc7z020clg484-1 -mode out_of_context
create_clock -name uart_clk -period 10.000 [get_ports clk]
report_utilization -file [file join $out utilization.rpt]
report_timing_summary -file [file join $out timing_synth.rpt]
report_timing -from [all_registers -clock uart_clk] -to [all_registers -clock uart_clk] \
    -max_paths 10 -file [file join $out register_paths.rpt]
set latches [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]
if {[llength $latches]} { error "Unexpected UART latches: $latches" }
set paths [get_timing_paths -from [all_registers -clock uart_clk] -to [all_registers -clock uart_clk] -max_paths 1]
if {![llength $paths]} { error "No constrained UART register path" }
set slack [get_property SLACK [lindex $paths 0]]
set stream [open [file join $out summary.txt] w]
puts $stream "UART MMIO out-of-context synthesis; Vivado [version -short]"
puts $stream "Device: xc7z020clg484-1; default divider 868; clock constraint 10.000 ns"
puts $stream "Inferred latches: 0"
puts $stream "Estimated worst register-to-register setup slack: $slack ns"
puts $stream "Pre-route estimate only; top-level I/O delays intentionally unspecified."
puts $stream "CPU integration, routed timing, and physical UART operation remain pending."
close $stream
write_checkpoint -force [file join $out uart_mmio_synth.dcp]
close_project
puts "UART_SYNTHESIS_COMPLETE: register setup estimate $slack ns; no latches"
