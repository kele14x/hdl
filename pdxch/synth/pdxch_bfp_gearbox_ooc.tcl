set script_dir [file dirname [file normalize [info script]]]
set repo_dir [file normalize [file join $script_dir .. ..]]
set output_dir [file normalize [file join $repo_dir sim_build vivado_ooc_pdxch_bfp_gearbox_20260806]]
set part xcku5p-ffvb676-2-i

file mkdir $output_dir

read_verilog -sv [file join $repo_dir pdxch rtl pdxch_bfp_gearbox.sv]
synth_design -top pdxch_bfp_gearbox -part $part -mode out_of_context

report_utilization -file [file join $output_dir pdxch_bfp_gearbox_utilization.rpt]
report_timing_summary -file [file join $output_dir pdxch_bfp_gearbox_timing_summary.rpt]
write_checkpoint -force [file join $output_dir pdxch_bfp_gearbox_ooc.dcp]

puts "PDXCH_BFP_GEARBOX_OOC_DONE"
