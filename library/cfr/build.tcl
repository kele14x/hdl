# Create project, override if exist
create_project project_1 ./prj -part xczu49dr-ffvf1760-2lvi-i -force

# Add source files
add_files -norecurse ./../cdc/cdc_array_single.sv
add_files -norecurse ./../cdc/cdc_async_rst_sync.sv
add_files -norecurse ./../cfr_hardclipping/cfr_hardclipping.sv
add_files -norecurse ./../cfr_pc/cfr_pc.sv
add_files -norecurse ./../cfr_pc/cfr_pc_cpg.sv
add_files -norecurse ./../cfr_pc/cfr_pc_pd.sv
add_files -norecurse ./../cfr_pc/cfr_pc_softclipper.sv
add_files -norecurse ./../cmult/cmult.sv
add_files -norecurse ./../cordic_cart2pol/cordic_cart2pol.sv
add_files -norecurse ./../cordic_pol2cart/cordic_pol2cart.sv
add_files -norecurse ./../cordic_rotate/cordic_rotate.sv
add_files -norecurse ./../hb_up2/hb_up2.sv
add_files -norecurse ./../ram/bram_sdp.sv
add_files -norecurse ./../ram/bram_sdp_pipe.sv
add_files -norecurse ./../ram/bram_sp.sv
add_files -norecurse ./../ram/bram_sp_pipe.sv
add_files -norecurse ./../util/adder.sv
add_files -norecurse ./../util/reg_pipeline.sv
add_files -norecurse ./cfr.sv
add_files -norecurse ./cfr_branch.sv
update_compile_order -fileset sources_1

# Add constrain files
add_files -fileset constrs_1 -norecurse ./cfr_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files ./cfr_ooc.xdc]

# Project property
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
set_property -name {STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY} -value {none} -objects [get_runs synth_1]

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Start GUI
start_gui
