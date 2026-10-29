set root [file normalize [file join [file dirname [info script]] ..]]
open_project [file join $root vivado riscv_soc_lab riscv_soc_lab.xpr]
source [file join $root scripts add_uart_to_project.tcl]
current_fileset -simset [get_filesets sim_uart_tx]
close_project
puts "UART_GUI_READY"
