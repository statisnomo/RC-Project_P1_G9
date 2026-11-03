# Run a create_*_board_project entry point from the GUI with other projects closed.
if {[llength [get_projects -quiet]]} {error "Close the open project first."}
set root [file normalize [file join [file dirname [info script]] ..]]
set base [file join $root vivado]
set name ${lab_board_top}_lab
set i 1
while {[file exists [file join $base $name]]} {set name ${lab_board_top}_lab_$i; incr i}
create_project $name [file join $base $name] -part xc7z020clg484-1
set_property target_simulator XSim [current_project]
set_property target_language Verilog [current_project]
add_files -norecurse [list [file join $root rtl board ${lab_board_top}.v]]
if {$lab_board_top eq "zedboard_keypad_aes"} {
    foreach dir {cpu mem crypto} {add_files -norecurse [glob [file join $root rtl $dir *.v]]}
    foreach path {cpu/cpu_defs.vh soc/soc_minimal.v peripherals/keypad_scanner.v peripherals/keypad_mmio.v} {
        add_files -norecurse [list [file join $root rtl $path]]
    }
    set_property include_dirs [list [file join $root rtl cpu]] [get_filesets sources_1]
    set rom [file join $root fw keypad_aes.hex]
    add_files -norecurse [list $rom]
    set_property file_type {Memory Initialization Files} [get_files [list $rom]]
    source [file join $root scripts add_keypad_to_project.tcl]
    set bench tb_keypad_aes
    set fs sim_keypad_aes
    create_fileset -simset $fs
    set matrix [file join $root tb peripherals keypad_matrix_model.v]
    add_files -fileset $fs -norecurse [list $matrix]
    add_files -fileset $fs -norecurse [list $rom]
    set_property file_type {Memory Initialization Files} [get_files -of_objects [get_filesets $fs] [list $rom]]
} else {
    set bench tb_oled_pattern
    set fs sim_oled_pattern
    create_fileset -simset $fs
}
set bench_path [file join $root tb board ${bench}.v]
add_files -fileset $fs -norecurse [list $bench_path]
set_property file_type SystemVerilog [get_files -of_objects [get_filesets $fs] [list $bench_path]]
set_property top $bench [get_filesets $fs]
set_property xsim.simulate.runtime 0ns [get_filesets $fs]
current_fileset -simset [get_filesets $fs]
add_files -fileset constrs_1 -norecurse [list [file join $root constraints ${lab_board_top}.xdc]]
set_property top $lab_board_top [get_filesets sources_1]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
update_compile_order -fileset sources_1
puts "LAB_BOARD_PROJECT_READY: [get_property DIRECTORY [current_project]]"
