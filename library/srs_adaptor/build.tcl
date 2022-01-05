# Create project, override if exist
create_project project_1 ./prj -part xczu19eg-ffvc1760-2-i -force

# Add source files
add_files -norecurse ./ip/srs_adaptor_controller_fifo/srs_adaptor_controller_fifo.xci
add_files -norecurse ./ip/srs_adaptor_controller_tdp/srs_adaptor_controller_tdp.xci
add_files -norecurse ./ip/srs_adaptor_runner_sdp/srs_adaptor_runner_sdp.xci
add_files -norecurse ./rtl/srs_adaptor.sv
add_files -norecurse ./rtl/srs_adaptor_buffer.sv
add_files -norecurse ./rtl/srs_adaptor_controller.sv
add_files -norecurse ./rtl/srs_adaptor_filter.sv
add_files -norecurse ./rtl/srs_adaptor_framer.sv
add_files -norecurse ./rtl/srs_adaptor_fwd.sv
add_files -norecurse ./rtl/srs_adaptor_mux.sv
add_files -norecurse ./rtl/srs_adaptor_runner.sv
update_compile_order -fileset sources_1

# Add simulation only files
add_files -fileset sim_1 -norecurse ./tb/tb_srs_adaptor.sv
add_files -fileset sim_1 -norecurse ./tb/srs_adaptor_unsol_checker.sv
update_compile_order -fileset sim_1

# Add constrain files
add_files -fileset constrs_1 -norecurse ./constr/srs_adaptor_ooc.xdc
set_property USED_IN {synthesis implementation out_of_context} [get_files ./constr/srs_adaptor_ooc.xdc]

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
