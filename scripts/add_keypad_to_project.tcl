# Scanner-only increment; the CPU/MMIO connection is a later step.
set scanner_file [file join $root rtl peripherals keypad_scanner.v]
if {![llength [get_files -quiet [list $scanner_file]]]} {
    add_files -norecurse [list $scanner_file]
}
if {![llength [get_filesets -quiet sim_keypad_scanner]]} {
    create_fileset -simset sim_keypad_scanner
}
set fs [get_filesets sim_keypad_scanner]
foreach name {tb_keypad_scanner keypad_matrix_model} {
    set path [file join $root tb peripherals ${name}.v]
    if {![llength [get_files -quiet -of_objects $fs [list $path]]]} {
        add_files -fileset $fs -norecurse [list $path]
    }
    set_property file_type SystemVerilog [get_files -of_objects $fs [list $path]]
}
set_property top tb_keypad_scanner $fs
set_property xsim.simulate.runtime 0ns $fs
set_property xsim.elaborate.debug_level typical $fs
set_property xsim.simulate.log_all_signals true $fs
update_compile_order -fileset sources_1
update_compile_order -fileset $fs
set event_file [file join $root rtl peripherals keypad_mmio.v]
if {![llength [get_files -quiet [list $event_file]]]} { add_files -norecurse [list $event_file] }
if {![llength [get_filesets -quiet sim_keypad_mmio]]} { create_fileset -simset sim_keypad_mmio }
set fs [get_filesets sim_keypad_mmio]
foreach name {tb_keypad_mmio keypad_matrix_model} {
    set path [file join $root tb peripherals ${name}.v]
    if {![llength [get_files -quiet -of_objects $fs [list $path]]]} { add_files -fileset $fs -norecurse [list $path] }
    set_property file_type SystemVerilog [get_files -of_objects $fs [list $path]]
}
set_property top tb_keypad_mmio $fs
set_property xsim.simulate.runtime 0ns $fs
set_property xsim.elaborate.debug_level typical $fs
set_property xsim.simulate.log_all_signals true $fs
update_compile_order -fileset sources_1
update_compile_order -fileset $fs
