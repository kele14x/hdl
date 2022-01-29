# General information
set script_version "0.1"


## Help information for this script
#
proc print_help {} {
  set script_file [file tail [info script]]

  puts "$script_file"
  puts ""
  puts "Description:"
  puts "Create a Vivado project using a filesets (.flt) file"
  puts ""
  puts "Syntax:"
  puts "$script_file -tclargs \[--filesets <path>\]"
  puts "$script_file -tclargs \[--project_name <name>\]"
  puts "$script_file -tclargs \[--help\]"
  puts ""
  puts "Usage:"
  puts "Name                   Description"
  puts "-------------------------------------------------------------------------"
  puts "\[--filesets <path>\]     Path to the filesets (.flt) file."
  puts ""
  puts "\[--project_name <name>\] Create project with the specified name. Default"
  puts "                        name is the filename of the .flt file."
  puts ""
  puts "\[--help\]                Print help information for this script"
  puts "-------------------------------------------------------------------------\n"
}


## Parse filesets (.flt) file
#
# \param[file] - The filename of .flt
#
proc hdl_read_flt {file} {
  set filename [file normalize $file]
  puts "Parse file list: $filename"

  set infile [open $filename r]
  set files []

  # -1 if the end of the file is found
  while { [gets $infile line] >= 0 } {

    # Skip the line starts with '#' (comments)
    set line [string trim $line]
    if { [string match "#*" $line] } {
      continue
    }

    # As destination, all files are related to .flt. If absolute path is
    # specified, `file join` still handles it well
    set ifile [file normalize [file join [file dirname $filename] $line]]

    if { [string equal -nocase ".flt" [file extension $ifile]] } {
      # Recursively process .flt file
      foreach iifile [hdl_read_flt $ifile] {
        lappend files $iifile
      }
    } else {
      puts "$ifile"
      lappend files $ifile
    }
  }

  close $infile
  return $files
}


## Check if required files exists
#
# \param[origin_dir] - list of required files
#
proc hdl_check_required_files {files} {
  set status true
  foreach ifile $files {
    if { ![file isfile $ifile] } {
      puts "WARNING: Could not find file '$ifile'"
      set status false
    }
  }
  return status
}


## Create a project which will hold synthesis and simulation.
#
# \param[prj_name] - Project name
# \param[prj_dir]  - Project folder
# \param[part]     - FPGA part number
#
proc hdl_create_project {prj_name {prj_dir ./prj_dir} {part xczu19eg-ffvc1760-2-i}} {
  # Create project with part number
  put "Create project $prj_name under directory $prj_dir"
  create_project -force -part $part $prj_name $prj_dir

  # Project property
  set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
  set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY none [get_runs synth_1]
  set_property AUTO_INCREMENTAL_CHECKPOINT 0 [get_runs synth_1]
}


## Add source files to current project.
#
# \param[files] - List of source files (*.v *.vhd *.sv *.xdc, etc.)
#
proc hdl_add_source_files {files} {
  foreach ifile $files {
    if {[file extension $ifile] eq ".xdc"} {
      # Specially, add .xdc files to constraint file set
      if {[string match -nocase "*_ooc.xdc" [file tail $ifile]]} {
        put "Add out of context constrains file: $ifile"
        add_files -norecurse -fileset constrs_1 $ifile
        set_property USED_IN {synthesis implementation out_of_context} [get_files $ifile]
      } else {
        put "Add constrains file: $ifile"
        add_files -norecurse -fileset constrs_1 $ifile
      }
    } else {
      put "Add design source file: $ifile"
      add_files -norecurse $ifile
    }
  }
  update_compile_order -fileset sources_1
}


## Add all simulation files to current project.
#
# \param[files] - List of simulation files (*.v *.vhd *.xdc, etc.)
#
proc hdl_add_sim_files {files} {
  foreach ifile $files {
    put "Add simulation source file: $ifile"
    add_files -norecurse -fileset sim_1 $ifile
  }
  update_compile_order -fileset sim_1
}



# Script name
set script_file [file tail [info script]]

# Parse arguments
if { $argc > 0 } {
  for {set i 0} {$i < $argc} {incr i} {
    set option [string trim [lindex $argv $i]]
    switch -regexp -- $option {
      "--filesets"     { incr i; set filesets [lindex $argv $i] }
      "--project_name" { incr i; set project_name [lindex $argv $i] }
      "--help"         { print_help; return 0 }
      default {
        if { [regexp {^-} $option] } {
          puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
          return 1
        }
      }
    }
  }
}

# Some basic information
put "HDL build Tcl script, version $script_version"
put "Current working directory: [pwd]"

# HDL folder path
set script_folder [file dirname [file normalize [info script]]]
set hdl_folder [file normalize [file join script_folder "../.."]]
put "HDL folder path: $hdl_folder"

# Required VIVADO version
set required_vivado_version "2021.2.1"
if {[info exists REQUIRED_VIVADO_VERSION]} {
  set required_vivado_version REQUIRED_VIVADO_VERSION
}

# Check current VIVADO version
set current_vivado_version [version -short]
if { ![string equal $required_vivado_version $current_vivado_version] } {
  error "ERROR: Vivado version mismatch, expected $required_vivado_version, got $current_vivado_version.\n"
  return 1
}

# Read filesets (.flt) file
set files [hdl_read_flt $filesets]
hdl_check_required_files $files

if { ![info exists project_name] } {
  set project_name [file rootname [file tail $filesets]]
}

# Create Project
hdl_create_project $project_name
hdl_add_source_files $files

# Start GUI
puts "Launching GUI..."
start_gui
