# Out-of-context synthesis for the default FFT configuration.
#
# Writes the synthesis checkpoint that fft_impl.tcl consumes.  Implementation
# (opt/place/route) lives in fft_impl.tcl so `make ooc` stays fast.
#
# tclargs (optional):
#   1. output directory, default fft/vivado_ooc/fft_ooc

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]
set build_dir [file normalize [file join $repo_root fft vivado_ooc fft_ooc]]
if {[llength $argv] > 1} {
  error "usage: -source fft_ooc.tcl [-tclargs <output_dir>]"
}
if {[llength $argv] == 1} {
  set build_dir [file normalize [lindex $argv 0]]
}
set part xcku5p-ffvb676-2-i
set top fft

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

add_flt [file join $repo_root fft fft.flt]
puts "INFO: resolved [llength $sources] unique RTL sources"
foreach source $sources {
  puts "INFO: source $source"
}

read_verilog -sv {*}$sources
read_xdc -mode out_of_context [file join $script_dir fft_ooc.xdc]

# Keep this consistent with the existing OOC flows so the long delay lines
# use the XPM RAM implementation rather than the simulation-only fallback.
synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy none \
    -verilog_define {RAM_USE_XPM}

report_utilization -file [file join $build_dir fft_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir fft_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir fft_timing_summary.rpt]
set syn_dcp [file join $build_dir fft_ooc.dcp]
write_checkpoint -force $syn_dcp

puts "INFO: FFT OOC synthesis completed"
puts "INFO: synthesis checkpoint: $syn_dcp"
puts "INFO: utilization report: [file join $build_dir fft_utilization.rpt]"
puts "INFO: run 'make ooc-impl' for opt/place/route"
