# Maintainer verification. Users run these same sim sets with GUI buttons.
# The saved project is tested as-is; this script never adds/repairs sources.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build uart_tests]
file mkdir $out
open_project [file join $root vivado riscv_soc_lab riscv_soc_lab.xpr]
foreach source_file [get_files -all] {
    set resolved [file normalize $source_file]
    if {![file exists $resolved] || [string first "${root}/" $resolved] != 0} {
        error "Missing or external source in saved project: $resolved"
    }
}
set pairs {sim_uart_tx tb_uart_tx sim_uart_mmio tb_uart_mmio}
if {[llength $argv] && [lindex $argv 0] eq "regression"} {
    lappend pairs sim_aes_board tb_aes_board sim_cpu_board tb_cpu_board
}
set summary {}
foreach {simset bench} $pairs {
    current_fileset -simset [get_filesets $simset]
    launch_simulation -simset $simset -mode behavioral
    run all
    close_sim
    set log_path [file join $root vivado riscv_soc_lab riscv_soc_lab.sim $simset behav xsim simulate.log]
    set stream [open $log_path r]
    set contents [read $stream]
    close $stream
    set pattern [format {(?m)^PASS %s:[^\r\n]*} $bench]
    if {[regexp {\mFAIL\M} $contents] || ![regexp $pattern $contents pass_line]} {
        error "GUI test did not pass: $simset"
    }
    file copy -force $log_path [file join $out ${bench}.log]
    lappend summary $pass_line
}
current_fileset -simset [get_filesets sim_uart_tx]
close_project
set stream [open [file join $out gui_summary.txt] w]
puts $stream [join $summary "\n"]
puts $stream "UART_GUI_PASS"
close $stream
puts [join $summary "\n"]
puts "UART_GUI_PASS"
