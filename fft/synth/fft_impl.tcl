# Out-of-context implementation for the default FFT configuration.
#
# Consumes the synthesis checkpoint written by fft_ooc.tcl and runs
# opt/place/phys_opt/route.  Kept separate so `make ooc` (synthesis only) stays
# fast; run this through `make ooc-impl` when the post-route numbers matter.
#
# tclargs (optional):
#   1. build directory, default fft/vivado_ooc/fft_ooc (same as fft_ooc.tcl)

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]
set build_dir [file normalize [file join $repo_root fft vivado_ooc fft_ooc]]
if {[llength $argv] > 1} {
  error "usage: -source fft_impl.tcl [-tclargs <build_dir>]"
}
if {[llength $argv] == 1} {
  set build_dir [file normalize [lindex $argv 0]]
}

set syn_dcp [file join $build_dir fft_ooc.dcp]
if {![file exists $syn_dcp]} {
  error "missing synthesis checkpoint: $syn_dcp (run 'make ooc' first)"
}

cd $build_dir
open_checkpoint $syn_dcp

opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $build_dir fft_impl_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir fft_impl_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir fft_impl_timing_summary.rpt]
report_route_status -file [file join $build_dir fft_impl_route_status.rpt]
set impl_dcp [file join $build_dir fft_impl.dcp]
write_checkpoint -force $impl_dcp

puts "INFO: FFT OOC implementation completed"
puts "INFO: implementation checkpoint: $impl_dcp"
puts "INFO: implementation utilization report: [file join $build_dir fft_impl_utilization.rpt]"
