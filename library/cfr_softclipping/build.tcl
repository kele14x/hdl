# Create project, override if exist
create_project project_1 ./prj -part xczu21dr-ffvd1156-2-e -force

# Add source files
add_files -norecurse ./../cmult/cmult.sv
add_files -norecurse ./../cordic_cart2pol/cordic_cart2pol.sv
add_files -norecurse ./../cordic_pol2cart/cordic_pol2cart.sv
add_files -norecurse ./../cordic_rotate/cordic_rotate.sv
add_files -norecurse ./../hb_up2/hb_up2_int2.sv
add_files -norecurse ./../util/adder.sv
add_files -norecurse ./../util/bram_sdp.sv
add_files -norecurse ./../util/reg_pipeline.sv
add_files -norecurse ./cfr_cpg_int2.sv
add_files -norecurse ./cfr_cpgs_int2.sv
add_files -norecurse ./cfr_pd.sv
add_files -norecurse ./cfr_softclipping.sv
update_compile_order -fileset sources_1

# Add simulation only files
add_files -fileset sim_1 -norecurse ./test_cfr_softclipping_data_i_in.txt
add_files -fileset sim_1 -norecurse ./test_cfr_softclipping_data_q_in.txt
add_files -fileset sim_1 -norecurse ./test_cfr_softclipping_data_i_out.txt
add_files -fileset sim_1 -norecurse ./test_cfr_softclipping_data_q_out.txt
add_files -fileset sim_1 -norecurse ./tb_cfr_softclipping.sv
update_compile_order -fileset sim_1

# Add constrain files
add_files -fileset constrs_1 -norecurse ./cfr_softclipping_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files ./cfr_softclipping_ooc.xdc]

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
