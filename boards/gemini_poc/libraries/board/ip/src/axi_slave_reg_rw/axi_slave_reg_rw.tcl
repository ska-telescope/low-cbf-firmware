#############
# IP Settings
#############

set design axi_slave_reg_rw

set projdir ./build/
set repodir ../../repo/

set root "."

# FPGA device
set partname "xcvu9p-flga2577-2L-e-es1"

# Board part
set boardpart ""

set hdl_files [list $root/vhdl/]

set ip_files []

set constraints_files []

if ![file exists $projdir]  {file mkdir $projdir}

###########################
# Create Managed IP Project
###########################

create_project -force $design $projdir -part $partname 
set_property target_language Verilog [current_project]
set_property source_mgmt_mode None [current_project]

if {$boardpart != ""} {
set_property "board_part" $boardpart [current_project]
}

##########################################
# Create filesets and add files to project
##########################################

#HDL
if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}

add_files -norecurse -fileset [get_filesets sources_1] $hdl_files

set_property top $design [get_filesets sources_1]

#CONSTRAINTS
if {[string equal [get_filesets -quiet constraints_1] ""]} {
  create_fileset -constrset constraints_1
}
if {[llength $constraints_files] != 0} {
    add_files -norecurse -fileset [get_filesets constraints_1] $constraints_files
}

#ADDING IP
if {[llength $ip_files] != 0} {
    
    #Add to fileset
    add_files -norecurse -fileset [get_filesets sources_1] $ip_files
   
    #RERUN/UPGRADE IP
    upgrade_ip [get_ips]
}


#########
# Package
#########

ipx::package_project -import_files -force -root_dir $projdir
ipx::associate_bus_interfaces -busif s00_axi -clock "s00_axi_aclk" [ipx::current_core]

ipx::remove_memory_map {s00_axi} [ipx::current_core]
ipx::add_memory_map {s00_axi} [ipx::current_core]
set_property slave_memory_map_ref {s00_axi} [ipx::get_bus_interfaces s00_axi -of_objects [ipx::current_core]]
ipx::add_address_block {axi_lite} [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]
set_property range {65536} [ipx::get_address_blocks axi_lite -of_objects \
    [ipx::get_memory_maps s00_axi -of_objects [ipx::current_core]]]

set_property vendor              {user.org}              [ipx::current_core]
set_property library             {user}                  [ipx::current_core]
set_property taxonomy            {{/AXI_Infrastructure}} [ipx::current_core]
set_property vendor_display_name {}                      [ipx::current_core]
set_property company_url         {}                      [ipx::current_core]
set_property supported_families  { \
                     {virtexuplus}  {Pre-Production} \
                     }   [ipx::current_core]


############################
# Save and Write ZIP archive
############################

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
ipx::check_integrity -quiet [ipx::current_core]
ipx::archive_core [concat $repodir/$design.zip] [ipx::current_core]

exit

