#
# build.tcl: Tcl script for re-creating project 'ac701_hpc_pcie'
#
#*****************************************************************************************

set design_name ac701_hpc_pcie

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/$design_name"]"

# Create project
create_project $design_name $origin_dir/$design_name -part xc7a200tfbg676-2

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set obj [get_projects $design_name]
set_property -name "board_part" -value "xilinx.com:ac701:part0:1.3" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "$proj_dir/$design_name.cache/ip" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}


# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" "${design_name}_wrapper" $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/src/constraints/ac701-hpc.xdc"]"
set file_added [add_files -norecurse -fileset $obj $file]
set file "$origin_dir/src/constraints/ac701-hpc.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property "file_type" "XDC" $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property "target_constrs_file" "[file normalize "$origin_dir/src/constraints/ac701-hpc.xdc"]" $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property "top" "${design_name}_wrapper" $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part xc7a200tfbg676-2 -flow {Vivado Synthesis 2017} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2017" [get_runs synth_1]
}
set obj [get_runs synth_1]

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part xc7a200tfbg676-2 -flow {Vivado Implementation 2017} -strategy "Performance_Explore" -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Performance_Explore" [get_runs impl_1]
  set_property flow "Vivado Implementation 2017" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:${design_name}"

# Create block design
source $origin_dir/src/bd/design_1-ac701-hpc.tcl

# Generate the wrapper
make_wrapper -files [get_files *${design_name}.bd] -top
add_files -norecurse ${design_name}/${design_name}.srcs/sources_1/bd/${design_name}/hdl/${design_name}_wrapper.v

# Update the compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Ensure parameter propagation has been performed
close_bd_design [current_bd_design]
open_bd_design [get_files ${design_name}.bd]
validate_bd_design -force
save_bd_design

