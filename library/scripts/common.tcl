# HDL folder path

set hdl_dir [file normalize [file join [file dirname [info script]] "../.."]]

# Check tool version

if {![info exists REQUIRED_VIVADO_VERSION]} {
  set REQUIRED_VIVADO_VERSION "2020.2"
}

set VIVADO_VERSION [version -short]
if {[string compare $VIVADO_VERSION $REQUIRED_VIVADO_VERSION] != 0} {
  puts -nonewline "CRITICAL WARNING: vivado version mismatch; "
  puts -nonewline "expected $REQUIRED_VIVADO_VERSION, "
  puts -nonewline "got $VIVADO_VERSION.\n"
}

## Create a project which will hold synthesis and simulation.
#
# \param[prj_name] - Project name
#
proc hdl_prj_create {prj_name} {
  create_project $prj_name . -force
}

## Add all source files to the project.
#
# \param[prj_name] - The project name
# \param[prj_files] - Project source files (*.v *.vhd *.xdc)
#
proc hdl_prj_files {prj_name prj_files} {
  foreach prj_file $prj_files {
    if {[file extension $prj_file] eq ".xdc"} {
      # Specially, add .xdc files to constraint file set
      add_files -norecurse -fileset constrs_1 $m_file
    } else {
      add_files -norecurse $prj_file
    }
  }
  update_compile_order -fileset sources_1
}

## Add all simulation files to the project.
#
# \param[prj_name] - The project name
# \param[prj_sim_files] - Project simulation files (*.v *.vhd *.xdc)
#
proc hdl_prj_files {prj_name prj_files} {
  foreach prj_file $prj_files {
    if {[file extension $prj_file] eq ".xdc"} {
      # Specially, add .xdc files to constraint file set
      add_files -norecurse -fileset constrs_1 $m_file
    } else {
      add_files -norecurse $prj_file
    }
  }
  update_compile_order -fileset sources_1
}
