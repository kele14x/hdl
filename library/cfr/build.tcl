# Create project, override if exist
create_project project_1 ./prj -part xczu21dr-ffvd1156-2-e -force

# Add source files
add_files -norecurse ./../axi4l_ipif/axi4l_ipif_top.sv
add_files -norecurse ./../cfr_hardclipping/cfr_hardclipping.sv
add_files -norecurse ./../cmult/cmult.sv
add_files -norecurse ./../cordic_cart2pol/cordic_cart2pol.sv
add_files -norecurse ./../cordic_pol2cart/cordic_pol2cart.sv
add_files -norecurse ./../cordic_rotate/cordic_rotate.sv
add_files -norecurse ./../cordic_rotate/cordic_rotate.sv
add_files -norecurse ./../hb_up2/hb_up2_int2.sv
add_files -norecurse ./../pc_cfr/pc_cfr.sv
add_files -norecurse ./../pc_cfr/pc_cfr_cpg.sv
add_files -norecurse ./../pc_cfr/pc_cfr_pd.sv
add_files -norecurse ./../pc_cfr/pc_cfr_softclipper.sv
add_files -norecurse ./../util/adder.sv
add_files -norecurse ./../util/bram_sdp.sv
add_files -norecurse ./../util/reg_pipeline.sv
add_files -norecurse ./cfr.sv
add_files -norecurse ./cfr_branch.sv
add_files -norecurse ./cfr_ipif_mux.sv
add_files -norecurse ./cfr_regs.sv
update_compile_order -fileset sources_1

# Add constrain files
add_files -fileset constrs_1 -norecurse ./cfr_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files ./cfr_ooc.xdc]

# Project property
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Start GUI
start_gui