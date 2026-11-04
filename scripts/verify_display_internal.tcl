# Development only. Does not open or update either published lab project.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build display_internal run_[pid]]
create_project internal $out -part xc7z020clg484-1
foreach dir {cpu mem crypto peripherals} {
    add_files -norecurse [glob [file join $root rtl $dir *.v]]
}
foreach path {cpu/cpu_defs.vh soc/soc_display.v soc/soc_minimal.v} {
    add_files -norecurse [list [file join $root rtl $path]]
}
set_property include_dirs [list [file join $root rtl cpu]] [get_filesets sources_1]
set_property top soc_display [get_filesets sources_1]
set rom [file join $root fw display.hex]
add_files -norecurse [list $rom]
set_property file_type {Memory Initialization Files} [get_files [list $rom]]
set evidence [file join $root evidence display_internal]
file mkdir $evidence
foreach top {tb_oled_access tb_display_system} {
    set fs [create_fileset -simset sim_$top]
    foreach f [list [file join $root tb internal ${top}.sv] [file join $root tb peripherals keypad_matrix_model.v] $rom] {
        add_files -fileset $fs -norecurse [list $f]
    }
    set_property file_type {Memory Initialization Files} [get_files -of_objects $fs [list $rom]]
    set_property top $top $fs
    set_property xsim.simulate.runtime 0ns $fs
    current_fileset -simset $fs
    launch_simulation -mode behavioral
    run all
    close_sim
    set log [file join $out internal.sim sim_$top behav xsim simulate.log]
    set fd [open $log];set contents [read $fd];close $fd
    if {[string first "PASS ${top}:" $contents]<0 || [regexp {Fatal:|\mFAIL\M} $contents]} {error "$top failed: $log"}
    file copy -force $log [file join $evidence ${top}.log]
}
close_project
puts "DISPLAY_INTERNAL_PASS"
