#! /bin/env tclsh
# ----------------------------------
# Vivado AXI->Gemini M&C
#
# ----------------------------------

set AXI_DEVICE hw_axi_1 ;              # <= must be set to AXI device ID from HW manager

proc axi_read {addr rlength} {
   global AXI_DEVICE
   set txn [create_hw_axi_txn tmp_rd_txn [get_hw_axis $AXI_DEVICE] -address $addr -len $rlength -type read -force]
   run_hw_axi $txn
   return [scan [get_property DATA $txn] %x]
}

proc axi_write {addr words} {
   global AXI_DEVICE
   
   set data_list {}
   set i 0
   foreach write_word $words {
      lappend data_list [format 0x%08X $write_word]
      incr i
   }

   set txn [create_hw_axi_txn tmp_wr_txn [get_hw_axis $AXI_DEVICE] -address $addr -data $data_list -len $i -type write -force]
   run_hw_axi $txn
   return 0
}

proc dec2bin i {
   #returns a string, e.g. dec2bin 10 => 1010 
   set res {} 
   while {$i>0} {
      set res [expr {$i%2}]$res
      set i [expr {$i/2}]
   }
   if {$res == {}} {set res 0}
   
   return $res
}

proc bin2dec {num} {
   set num h[string map {1 i 0 o} $num]
   while {[regexp {[io]} $num]} {
      set num\
        [string map {0o 0 0i 1 1o 2 1i 3 2o 4 2i 5 3o 6 3i 7 4o 8 4i 9 ho h hi h1}\
          [string map {0 o0 1 o1 2 o2 3 o3 4 o4 5 i0 6 i1 7 i2 8 i3 9 i4} $num]]
   }
   string range $num 1 end
}

proc conv_float d {
   set a [dec2bin $d]
   
   if {$a == 0} {
      return 0.0
   }
   
   set exp [expr {[bin2dec [string range $a 0 4]] - 32}]
   set mant [bin2dec [string range $a 5 15]]      
     
   return [expr {double($mant) * (2 ** double($exp))}]
}

# ----------------------------------
# Monitor function

