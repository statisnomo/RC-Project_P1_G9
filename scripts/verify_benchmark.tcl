# Isolated development project; does not modify the published display projects.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root build benchmark run_[pid]]
set evidence [file join $root evidence benchmark_2026-11-05]
file mkdir $evidence
create_project benchmark $out -part xc7z020clg484-1
foreach dir {cpu mem crypto} {add_files -norecurse [glob [file join $root rtl $dir *.v]]}
foreach f {rtl/cpu/cpu_defs.vh rtl/soc/soc_minimal.v rtl/soc/soc_benchmark.v rtl/peripherals/benchmark_timer.v fw/benchmark.hex} {
    add_files -norecurse [list [file join $root $f]]
}
set_property include_dirs [list [file join $root rtl cpu]] [get_filesets sources_1]
set_property top soc_benchmark [get_filesets sources_1]
set_property file_type {Memory Initialization Files} [get_files *benchmark.hex]
set tops {tb_benchmark_timer tb_aes_benchmark tb_benchmark_recovery}
if {[lsearch -exact $argv recovery-only]>=0} {set tops {tb_benchmark_recovery}}
foreach top $tops {
    set fs [create_fileset -simset sim_$top]
    foreach f [list tb/internal/${top}.sv fw/benchmark.hex tb/internal/benchmark_vectors.mem] {
        add_files -fileset $fs -norecurse [list [file join $root $f]]
    }
    foreach pattern {*benchmark.hex *benchmark_vectors.mem} {
        set_property file_type {Memory Initialization Files} [get_files -of_objects $fs $pattern]
    }
    set_property top $top $fs
    set_property xsim.simulate.runtime 0ns $fs
    current_fileset -simset $fs
    launch_simulation -mode behavioral
    run all
    close_sim
    set log [file join $out benchmark.sim sim_$top behav xsim simulate.log]
    set fd [open $log];set content [read $fd];close $fd
    if {[string first "PASS ${top}:" $content]<0 || [regexp {Fatal:|\mFAIL\M} $content]} {error "$top failed"}
    file copy -force $log [file join $evidence ${top}.log]
}
close_project
puts "BENCHMARK_VERIFIED"
