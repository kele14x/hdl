source ../scripts/common.tcl

hdl_prj_create cmult_chain
hdl_prj_src_files [list \
 "cmult_chain.sv" ]
hdl_prj_sim_files [list \
 "tb_cmult_chain.sv" ]

start_gui

