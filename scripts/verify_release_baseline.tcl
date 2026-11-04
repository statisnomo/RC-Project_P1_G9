# Maintainer regression of all 20 previously passed lab benches, unchanged IDs.
set root [file normalize [file join [file dirname [info script]] ..]]
set lab_project_name release_regression_[pid]
set lab_keep_open 1
source [file join $root scripts create_vivado_gui_project.tcl]
foreach f [glob [file join $root rtl peripherals *.v]] {
    if {![llength [get_files -quiet [list $f]]]} {add_files -norecurse [list $f]}
}
add_lab_sim sim_keypad_aes tb_keypad_aes board/tb_keypad_aes.v
add_lab_sim sim_oled_pattern tb_oled_pattern board/tb_oled_pattern.v
set rom [file join $root fw keypad_aes.hex]
add_files -fileset sim_keypad_aes -norecurse [list $rom [file join $root tb peripherals keypad_matrix_model.v]]
set_property file_type {Memory Initialization Files} [get_files -of_objects [get_filesets sim_keypad_aes] [list $rom]]
set out [get_property DIRECTORY [current_project]]
set name [get_property NAME [current_project]]
set evidence [file join $root evidence release_regression_2026-11-05]
file mkdir $evidence
set summary {}
foreach fs {sim_1 sim_regfile sim_imm_gen sim_decode sim_memories sim_cpu_core sim_soc_minimal
    sim_alu_board sim_cpu_board sim_aes_primitives sim_aes_core sim_aes_mmio sim_soc_aes sim_aes_board
    sim_uart_tx sim_uart_mmio sim_keypad_scanner sim_keypad_mmio sim_keypad_aes sim_oled_pattern} {
    set top [get_property TOP [get_filesets $fs]]
    current_fileset -simset [get_filesets $fs]
    launch_simulation -simset $fs -mode behavioral
    run all
    close_sim
    set log [file join $out ${name}.sim $fs behav xsim simulate.log]
    set fd [open $log];set contents [read $fd];close $fd
    if {[regexp {Fatal:|\mFAIL\M} $contents] || ![regexp [format {(?m)^PASS %s:[^\r\n]*} $top] $contents line]} {error "Regression failed: $top"}
    file copy -force $log [file join $evidence ${top}.log]
    lappend summary $line
}
set fd [open [file join $evidence summary.txt] w]
puts $fd "Vivado [version -short]: all 20 baseline lab simulations passed locally."
puts $fd [join $summary \n]
close $fd
close_project
puts "RELEASE_BASELINE_PASS"
