proc write_mmi {bmm_file} {
    set mmi [file rootname $bmm_file]
    set fp [open $bmm_file r]
    set file_data [read $fp]
    close $fp
    set data [split $file_data "\n"]
    set fileout [open "${mmi}.mmi" "w"]
    puts $fileout "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    puts $fileout "<MemInfo Version=\"1\" Minor=\"0\">"
    set proc 0
    set addr_space 0
    set bus_space 0
    set block_count -1   
    for {set i 0} {$i < [llength $data]} {incr i} {
        set comment [string range [string trim [lindex $data $i]] 0 1]
        if {$comment != "//"} {
            set addr_name [string first "ADDRESS_SPACE" [lindex $data $i]]
            set addr_map [string first "ADDRESS_MAP" [lindex $data $i]]
     		set bus_block [string first "BUS_BLOCK" [lindex $data $i]]
            if {$addr_map != -1 && $proc == 0} {
                set proc 1
                puts $fileout " <Processor Endianness=\"[address_map_info [lindex $data $i] endian]\" InstPath=\"dummy\">"
                set proc_name [address_map_info [lindex $data $i] inst]
            } elseif {$addr_map != -1 && $proc == 1} {
                set proc 0
                puts $fileout " </Processor>"
            }  elseif {$addr_name != -1 && $addr_space == 0} {
     			set addr_space 1
     			puts $fileout "    <AddressSpace Name=\"[address_range [lindex $data $i] name]\" Begin=\"[address_range [lindex $data $i] low]\" End=\"[address_range [lindex $data $i] high]\">"
     		} elseif {$addr_name != -1 && $addr_space == 1} {
     			set addr_space 0
     			puts $fileout "    </AddressSpace>"
     		} elseif {$bus_block != -1 && $bus_space == 0} {
     			set bus_space 1
     			set block_count [expr {$block_count + 1}]
     			puts $fileout "      <BusBlock>"
     		} elseif {$bus_block != -1 && $bus_space == 1} {
     			set bus_space 0
     			puts $fileout "      </BusBlock>"
     		} elseif {[string match *RAM_reg* [lindex $data $i]]} {        
                set temp [string trimleft [lindex $data $i]]
                set temp [split $temp " "]
                set bram [lindex $temp 0]
        
                set bmm_msb [bram_info $bram msb]
                set bmm_lsb [bram_info $bram lsb]
                set bram_type "RAMB32"
                set range_begin [bram_info $bram begin]
                set range_end [bram_info $bram end]
                set placed [bram_info $bram location]

                puts $fileout "        <BitLane MemType=\"$bram_type\" Placement=\"$placed\">"
                puts $fileout "          <DataWidth MSB=\"$bmm_msb\" LSB=\"$bmm_lsb\"/>"
                puts $fileout "          <AddressRange Begin=\"$range_begin\" End=\"$range_end\"/>"
                puts $fileout "          <Parity ON=\"false\" NumBits=\"0\"/>"
                puts $fileout "        </BitLane>"
     		}
        }
    }
     
     puts $fileout "<Config>"
     puts $fileout "  <Option Name=\"Part\" Val=\"[get_property PART [current_project ]]\"/>"
     puts $fileout "</Config>"
     puts $fileout "</MemInfo>"
     close $fileout
     puts "Conversion complete. To use updatemem, use the template command line below"
     puts "updatemem -force --meminfo ${mmi}.mmi --data <path to data file>.elf/mem --bit <path to bit file>.bit --proc $proc_name --out <output bit file>.bit"
}

proc bram_info {bram type} {
    set loc [get_property LOC [get_cells -hier $bram]]
    puts $bram
    set temp [split $bram "_"] 
    set row [lindex $temp 4]
    set col [lindex $temp 2]
    puts $col
    if {$type == "msb"} {
        return [expr $col*8+1*8-1]
    } elseif {$type == "lsb"} {
        puts $col
        return [expr $col*8]
    } elseif {$type == "begin"} {
        return [get_property bram_addr_begin [get_cells -hier $bram]]
    } elseif {$type == "end"} {
        return [get_property bram_addr_end [get_cells -hier $bram]]
    } elseif {$type == "type"} {
        return ["RAMB32"]
    } elseif {$type == "location"} {
        puts $loc
        set temp [split $loc "_"]
        return [lindex $temp 1]
    }

}



proc bmm_info {data type} {

	if {$type == "msb"} {
		return [get_bit_lanes $data msb]
	} elseif {$type == "lsb"} {
		return [get_bit_lanes $data lsb]
	} elseif {$type == "begin"} {
		return [get_bit_lanes $data msb]
	} elseif {$type == "end"} {
		return [get_bit_lanes $data lsb]
	}
	
}

proc address_map_info {string type} {
	set temp [split $string " "]
	set endian [lindex $temp 2]
	if {$type == "endian"} {
		if {$endian == "MICROBLAZE-LE"} {
			return "Little"
		} else {
			return "Big"
		}
	} elseif {$type == "inst"} {
		return [lindex $temp 4]
	}
}

proc address_range {string type} {
	set temp [split [string trim $string] " "]
	set range [lindex $temp 3]
	set range [split $range ":"]
	if {$type == "name"} {
		return [lindex $temp 1]
	} elseif {$type == "high"} {
		set high [string range [lindex $range 1] 2 [expr {[string length [lindex $range 1]] - 2 }]]
		return [hex2dec $high]
	} elseif {$type == "low"} {
		set low [string range [lindex $range 0] 3 [string length [lindex $range 0]]]
		return [hex2dec $low]
	}
}

proc hex2dec {largeHex} {
    set res 0
    set largeHex [string range $largeHex 2 [expr {[string length $largeHex] - 1}]]
    foreach hexDigit [split $largeHex {}] {
        set new 0x$hexDigit
        set res [expr {16*$res + $new}]
    }
    return $res
}

