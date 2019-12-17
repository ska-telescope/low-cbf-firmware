###############################################################################
#
# Copyright (C) 2014
# ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
# P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

# Purpose: Provide useful commands for simulating Modelsim projects
# Desription:
#
# * The user commands are typically used at the Modelsim prompt are:
#
#   . lp <name> : load HDL library <name>.mpf project
#   . mk <name> : make one or range of HDL library mpf projects
#   . as #      : add signals for # levels of hierarchy to the wave window
#   . ds        : delete all signals from the wave window
#
# * The other procedures in this commands.do are internal command procedures
#   that are typically not used at the Modelsim prompt.
#
# * The recommended project directory structure is:
#
#     $arg_lib/build/modelsim    : Modelsim project file
#                   /quartus     : Quartus project file
#             /src/vhdl          : VHDL source code that gets synthesized
#             /tb/vhdl           : VHDL source code for test bench
#
#   Alternatively the build/ directory may be located at another more central
#   location.
#

#-------------------------------------------------------------------------------
# HDL library settings
#-------------------------------------------------------------------------------

echo "Loading general HDL library commands..."

proc hdl_env {} {
    global env
    return $env(RADIOHDL)
}

proc hdl_build {} {
    global env
    return $env(HDL_BUILD_DIR)
}

proc hdl_toolset {} {
    global env
    return $env(TOOLSET)
}

#-------------------------------------------------------------------------------
# LP = Load project
#-------------------------------------------------------------------------------

proc get_cur_lib {} {
    set mpf [eval project env]
    set cur_lib [string range $mpf [expr [string last / $mpf]+1] [expr [string last . $mpf]-1]]
    return $cur_lib
}

proc lp {{arg_lib ""}} {
    set cur_lib [get_cur_lib]
    if {$arg_lib=="help"} {
        echo ""
        echo "lp \[project\]"
        echo "  possible projects are:"
        echo "    <lib_name> : load project <lib_name>.mpf"
        echo "               : report current project library"
        echo "    all        : report all libraries that the current project library depends on"
        echo "    help       : displays this help"
        echo ""
    } elseif {$arg_lib == "" || $arg_lib == $cur_lib} {
        return $cur_lib
    } elseif {$arg_lib=="all"} {
        read_lib_compile_order_file $cur_lib
        return
    } else {
        set sim [simdir $arg_lib]
        if {[eval project env]!=""} {
            project close                 ;# close current project
        }
        project open $sim/$arg_lib.mpf    ;# load project for the requested library
        return $arg_lib
    }
}


#-------------------------------------------------------------------------------
# MK = Make project
#-------------------------------------------------------------------------------

proc project_mk_cmds {} {
    return {clean execute compile files make test vmake}   ;# mk with arg_cmd="" will default to "make"
}

# Get commands from the mk args
proc parse_for_cmds arg_list {
    set cmds {}
    if [ string equal $arg_list "help" ] then {
        echo ""
        echo "mk \[commands\] \[projects\]"
        echo "  possible commands are:"
        echo "    clean:   removes the library files"
        echo "    execute: runs compile IP scripts"
        echo "    compile: runs project compileall"
        echo "    files:   list files in compile order"
        echo "    help:    displays this help"
        echo "    make:    runs makefile"
        echo "    test:    runs test cases"
        echo "    vmake:   creates makefile"
        echo ""
        echo "  commands are executed for the projects indicated"
        echo "  - when no command is specified, 'make' is used as default"
        echo "  - when no projects are specified, the current project is used"
        echo "  - when the keyword 'all' is specified, then the command is applied to all projects that the current project depends on"
        echo ""
        return
    } else {
        # search for commands in arg_list
        foreach cmd [project_mk_cmds] {
            if {[lsearch $arg_list $cmd] >= 0} then {
                lappend cmds $cmd
            }
        }
        if {[llength $cmds] == 0} then {
            # no commands found, use default command
            set cmds {make}
        }
    }
    return $cmds
}

