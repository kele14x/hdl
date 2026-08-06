# Vivado 2026.1 out-of-context synthesis for the mandatory-BFP PDXCH top.

set repo_root [file normalize [file join [file dirname [info script]] .. ..]]
set build_dir [file normalize [file join $repo_root sim_build vivado_ooc_pdxch_top_20260806]]
set part xcku5p-ffvb676-2-i
set top pdxch_top

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

add_flt [file join $repo_root pdxch pdxch.flt]
puts "INFO: resolved [llength $sources] unique RTL sources"
foreach source $sources {
  puts "INFO: source $source"
}

read_verilog -sv {*}$sources
synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt \
    -verilog_define {RAM_USE_XPM}

report_utilization -file [file join $build_dir pdxch_top_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir pdxch_top_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir pdxch_top_timing_summary.rpt]
write_checkpoint -force [file join $build_dir pdxch_top_ooc.dcp]

puts "INFO: pdxch_top OOC synthesis completed"
puts "INFO: utilization report: [file join $build_dir pdxch_top_utilization.rpt]"
