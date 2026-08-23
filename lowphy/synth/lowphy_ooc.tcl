# Vivado 2026.1 out-of-context synthesis for lowphy0_wrapper / lowphy1_wrapper.
# Usage:
#   vivado.bat -mode batch -source lowphy/synth/lowphy_ooc.tcl -nojournal \
#              -log vivado_lowphy1_20260824.log -tclargs lowphy1_wrapper 20260824

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]
set part xcku5p-ffvb676-2-i
set top lowphy1_wrapper
set tag 20260824

if {[llength $argv] >= 1} {
  set top [lindex $argv 0]
}
if {[llength $argv] >= 2} {
  set tag [lindex $argv 1]
}
set build_dir [file normalize [file join $repo_root sim_build vivado_ooc_${top}_${tag}]]
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

report_utilization -file [file join $build_dir ${top}_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir ${top}_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir ${top}_timing_summary.rpt]
write_checkpoint -force [file join $build_dir ${top}_ooc.dcp]

puts "INFO: ${top} OOC synthesis completed"
puts "INFO: utilization report: [file join $build_dir ${top}_utilization.rpt]"