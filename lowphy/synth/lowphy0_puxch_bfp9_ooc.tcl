# Vivado 2026.1 out-of-context synthesis for the full-block PUXCH BFP9 buffer.

set repo_root [file normalize [file join [file dirname [info script]] .. ..]]
set build_dir [file normalize [file join $repo_root sim_build vivado_ooc_lowphy0_puxch_bfp9_20260827]]
set part xcku5p-ffvb676-2-i
set top lowphy0_wrapper

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

add_flt [file join $repo_root lowphy lowphy.flt]
puts "INFO: resolved [llength $sources] unique RTL sources"

read_verilog -sv {*}$sources
synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt \
    -verilog_define {RAM_USE_XPM}

report_utilization -file [file join $build_dir lowphy0_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir lowphy0_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir lowphy0_timing_summary.rpt]

set primitive_file [open [file join $build_dir lowphy0_bram_primitives.txt] w]
puts $primitive_file "REF_NAME | NAME"
foreach cell [lsort [get_cells -hierarchical -filter {REF_NAME == RAMB36E2 || REF_NAME == RAMB18E2}]] {
  puts $primitive_file "[get_property REF_NAME $cell] | [get_property NAME $cell]"
}
close $primitive_file

set puxch_cell [get_cells -hierarchical -filter {NAME =~ */u_puxch}]
if {[llength $puxch_cell] == 1} {
  report_utilization -cells $puxch_cell -file [file join $build_dir lowphy0_puxch_utilization.rpt]
} else {
  puts "WARNING: expected one PUXCH hierarchy cell, found [llength $puxch_cell]"
}

write_checkpoint -force [file join $build_dir lowphy0_puxch_bfp9_ooc.dcp]

puts "INFO: lowphy0 PUXCH BFP9 OOC synthesis completed"
puts "INFO: build directory: $build_dir"
