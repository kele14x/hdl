# Create project, override if exist
create_project project_1 ./prj -part xczu21dr-ffvd1156-2-e -force

# Add source files
add_files -norecurse ./../cdc/cdc_array_single.sv
add_files -norecurse ./../cmult/cmult.sv
add_files -norecurse ./../cordic_cart2pol/cordic_cart2pol.sv
add_files -norecurse ./../cordic_pol2cart/cordic_pol2cart.sv
add_files -norecurse ./../cordic_rotate/cordic_rotate.sv
add_files -norecurse ./../hb_up2/hb_up2.sv
add_files -norecurse ./../util/adder.sv
add_files -norecurse ./../util/bram_sdp.sv
add_files -norecurse ./../util/reg_pipeline.sv
add_files -norecurse ./pc_cfr_cpg.sv
add_files -norecurse ./pc_cfr_softclipper.sv
add_files -norecurse ./pc_cfr_pd.sv
add_files -norecurse ./pc_cfr.sv
update_compile_order -fileset sources_1

# Add simulation only files
add_files -fileset sim_1 -norecurse ./test_pc_cfr_cancellation_pulse_i.txt
add_files -fileset sim_1 -norecurse ./test_pc_cfr_cancellation_pulse_q.txt
add_files -fileset sim_1 -norecurse ./test_pc_cfr_data_i_in.txt
add_files -fileset sim_1 -norecurse ./test_pc_cfr_data_q_in.txt
add_files -fileset sim_1 -norecurse ./test_pc_cfr_data_i_out.txt
add_files -fileset sim_1 -norecurse ./test_pc_cfr_data_q_out.txt
add_files -fileset sim_1 -norecurse ./tb_pc_cfr.sv
update_compile_order -fileset sim_1

# Add constrain files
add_files -fileset constrs_1 -norecurse ./pc_cfr_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files ./pc_cfr_ooc.xdc]

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
