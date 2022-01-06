source ../scripts/common.tcl

hdl_prj_create cmult_chain
hdl_prj_src_files [list \
 "../adder/adder.sv" \
 "cmult_chain.sv" \
 "cmult_chain_ooc.xdc" \
 "cmult_chain_pe.sv" ]
hdl_prj_sim_files [list \
 "tb_cmult_chain.sv" ]

start_gui

