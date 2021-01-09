# Create project, override if exist
create_project project_1 ./prj -part xczu21dr-ffvd1156-2-e -force

# Add source files
add_files -norecurse ./hb_up2_int2.sv
update_compile_order -fileset sources_1

# Add simulation only files
add_files -fileset sim_1 -norecurse ./test_hb_up2_xin.txt
add_files -fileset sim_1 -norecurse ./test_hb_up2_coe.txt
add_files -fileset sim_1 -norecurse ./test_hb_up2_yout.txt
add_files -fileset sim_1 -norecurse ./test_hb_up2_ovf.txt
add_files -fileset sim_1 -norecurse ./tb_hb_up2_int2.sv
update_compile_order -fileset sim_1

# Add constrain files
add_files -fileset constrs_1 -norecurse ./hb_up2_int2_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files ./hb_up2_int2_ooc.xdc]

# Project property
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

# Run simulation
launch_simulation
run all
close_sim

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Start GUI
start_gui
