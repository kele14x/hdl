#*******************************************************************************
# Vivado (TM) v2019.2 (64-bit)
#
# run_impl.tcl: Tcl script for re-creating project and generate bitstream for 
# top level project.
#
#*******************************************************************************

# Set the project name
set proj_name "Coreboard1588_prj"

# Set the top level module name
set top_module_name "coreboard1588"

# Set the origin directory path, by default is the script placed dir
set origin_dir "."

# Set the repo directory path
set repo_dir "[file normalize "$origin_dir/../.."]"

# Set the directory path
set proj_dir "[file normalize "$origin_dir/prj"]"


# Create project
create_project ${proj_name} $proj_dir/${proj_name} -part xc7a100tcsg324-2L -force

# Set project properties
set obj [current_project]
set_property -name "part" -value "xc7a100tcsg324-2L" -objects $obj


# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/src/dummy_fmc.v"] \
 [file normalize "${origin_dir}/src/leds.v"] \
 [file normalize "${origin_dir}/src/coreboard1588_bd/coreboard1588_bd.bd"] \
 [file normalize "${origin_dir}/src/coreboard1588_bd/hdl/coreboard1588_bd_wrapper.v"] \
 [file normalize "${origin_dir}/src/coreboard1588.sv"] \

 [file normalize "${repo_dir}/library/fmc_slv_if/src/fmc_slv_if.v"] \
 [file normalize "${repo_dir}/library/fmc_slv_if/src/fmc_slv_if_top.sv"] \
 
 [file normalize "${repo_dir}/library/axi4l_ipif/src/axi4l_ipif.v"] \
 [file normalize "${repo_dir}/library/axi4l_ipif/src/axi4l_ipif_top.sv"] \
 
 [file normalize "${repo_dir}/library/axis_spi_master/src/axis_spi_master.v"] \
 [file normalize "${repo_dir}/library/axis_spi_master/src/axis_spi_master_top.sv"] \

 
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x.v"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x_pkg.sv"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x_ctrl.sv"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x_regs.sv"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x_top.sv"] \
 
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x.v"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x_pkg.sv"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x_ctrl.sv"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x_regs.sv"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x_top.sv"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value $top_module_name -objects $obj

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "[file normalize "$repo_dir/library"]" $obj

# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild


# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]
set files [list \
 [file normalize "${repo_dir}/projects/Coreboard1588/src/debug.xdc"] \
 [file normalize "${repo_dir}/projects/Coreboard1588/src/impl.xdc"] \
 [file normalize "${repo_dir}/projects/Coreboard1588/src/pins.xdc"] \
]
add_files -norecurse -fileset $obj $files

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property -name "target_constrs_file" -value "[file normalize "$repo_dir/projects/Coreboard1588/src/debug.xdc"]" -objects $obj

# Set 'impl_1' implementation run properties
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]

# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Run implementation
launch_runs impl_1
wait_on_run impl_1

