Purpose
-------


Tool:
-----
Xilinx/Vivado 2017.2


Quick steps to compile and use design [kcu105_mac10g_test] in RadionHDL
-----------------------------------------------------------------------

1.

-> For complete synthesis of this design until bitstream-file do:
    python $RADIOHDL/tools/radiohdl/base/vivado_config.py -t kcu105 -l kcu105_mac10g_test -r -v3

    -t: technology
    -l: the design name
    -r: do compile all until bitstream file
    -v: verbose

    if in doubt: add -h for help

The python scripts create projectfiles and bitstream file in the [build] directory: $RADIOHDL/build


2.

Test on hardware.
The kcu105 board is connected via JTAG/USB to the server at CSIRO: ASKAP-DGS0D (IP addr 130.155.203.23)

Start the Xilinx hw_server on that machine:

ssh root@130.155.203.23
cd /opt/Xilinx/HWSRVR/2017.2/bin/
./hw_server -s tcp::3122

Then in the Vivado, remotely, program the FPGA, using this server/port.

After the FPGA image is loaded the 10G link can be tested via the server where the 10G link is attached to:

ssh -X hie004@perseus.atnf.csiro.au

/sbin/ifconfig eth6
# shows that the 10G NIC has the IP address: 10.32.1.1  
# the kcu105 has the IP address (hardcoded): 10.32.1.2 (mac address: 1a:2b:3c:4d:5e:6f)

# manually add the kcu105 to the ARP table:
sudo /usr/sbin/arp -s 10.32.1.2 1a:2b:3c:4d:5e:6f -i eth6

# for packet monitoring, tcpdump can be used:
sudo /usr/sbin/tcpdump -i eth6 -XXvve

# or wireshark:
wireshark