# Get libraries from the mk args
proc parse_for_libs arg_list {
    # strip the commands from arg_list to keep only the libraries
    set libs $arg_list
    foreach cmd [project_mk_cmds] {
        set i [lsearch $libs $cmd]
        if {$i >= 0} then {
            set libs [lreplace $libs $i $i]
        }
    }
    return $libs
}

# Create work library
proc do_vlib arg_work {
    set modelsimId [vsimId]
    set dot_index [string first . $modelsimId]
    set majorId [string range $modelsimId 0 [expr $dot_index-1]]
    if {$majorId <= 6} {
        vlib $arg_work
    } else {
        # The makefile that is created by vmake relies on using directories in vlib
        vlib -type directory $arg_work
    }
}

# Extract this lib or all libs that it depends on for arg_lib
proc extract_all_libs arg_lib {
    if {$arg_lib=="all"} {
        set cur_lib [get_cur_lib]
        return [read_lib_compile_order_file $cur_lib]
    } else {
        return $arg_lib
    }
}

# General make project
proc mk args {
    # Parse the args, the args is a special TCL argument because it allows more than one formal.
    set arg_cmd [parse_for_cmds $args]
    set arg_lib [parse_for_libs $args]
    # Extract arg_lib or all libs that it depends on for arg_lib
    set arg_lib [extract_all_libs $arg_lib]

    # keep current lib
    set cur_lib [get_cur_lib]

    # Without arguments mk current lib
    if { [llength $arg_lib] == 0 } {
        set arg_lib $cur_lib
    }
    # Perform the commands on the specified libs
    foreach cmd $arg_cmd {
        foreach lib $arg_lib {
            if { [ catch { eval ["mk_$cmd" $lib] } msg ] } {
                echo $msg
            }
        }
    }

    # back to original lib
    lp $cur_lib
}

proc mk_clean {arg_lib} {
    echo "\[mk clean $arg_lib\]"
    set sim [simdir $arg_lib]
    if {[file exists "$sim/work"]} then {
        vdel -lib $sim/work -all
    }
    if {[file exists "$sim/makefile"]} then {
        file delete $sim/makefile
    }
    if {[file exists "$sim/vsim.wlf"]} then {
        file delete $sim/vsim.wlf
    }
    if {[file exists "$sim/$arg_lib.cr.mti"]} then {
        file delete $sim/$arg_lib.cr.mti
    }
}

proc mk_execute {arg_lib} {
    # if there are compile scripts for IP files then first use use mk_execute to compile those into this work
    set compile_ip [read_lib_compile_ip_file $arg_lib]
    if {[llength $compile_ip] > 0} {
        echo "\[mk execute $arg_lib\]"
        set sim [simdir $arg_lib]
        lp $arg_lib
        # create work library if it does not already exist
        if {![file exists "$sim/work"]} then {
            do_vlib work
        }
        global env   ;# Make global env() variable known locally. This is necessary for $env(*) in compile IP tcl script, alternatively use $::env(*) in compile IP tcl scrip
        foreach ip $compile_ip {
            echo "do $ip"
            do ${ip}.do
        }
    }
}

proc mk_compile {arg_lib} {
    set sim [simdir $arg_lib]
    if {[string compare [env] "<No Context>"] != 0} {
        echo "A project cannot be closed while a simulation is in progress.\nUse the \"quit -sim\" command to unload the simulation first."
        return
    }
    echo "\[mk compile $arg_lib\]"
    lp $arg_lib
    # recreate work library
    if {[file exists "$sim/work"]} then {
        vdel -lib $sim/work -all
    }
    do_vlib work
    # and then first execute any IP compile scripts
    mk_execute $arg_lib
    # and then compile the HDL
    project compileall
}

proc mk_files {arg_lib} {
    lp $arg_lib
    foreach file [project compileorder] {
        echo $file
    }
}

