# Maintenance verification; users run these same saved sim sets using GUI buttons.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build aes_tests]
file mkdir $out
open_project [file join $root vivado riscv_soc_lab riscv_soc_lab.xpr]
# In relocation mode verify the saved project as delivered, without repairing it.
if {![llength $argv] || [lindex $argv 0] ne "relocated"} {
    source [file join $root scripts add_aes_to_project.tcl]
    source [file join $root scripts add_cpu_aes_to_project.tcl]
}
set pairs {sim_aes_primitives tb_aes_primitives}
if {[llength $argv] && [lindex $argv 0] eq "mmio"} {
    set pairs {sim_aes_mmio tb_aes_mmio}
}
if {[llength $argv] && [lindex $argv 0] eq "integration"} {
    set pairs {sim_aes_mmio tb_aes_mmio sim_soc_aes tb_soc_aes sim_aes_board tb_aes_board}
}
if {[llength $argv] && [lindex $argv 0] eq "soc"} {
    set pairs {sim_soc_aes tb_soc_aes sim_cpu_board tb_cpu_board}
}
if {[llength $argv] && [lindex $argv 0] eq "board"} {
    set pairs {sim_aes_board tb_aes_board sim_soc_aes tb_soc_aes}
}
if {[llength $argv] && [lindex $argv 0] eq "core"} {
    set pairs {sim_aes_core tb_aes128_core sim_cpu_board tb_cpu_board}
}
if {[llength $argv] && [lindex $argv 0] eq "relocated"} {
    set pairs {
        sim_1 tb_alu sim_regfile tb_regfile sim_imm_gen tb_imm_gen sim_decode tb_decode
        sim_memories tb_memories sim_cpu_core tb_cpu_core sim_soc_minimal tb_soc_minimal
        sim_alu_board tb_alu_selftest sim_cpu_board tb_cpu_board
        sim_aes_primitives tb_aes_primitives sim_aes_core tb_aes128_core
        sim_aes_mmio tb_aes_mmio sim_soc_aes tb_soc_aes sim_aes_board tb_aes_board
    }
    foreach source_file [get_files -all] {
        set resolved [file normalize $source_file]
        if {![file exists $resolved] || [string first "${root}/" $resolved] != 0} {
            error "Relocated project has a missing or external source: $resolved"
        }
    }
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
        error "AES GUI test did not pass: $simset"
    }
    file copy -force $log_path [file join $out ${bench}.log]
    lappend summary $pass_line
}
current_fileset -simset [get_filesets sim_aes_primitives]
close_project
puts [join $summary "\n"]
set stream [open [file join $out gui_summary.txt] w]
puts $stream [join $summary "\n"]
puts $stream "AES_GUI_PASS"
close $stream
puts "AES_GUI_PASS"
