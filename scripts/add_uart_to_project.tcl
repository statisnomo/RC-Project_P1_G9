# Shared by fresh-project creation and the updater. A project is open.
set uart_rtl [list [file join $root rtl peripherals uart_tx.v] \
                   [file join $root rtl peripherals uart_mmio.v]]
foreach source_file $uart_rtl {
    if {![llength [get_files -quiet [list $source_file]]]} {
        add_files -norecurse [list $source_file]
    }
}
set_property file_type Verilog [get_files $uart_rtl]
foreach {simset bench} {sim_uart_tx tb_uart_tx sim_uart_mmio tb_uart_mmio} {
    if {![llength [get_filesets -quiet $simset]]} { create_fileset -simset $simset }
    set fs [get_filesets $simset]
    foreach name [list $bench uart_line_checker] {
        set source_file [file join $root tb peripherals ${name}.v]
        if {![llength [get_files -quiet -of_objects $fs [list $source_file]]]} {
            add_files -fileset $simset -norecurse [list $source_file]
        }
        set_property file_type SystemVerilog [get_files -of_objects $fs [list $source_file]]
    }
    set_property top $bench $fs
    set_property xsim.elaborate.debug_level typical $fs
    set_property xsim.simulate.runtime 0ns $fs
    set_property xsim.simulate.log_all_signals true $fs
    update_compile_order -fileset $fs
}
update_compile_order -fileset sources_1
