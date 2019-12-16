# -*- coding: utf-8 -*-
"""
Created on Fri Jul 12 23:27:47 2019

@author: hum089
"""

import numpy as np
import inspect
from datetime import datetime

def generateVHDLCRC32_64step(fname = 'crc32Full64Step', outputDirectory = 'generated_code/'):
    # Generates code to calculate the ethernet crc32, with 8 bytes of new data.
    # there are 32 bits of state information, and 64 new input bits.
    # For bytesIn = 8, the function updates the state using all 8 bytes of the new data.
    # The new state of each bit is an xor of some combination of the 32 current state bits and the 64 new bits.
    # The bits which contribute to the XOR depend on the number of bytes being shifted in.
    # This function calculates that combination for each of the 8 cases, and generates look up tables.
    # There are 96 input bits in total, so there are 96/6 = 16 look up tables for each of the 32 
    # state bits we need to generate.
    #
    # The Ethernet CRC 32 polynomial is 0x04C11DB7
    polynomial = np.int32([0,0,0,0,0,1,0,0,1,1,0,0,0,0,0,1,0,0,0,1,1,1,0,1,1,0,1,1,0,1,1,1])
    variableList = '\n'
    codeList = '\n'
    codeList1 = '\n'
    variableList += '   signal allbits : std_logic_vector(95 downto 0);\n'
    variableList += '   signal cur_state : std_logic_vector(31 downto 0);\n'
    variableList += '   signal new_state : std_logic_vector(31 downto 0);\n'
    codeList += '   allbits <= data_i & cur_state when sof_i = \'0\' else data_i & x\"ffffffff\"; -- Concatenate the data bits and state bits to make selecting them easier \n'
    for generatedBit in range(32):
        print('making bit ' + str(generatedBit))
        dataBitName = 'LUT_gen' + str(generatedBit)
        variableList += '   signal ' + dataBitName + ' : std_logic_vector(15 downto 0);\n'
        LUTMax = 16  # 16 LUTs per generated bit
        for LUT in range(LUTMax):
            # Generate the address to this LUT. Top 3 bits are the shift size, low three bits are data.
            addrName = 'LUT_gen' + str(generatedBit) + '_block' + str(LUT) + '_addr'
            dataName = 'LUT_gen' + str(generatedBit) + '_block' + str(LUT) + '_data'
            # Generate the LUT contents.
            ROMContents = np.zeros(64)
            shift = 0 # Note shift = 0 is used here to mean all 8 bytes were shifted in. (and 1 for one byte etc)
            bitsToShiftIn = 64
            bitsMax = 64  # groups of 6 bits per LUT, so 64 combinations.
            for bits in range(bitsMax):
                # LUT contents are '1' if the binary representation of the number "bits" will generate a 
                # 1 in state register bit "generatedBit" when the number of bytes shifted in is "shift"
                fullState = np.zeros(96,dtype = np.int32)
                fullStateNew = np.zeros(96,dtype = np.int32)
                fullState[6*LUT] = bits % 2
                fullState[6*LUT + 1] = (bits // 2) % 2
                fullState[6*LUT + 2] = (bits // 4) % 2
                fullState[6*LUT + 3] = (bits // 8) % 2
                fullState[6*LUT + 4] = (bits // 16) % 2
                fullState[6*LUT + 5] = (bits // 32) % 2
                for shiftCount in range(bitsToShiftIn):
                    for polybit in range(32):
                        if (polynomial[polybit] == 1):
                            if (polybit == 31):
                                fullStateNew[polybit] = fullState[0] ^ fullState[32]
                            else:
                                fullStateNew[polybit] = fullState[polybit+1] ^ fullState[0] ^ fullState[32]
                        else:
                            fullStateNew[polybit] = fullState[polybit + 1]
                    for otherbit in range(32,95):
                        fullStateNew[otherbit] = fullState[otherbit + 1]
                    fullStateNew[95] = 0                        
                    #if ((bitsToShiftIn == 64) and (bits == 1) and (generatedBit == 0) and (LUT == 11)):
                    #    print(fullState[0:40].tolist())
                    fullState = fullStateNew.copy()
                ROMContents[bits] = fullState[generatedBit]
                
            # put ROMContents into a 64 bit vector
            ROMList = list('0000000000000000000000000000000000000000000000000000000000000000')
            ROMAllZero = True
            for ROMIndex in range(64):
                if (ROMContents[ROMIndex] == 1):
                   ROMList[63-ROMIndex] = '1'
                   ROMAllZero = False
            if ROMAllZero:
                codeList += '   ' + dataBitName + '(' + str(LUT) + ') <= \'0\';\n'
            else:
                ROMString = "".join(ROMList)
                variableList += '   signal ' + addrName + ' : std_logic_vector(5 downto 0);\n'
                variableList += '   constant ' + dataName + ' : std_logic_vector(63 downto 0) := \"' + ROMString + '\";\n'
                codeList += '   ' + addrName + ' <= allbits(' + str(6*LUT+5) + ' downto ' + str(6*LUT) + ');\n'
                codeList += '   ' + dataBitName + '(' + str(LUT) + ') <= ' + dataName + '(to_integer(unsigned(' + addrName + ')));\n'
        codeList1 += '   new_state(' + str(generatedBit)  + ') <= '
        for LUT in range(LUTMax):
            codeList1 += dataBitName + '(' + str(LUT) + ')'
            if (LUT == (LUTMax - 1)):
                codeList1 += ';\n'
            else:
                codeList1 += ' xor '
                
    timestamp = str(datetime.now())
    filename = inspect.stack()[0][1]
    vhdl = '-------------------------------------------------------------\n'
    vhdl += '-- Ethernet CRC32 calculate and check \n'
    vhdl += '-- Creation date ' + timestamp + '\n'
    vhdl += '-- Written by python script : ' + filename + '\n'
    vhdl += '-- By David Humphrey (dave.humphrey@csiro.au) \n'
    vhdl += '-- \n'
    vhdl += '-- \n'
    vhdl += '------------------------------------------------------------\n'
    vhdl += '\n'
    vhdl += 'library IEEE;\n'
    vhdl += 'use IEEE.STD_LOGIC_1164.ALL;\n'
    #vhdl += 'use IEEE.STD_LOGIC_ARITH.ALL;\n'
    #vhdl += 'use IEEE.STD_LOGIC_UNSIGNED.ALL;\n'
    vhdl += 'use IEEE.NUMERIC_STD.ALL;\n'
    vhdl += '\n'
    vhdl += 'entity ' + fname + ' is\n'
    vhdl += '   port (\n'
    vhdl += '      clk     : in std_logic;\n'
    vhdl += '      data_i  : in std_logic_vector(63 downto 0);\n'
    vhdl += '      valid_i : in std_logic;\n'
    vhdl += '      sof_i   : in std_logic;\n'
    vhdl += '      state_o : out std_logic_vector(31 downto 0);\n'
    vhdl += '      new_state_o : out std_logic_vector(31 downto 0) -- logic only path from data_i, bytes_i\n'
    vhdl += '   );\n'
    vhdl += 'end ' + fname + ';\n'
    vhdl += '\n'
    vhdl += 'architecture Behavioral of ' + fname + ' is\n'
    vhdl += variableList + '\n'
    vhdl += '   signal valid_del1 : std_logic := \'0\';\n'
    vhdl += 'begin\n'
    vhdl += '   \n'
    vhdl += '   process(clk)\n'
    vhdl += '   begin \n'
    vhdl += '      if rising_edge(clk) then \n'
    vhdl += '         valid_del1 <= valid_i;\n'
    vhdl += '         if valid_i = \'1\' then\n'
    vhdl += '            cur_state <= new_state;\n'
    vhdl += '         end if;\n'
    vhdl += '      end if;\n'
    vhdl += '   end process;\n'
    vhdl += '   \n'    
    vhdl += '   state_o <= cur_state;\n'
    vhdl += '   new_state_o <= new_state;\n'
    vhdl += '   \n'
    vhdl += codeList1 + '\n'
    vhdl += codeList + '\n'
    vhdl += 'end Behavioral;\n'
    
    # write it out to a file   
    f = open(outputDirectory + fname + '.vhd', 'w')
    f.write(vhdl)
    f.close()
    
generateVHDLCRC32_64step(fname = 'crc32Full64Step', outputDirectory = '../vhdl/')


