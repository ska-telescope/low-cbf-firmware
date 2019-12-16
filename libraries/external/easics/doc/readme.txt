
The CRC packages in modules/easics/src/vhdl/ have been generated using the CRC web tool from Easics:

http://www.easics.com/webtools/crctool

The Xilinx application note:

modules/Lofar/diag/doc/xapp052.pdf

lists LFSR feedback coefficients for word lengths from n=3 to 168.

Another interesting Xilinx application note is:

modules/Lofar/diag/doc/xapp217.pdf

This document contains the LFSR that was used to randomize the cross correlation
between X and Y that occurs in the LOFAR PFT.

For most n there exist many LFSR feedback coefficient sets that yield maximum length sequences.

The files:

modules/easics/doc/4stages.txt
modules/easics/doc/8stages.txt
modules/easics/doc/16stages.txt
modules/easics/doc/18stages.txt
modules/easics/doc/20stages.txt
modules/easics/doc/32stages.txt

The reversed polynomial of [m A B C] is [m m-C m-B m-A].

from:

http://www.newwaveinstruments.com/resources/articles/m_sequence_linear_feedback_shift_register_lfsr.htm

give the sets for n=16 and n=32.

The set [ 4, 3]          was used for diag_lfsr4d4(pkg).vhd   that was used in LOFAR DIAG exists in 4stages.txt.
The set [ 8,  7,  6, 1]  was used for diag_lfsr8d8(pkg).vhd   that was used in LOFAR DIAG exists in 8stages.txt.
The set [16, 15, 13, 4]  was used for diag_lfsr16d16(pkg).vhd that was used in LOFAR DIAG exists in 16stages.txt.
The set [32, 31, 30, 10] was used for diag_lfsr32d32(pkg).vhd that was used in LOFAR DIAG exists in 32stages.txt.

The set [16, 12, 5] was used for RAD_CRC16_D16.vhd that was used in LOFAR RAD does not exist  in 16stages.txt.
The set [18,  4, 1] was used for RAD_CRC18_D18.vhd that was used in LOFAR RAD does not exist  in 18stages.txt.
The set [20, 17]    was used for RAD_CRC20_D20.vhd that was used in LOFAR RAD          exists in 20stages.txt.

For modules/easics/src/vhdl/PCK_CRC32_D* the Ethernet polynomial 0 1 2 4 5 7 8 10 11 12 16 22 23 26 32 was used, this does not exist in 32stages.txt
For modules/easics/src/vhdl/PCK_CRC16_D* the USB polynomial 0 2 15 16 was used, this does not exist in 16stages.txt

. If the D* width does not match the user data width, then the user data width can be padded with zeros.
. If the CRC width does not match the link data width, then the CRC can be padded with zeros or the MSBits can be skipped.
