proc write_ip_tcl_script {component} {
  puts "set componentName $component"
  set type [lindex [split [get_property ipdef [get_ips $component]] :] {2}]
  set lib [lindex [split [get_property ipdef [get_ips $component]] :] {1}]
  set vendor [lindex [split [get_property ipdef [get_ips $component]] :] {0}]
  puts "create_ip -name $type -vendor $vendor -library $lib -module_name \044componentName"
  puts -nonewline {set_property -dict [list }

  foreach IPfile [get_ips $component] {
    foreach prop [list_property [get_ips $IPfile] -regexp {^CONFIG\.\w+$}] {
      if {[get_property $prop\.value_src [get_ips $IPfile]]=="user"} {
        puts -nonewline "$prop {[get_property $prop [get_ips $IPfile]]} "
      }
    }
  }
  puts {] [get_ips $componentName]}
  puts {source $env(RADIOHDL)/libraries/technology/build_ip.tcl}
}