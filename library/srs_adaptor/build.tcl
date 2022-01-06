source ../scripts/common.tcl

hdl_prj_create srs_adaptor

hdl_prj_src_files [list \
  "./constr/srs_adaptor_ooc.xdc" \
  "./ip/srs_adaptor_controller_fifo/srs_adaptor_controller_fifo.xci" \
  "./ip/srs_adaptor_controller_tdp/srs_adaptor_controller_tdp.xci" \
  "./ip/srs_adaptor_runner_sdp/srs_adaptor_runner_sdp.xci" \
  "./rtl/srs_adaptor.sv" \
  "./rtl/srs_adaptor_buffer.sv" \
  "./rtl/srs_adaptor_controller.sv" \
  "./rtl/srs_adaptor_filter.sv" \
  "./rtl/srs_adaptor_framer.sv" \
  "./rtl/srs_adaptor_fwd.sv" \
  "./rtl/srs_adaptor_mux.sv" \
  "./rtl/srs_adaptor_runner.sv"]

hdl_prj_sim_files [list \
 "./tb/tb_srs_adaptor.sv" \
 "./tb/srs_adaptor_unsol_checker.sv"]

start_gui
