# Developer validation of the saved project/filesets opened by the GUI.
# Run against a relocated source copy to check portable project references.
set root [file normalize [file join [file dirname [info script]] ..]]
set copy_root [file join $root build vivado_gui_validation riscv_soc_project]
set project_dir [file join $copy_root vivado riscv_soc_lab]
open_project [file join $project_dir riscv_soc_lab.xpr]
set summary {}
set resume_remaining [expr {[llength $argv] > 0 && [lindex $argv 0] eq "remaining"}]
foreach {simset bench} {
    sim_1 tb_alu
    sim_regfile tb_regfile
    sim_imm_gen tb_imm_gen
    sim_decode tb_decode
    sim_memories tb_memories
    sim_cpu_core tb_cpu_core
    sim_soc_minimal tb_soc_minimal
    sim_alu_board tb_alu_selftest
    sim_cpu_board tb_cpu_board
} {
    # On a retry after a data-path change, retain the four unaffected block runs.
    if {!$resume_remaining || $simset ni {sim_1 sim_regfile sim_imm_gen sim_decode}} {
        puts "GUI_TEST_START: $simset"
        current_fileset -simset [get_filesets $simset]
        launch_simulation -simset $simset -mode behavioral
        run all
        close_sim
    }
    set log_path [file join $project_dir riscv_soc_lab.sim $simset behav xsim simulate.log]
    set stream [open $log_path r]
    set contents [read $stream]
    close $stream
    set pattern [format {(?m)^PASS %s:[^\r\n]*} $bench]
    if {[regexp {\mFAIL\M} $contents] || ![regexp $pattern $contents pass_line]} {
        error "GUI project simulation did not pass: $simset; inspect $log_path"
    }
    lappend summary $pass_line
    puts "GUI_TEST_PASS: $simset"
}
current_fileset -simset [get_filesets sim_1]
close_project
set output [file join $root build vivado_gui_validation gui_test_summary.txt]
set stream [open $output w]
puts $stream "Vivado 2025.2 project-mode simulations, relocated project; 22 October 2026"
puts $stream [join $summary "\n"]
puts $stream "GUI_PROJECT_PASS: all 9 simulation sets"
close $stream
puts "GUI_PROJECT_PASS: all 9 simulation sets; $output"
