# Run with the project open and root pointing to this extracted source tree.
source [file join $root scripts check_simulation_data.tcl]
proc register_lab_data {simset path} {
    set fs [get_filesets $simset]
    if {![llength [get_files -quiet -of_objects $fs [list $path]]]} {
        add_files -fileset $simset -norecurse [list $path]
    }
    set_property file_type {Memory Initialization Files} [get_files -of_objects $fs [list $path]]
    set_property used_in_simulation true [get_files -of_objects $fs [list $path]]
}
foreach simset {sim_cpu_core sim_memories sim_soc_minimal sim_aes_core sim_aes_mmio sim_soc_aes sim_aes_board} {
    set fs [get_filesets $simset]
    set definitions [get_property verilog_define $fs]
    if {[lsearch -exact $definitions VIVADO_GUI] < 0} { lappend definitions VIVADO_GUI }
    set_property verilog_define $definitions $fs
}
foreach simset {sim_cpu_core sim_soc_minimal sim_aes_core sim_aes_mmio sim_soc_aes} {
    set fs [get_filesets $simset]
    set include_paths [get_property include_dirs $fs]
    lappend include_paths [file join $root tb common]
    set_property include_dirs [lsort -unique $include_paths] $fs
    set guard [file join $root tb common sim_data_check.vh]
    if {![llength [get_files -quiet -of_objects $fs [list $guard]]]} {
        add_files -fileset $simset -norecurse [list $guard]
    }
}
foreach extension {hex trace bus regs ram} {
    foreach path [glob [file join $root tb programs *.$extension]] {
        register_lab_data sim_cpu_core $path
    }
}
foreach simset {sim_aes_core sim_aes_mmio} {
    register_lab_data $simset [file join $root tb crypto vectors aes128_kat.mem]
}
# Register ROMs directly in their simulation sets as well as in sources_1.
foreach simset {sim_memories sim_soc_minimal sim_cpu_board} {
    register_lab_data $simset [file join $root fw cpu_smoke.hex]
}
foreach simset {sim_soc_aes sim_aes_board} {
    register_lab_data $simset [file join $root fw aes_smoke.hex]
}
foreach fs [get_filesets -filter {FILESET_TYPE == SimulationSrcs}] {
    update_compile_order -fileset $fs
}
