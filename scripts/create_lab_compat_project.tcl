# Lab GUI entry point: Tools > Run Tcl Script, with other projects closed.
# Creates a project in the currently running Vivado version. Does not
# downgrade an XPR, change RTL, or replace a previously generated project.
if {[llength [get_projects -quiet]]} {
    error "Close the current project with File > Project > Close, then run this script again."
}
set root [file normalize [file join [file dirname [info script]] ..]]
source [file join $root scripts check_simulation_data.tcl]
set lab_project_name riscv_soc_lab_compat
set suffix 1
while {[file exists [file join $root vivado $lab_project_name]]} {
    set lab_project_name riscv_soc_lab_compat_$suffix
    incr suffix
}
set lab_keep_open 1
source [file join $root scripts create_vivado_gui_project.tcl]
current_fileset -simset [get_filesets sim_cpu_core]
set report_path [file join [get_property DIRECTORY [current_project]] setup_report.txt]
set stream [open $report_path w]
puts $stream "Project created by Vivado [version -short]"
puts $stream "Source root: $root"
puts $stream "Project: $project_file"
puts $stream "128 simulation data files checked for word count and hex format."
puts $stream "16 simulation sets; active: sim_cpu_core."
puts $stream "Run the five reported failing tests first: 6 CPU, 7 minimal SoC, 11 AES core, 12 AES MMIO, 13 CPU/AES."
puts $stream "Project creation is not a simulation PASS. Save the actual test results."
close $stream
puts "LAB_COMPAT_PROJECT_READY: $project_file"
puts "Lab users: Run Simulation > Run Behavioral Simulation, then Run All."
