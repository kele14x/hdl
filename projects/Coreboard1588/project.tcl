#*******************************************************************************
# run_impl.tcl: Tcl script for re-creating the Vivado project
#*******************************************************************************

# Set the project code name
set project_name "Coreboard1588"

# Set the expected Vivado tool version
set vivado_version "2019.2"

# Set the Vivado project name
set vivado_project_name ${project_name}_prj

# Set the top level module name
set top_module_name "coreboard1588"

# Set the top level simulation module name
set top_sim_module_name "tb_coreboard1588"

# Set the origin directory path, by default is the script placed dir
set origin_dir "."

# Set the repo directory path
set repo_dir "[file normalize "$origin_dir/../.."]"

# Set the directory path
set proj_dir "[file normalize "$origin_dir/prj"]"


if {[string compare $vivado_version [version -short]] != 0} {
	error "The project "$project_name" is only tested on Vivado version "$vivado_version
}

#******************************************************************************
# Project
#******************************************************************************

# Create project
create_project $vivado_project_name $proj_dir/$vivado_project_name -part xc7a100tcsg324-2L -force

# Set project properties
set obj [current_project]
set_property -name "part" -value "xc7a100tcsg324-2L" -objects $obj

#******************************************************************************
# Source files
#******************************************************************************

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/src/version.vh"] \
 [file normalize "${origin_dir}/src/build_time.vh"] \
 [file normalize "${origin_dir}/src/coreboard1588.sv"] \
 [file normalize "${origin_dir}/src/coreboard1588_axi_fmc.sv"] \
 [file normalize "${origin_dir}/src/coreboard1588_axi_regs.sv"] \
 [file normalize "${origin_dir}/src/coreboard1588_axi_rtc.sv"] \
 [file normalize "${origin_dir}/src/coreboard1588_axi_top.v"] \
 [file normalize "${origin_dir}/src/coreboard1588_bd/coreboard1588_bd.bd"] \
 [file normalize "${origin_dir}/src/coreboard1588_bd/hdl/coreboard1588_bd_wrapper.v"] \
 [file normalize "${origin_dir}/src/leds.v"] \
 [file normalize "${repo_dir}/library/axi4l_ipif/src/axi4l_ipif.v"] \
 [file normalize "${repo_dir}/library/axi4l_ipif/src/axi4l_ipif_top.sv"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x.v"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x_ctrl.sv"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x_pkg.sv"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x_regs.sv"] \
 [file normalize "${repo_dir}/library/axi_ads124x/src/axi_ads124x_top.sv"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x.v"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x_ctrl.sv"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x_pkg.sv"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x_regs.sv"] \
 [file normalize "${repo_dir}/library/axi_ads868x/src/axi_ads868x_top.sv"] \
 [file normalize "${repo_dir}/library/axis_axi_master/src/axis_axi_master.v"] \
 [file normalize "${repo_dir}/library/axis_axi_master/src/axis_axi_master_top.sv"] \
 [file normalize "${repo_dir}/library/axis_spi_master/src/axis_spi_master.v"] \
 [file normalize "${repo_dir}/library/axis_spi_master/src/axis_spi_master_top.sv"] \
 [file normalize "${repo_dir}/library/axis_spi_slave2/src/axis_spi_slave2.v"] \
 [file normalize "${repo_dir}/library/axis_spi_slave2/src/axis_spi_slave2_top.sv"] \
 [file normalize "${repo_dir}/library/fmc_slv_if/src/fmc_slv_if.v"] \
 [file normalize "${repo_dir}/library/fmc_slv_if/src/fmc_slv_if_top.sv"] \
 [file normalize "${repo_dir}/library/pps_receiver/src/pps_receiver.v"] \
 [file normalize "${repo_dir}/library/pps_receiver/src/pps_receiver_top.sv"] \

]
add_files -norecurse -fileset $obj $files

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value $top_module_name -objects $obj

# Update compile oerder
update_compile_order -fileset sources_1

#******************************************************************************
# Constrs
#******************************************************************************

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


#******************************************************************************
# Simluation files
#******************************************************************************

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
 [file normalize "${repo_dir}/projects/Coreboard1588/tb/tb_coreboard1588.sv"] \
 [file normalize "${repo_dir}/library/sim_util/sim_clk_gen.sv"] \
]
add_files -norecurse -fileset $obj $files

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value $top_sim_module_name -objects $obj
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects $obj

#******************************************************************************
# Implemation
#******************************************************************************

# Set 'impl_1' implementation run properties
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
