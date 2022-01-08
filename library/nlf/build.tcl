source ../scripts/common.tcl

hdl_prj_create nlf
hdl_prj_src_files [list \
 "../adder/adder.sv" \
 "../cmult_chain/cmult_chain.sv" \
 "../cmult_chain/cmult_chain_core.sv" \
 "../cordic_cart2pol/cordic_cart2pol.sv" \
 "../util/reg_pipeline.sv" \
 "nlf.sv" \
 "nlf_core.sv" \
 "nlf_delay_line.sv" \
 "nlf_lut.sv" \
 "nlf_ooc.xdc" \
 "nlf_srl.sv" ]
hdl_prj_sim_files [list \
 "tb_nlf.sv" ]

start_gui