proc monitor {} {

   # Humidity
   set temp [axi_read 0x6108 1]
   puts [format "Ambient Humidity = %.1f%%" [expr {(double($temp) * 125/65536) -6 }]]

   set temp [axi_read 0x610c 1]
   puts [format "Ambient Temperature = %.1f C" [expr {(double($temp) * 175.72/65536) -46.85 }]]

   # SFP
   set temp [axi_read 0x3108 1]
   puts [format "SFP Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x310c 1]
   puts [format "SFP TX Bias = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x3110 1]
   puts [format "SFP TX Power = %.2f uW" [expr {double($temp) * 0.1}]]

   set temp [axi_read 0x3114 1]
   puts [format "SFP RX Power = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x3118 1]
   puts [format "SFP Temperature = %.1f C" [expr {double($temp) * 1/256}]]

   # QSFP
   set temp [axi_read 0x210c 1]
   puts [format "QSFP A Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x2110 1]
   puts [format "QSFP A TX Bias 0 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2114 1]
   puts [format "QSFP A TX Bias 1 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2118 1]
   puts [format "QSFP A TX Bias 2 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x211c 1]
   puts [format "QSFP A TX Bias 3 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2120 1]
   puts [format "QSFP A RX Power 0 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2124 1]
   puts [format "QSFP A RX Power 1 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2128 1]
   puts [format "QSFP A RX Power 2 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x212c 1]
   puts [format "QSFP A RX Power 3 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2130 1]
   puts [format "QSFP A Temperature = %.1f C" [expr {double($temp) * 1/256}]]

   set temp [axi_read 0x2138 1]
   puts [format "QSFP B Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x213c 1]
   puts [format "QSFP B TX Bias 0 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2140 1]
   puts [format "QSFP B TX Bias 1 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2144 1]
   puts [format "QSFP B TX Bias 2 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2148 1]
   puts [format "QSFP B TX Bias 3 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x214c 1]
   puts [format "QSFP B RX Power 0 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2150 1]
   puts [format "QSFP B RX Power 1 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2154 1]
   puts [format "QSFP B RX Power 2 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2158 1]
   puts [format "QSFP B RX Power 3 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x215c 1]
   puts [format "QSFP B Temperature = %.1f C" [expr {double($temp) * 1/256}]]

   set temp [axi_read 0x2164 1]
   puts [format "QSFP C Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x2168 1]
   puts [format "QSFP C TX Bias 0 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x216c 1]
   puts [format "QSFP C TX Bias 1 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2170 1]
   puts [format "QSFP C TX Bias 2 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2174 1]
   puts [format "QSFP C TX Bias 3 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2178 1]
   puts [format "QSFP C RX Power 0 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x217c 1]
   puts [format "QSFP C RX Power 1 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2180 1]
   puts [format "QSFP C RX Power 2 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2184 1]
   puts [format "QSFP C RX Power 3 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x2188 1]
   puts [format "QSFP C Temperature = %.1f C" [expr {double($temp) * 1/256}]]

   set temp [axi_read 0x2190 1]
   puts [format "QSFP D Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x2194 1]
   puts [format "QSFP D TX Bias 0 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x2198 1]
   puts [format "QSFP D TX Bias 1 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x219c 1]
   puts [format "QSFP D TX Bias 2 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x21a0 1]
   puts [format "QSFP D TX Bias 3 = %.2f mA " [expr {double($temp) * 0.002}]]

   set temp [axi_read 0x21a4 1]
   puts [format "QSFP D RX Power 0 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x21a8 1]
   puts [format "QSFP D RX Power 1 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x21ac 1]
   puts [format "QSFP D RX Power 2 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x21b0 1]
   puts [format "QSFP D RX Power 3 = %.2f uW" [expr {double($temp) * 0.1 }]]

   set temp [axi_read 0x21b4 1]
   puts [format "QSFP D Temperature = %.1f C" [expr {double($temp) * 1/256}]]

   # MBO A
   set temp [axi_read 0x118 1]
   puts [format "MBO A LOS = %s " $temp]   

   set temp [axi_read 0x111c 1]
   puts [format "MBO A TX CDR Unlocked = %s " $temp]   

   set temp [axi_read 0x1120 1]
   puts [format "MBO A RX CDR Unlocked = %s " $temp]  

   set temp [axi_read 0x1124 1]
   puts [format "MBO A Temperature = %.1f C" [expr {double($temp) * 1/256}]]

   set temp [axi_read 0x1128 1]
   puts [format "MBO A TX Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x112c 1]
   puts [format "MBO A RX Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x1130 1]
   puts [format "MBO A Vcch Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   # MBO B
   set temp [axi_read 0x1144 1]
   puts [format "MBO B LOS = %s " $temp]   

   set temp [axi_read 0x1148 1]
   puts [format "MBO B TX CDR Unlocked = %s " $temp]   

   set temp [axi_read 0x114c 1]
   puts [format "MBO B RX CDR Unlocked = %s " $temp]  

   set temp [axi_read 0x1150 1]
   puts [format "MBO B Temperature = %.1f C" [expr {double($temp) * 1/256}]]

   set temp [axi_read 0x1154 1]
   puts [format "MBO B TX Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x1158 1]
   puts [format "MBO B RX Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x115c 1]
   puts [format "MBO B Vcch Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   # MBO C
   set temp [axi_read 0x1170 1]
   puts [format "MBO C LOS = %s " $temp]   

   set temp [axi_read 0x1174 1]
   puts [format "MBO C TX CDR Unlocked = %s " $temp]   

   set temp [axi_read 0x1178 1]
   puts [format "MBO C RX CDR Unlocked = %s " $temp]  

   set temp [axi_read 0x117c 1]
   puts [format "MBO C Temperature = %.1f C" [expr {double($temp) * 1/256}]]

   set temp [axi_read 0x1180 1]
   puts [format "MBO C TX Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x1184 1]
   puts [format "MBO C RX Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   set temp [axi_read 0x1188 1]
   puts [format "MBO C Vcch Rail = %.2fV" [expr {double($temp) * 0.0001 }]]

   # FPGA Core supplies
   set temp [axi_read 0x104 1]
   puts [format "0.72A Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x108 1] 
   puts [format "0.72A Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -13)}] $temp]

   set temp [axi_read 0x10c 1]
   puts [format "0.72A Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x110 1]
   puts [format "0.72A Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x118 1]
   puts [format "0.72B Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x11c 1]
   puts [format "0.72B Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -13)}] $temp]

   set temp [axi_read 0x120 1]
   puts [format "0.72B Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x124 1]
   puts [format "0.72B Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x12c 1]
   puts [format "0.72C Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x130 1]
   puts [format "0.72C Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -13)}] $temp]

   set temp [axi_read 0x134 1]
   puts [format "0.72C Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x138 1]
   puts [format "0.72C Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x140 1]
   puts [format "0.85V Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x144 1]
   puts [format "0.85V Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -12)}] $temp]

   set temp [axi_read 0x148 1]
   puts [format "0.85V Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x14c 1]
   puts [format "0.85V Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x158 1]
   puts [format "0.9V Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x15c 1]
   puts [format "0.9V Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -12)}] $temp]

   set temp [axi_read 0x160 1]
   puts [format "0.9V Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x164 1]
   puts [format "0.9V Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x168 1]
   puts [format "0.9V Temp int = %.2f C (%x)" [conv_float $temp ] $temp]
   
   set temp [axi_read 0x170 1]
   puts [format "1.2A Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x174 1]
   puts [format "1.2A Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -12)}] $temp]

   set temp [axi_read 0x178 1]
   puts [format "1.2A Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x17c 1]
   puts [format "1.2A Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x180 1]
   puts [format "1.2A Temp int = %.2f C (%x)" [conv_float $temp ] $temp]
   
   set temp [axi_read 0x188 1]
   puts [format "1.2B Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x18c 1]
   puts [format "1.2B Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -12)}] $temp]

   set temp [axi_read 0x190 1]
   puts [format "1.2B Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x194 1]
   puts [format "1.2B Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x198 1]
   puts [format "1.2B Temp int = %.2f C (%x)" [conv_float $temp ] $temp]
   
   set temp [axi_read 0x1a0 1]
   puts [format "1.8V Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1a4 1]
   puts [format "1.8V Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -12)}] $temp]

   set temp [axi_read 0x1a8 1]
   puts [format "1.8V Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1ac 1]
   puts [format "1.8V Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1b0 1]
   puts [format "1.8V Temp int = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1b8 1]
   puts [format "2.5V Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1bc 1]
   puts [format "2.5V Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -12)}] $temp]

   set temp [axi_read 0x1c0 1]
   puts [format "2.5V Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1c4 1]
   puts [format "2.5V Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1c8 1]
   puts [format "2.5V Temp int = %.2f C (%x)" [conv_float $temp ] $temp]
   
   set temp [axi_read 0x1d0 1]
   puts [format "3.3V Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1d4 1]
   puts [format "3.3V Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -12)}] $temp]

   set temp [axi_read 0x1d8 1]
   puts [format "3.3V Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1dc 1]
   puts [format "3.3V Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1e0 1]
   puts [format "3.3V Iout 2 = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1e4 1]
   puts [format "3.3V Temp 2 = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1e8 1]
   puts [format "3.3V Temp int = %.2f C (%x)" [conv_float $temp ] $temp]
   
   set temp [axi_read 0x1f0 1]
   puts [format "12V Vin = %.2fV (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1f4 1]
   puts [format "12V Vout = %.2fV (%x)" [expr {double($temp) * (2.0 ** -11)}] $temp]

   set temp [axi_read 0x1f8 1]
   puts [format "12V Iout = %.3fA (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x1fc 1]
   puts [format "12V Temp = %.2f C (%x)" [conv_float $temp ] $temp]

   set temp [axi_read 0x200 1]
   puts [format "12V Temp int = %.2f C (%x)" [expr {double($temp) * (2.0 ** -11)}] $temp]

}







# Serial Number Write
#axi_write 0x4006 0x64
#axi_write 0x4007 0xca000000
#axi_write 0x4001 0x20

# Serial Number read
#axi_write 0x4001 0x40 
#axi_read 0x4000 1
#axi_read 0x4004 1
#axi_read 0x4005 1

# Default IP address Write
#axi_write 0x4006 0xc0A80102
#axi_write 0x4007 0xab000000
#axi_write 0x4001 0x21

# Default IP addres read
#axi_write 0x4001 0x41 
#axi_read 0x4000 1
#axi_read 0x4004 1
#axi_read 0x4005 1


# Program pmbus i2c transaction
#axi_write 0 0x09
#axi_write 1 0x10
#axi_write 2 0xe7
#axi_write 3 0x13
#axi_write 4 0x11
#axi_write 0x81 4

# Read response
#axi_read 0x82 1
#axi_read 0x20 1
#axi_read 0x21 1


#axi_write 0 0x09
#axi_write 1 0x10
#axi_write 2 0x8e
#axi_write 3 0x13
#axi_write 4 0x11
#axi_write 0x81 4

#axi_read 0x82 1
#axi_read 0x20 1
#axi_read 0x21 1