# Out-of-context synthesis for the mandatory-BFP PRACH wrapper.
# PRACH uses a fixed 1536-point FFT; HALF_BLOCK/HALF_FFT are not applicable.
#
# Parameter overrides (default = antenna 0):
#   tclargs: <ant_id>
#   ant_id=0/1/... -> PRACH antenna instance

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]
set part xcku5p-ffvb676-2-i
set top prach

# Parameter override via -tclargs (default 0)
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
puts "INFO: prach OOC params: ANT_ID=$ant_id"
set build_dir [file normalize [file join $repo_root prach vivado_ooc \
    prach_20260901_ant${ant_id}]]

file mkdir $build_dir
cd $build_dir

array set flt_seen {}
array set source_seen {}
set sources {}

proc add_flt {path} {
  global flt_seen source_seen sources

  set path [file normalize $path]
  if {![file exists $path]} {
    error "missing source or file list: $path"
  }

  if {[string equal -nocase [file extension $path] ".flt"]} {
    if {[info exists flt_seen($path)]} {
      return
    }
    set flt_seen($path) 1

    set fh [open $path r]
    set contents [read $fh]
    close $fh
    set base [file dirname $path]
    foreach line [split $contents "\n"] {
      set line [string trim $line]
      if {$line eq "" || [string match "#*" $line]} {
        continue
      }
      add_flt [file join $base $line]
    }
  } elseif {![info exists source_seen($path)]} {
    set source_seen($path) 1
    lappend sources $path
  }
}

add_flt [file join $repo_root prach prach.flt]
puts "INFO: resolved [llength $sources] unique RTL sources"
foreach source $sources {
  puts "INFO: source $source"
}

read_verilog -sv {*}$sources

# OOC clock constraints: s_axi_aclk 100 MHz, clk 491.52 MHz, clk_eth_xran 400 MHz
read_xdc -mode out_of_context [file join $script_dir prach_ooc.xdc]

synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy none \
    -verilog_define {RAM_USE_XPM} \
    -generic ANT_ID=$ant_id

report_utilization -file [file join $build_dir prach_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir prach_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir prach_timing_summary.rpt]
write_checkpoint -force [file join $build_dir prach_ooc.dcp]

puts "INFO: prach OOC synthesis completed"
puts "INFO: utilization report: [file join $build_dir prach_utilization.rpt]"
