# Shared by fresh-project creation and the updater below. A project is open.
set aes_rtl [glob [file join $root rtl crypto *.v]]
add_files -norecurse $aes_rtl
set_property file_type Verilog [get_files $aes_rtl]
foreach {simset bench} {sim_aes_primitives tb_aes_primitives sim_aes_core tb_aes128_core sim_aes_mmio tb_aes_mmio} {
    if {[llength [get_filesets -quiet $simset]] == 0} { create_fileset -simset $simset }
    set fs [get_filesets $simset]
    set bench_file [file join $root tb crypto ${bench}.v]
    add_files -fileset $simset -norecurse [list $bench_file]
    add_files -fileset $simset -norecurse [list [file join $root tb crypto aes_reference.vh]]
    set_property file_type SystemVerilog [get_files [list $bench_file]]
    set_property top $bench $fs
    set_property include_dirs [list [file join $root tb crypto] [file join $root tb crypto vectors]] $fs
    if {$simset in {sim_aes_core sim_aes_mmio}} {
        set vector_file [file join $root tb crypto vectors aes128_kat.mem]
        add_files -fileset $simset -norecurse [list $vector_file [file join $root tb crypto vectors aes128_vector_count.vh]]
        set_property file_type {Memory Initialization Files} [get_files [list $vector_file]]
        set_property verilog_define {VIVADO_GUI} $fs
    }
    set_property xsim.elaborate.debug_level typical $fs
    set_property xsim.simulate.runtime 0ns $fs
    set_property xsim.simulate.log_all_signals true $fs
    update_compile_order -fileset $fs
}
update_compile_order -fileset sources_1
