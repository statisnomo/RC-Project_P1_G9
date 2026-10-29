# Maintenance helper. Lab users open the generated .xpr in Vivado.
# Regenerating deliberately refuses to overwrite an existing GUI project.
set root [file normalize [file join [file dirname [info script]] ..]]
if {![info exists lab_project_name]} { set lab_project_name riscv_soc_lab }
set out [file join $root vivado $lab_project_name]
set project_file [file join $out ${lab_project_name}.xpr]
if {[file exists $project_file]} { error "Project already exists: $project_file" }
create_project $lab_project_name $out -part xc7z020clg484-1
set_property target_language Verilog [current_project]
set_property target_simulator XSim [current_project]
set_property simulator_language Mixed [current_project]
set rtl [concat [glob [file join $root rtl cpu *.v]] \
                [glob [file join $root rtl mem *.v]] \
                [glob [file join $root rtl soc *.v]] \
                [glob [file join $root rtl board *.v]]]
add_files -norecurse $rtl
add_files -norecurse [list [file join $root rtl cpu cpu_defs.vh]]
set_property include_dirs [list [file join $root rtl cpu]] [get_filesets sources_1]
set_property top zedboard_aes_demo [get_filesets sources_1]
add_files -fileset constrs_1 -norecurse [list [file join $root constraints zedboard_aes_demo.xdc]]
add_files -norecurse [list [file join $root fw cpu_smoke.hex]]
set_property file_type {Memory Initialization Files} [get_files [list [file join $root fw cpu_smoke.hex]]]
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]

proc add_lab_sim {name bench relative_file} {
    global root
    if {[llength [get_filesets -quiet $name]] == 0} { create_fileset -simset $name }
    set fs [get_filesets $name]
    set bench_file [file join $root tb $relative_file]
    add_files -fileset $name -norecurse [list $bench_file]
    set_property file_type SystemVerilog [get_files [list $bench_file]]
    set_property top $bench $fs
    set_property include_dirs [list [file join $root rtl cpu] [file join $root tb programs] [file join $root tb common]] $fs
    set_property xsim.elaborate.debug_level typical $fs
    # Open at time zero; the user selects signals then clicks Run All.
    set_property xsim.simulate.runtime 0ns $fs
    set_property xsim.simulate.log_all_signals true $fs
}
add_lab_sim sim_1 tb_alu cpu/tb_alu.v
add_lab_sim sim_regfile tb_regfile cpu/tb_regfile.v
add_lab_sim sim_imm_gen tb_imm_gen cpu/tb_imm_gen.v
add_lab_sim sim_decode tb_decode cpu/tb_decode.v
add_lab_sim sim_memories tb_memories cpu/tb_memories.v
add_lab_sim sim_cpu_core tb_cpu_core cpu/tb_cpu_core.v
add_lab_sim sim_soc_minimal tb_soc_minimal cpu/tb_soc_minimal.v
add_lab_sim sim_alu_board tb_alu_selftest board/tb_alu_selftest.v
add_lab_sim sim_cpu_board tb_cpu_board board/tb_cpu_board.v

# Vivado stages registered data files in each simulation working folder.
# Original parameter defaults still work with the standalone test runners.
foreach name {sim_memories sim_soc_minimal sim_cpu_core} {
    set_property verilog_define VIVADO_GUI [get_filesets $name]
}
add_files -fileset sim_cpu_core -norecurse [list [file join $root tb programs cases.vh]]
add_files -fileset sim_cpu_core -norecurse [list [file join $root tb common sim_data_check.vh]]
set vectors {}
foreach extension {hex trace bus regs ram} {
    set vectors [concat $vectors [glob [file join $root tb programs *.$extension]]]
}
add_files -fileset sim_cpu_core -norecurse $vectors
set_property file_type {Memory Initialization Files} [get_files $vectors]
source [file join $root scripts add_aes_to_project.tcl]
source [file join $root scripts add_cpu_aes_to_project.tcl]
source [file join $root scripts add_uart_to_project.tcl]
source [file join $root scripts configure_lab_simulation_data.tcl]
update_compile_order -fileset sources_1
foreach fs [get_filesets -filter {FILESET_TYPE == SimulationSrcs}] {
    update_compile_order -fileset $fs
}
current_fileset -simset [get_filesets sim_uart_tx]
if {![info exists lab_keep_open] || !$lab_keep_open} { close_project }
unset -nocomplain lab_project_name lab_keep_open
puts "GUI_PROJECT_READY: $project_file"
