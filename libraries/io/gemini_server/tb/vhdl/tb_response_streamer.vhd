-------------------------------------------------------------------------------
--
-- Copyright (C) 2017
-- CSIRO 
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------


-- Purpose: Testbench for Response Streamer module
-- Description:
--

LIBRARY IEEE, gemini_server_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_textio.ALL;
USE technology_lib.technology_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;

LIBRARY STD;
USE STD.textio.ALL;

ENTITY tb_response_streamer IS
END tb_response_streamer;

ARCHITECTURE tb OF tb_response_streamer IS

    CONSTANT c_clk_period : TIME := 10 ns;
    CONSTANT c_data_w : NATURAL := 64;
    CONSTANT c_technology : t_technology := c_tech_xcku040;
    CONSTANT c_crsb_fifo_w : NATURAL := 80;
    CONSTANT c_crsb_addr_w : NATURAL := 5;

    CONSTANT c_crsb_low_addr : INTEGER := 3;
    CONSTANT c_crsb_high_addr : INTEGER := 19;
    CONSTANT c_ssn : INTEGER := 3;

    TYPE t_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);

    -- Template for Ethernet packet header
    CONSTANT c_pkthdr_arr : t_data_arr(1 TO 5) := ( x"55_40_DD_DD_DD_DD_DD_40",
                                                    x"00_45_00_08_01_55_55_55",
                                                    x"11_00_00_00_00_00_00_00",
                                                    x"DD_DD_55_55_55_55_00_00",
                                                    x"00_00_00_30_30_75_DD_DD" );

    TYPE t_test IS RECORD
        nregs : INTEGER;
        addr : INTEGER;
        ethtx_tkeep : STD_LOGIC_VECTOR(c_data_w/8-1 DOWNTO 0);
        ethtx_len : INTEGER;
        ethtx : t_data_arr(1 TO 10);
    END RECORD t_test;
    
    TYPE t_test_vec IS ARRAY (INTEGER RANGE <>) OF t_test;
    CONSTANT c_test_vec : t_test_vec(1 TO 3) := ( 

            -- Test vector for Gemini PDU 1
            ( nregs => 3, addr => 7 , ethtx_tkeep => x"03", ethtx_len => 9, 
                        ethtx => ( x"00_00_01_02_03_04_05_06",
                                   x"00_45_00_08_00_00_00_00",
                                   x"11_00_00_00_00_00_34_00",  -- IPTotLen = (3+10)*4 = 0x34
                                   x"15_16_00_00_00_00_00_00",
                                   x"20_00_11_12_30_75_13_14",  -- UDPLen = (3+5)*4 = 0x20
                                   x"23_24_03_87_08_01_00_00",
                                   x"33_34_00_00_00_03_21_22",
                                   x"53_54_41_42_43_44_31_32",
                                   x"00_00_00_00_00_00_51_52",
                                   x"00_00_00_00_00_00_00_00" ) ),

            -- Test vector for Gemini PDU 2
            ( nregs => 0, addr => 12 , ethtx_tkeep => x"3F", ethtx_len => 7, 
                        ethtx => ( x"00_00_10_20_30_40_50_60",
                                   x"00_45_00_08_00_00_00_00",
                                   x"11_00_00_00_00_00_28_00", -- IPTotLen = (0+10)*4 = 0x28
                                   x"25_26_00_00_00_00_00_00",
                                   x"14_00_21_22_30_75_23_24",  -- UDPLen = (0+5)*4 = 0x14
                                   x"33_34_03_88_09_01_00_00",
                                   x"00_00_FE_FD_00_00_31_32",
                                   x"FF_FF_FF_FF_FF_FF_FF_FF",
                                   x"FF_FF_FF_FF_FF_FF_FF_FF",
                                   x"FF_FF_FF_FF_FF_FF_FF_FF" ) ),

            -- Test vector for Gemini PDU 3
            ( nregs => 6, addr => 16 , ethtx_tkeep => x"3F", ethtx_len => 10, 
                        ethtx => ( x"00_00_07_08_09_0A_0B_0C",
                                   x"00_45_00_08_00_00_00_00",
                                   x"11_00_00_00_00_00_40_00",  -- IPTotLen = (6+10)*4 = 0x40
                                   x"A5_A6_00_00_00_00_00_00",
                                   x"2C_00_A1_A2_30_75_A3_A4",  -- UDPLen = (6+5)*4 = 0x2C
                                   x"2C_2D_03_89_0A_01_00_00",
                                   x"63_64_FF_FF_00_06_2A_2B",
                                   x"83_84_71_72_73_74_61_62",
                                   x"A3_A4_91_92_93_94_81_82",
                                   x"00_00_B1_B2_B3_B4_A1_A2" ) )

                    );

    SIGNAL crsb_mem : t_data_arr(0 TO c_crsb_high_addr) := ( 

                0 => x"00_00_00_00_00_00_00_00", -- Unused
                1 => x"00_00_00_00_00_00_00_00",
                2 => x"00_00_00_00_00_00_00_00",
                
                3 => x"81_82_83_84_71_72_73_74", -- Continuation of gemini response PDU frame 3 payload
                4 => x"A1_A2_A3_A4_91_92_93_94", 
                5 => x"FF_FF_FF_FF_B1_B2_B3_B4",
                6 => x"00_00_00_00_00_00_00_00", 

                -- CRSB frame containing Gemini PDU 1
                7 => x"00_03_01_02_03_04_05_06",  -- N=3, MACDst x"010203040506"
                8 => x"FF_FF_11_12_13_14_15_16",  -- UDPDstPt x"1112"  IPDstAddr x"13141516"
                9 => x"21_22_23_24_FF_87_08_01",  -- Gemini protocol header: ver 1, cmd ACK, CSN x"87", Addr x"21222324"
                10 => x"31_32_33_34_00_00_00_03", -- Gemini protocol header & payload: nRegs 3, FC 0, Reg1 x"31323334"
                11 => x"51_52_53_54_41_42_43_44", -- Reg2 x"41424344" Reg3 x"51525354"

                -- CRSB frame containing Gemini PDU 2
                12 => x"00_00_10_20_30_40_50_60",  -- N=0, MACDst x"102030405060"
                13 => x"FF_FF_21_22_23_24_25_26",  -- UDPDstPt x"2122"  IPDstAddr x"23242526"
                14 => x"31_32_33_34_FF_88_09_01",  -- Gemini protocol header: ver 1, cmd NACK-T, CSN x"88", Addr x"31323334"
                15 => x"FF_FF_FF_FF_FE_FD_00_00", -- Gemini protocol header: nRegs 0, FC FEFD

                -- CRSB frame containing Gemini PDU 3
                16 => x"00_06_07_08_09_0A_0B_0C",  -- N=6, MACDst x"0708090A0B0C"
                17 => x"FF_FF_A1_A2_A3_A4_A5_A6",  -- UDPDstPt x"A1A2"  IPDstAddr x"A3A4A5A6"
                18 => x"2A_2B_2C_2D_FF_89_0A_01",  -- Gemini protocol header: ver 1, cmd NACK-P, CSN x"89", Addr x"2A2B2C2D"
                19 => x"61_62_63_64_FF_FF_00_06" ); -- Gemini protocol header & payload: nRegs 6, FC x"FFFF", Reg1 x"61626364"

    SIGNAL rst : STD_LOGIC;
    SIGNAL clk : STD_LOGIC := '1';
    SIGNAL tb_end : STD_LOGIC := '0';
    SIGNAL crsb_data : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    SIGNAL crsb_data_d : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    SIGNAL crsb_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);        
    SIGNAL ethtx_tvalid : STD_LOGIC;
    SIGNAL ethtx_tready : STD_LOGIC;
    SIGNAL ethtx_tdata : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    SIGNAL ethtx_tstrb : STD_LOGIC_VECTOR(c_data_w/8-1 DOWNTO 0);
    SIGNAL ethtx_tkeep : STD_LOGIC_VECTOR(c_data_w/8-1 DOWNTO 0);
    SIGNAL ethtx_tlast : STD_LOGIC;
    SIGNAL crsb_fifo_data : STD_LOGIC_VECTOR(c_crsb_fifo_w-1 DOWNTO 0);
    SIGNAL crsb_fifo_rd : STD_LOGIC;
    SIGNAL crsb_fifo_empty : STD_LOGIC;