proc mk_vmake {arg_lib} {
    set sim [simdir $arg_lib]
    if {![file exists "$sim/work/_info"]} then {
        mk_compile $arg_lib

        if {[file exists "$sim/makefile"]} then {
            file delete $sim/makefile
        }
    }
    echo "\[mk vmake $arg_lib\]"
    if {![file exists "$sim/makefile"] || ([file mtime "$sim/makefile"] < [file mtime "$sim/work/_info"]) } then {
        # Both the specific library name $(arg_lib)_lib and the work library map to the same local work library,
        # so to be compatible for both names always use work to generate the makefile

        echo [exec vmake -fullsrcpath work > $sim/makefile]
    }
    # recreate work library
    vdel -lib $sim/work -all
    do_vlib work
    # and then first execute any IP compile scripts
    mk_execute $arg_lib
}

proc mk_make {arg_lib} {
    set sim [simdir $arg_lib]
    if {![file exists "$sim/makefile"] } then {
        mk_vmake $arg_lib
    }
    echo "\[mk make $arg_lib\]"
    if {[this_os]=="Windows"} {
        echo [exec [hdl_env]/tools/bin/make.exe -C $sim -s -k -f makefile]
    } else {
        echo [exec /usr/bin/make -C $sim -s -k -f makefile]
    }
}

proc mk_test {arg_lib} {
  echo "\[mk test $arg_lib\]"
  radix -decimal
  vsim -quiet tst_lib.tb_$arg_lib
  set tb [tbdir $arg_lib]

  foreach tc [glob -directory $tb/data -type d -nocomplain tc*] {
      echo "testcase $tc"
      foreach fileName [glob -directory $tc -type f -nocomplain *.in *.out *.ref] {
          file copy -force $fileName .
      }
      restart -force
      run 1 ms
      foreach fileName [glob -dir . -type f -nocomplain *.in *.out *.ref] {
          file delete -force $fileName
      }
  }
  quit -sim
}


#-------------------------------------------------------------------------------
# Auxiliary procedures
#-------------------------------------------------------------------------------

proc read_modelsim_project_files_file {} {
    set fp [open [hdl_build]/[hdl_toolset]/modelsim/modelsim_project_files.txt]
    set data [read $fp]
    close $fp
    set lines [split $data \n]
    set lib_names {}
    set mpf_paths {}
    foreach line $lines {
        set ll [split $line]
        if {[lindex $ll 1]== "="} {
            lappend lib_names [lindex $ll 0]
            lappend mpf_paths [lindex $ll 2]
        }
    }
    set ret {}
    lappend ret $lib_names
    lappend ret $mpf_paths
    return $ret
}

proc read_lib_compile_order_file {arg_lib} {
    set sim [simdir $arg_lib]
    set file_name $arg_lib
    append file_name "_lib_order.txt"
    set fp [open $sim/$file_name]
    set data [read $fp]
    set data [string trim $data]  ;# trim any trailing white space
    close $fp
    set lib_names [split $data]
    echo $lib_names
    return $lib_names
}

proc read_lib_compile_ip_file {arg_lib} {
    set sim [simdir $arg_lib]
    set file_name $arg_lib
    append file_name "_lib_compile_ip.txt"
    if {[file exists "$sim/$file_name"]} then {
        set fp [open $sim/$file_name]
        set data [read $fp]
        set data [string trim $data]  ;# trim any trailing white space
        close $fp
        set compile_ip [split $data]
        echo $compile_ip
        return $compile_ip
    } else {
        return
    }
}

# Compute simulation directory where the mpf is located
proc simdir {arg_lib} {
    set project_libs [read_modelsim_project_files_file]
    set lib_names [lindex $project_libs 0]
    set mpf_paths [lindex $project_libs 1]
    set lib_index [lsearch $lib_names $arg_lib]
    if {$lib_index >= 0} {
        return [lindex $mpf_paths $lib_index]
    } else {
        error "Project directory $arg_lib not found"
        return -1
    }
}

# Compute tb directory
proc tbdir {arg_lib} {
}

# find out which environment operating system we are on
proc this_os {} {
    if {$::tcl_platform(platform)=="windows"} {
        return "Windows"
    } else {
        return "Not Windows"   ;# Linux, Unix, ...
    }
}


#-------------------------------------------------------------------------------
# DS = Delete Signals : deletes all signals in the waveform window.
#-------------------------------------------------------------------------------
proc ds {} {
    delete wave *
}

