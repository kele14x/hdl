# Out-of-context implementation for the mandatory-BFP PRACH wrapper.
#
# Consumes the synthesis checkpoint written by prach_ooc.tcl and runs
# opt/place/phys_opt/route.  Keep the ANT_ID argument consistent with the
# synthesis run so both stages read the same build directory.
#
# Parameter overrides (default = antenna 0):
#   tclargs: <ant_id>
#   ant_id=0/1/... -> PRACH antenna instance

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]

if {[llength $argv] > 1} {
  error "usage: <ant_id>"
}
if {[llength $argv] >= 1} {
  set ant_id [lindex $argv 0]
} else {
  set ant_id 0
}
if {![string is integer -strict $ant_id] || $ant_id < 0} {
  error "ANT_ID must be a non-negative integer"
}
puts "INFO: prach OOC impl params: ANT_ID=$ant_id"
set build_dir [file normalize [file join $repo_root prach vivado_ooc \
    prach_20260901_ant${ant_id}]]

set syn_dcp [file join $build_dir prach_ooc.dcp]
if {![file exists $syn_dcp]} {
  error "missing synthesis checkpoint: $syn_dcp (run 'make ooc' first)"
}

cd $build_dir
open_checkpoint $syn_dcp

opt_design
place_design
phys_opt_design
route_design

report_utilization -file [file join $build_dir prach_impl_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir prach_impl_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir prach_impl_timing_summary.rpt]
report_route_status -file [file join $build_dir prach_impl_route_status.rpt]
set impl_dcp [file join $build_dir prach_impl.dcp]
write_checkpoint -force $impl_dcp

puts "INFO: prach OOC implementation completed"
puts "INFO: implementation checkpoint: $impl_dcp"
puts "INFO: implementation utilization report: [file join $build_dir prach_impl_utilization.rpt]"
