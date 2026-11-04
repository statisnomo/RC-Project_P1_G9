# Internal development run. Existing lab projects and their products are untouched.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build display_candidate run_[pid]]
set evidence [file join $root evidence display_candidate_2026-11-04]
file mkdir $evidence
create_project display_candidate $out -part xc7z020clg484-1
foreach dir {cpu mem crypto peripherals} {add_files -norecurse [glob [file join $root rtl $dir *.v]]}
foreach path {cpu/cpu_defs.vh soc/soc_minimal.v soc/soc_display.v board/zedboard_display.v} {
    add_files -norecurse [list [file join $root rtl $path]]
}
set_property include_dirs [list [file join $root rtl cpu]] [get_filesets sources_1]
set_property top zedboard_display [get_filesets sources_1]
set rom [file join $root fw display.hex]
add_files -norecurse [list $rom]
set_property file_type {Memory Initialization Files} [get_files [list $rom]]
add_files -fileset constrs_1 -norecurse [list [file join $root constraints zedboard_display.xdc]]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
foreach top {tb_oled_access tb_display_system tb_display_board} {
    set fs [create_fileset -simset sim_$top]
    add_files -fileset $fs -norecurse [list [file join $root tb internal ${top}.sv] [file join $root tb peripherals keypad_matrix_model.v] $rom]
    set_property file_type {Memory Initialization Files} [get_files -of_objects $fs [list $rom]]
    set_property top $top $fs
    set_property xsim.simulate.runtime 0ns $fs
    current_fileset -simset $fs
    launch_simulation -mode behavioral
    run all
    close_sim
    set log [file join $out display_candidate.sim sim_$top behav xsim simulate.log]
    set fd [open $log];set contents [read $fd];close $fd
    if {[string first "PASS ${top}:" $contents]<0 || [regexp {Fatal:|\mFAIL\M} $contents]} {error "$top failed"}
    file copy -force $log [file join $evidence ${top}.log]
}
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
open_run impl_1
report_timing_summary -report_unconstrained -file [file join $evidence timing.rpt]
report_utilization -hierarchical -file [file join $evidence utilization.rpt]
report_io -file [file join $evidence pins.rpt]
report_drc -file [file join $evidence drc.rpt]
foreach delay {max min} {
    set paths [get_timing_paths -delay_type $delay -max_paths 1]
    if {![llength $paths]} {error "No $delay timing paths"}
    set slack($delay) [get_property SLACK $paths]
    if {$slack($delay)<0} {error "Routed $delay failed: $slack($delay)"}
}
if {[llength [get_drc_violations -quiet -filter {SEVERITY == Error || SEVERITY == "Critical Warning"}]]} {error "DRC failed"}
if {[llength [get_cells -hier -filter {REF_NAME =~ LD*}]]} {error "Latches inferred"}
foreach memory {rom ram} {
    if {![llength [get_cells -hier -filter "NAME =~ soc/system/$memory/* && REF_NAME =~ RAMB*"]]} {error "Missing $memory BRAM"}
}
file copy -force [file join [get_property DIRECTORY [get_runs impl_1]] zedboard_display.bit] [file join $root build display_candidate zedboard_display.bit]
set fd [open [file join $evidence summary.txt] w]
puts $fd "Vivado [version -short], 100MHz. Setup $slack(max) ns; hold $slack(min) ns. Three simulations passed. Physical test pending."
close $fd
close_project
puts "DISPLAY_CANDIDATE_PASS"
