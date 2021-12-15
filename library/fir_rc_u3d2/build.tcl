# Create project, override if exist
create_project project_1 ./prj -part xczu21dr-ffvd1156-2-e -force

# Add source files
add_files -norecurse ./fir_rc_u3d2.sv
update_compile_order -fileset sources_1

# Add simulation only files
add_files -fileset sim_1 -norecurse ./test_fir_rc_u3d2_input_xin.txt
add_files -fileset sim_1 -norecurse ./test_fir_rc_u3d2_input_coe.txt
add_files -fileset sim_1 -norecurse ./test_fir_rc_u3d2_output_yout.txt
add_files -fileset sim_1 -norecurse ./test_fir_rc_u3d2_output_ovf.txt
add_files -fileset sim_1 -norecurse ./tb_fir_rc_u3d2.sv
update_compile_order -fileset sim_1

# Add constrain files
add_files -fileset constrs_1 -norecurse ./fir_rc_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files ./fir_rc_ooc.xdc]

# Project property
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY} -value {none} -objects [get_runs synth_1]

# Run simulation
launch_simulation
run all
close_sim

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Start GUI
start_gui
