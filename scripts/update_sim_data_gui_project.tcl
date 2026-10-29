set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root vivado riscv_soc_lab riscv_soc_lab.xpr]
source [file join $root scripts configure_lab_simulation_data.tcl]
current_fileset -simset [get_filesets sim_cpu_core]
close_project
puts "SIM_DATA_GUI_UPDATED"
