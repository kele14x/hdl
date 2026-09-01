# Out-of-context synthesis baseline for lowphy0_wrapper.
# The repo's generated FH IP targets xczu19eg, but this Vivado installation
# only has Kintex UltraScale+ parts installed. Use a same-generation KU+ part
# as a temporary resource-comparison proxy until ZU19EG device support exists.

set script_dir [file dirname [file normalize [info script]]]
set repo_root [file normalize [file join $script_dir .. ..]]
set build_dir [file normalize [file join $repo_root lowphy vivado_ooc lowphy0_20260901]]
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
foreach source $sources {
  puts "INFO: source $source"
}

read_verilog -sv {*}$sources

# OOC clock constraints: s_axi_aclk 100 MHz, clk 491.52 MHz, internal_bus_clk 400 MHz
read_xdc -mode out_of_context [file join $script_dir lowphy0_ooc.xdc]

synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt \
    -verilog_define {RAM_USE_XPM}

report_utilization -file [file join $build_dir lowphy0_utilization.rpt]
report_utilization -hierarchical -file [file join $build_dir lowphy0_utilization_hierarchical.rpt]
report_timing_summary -file [file join $build_dir lowphy0_timing_summary.rpt]
write_checkpoint -force [file join $build_dir lowphy0_ooc.dcp]

puts "INFO: lowphy0 OOC synthesis completed"
puts "INFO: utilization report: [file join $build_dir lowphy0_utilization.rpt]"
