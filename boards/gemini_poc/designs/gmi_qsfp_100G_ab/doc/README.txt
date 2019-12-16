Purpose
-------


Tool
----
Vivado 2016.4


Quick steps to compile and use design [gmi_test_i2c] in RadionHDL
-----------------------------------------------------------------

-> In case it is necessary to compile the AXI slave IP's: see:
    $RADIOHDL/boards/gemini/doc/README.txt

-> In case it is necessary to compile the .bd file:
    cd $RADIOHDL/boards/gemini/designs/gmi_qsfp_100G_ab/vivado/bd/src
    excute [gmi_qsfp_axi.tcl] script in Vivado

1.
-> In case of needing a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


-> For complete synthesis of this design until bitstream-file do:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t gmi -l gmi_qsfp_100G_ab -r -v3

    -t: technology
    -l: the design name
    -r: do compile all until bitstream file
    -v: verbose

    if in doubt: add -h for help

The python scripts create projectfiles and bitstream file in the [build] directory: $RADIOHDL/build



2. Test on hardware: the Gemini board:

    
To get rid of the Vivado message sizelimit:

set_param messaging.defaultLimit 100000
set addr_led    0x44a00000
set addr_reg    0x44a10000
set addr_avs    0x44a20000
set addr_m3     0x44a40000
set addr_m4     0x44a30000

proc mm_write { addr  data } {
  create_hw_axi_txn wr_txn [get_hw_axis hw_axi_1] -address [format %08x $addr] -data [format %08x $data] -type write -force
  run_hw_axi [get_hw_axi_txns wr_txn]
  after 10
}

proc mm_read { addr } {
  create_hw_axi_txn rd_txn [get_hw_axis hw_axi_1] -address [format %08x $addr] -len 1 -type read -force
  run_hw_axi [get_hw_axi_txns rd_txn]
  return [get_property DATA [get_hw_axi_txn rd_txn]]
}



for {set addr 0x44A20000} {$addr<0x44A20080} {incr addr} {
   puts "ADDR=0x[format %x $addr]  VAL= [ mm_read $addr ]"
   after 10
}

----
I2C convert optics_l QSFP sensors
readout was:
INFO: [Labtoolstcl 44-481] READ DATA is: 0000000d
ADDR=0x44a20054  VAL= 0000000d
INFO: [Labtoolstcl 44-481] READ DATA is: 00000023
ADDR=0x44a20055  VAL= 00000023
INFO: [Labtoolstcl 44-481] READ DATA is: 000000ff
ADDR=0x44a20056  VAL= 000000ff
INFO: [Labtoolstcl 44-481] READ DATA is: 0000007f
ADDR=0x44a20057  VAL= 0000007f
INFO: [Labtoolstcl 44-481] READ DATA is: 000000f6
ADDR=0x44a20058  VAL= 000000f6

id=0xd

Voltage:
octave:3> (0x7f*256+0xf6)*0.0001
ans =  3.2758

Temperature:
octave:4> (0x23*256+0xff)/256
ans =  35.996
----



# walk through LEDs:
for {set i 0} {$i<100} {incr i} {
   mm_write $addr_led 0x00ffffff
   after 10
   mm_write $addr_led 0x00000000
   after 10
}


----
QSFP (A) 4 loopback links to itself (TX0:3 - RX0:3)
Successful test result:

mm_read 0x44a10000
INFO: [Labtoolstcl 44-481] READ DATA is: 00441d00
                                             ^^

#To restart the test:
mm_write 0x44a10000 0x20
#INFO: [Labtoolstcl 44-481] WRITE DATA is: 00000020
mm_write 0x44a10000 0x0
#INFO: [Labtoolstcl 44-481] WRITE DATA is: 00000000
mm_read 0x44a10000
#INFO: [Labtoolstcl 44-481] READ DATA is: 00441d00

bit8 : TX_done
bit9 : TX_busy
bit10: RX GT locked
bit11: RX aligned
bit12: RX_done
bit13: RX data fail
bit14: RX_busy


#QSFP cage reset:
mm_write 0x44a10000 0xf
mm_write 0x44a10000 0x0

#NEW:
#-----
#QSFP A to/from B. Control via AXI:
#set sanity_init_dones to 0, restart
mm_write 0x44a10000 0x0020
mm_write 0x44a10000 0x0000

#reset ADDR_GT_RESET_REG
mm_write 0x44a30000 1
mm_write 0x44a40000 1
mm_write 0x44a30000 0
mm_write 0x44a40000 0

#reset ADDR_RESET_REG
mm_write 0x44a30004 1
mm_write 0x44a40004 1
mm_write 0x44a30004 0
mm_write 0x44a40004 0


# tick register:
mm_write 0x44a302B0 1
mm_write 0x44a402B0 1

#read result LEDs:
mm_read 0x44a10000
# I see: 004e4e00

#set sanity_init_dones to 0:
mm_write 0x44a10000 0x00

#ADDR_CONFIG_RX_REG1 to 1 (state STATE_INIT_RX_ALIGNED)
mm_write 0x44a40014 1
mm_write 0x44a30014 1
#ADDR_CONFIG_TX_REG1 to 0x18
mm_write 0x44a3000C 0x18
mm_write 0x44a4000C 0x18

#intermediate read result LEDs:
mm_read 0x44a10000

#ADDR_CONFIG_TX_REG1 to 1 (state STATE_INIT_PKT_TRANSFER)
mm_write 0x44a4000C 0x1
mm_write 0x44a3000C 0x1

#intermediate read result LEDs:
mm_read 0x44a10000

#set sanity_init_dones to 1:
mm_write 0x44a10000 0x1100

#read result LEDs:
mm_read 0x44a10000
# I see: 005f5f00

#pull out cable,
#read result LEDs:
mm_read 0x44a10000
# I see: 00050500
# run test again (with pulled out cable)
# I see: 00040400



# tick register:
mm_write 0x44a302B0 1
mm_write 0x44a402B0 1


# read nof tx packets
mm_read 0x44a30500
mm_read 0x44a40500

# read error stat
mm_read 0x44a30200
mm_read 0x44a40200
