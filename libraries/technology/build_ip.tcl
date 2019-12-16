## Boiler plate build code or generate simulation files & do script

if {[string equal [current_project] "New Project"]} {
  generate_target Simulation [get_ips $componentName]

  set filelist [get_files -of_objects [get_ips $componentName] -compile_order sources -used_in simulation]

  file copy -force {*}$filelist .
  set ipBuildScript [open ${componentName}.do w]
  foreach file $filelist {

    set element [file tail $file]

    # Build compilation script
    if {[string equal [file extension $element] ".vhd"] || [string equal [file extension $element] ".vhdl"]} {
      set entry "vcom $element"
    } elseif {[string equal [file extension $element] ".sv"]} {
      set entry "vlog -sv $element"
    } elseif {[string equal [file extension $element] ".vh"]} {
      set entry "#vlog $element # Header file"
    } else {
      set entry "vlog $element"
    }

    puts $ipBuildScript $entry
  }

  close $ipBuildScript
} else {
  create_ip_run [get_ips $componentName]
}