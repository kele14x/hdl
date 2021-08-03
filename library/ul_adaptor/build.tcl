# Create project, override if exist
create_project project_1 ./prj -part xczu19eg-ffvc1760-2-i -force

# Add source files
add_files -norecurse ./ip/ul_adaptor_ctrl_c_addsub_v12_0_i0/ul_adaptor_ctrl_c_addsub_v12_0_i0.xci
add_files -norecurse ./ip/ul_adaptor_ctrl_c_addsub_v12_0_i1/ul_adaptor_ctrl_c_addsub_v12_0_i1.xci
add_files -norecurse ./ip/ul_adaptor_ctrl_c_counter_binary_v12_0_i0/ul_adaptor_ctrl_c_counter_binary_v12_0_i0.xci
add_files -norecurse ./ip/ul_adaptor_ctrl_c_counter_binary_v12_0_i1/ul_adaptor_ctrl_c_counter_binary_v12_0_i1.xci
add_files -norecurse ./ip/ul_adaptor_ctrl_c_counter_binary_v12_0_i2/ul_adaptor_ctrl_c_counter_binary_v12_0_i2.xci
add_files -norecurse ./ip/ul_adaptor_ctrl_dist_mem_gen_i0/ul_adaptor_ctrl_dist_mem_gen_i0.xci
add_files -norecurse ./ip/ul_adaptor_ctrl_dist_mem_gen_i0_vivado.coe
add_files -norecurse ./ip/ul_adaptor_ctrl_dist_mem_gen_i1/ul_adaptor_ctrl_dist_mem_gen_i1.xci
add_files -norecurse ./ip/ul_adaptor_ctrl_dist_mem_gen_i1_vivado.coe
add_files -norecurse ./ip/ul_adaptor_data_blk_mem_gen_i0/ul_adaptor_data_blk_mem_gen_i0.vhd
add_files -norecurse ./ip/ul_adaptor_data_blk_mem_gen_i0_vivado.coe
add_files -norecurse ./ip/ul_adaptor_fram_fifo/ul_adaptor_fram_fifo.xci
add_files -norecurse ./ip/ul_adaptor_req_fifo/ul_adaptor_req_fifo.xci
add_files -norecurse ./rtl/ul_adaptor.sv
add_files -norecurse ./rtl/ul_adaptor_buf.sv
add_files -norecurse ./rtl/ul_adaptor_ctrl.vhd
add_files -norecurse ./rtl/ul_adaptor_ctrl_entity_declarations.vhd
add_files -norecurse ./rtl/ul_adaptor_data.vhd
add_files -norecurse ./rtl/ul_adaptor_data_entity_declarations.vhd
add_files -norecurse ./rtl/ul_adaptor_gearbox.sv
add_files -norecurse ./rtl/ul_adaptor_gearbox_bfp9.sv
add_files -norecurse ./rtl/ul_adaptor_gearbox_bfp9_axis.sv
add_files -norecurse ./rtl/ul_adaptor_gearbox_bfp9_comp.sv
add_files -norecurse ./rtl/ul_adaptor_gearbox_bfp9_reader.sv
add_files -norecurse ./rtl/ul_adaptor_gearbox_raw.sv
add_files -norecurse {./sysgen\ libs/conv_pkg.vhd}
add_files -norecurse {./sysgen\ libs/single_reg_w_init.vhd}
add_files -norecurse {./sysgen\ libs/srl17e.vhd}
add_files -norecurse {./sysgen\ libs/srl33e.vhd}
add_files -norecurse {./sysgen\ libs/synth_reg.vhd}
add_files -norecurse {./sysgen\ libs/synth_reg_reg.vhd}
add_files -norecurse {./sysgen\ libs/synth_reg_w_init.vhd}
add_files -norecurse {./sysgen\ libs/xlclockdriver_rd.vhd}
update_compile_order -fileset sources_1

# Add simulation only files
add_files -fileset sim_1 -norecurse ./tb/tb_ul_adaptor.sv
update_compile_order -fileset sim_1

# Add constrain files
add_files -fileset constrs_1 -norecurse ./constr/ul_adaptor_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files ./constr/ul_adaptor_ooc.xdc]

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
