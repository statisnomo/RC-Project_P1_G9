# Maintainer: verify the same GUI projects and run products supplied to the lab.
set kind [lindex $argv 0]
if {$kind ni {oled keypad}} {error "Choose oled or keypad"}
set root [file normalize [file join [file dirname [info script]] ..]]
set evidence [file join $root evidence week_2026-11-03 $kind]
file mkdir $evidence
source [file join $root scripts create_${kind}_board_project.tcl]
set name [get_property NAME [current_project]]
set dir [get_property DIRECTORY [current_project]]
set simlist [expr {$kind eq "oled" ? "sim_oled_pattern" : "sim_keypad_aes sim_keypad_scanner sim_keypad_mmio"}]
foreach simset $simlist {
    set bench [get_property top [get_filesets $simset]]
    current_fileset -simset [get_filesets $simset]
    launch_simulation -simset $simset -mode behavioral
    run all
    close_sim
    set log [file join $dir ${name}.sim $simset behav xsim simulate.log]
    set fd [open $log]; set result [read $fd]; close $fd
    if {[string first "PASS ${bench}:" $result]<0 || [regexp {Fatal:|\mFAIL\M} $result]} {error "Simulation failed: $simset"}
    file copy -force $log [file join $evidence ${bench}.log]
}
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation failed"}
open_run impl_1
foreach delay {max min} {
    set path [get_timing_paths -delay_type $delay -max_paths 1]
    if {![llength $path]} {error "No $delay path"}
    set slack($delay) [get_property SLACK $path]
    if {$slack($delay)<0} {error "Routed $delay timing failed: $slack($delay)"}
}
report_drc -file [file join $evidence drc.rpt]
if {[llength [get_drc_violations -quiet -filter {SEVERITY == Error || SEVERITY == "Critical Warning"}]]} {error "DRC failed"}
report_io -file [file join $evidence pins.rpt]
report_timing_summary -file [file join $evidence timing.rpt]
set artifact [file join $root build $lab_board_top]
file mkdir $artifact
file copy -force [file join [get_property DIRECTORY [get_runs impl_1]] ${lab_board_top}.bit] [file join $artifact ${lab_board_top}.bit]
puts "LAB_IMAGE_PASS $kind setup=$slack(max) hold=$slack(min)"
close_project