BEGIN

    clk <= NOT clk OR tb_end AFTER c_clk_period/2;
    rst <= '1', '0' AFTER 3*c_clk_period;
  
    crsb_fifo_data(7 DOWNTO 0) <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_ssn,8));
    crsb_fifo_data(8+2*24-1 DOWNTO 8+24) <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_crsb_low_addr,24));
    crsb_fifo_data(8+3*24-1 DOWNTO 8+2*24) <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_crsb_high_addr,24));

    -- Simulate ethtx output that is ocasionally not ready
    -- This is important to test the case where u_tx_fifo goes full
    p_axi_stimulus : PROCESS(clk)
        VARIABLE count : INTEGER;
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                ethtx_tready <= '0';
                count := 0;
            ELSE
                ethtx_tready <= '0';
                IF count > 14 THEN
                    ethtx_tready <= '1';
                END IF;
                count := count + 1;
            END IF;
        END IF;
    END PROCESS;

    p_stimuli : PROCESS
    BEGIN
        
        -- Initialization
        crsb_fifo_empty <= '1';
        WAIT UNTIL rst='0';
        WAIT UNTIL RISING_EDGE(clk);

        FOR T IN c_test_vec'range LOOP

            crsb_fifo_data(8+24-1 DOWNTO 8) <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_test_vec(T).addr,24));
            crsb_fifo_empty <= '0';
            WAIT UNTIL RISING_EDGE(clk);
            
            crsb_fifo_empty <= '1';

            --WAIT FOR 3 * c_clk_period;
            
            FOR I IN 1 TO c_test_vec(T).ethtx_len LOOP

                WAIT UNTIL RISING_EDGE(clk) AND ethtx_tready = '1' AND ethtx_tvalid = '1';
                IF I = c_test_vec(T).ethtx_len THEN
                    ASSERT ethtx_tlast = '1' REPORT "Incorrect TLAST" SEVERITY FAILURE;
                    ASSERT ethtx_tkeep = c_test_vec(T).ethtx_tkeep REPORT "Incorrect TKEEP" SEVERITY FAILURE;
                    CASE c_test_vec(T).ethtx_tkeep IS
                    WHEN x"03" => 
                        ASSERT ( ethtx_tdata AND x"00_00_00_00_00_00_FF_FF" ) = c_test_vec(T).ethtx(I) REPORT "Incorrect TDATA" SEVERITY FAILURE;
                    WHEN x"3F" =>
                        ASSERT ( ethtx_tdata AND x"00_00_FF_FF_FF_FF_FF_FF" ) = c_test_vec(T).ethtx(I) REPORT "Incorrect TDATA" SEVERITY FAILURE;
                    WHEN OTHERS =>
                        ASSERT FALSE REPORT "Incorrect TDATA" SEVERITY FAILURE;
                    END CASE;                        
                ELSE
                    ASSERT ethtx_tlast = '0' REPORT "Incorrect TLAST" SEVERITY FAILURE;
                    ASSERT ethtx_tkeep = x"FF" REPORT "Incorrect TKEEP" SEVERITY FAILURE;
                    ASSERT ethtx_tdata = c_test_vec(T).ethtx(I) REPORT "Incorrect TDATA" SEVERITY FAILURE;
                END IF;

            END LOOP;

        END LOOP;

        tb_end <= '1';
        ASSERT FALSE REPORT "Simulation completed with no errors." SEVERITY NOTE;
        WAIT;

    END PROCESS;
    
    -- Simulate memory with 2 clocks read latency
    p_crsb_mem : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            crsb_data_d <= crsb_mem(TO_INTEGER(UNSIGNED(crsb_addr)));
            crsb_data <= crsb_data_d;
        END IF;
    END PROCESS;        

    u_dut : ENTITY gemini_server_lib.response_streamer
    GENERIC MAP (
        g_technology => c_technology,
        g_data_w => c_data_w,
        g_crsb_fifo_w => c_crsb_fifo_w,
        g_crsb_addr_w => c_crsb_addr_w,
        g_crsb_ram_rd_latency => 2 )
    PORT MAP (
        clk => clk,
        rst => rst,
        ethtx_tvalid_out => ethtx_tvalid,
        ethtx_tready_in => ethtx_tready,
        ethtx_tdata_out => ethtx_tdata,
        ethtx_tstrb_out => ethtx_tstrb,
        ethtx_tkeep_out => ethtx_tkeep,
        ethtx_tlast_out => ethtx_tlast,
        crsb_fifo_data_in => crsb_fifo_data,
        crsb_fifo_rd_out => crsb_fifo_rd,
        crsb_fifo_empty_in => crsb_fifo_empty,
        crsb_data_in => crsb_data,
        crsb_addr_out => crsb_addr );

END tb;
