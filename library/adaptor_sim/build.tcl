# Create project, override if exist
create_project project_1 ./prj -part xczu19eg-ffvc1760-2-i -force

# Add source files
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_c_addsub_v12_0_i0/dl_adaptor_ctrl_c_addsub_v12_0_i0.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_c_addsub_v12_0_i1/dl_adaptor_ctrl_c_addsub_v12_0_i1.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_c_counter_binary_v12_0_i0/dl_adaptor_ctrl_c_counter_binary_v12_0_i0.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_c_counter_binary_v12_0_i1/dl_adaptor_ctrl_c_counter_binary_v12_0_i1.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_c_counter_binary_v12_0_i2/dl_adaptor_ctrl_c_counter_binary_v12_0_i2.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_c_counter_binary_v12_0_i3/dl_adaptor_ctrl_c_counter_binary_v12_0_i3.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_dist_mem_gen_i0/dl_adaptor_ctrl_dist_mem_gen_i0.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_dist_mem_gen_i0_vivado.coe
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_dist_mem_gen_i1/dl_adaptor_ctrl_dist_mem_gen_i1.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_dist_mem_gen_i1_vivado.coe
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_dist_mem_gen_i2/dl_adaptor_ctrl_dist_mem_gen_i2.xci
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_ctrl_dist_mem_gen_i2_vivado.coe
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_data_blk_mem_gen_i0/dl_adaptor_data_blk_mem_gen_i0.vhd
add_files -norecurse ./../dl_adaptor/ip/dl_adaptor_fifo/dl_adaptor_fifo.xci
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor.sv
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor_buf.sv
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor_ctrl.vhd
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor_ctrl_entity_declarations.vhd
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor_data.vhd
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor_data_entity_declarations.vhd
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor_gearbox.sv
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor_gearbox_bfp9.sv
add_files -norecurse ./../dl_adaptor/rtl/dl_adaptor_gearbox_raw.sv
add_files -norecurse {./../dl_adaptor/sysgen\ libs/conv_pkg.vhd}
add_files -norecurse {./../dl_adaptor/sysgen\ libs/single_reg_w_init.vhd}
add_files -norecurse {./../dl_adaptor/sysgen\ libs/srl17e.vhd}
add_files -norecurse {./../dl_adaptor/sysgen\ libs/srl33e.vhd}
add_files -norecurse {./../dl_adaptor/sysgen\ libs/synth_reg.vhd}
add_files -norecurse {./../dl_adaptor/sysgen\ libs/synth_reg_reg.vhd}
add_files -norecurse {./../dl_adaptor/sysgen\ libs/synth_reg_w_init.vhd}
add_files -norecurse {./../dl_adaptor/sysgen\ libs/xlclockdriver_rd.vhd}
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_ctrl_c_addsub_v12_0_i0/ul_adaptor_ctrl_c_addsub_v12_0_i0.xci
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_ctrl_c_addsub_v12_0_i1/ul_adaptor_ctrl_c_addsub_v12_0_i1.xci
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_ctrl_c_counter_binary_v12_0_i0/ul_adaptor_ctrl_c_counter_binary_v12_0_i0.xci
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_ctrl_c_counter_binary_v12_0_i1/ul_adaptor_ctrl_c_counter_binary_v12_0_i1.xci
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_ctrl_dist_mem_gen_i0/ul_adaptor_ctrl_dist_mem_gen_i0.xci
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_ctrl_dist_mem_gen_i0_vivado.coe
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_ctrl_dist_mem_gen_i1/ul_adaptor_ctrl_dist_mem_gen_i1.xci
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_ctrl_dist_mem_gen_i1_vivado.coe
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_data_blk_mem_gen_i0/ul_adaptor_data_blk_mem_gen_i0.vhd
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_data_blk_mem_gen_i0_vivado.coe
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_fram_fifo/ul_adaptor_fram_fifo.xci
add_files -norecurse ./../ul_adaptor/ip/ul_adaptor_req_fifo/ul_adaptor_req_fifo.xci
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor.sv
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_buf.sv
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_ctrl.vhd
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_ctrl_entity_declarations.vhd
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_data.vhd
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_data_entity_declarations.vhd
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_gearbox.sv
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_gearbox_bfp9.sv
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_gearbox_bfp9_axis.sv
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_gearbox_bfp9_comp.sv
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_gearbox_bfp9_reader.sv
add_files -norecurse ./../ul_adaptor/rtl/ul_adaptor_gearbox_raw.sv
update_compile_order -fileset sources_1


# Add simulation only files
add_files -fileset sim_1 -norecurse ./../axi4s_vip/axi4s_if.sv
add_files -fileset sim_1 -norecurse ./../axi4s_vip/axi4s_vip.sv
add_files -fileset sim_1 -norecurse ./../dl_adaptor/tb/s_defm_data.txt
add_files -fileset sim_1 -norecurse ./tb_adaptor.sv
update_compile_order -fileset sim_1

# Add constrain files
add_files -fileset constrs_1 -norecurse  ./../dl_adaptor/constr/dl_adaptor_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files  ./../dl_adaptor/constr/dl_adaptor_ooc.xdc]

# Project property
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

# Run simulation
launch_simulation
run all
close_sim

# Start GUI
start_gui
