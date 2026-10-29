# Maintainer verification of the new local-version creator and data guards.
# By default, create a fresh project using exactly the lab GUI entry script.
# With an XPR argument, verify that saved project without modifying sources.
set root [file normalize [file join [file dirname [info script]] ..]]
set recovery_out [file join $root build lab_recovery_tests]
file mkdir $recovery_out
if {[llength $argv]} {
    open_project [lindex $argv 0]
} else {
    source [file join $root scripts create_lab_compat_project.tcl]
}
set project_dir [get_property DIRECTORY [current_project]]
set project_name [get_property NAME [current_project]]
foreach source_file [get_files -all] {
    set resolved [file normalize $source_file]
    if {![file exists $resolved] || [string first "${root}/" $resolved] != 0} {
        error "Missing or external project source: $resolved"
    }
}
set summary {}
set pairs {
    sim_cpu_core tb_cpu_core sim_soc_minimal tb_soc_minimal sim_aes_core tb_aes128_core
    sim_aes_mmio tb_aes_mmio sim_soc_aes tb_soc_aes
    sim_1 tb_alu sim_regfile tb_regfile sim_imm_gen tb_imm_gen sim_decode tb_decode
    sim_memories tb_memories
    sim_alu_board tb_alu_selftest sim_cpu_board tb_cpu_board
    sim_aes_primitives tb_aes_primitives sim_aes_board tb_aes_board
    sim_uart_tx tb_uart_tx sim_uart_mmio tb_uart_mmio
}
foreach {simset bench} $pairs {
    current_fileset -simset [get_filesets $simset]
    launch_simulation -simset $simset -mode behavioral
    run all
    close_sim
    set log_path [file join $project_dir ${project_name}.sim $simset behav xsim simulate.log]
    set stream [open $log_path r]; set contents [read $stream]; close $stream
    set pattern [format {(?m)^PASS %s:[^\r\n]*} $bench]
    if {[regexp {\mFAIL\M} $contents] || ![regexp $pattern $contents pass_line]} {
        error "Recovery regression did not pass: $simset"
    }
    file copy -force $log_path [file join $recovery_out ${bench}.log]
    lappend summary $pass_line
}
# Save the deliverable project with only its sixteen normal simulation sets.
current_fileset -simset [get_filesets sim_cpu_core]
close_project
set stream [open [file join $recovery_out summary.txt] w]
puts $stream "Vivado [version -short]; sixteen simulations passed."
puts $stream [join $summary "\n"]
puts $stream "LAB_RECOVERY_SIM_PASS"
close $stream

# A separate disposable project checks the preflight's failure paths.
set diagnostic_dir [file join $recovery_out diagnostics]
if {[file exists $diagnostic_dir]} {
    set diagnostic_dir [file join $recovery_out diagnostics_[clock seconds]]
}
create_project data_diagnostics $diagnostic_dir -part xc7z020clg484-1
set bench_file [file join $root tb common tb_sim_data_check.v]
add_files -fileset sim_1 -norecurse [list $bench_file [file join $root tb common sim_data_check.vh]]
set_property file_type SystemVerilog [get_files [list $bench_file]]
set_property top tb_sim_data_check [get_filesets sim_1]
set_property include_dirs [list [file join $root tb common]] [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
set fixture_files [glob [file join $root tb common fixtures *.mem]]
add_files -fileset sim_1 -norecurse $fixture_files
set_property file_type {Memory Initialization Files} [get_files $fixture_files]
set expected_patterns [list {PASS tb_sim_data_check:} \
    {FAIL SIM_DATA cannot open 'deliberately_missing.mem'} \
    {FAIL SIM_DATA 'short.mem': expected 2 words, found 1} \
    {FAIL SIM_DATA malformed hex in 'malformed.mem'} \
    {FAIL SIM_DATA unknown hex digits in 'unknown.mem'} \
    {FAIL SIM_DATA 'valid.mem': expected 1 words, found 2}]
for {set mode 0} {$mode < 6} {incr mode} {
    set_property generic MODE=$mode [get_filesets sim_1]
    catch {launch_simulation -simset sim_1 -mode behavioral} launch_result
    catch {run all}
    catch {close_sim}
    set log_path [file join $diagnostic_dir data_diagnostics.sim sim_1 behav xsim simulate.log]
    set stream [open $log_path r]; set contents [read $stream]; close $stream
    if {[string first [lindex $expected_patterns $mode] $contents] < 0} {
        error "Diagnostic mode $mode failed to produce its expected result: $launch_result"
    }
    file copy -force $log_path [file join $recovery_out diagnostic_${mode}.log]
}
# Exercise test 7's own preflight, including a valid file that did not reach
# the DUT intact. Keep these deliberate failures out of the lab's normal sets.
set soc_sources [concat [glob [file join $root rtl cpu *.v]] \
    [glob [file join $root rtl mem *.v]] \
    [list [file join $root rtl cpu cpu_defs.vh] [file join $root rtl soc soc_minimal.v]]]
add_files -norecurse $soc_sources
set soc_benches [list [file join $root tb cpu tb_soc_minimal.v] \
    [file join $root tb common tb_soc_minimal_rom_fault.v]]
add_files -fileset sim_1 -norecurse $soc_benches
set_property file_type SystemVerilog [get_files $soc_benches]
set_property include_dirs [list [file join $root rtl cpu]] [get_filesets sources_1]
set_property include_dirs [list [file join $root rtl cpu] [file join $root tb common]] [get_filesets sim_1]
set_property verilog_define VIVADO_GUI [get_filesets sim_1]
set_property top tb_soc_minimal_rom_fault [get_filesets sim_1]
set soc_rom [file join $root fw cpu_smoke.hex]
add_files -fileset sim_1 -norecurse [list $soc_rom]
set_property file_type {Memory Initialization Files} [get_files [list $soc_rom]]
set soc_patterns [list {FAIL SIM_DATA cannot open 'deliberately_missing_soc.hex'} \
    {FAIL SIM_ROM_LOAD 'cpu_smoke.hex' word=1023 actual=00000001 expected=00000000}]
for {set mode 0} {$mode < 2} {incr mode} {
    set_property generic MODE=$mode [get_filesets sim_1]
    launch_simulation -simset sim_1 -mode behavioral
    catch {run all}
    close_sim
    set log_path [file join $diagnostic_dir data_diagnostics.sim sim_1 behav xsim simulate.log]
    set stream [open $log_path r]; set contents [read $stream]; close $stream
    if {[string first [lindex $soc_patterns $mode] $contents] < 0 ||
        [string first {PASS tb_soc_minimal:} $contents] >= 0} {
        error "Test 7 ROM diagnostic mode $mode did not reject the bad setup"
    }
    file copy -force $log_path [file join $recovery_out soc_rom_diagnostic_${mode}.log]
}
close_project
set stream [open [file join $recovery_out summary.txt] a]
puts $stream "SIM_DATA_GUARD_PASS: valid accepted; missing, short, malformed, unknown, and extra data rejected."
puts $stream "SOC_ROM_GUARD_PASS: test 7 rejects a missing ROM file and a corrupted final DUT ROM word before CPU execution."
close $stream
puts "LAB_RECOVERY_SIM_PASS: 16 simulations and 8 data-diagnostic scenarios; Vivado [version -short]"
