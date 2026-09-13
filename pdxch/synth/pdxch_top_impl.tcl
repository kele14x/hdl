# Out-of-context implementation for the mandatory-BFP PDXCH wrapper.
#
# Consumes the synthesis checkpoint written by pdxch_top_ooc.tcl and runs
# opt/place/phys_opt/route.  Keep the HALF_BLOCK/HALF_FFT arguments consistent
# with the synthesis run so both stages read the same build directory.
#
# Parameter overrides (defaults = HALF_BLOCK=0, HALF_FFT=0: full block + 4k FFT):
#   tclargs: <half_block> <half_fft>
#   half_block=0/1 -> fdv_buffer IQ depth full/half
#   half_fft=0/1   -> FFT 4k/2k

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]

# Parameter override via -tclargs (default HALF_BLOCK=0 HALF_FFT=0)
if {[llength $argv] > 2} {
  error "usage: <half_block> <half_fft>"
}
if {[llength $argv] >= 1} {
  set half_block [lindex $argv 0]
} else {
  set half_block 0
}
if {[llength $argv] >= 2} {
  set half_fft [lindex $argv 1]
} else {
  set half_fft 0
}
if {![string is integer -strict $half_block] || ($half_block != 0 && $half_block != 1)} {
  error "HALF_BLOCK must be 0 or 1"
}
if {![string is integer -strict $half_fft] || ($half_fft != 0 && $half_fft != 1)} {
  error "HALF_FFT must be 0 or 1"
}
puts "INFO: pdxch OOC impl params: HALF_BLOCK=$half_block HALF_FFT=$half_fft"
set build_dir [file normalize [file join $repo_root pdxch vivado_ooc \
    pdxch_20260908_hb${half_block}_hf${half_fft}]]

set syn_dcp [file join $build_dir pdxch_ooc.dcp]
if {![file exists $syn_dcp]} {
  error "missing synthesis checkpoint: $syn_dcp (run 'make ooc' first)"
}

cd $build_dir
open_checkpoint $syn_dcp

opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $build_dir pdxch_impl_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir pdxch_impl_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir pdxch_impl_timing_summary.rpt]
report_route_status -file [file join $build_dir pdxch_impl_route_status.rpt]
set impl_dcp [file join $build_dir pdxch_impl.dcp]
write_checkpoint -force $impl_dcp

puts "INFO: pdxch OOC implementation completed"
puts "INFO: implementation checkpoint: $impl_dcp"
puts "INFO: implementation utilization report: [file join $build_dir pdxch_impl_utilization.rpt]"
