# Out-of-context synthesis for the mandatory-BFP PUXCH wrapper.
#
# Parameter overrides (defaults = max spec, full block + 4k FFT):
#   tclargs: <half_block> <half_fft>
#   half_block=0/1 -> puxch_buffer IQ depth full/half
#   half_fft=0/1   -> FFT 4k/2k

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]
set part xcku5p-ffvb676-2-i
set top puxch

# Parameter override via -tclargs (default 0 0 = max spec)
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
puts "INFO: puxch OOC params: HALF_BLOCK=$half_block HALF_FFT=$half_fft"
set build_dir [file normalize [file join $repo_root puxch vivado_ooc \
    puxch_20260901_hb${half_block}_hf${half_fft}]]

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

add_flt [file join $repo_root puxch puxch.flt]
puts "INFO: resolved [llength $sources] unique RTL sources"
foreach source $sources {
  puts "INFO: source $source"
}

read_verilog -sv {*}$sources

# OOC clock constraints: s_axi_aclk 100 MHz, clk 491.52 MHz, clk_eth_xran 400 MHz
read_xdc -mode out_of_context [file join $script_dir puxch_ooc.xdc]

synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt \
    -verilog_define {RAM_USE_XPM} \
    -generic HALF_BLOCK=$half_block -generic HALF_FFT=$half_fft

report_utilization -file [file join $build_dir puxch_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir puxch_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir puxch_timing_summary.rpt]
write_checkpoint -force [file join $build_dir puxch_ooc.dcp]

puts "INFO: puxch OOC synthesis completed"
puts "INFO: utilization report: [file join $build_dir puxch_utilization.rpt]"
