# Shared stage selection for the OOC Tcl entry points. Existing positional
# arguments are preserved; an optional -stage synth|impl must come last.
# Make always passes -stage synth, including during the regression sweep.

set ooc_stage synth
set stage_arg [lsearch -exact $argv -stage]
if {$stage_arg >= 0} {
  if {$stage_arg != [llength $argv] - 2} {
    error "-stage must be the final option, followed by synth or impl"
  }
  set ooc_stage [lindex $argv end]
  set argv [lrange $argv 0 [expr {$stage_arg - 1}]]
}
if {$ooc_stage ni {synth impl}} {
  error "-stage must be synth or impl"
}
