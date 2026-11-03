set root [file normalize [file join [file dirname [info script]] ..]]
set keypad_out [file join $root build keypad_mmio_tests]
file mkdir $keypad_out
open_project [file join $root vivado riscv_soc_lab riscv_soc_lab.xpr]
source [file join $root scripts add_keypad_to_project.tcl]
foreach {simset bench} {sim_keypad_mmio tb_keypad_mmio sim_keypad_scanner tb_keypad_scanner sim_soc_minimal tb_soc_minimal} {
    current_fileset -simset [get_filesets $simset]
    launch_simulation -simset $simset -mode behavioral
    run all
    close_sim
    set log_path [file join $root vivado riscv_soc_lab riscv_soc_lab.sim $simset behav xsim simulate.log]
    set stream [open $log_path r]; set contents [read $stream]; close $stream
    if {[regexp {\mFAIL\M} $contents] || [string first "PASS ${bench}:" $contents] < 0} {
        error "Keypad-step regression failed: $simset"
    }
    file copy -force $log_path [file join $keypad_out ${bench}.log]
}
current_fileset -simset [get_filesets sim_keypad_scanner]
close_project
create_project -in_memory -part xc7z020clg484-1
read_verilog [list [file join $root rtl peripherals keypad_scanner.v] [file join $root rtl peripherals keypad_mmio.v]]
synth_design -top keypad_mmio -part xc7z020clg484-1 -mode out_of_context
create_clock -name keypad_clk -period 10 [get_ports clk]
report_utilization -file [file join $keypad_out utilization.rpt]
report_timing -from [all_registers -clock keypad_clk] -to [all_registers -clock keypad_clk] -max_paths 5 -file [file join $keypad_out register_paths.rpt]
if {[llength [get_cells -quiet -hier -filter {REF_NAME =~ LD*}]]} { error "Keypad inferred latches" }
set paths [get_timing_paths -from [all_registers -clock keypad_clk] -to [all_registers -clock keypad_clk] -max_paths 1]
if {![llength $paths]} { error "Missing keypad register timing path" }
set slack [get_property SLACK [lindex $paths 0]]
if {$slack < 0} { error "Keypad preliminary register timing failed: $slack" }
set stream [open [file join $keypad_out summary.txt] w]
puts $stream "Vivado [version -short]; keypad MMIO, scanner and minimal SoC simulations passed."
puts $stream "Keypad default-parameter out-of-context synthesis: no latches; 100 MHz register setup estimate $slack ns."
puts $stream "Pre-route only. CPU integration, board constraints and physical keypad tests remain pending."
close $stream
close_project
puts "KEYPAD_MMIO_STEP_PASS"
