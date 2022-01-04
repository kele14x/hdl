# HDL folder path

set hdl_dir [file normalize [file join [file dirname [info script]] "../.."]]

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
#
proc hdl_prj_create {prj_name} {
  create_project $prj_name ./prj -force
}

## Add all source files to current project.
#
# \param[src_files] - Project source files (*.v *.vhd *.sv *.xdc, etc.)
#
proc hdl_prj_src_files {src_files} {
  foreach src_file $src_files {
    if {[file extension $src_file] eq ".xdc"} {
      # Specially, add .xdc files to constraint file set
      add_files -norecurse -fileset constrs_1 $src_file
    } else {
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
    add_files -norecurse -fileset sim_1 $sim_file
  }
  update_compile_order -fileset sim_1
}

