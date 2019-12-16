Purpose
-------


Tool
----
Vivado 2016.4


Quick steps to compile and use design [gmi_test_i2c] in RadionHDL
-----------------------------------------------------------------

1.
-> In case of needing a fresh compilation, delete the build directory.
    rm -r $RADIOHDL/build


-> For complete synthesis of this design until bitstream-file do:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t gmi -l gmi_test_i2c -r -v3

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
set addr_avs    0x44a20000

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
