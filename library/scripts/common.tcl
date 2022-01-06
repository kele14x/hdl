# General information
set SCRIPT_VERSION "0.1"
put "hdl build Tcl script, version $SCRIPT_VERSION"
put "current working directory: [pwd]"

# HDL folder path
set hdl_dir [file normalize [file join [file dirname [info script]] "../.."]]
put "hld directory path: $hdl_dir"

# Check tool version
if {![info exists REQUIRED_VIVADO_VERSION]} {
  set REQUIRED_VIVADO_VERSION "2021.2"
}

set VIVADO_VERSION [version -short]
if {[string compare $VIVADO_VERSION $REQUIRED_VIVADO_VERSION] != 0} {
  puts -nonewline "CRITICAL WARNING: vivado version mismatch, "
  puts -nonewline "expected $REQUIRED_VIVADO_VERSION, "
  puts -nonewline "got $VIVADO_VERSION.\n"
}

## Create a project which will hold synthesis and simulation.
#
# \param[prj_name] - Project name
# \param[part] - FPGA part number
#
proc hdl_prj_create {prj_name {prj_dir ./prj} {part xczu19eg-ffvc1760-2-i}} {
  # Create project with part number
  put "create project $prj_name under directory $prj_dir"
  create_project -force -part $part $prj_name $prj_dir

  # Project property
  set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
  set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]
}

## Add all source files to current project.
#
# \param[src_files] - Project source files (*.v *.vhd *.sv *.xdc, etc.)
#
proc hdl_prj_src_files {src_files} {
  # Add source files
  foreach src_file $src_files {
    if {[file extension $src_file] eq ".xdc"} {
      # Specially, add .xdc files to constraint file set
      if {[string match -nocase "*_ooc.xdc" [file tail $src_file]]} {
        put "add out of context constrains file: $src_file"
        add_files -norecurse -fileset constrs_1 $src_file
        set_property USED_IN {synthesis implementation out_of_context} [get_files $src_file]
      } else {
        put "add normal constrains file: $src_file"
        add_files -norecurse -fileset constrs_1 $src_file
      }
    } else {
      put "add design source file: $src_file"
      add_files -norecurse $src_file
    }
  }
  update_compile_order -fileset sources_1
}

## Add all simulation files to current project.
#
# \param[prj_sim_files] - Project simulation files (*.v *.vhd *.xdc)
#
proc hdl_prj_sim_files {sim_files} {
  foreach sim_file $sim_files {
    put "add simulation source file: $sim_file"
    add_files -norecurse -fileset sim_1 $sim_file
  }
  update_compile_order -fileset sim_1
}

