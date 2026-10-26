# Used after the AES and baseline GUI simulation sources have been added.
add_files -norecurse [list [file join $root rtl soc soc_aes.v]]
add_files -norecurse [list [file join $root rtl board aes_smoke_monitor.v] [file join $root rtl board zedboard_aes_demo.v]]
set rom_file [file join $root fw aes_smoke.hex]
add_files -norecurse [list $rom_file]
set_property file_type {Memory Initialization Files} [get_files [list $rom_file]]
foreach {simset bench relative} {sim_soc_aes tb_soc_aes cpu/tb_soc_aes.v sim_aes_board tb_aes_board board/tb_aes_board.v} {
    if {[llength [get_filesets -quiet $simset]]==0} {create_fileset -simset $simset}
    set fs [get_filesets $simset]
    set file [file join $root tb $relative]
    add_files -fileset $simset -norecurse [list $file]
    set_property file_type SystemVerilog [get_files [list $file]]
    set_property top $bench $fs
    set_property verilog_define VIVADO_GUI $fs
    set_property include_dirs [list [file join $root rtl cpu]] $fs
    set_property xsim.elaborate.debug_level typical $fs
    set_property xsim.simulate.runtime 0ns $fs
    set_property xsim.simulate.log_all_signals true $fs
    update_compile_order -fileset $fs
}
update_compile_order -fileset sources_1
set previous_xdc [get_files -quiet [list [file join $root constraints zedboard_cpu_demo.xdc]]]
if {[llength $previous_xdc]} {remove_files $previous_xdc}
add_files -fileset constrs_1 -norecurse [list [file join $root constraints zedboard_aes_demo.xdc]]
set_property top zedboard_aes_demo [get_filesets sources_1]
