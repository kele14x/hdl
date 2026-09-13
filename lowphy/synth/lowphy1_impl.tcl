# Out-of-context implementation for the HALF_BLOCK=1 lowphy variant.
#
# Consumes the synthesis checkpoint written by lowphy1_ooc.tcl and runs
# opt/place/phys_opt/route on the same KU5P comparison device.

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]
set build_dir [file normalize [file join $repo_root lowphy vivado_ooc lowphy1_20260901]]

set syn_dcp [file join $build_dir lowphy1_ooc.dcp]
if {![file exists $syn_dcp]} {
  error "missing synthesis checkpoint: $syn_dcp (run 'make ooc' first)"
}

cd $build_dir
open_checkpoint $syn_dcp

opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $build_dir lowphy1_impl_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir lowphy1_impl_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir lowphy1_impl_timing_summary.rpt]
report_route_status -file [file join $build_dir lowphy1_impl_route_status.rpt]
set impl_dcp [file join $build_dir lowphy1_impl.dcp]
write_checkpoint -force $impl_dcp

puts "INFO: lowphy1 OOC implementation completed"
puts "INFO: implementation checkpoint: $impl_dcp"
puts "INFO: implementation utilization report: [file join $build_dir lowphy1_impl_utilization.rpt]"
