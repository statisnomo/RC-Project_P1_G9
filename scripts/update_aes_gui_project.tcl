set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root vivado riscv_soc_lab riscv_soc_lab.xpr]
source [file join $root scripts add_aes_to_project.tcl]
source [file join $root scripts add_cpu_aes_to_project.tcl]
current_fileset -simset [get_filesets sim_aes_primitives]
close_project
puts "AES_GUI_READY"