#-------------------------------------------------------------------------------
# AS = Add signals : adds all signals up to hierarchy depth to the wave window
#-------------------------------------------------------------------------------
proc as {depth {inst ""}} {
    #asf $depth
    asg $depth $inst
}

#-------------------------------------------------------------------------------
# ASF = add signals flat : flat adds all signals up to hierarchy depth to the wave window
# It will automatically add dividers between the blocks, and it will discard all
# nxt_ and i_ signals. Altera alt_ blocks will also be ignored.
#-------------------------------------------------------------------------------
proc asf depth {
    global env
    # Start with all signals in the model.
    add wave -noupdate -divider {as}
    add wave -noupdate -depth $depth -r "/*"
    # Allow users to set environment variable if they don't want the signals to be deleted
    if { ![info exists ::env(MODELSIM_WAVE_NO_DEL) ] } {
        delete wave */nxt_*
        delete wave */i_*
    }
    #delete wave */alt*
    configure wave -signalnamewidth 0
    echo "Done."
}

#-------------------------------------------------------------------------------
# ASG = add signals in groups : recursively scans the hierarchy and adds signals
#       groupwise to the wave window.
#       Normal use:
#       . asg [depth]
#         => Adds all signals down to a depth of [depth].
#       Advanced/debugging use:
#       . asg [depth] [instance_name]
#         => Adds all signals in [instance_name] down to to a level of [depth]
#         NOTE: instance_name = NOT the entity name!
#-------------------------------------------------------------------------------
proc asg {depth {inst ""}} {
    add_wave_grouped_recursive "" "" $depth $inst 0
    wave refresh
    # The grouping already displays the hierarchy, so use short signal names.
    config wave -signalnamewidth 1
    # With our short signal names, the name column can be narrower than default.
    config wave -namecolwidth 300
}

# called by ASG:
proc add_wave_grouped_recursive {current_level prev_group_option depth target_inst target_inst_det} {
    # Find all instances (=next hierarchy levels) in the ecurrent hierarchy level
    set found_instances [find instances "$current_level/*"]

    # Find all blocks (=GENERATE statement labels that are also hierarchy levels to be explored)
    set found_blocks [find blocks "$current_level/*"]

    # Concatenate the instance list with the block list, sort them alphabetically
    set objects [lsort -dictionary [concat $found_instances $found_blocks]]

    foreach object $objects {
        # Separate "/object_path"  from "(entity_name)"
        set object_path [lindex [split $object " "] 0]
        # Get the word after last "/"
        set gname [lrange [split $object_path "/"] end end]

        if {[path_depth $object_path]<$depth} {
            if { $gname == $target_inst || $target_inst_det==1}  {
                # Found an instance that matches user input - or we're already inside that instance.
                add_wave_grouped_recursive "$object_path" "$prev_group_option -group $gname" $depth $target_inst 1
            } else {
                add_wave_grouped_recursive "$object_path" "$prev_group_option -group $gname" $depth $target_inst 0
            }
        }
    }

    if { $current_level != "" } {
        # First check if what we're about to add is an instance, not merely a GENERATE level
        if {[context isInst $current_level]==1} {
            set CMD "add wave -noupdate -radix unsigned $prev_group_option $current_level/*"

            if {$target_inst!=""} {
                # User passed a target inst. Check if we inside of it.
                if {$target_inst_det==0} {
                    # We're not in in instance. Only add a group and move on.
                    set CMD "add wave -noupdate -radix unsigned $prev_group_option"
                }
            }
            # Use catch so e.g. empty entities don't cause script to fail
            catch {eval $CMD}
        }
        return
    }
}

# Count the number of occurences in a string:
proc scount {subs string} {
    regsub -all $subs $string $subs string
}

# Return the depth of a given path; e.g. /some/path/to/some/thing = 5.
proc path_depth path {
    scount "/" $path
}


#-------------------------------------------------------------------------------
# NOWARN default disables the library warnings for subsequent simulation runs.
# Use argument 0 to enable the warnings again.
#-------------------------------------------------------------------------------
proc nowarn {{off 1}} {
    set ::StdArithNoWarnings   $off
    set ::NumericStdNoWarnings $off
}
