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


-- Purpose: Testbench for request_decoder
-- Description:
--

LIBRARY IEEE, gemini_server_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_textio.ALL;

LIBRARY STD;
USE STD.textio.ALL;

ENTITY tb_request_decoder IS
END tb_request_decoder;

ARCHITECTURE tb OF tb_request_decoder IS

    CONSTANT c_clk_period : TIME := 10 ns;  -- 100 MHz
    CONSTANT c_crqb_len : NATURAL := 11;
    CONSTANT c_max_nregs : NATURAL := 5;

    TYPE t_pkt_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(63 DOWNTO 0);
    
    TYPE t_test IS RECORD
        gem_len : NATURAL;
        gem : t_pkt_data_arr(1 TO 10); -- Gemini Ethernet packet in
        crqb_fifo : STD_LOGIC_VECTOR(79 DOWNTO 0);
        crqb_ram_len : NATURAL;
        crqb_ram : t_pkt_data_arr(1 TO 5);
    END RECORD t_test;
    
    TYPE t_test_vec IS ARRAY (INTEGER RANGE <>) OF t_test;
    CONSTANT c_test_vec : t_test_vec(1 TO 5) := ( 
    
            -- Client 1: Connect, CSN=1, Addr=0, NRegs=0
            (  gem_len => 7, 
               gem => ( 1 => x"55_40_DD_DD_DD_DD_DD_40",
                        2 => x"00_45_00_08_01_55_55_55",
                        3 => x"11_00_00_00_00_00_00_00",
                        4 => x"DD_DD_55_55_55_55_00_00",
                        5 => x"14_00_00_30_00_01_DD_DD",   -- UDPLen = (0+5)*4 = x14
                        6 => x"00_00_00_01_01_01_00_00",
                        others => x"00_00_00_00_00_00_00_00" ),
               crqb_fifo => x"00_00_00_00_00_00_00_00_01_09",
               crqb_ram_len => 2,
               crqb_ram => ( 1 => x"00_00_01_55_55_55_55_40",
                       others => x"00_00_00_01_55_55_55_55" ) ),

            -- Client 1: ReadInc, CSN=2, Addr=10A, NRegs=5
            (  gem_len => 7,
               gem => ( 1 => x"55_40_DD_DD_DD_DD_DD_40",
                        2 => x"00_45_00_08_01_55_55_55",
                        3 => x"11_00_00_00_00_00_00_00",
                        4 => x"DD_DD_55_55_55_55_00_00",
                        5 => x"14_00_00_30_00_01_DD_DD",   -- UDPLen = (0+5)*4 = x14
                        6 => x"01_0A_00_02_03_01_00_00",
                        others => x"00_00_00_00_00_05_00_00" ),
               crqb_fifo => x"00_02_00_00_01_0A_00_05_02_03",
               crqb_ram_len => 2,
               crqb_ram => ( 1 => x"00_00_01_55_55_55_55_40",
                       others => x"00_00_00_01_55_55_55_55" ) ),

            -- Client 1: WriteInc, CSN=3, Addr=1000A0, NRegs=1 (1 register payload)
            (  gem_len => 8,
               gem => ( 1 => x"55_40_DD_DD_DD_DD_DD_40",
                        2 => x"00_45_00_08_01_55_55_55",
                        3 => x"11_00_00_00_00_00_00_00",
                        4 => x"DD_DD_55_55_55_55_00_00",
                        5 => x"18_00_00_30_00_01_DD_DD",  -- UDPLen = (1+5)*4 = x18
                        6 => x"00_A0_00_03_05_01_00_00",
                        7 => x"56_78_00_00_00_01_00_10",
                        others => x"00_00_00_00_00_00_12_34" ),
              crqb_fifo => x"00_04_00_10_00_A0_00_01_03_05",
              crqb_ram_len => 3,
              crqb_ram => ( 1 => x"00_00_01_55_55_55_55_40",
                      2 => x"00_00_00_01_55_55_55_55",
                      others => x"00_00_00_00_12_34_56_78" ) ),

            -- Client 1: WriteInc, CSN=4, Addr=1000A0, NRegs=2 (2 registers payload)
            (  gem_len => 8,
               gem => ( 1 => x"55_40_DD_DD_DD_DD_DD_40",
                        2 => x"00_45_00_08_01_55_55_55",
                        3 => x"11_00_00_00_00_00_00_00",
                        4 => x"DD_DD_55_55_55_55_00_00",
                        5 => x"1C_00_00_30_00_01_DD_DD",  -- UDPLen = (2+5)*4 = x1C
                        6 => x"00_A0_00_04_05_01_00_00",
                        7 => x"56_78_00_00_00_02_00_10",
                        others => x"00_00_9A_BC_DE_F0_12_34" ),
              crqb_fifo => x"00_07_00_10_00_A0_00_02_04_05",
              crqb_ram_len => 3,
              crqb_ram => ( 1 => x"00_00_01_55_55_55_55_40",
                      2 => x"00_00_00_01_55_55_55_55",
                      others => x"9A_BC_DE_F0_12_34_56_78" ) ),
                      
            -- Client 1: WriteInc, CSN=5, Addr=1000A0, NRegs=3 (3 registers payload)
            (  gem_len => 9,
             gem => ( 1 => x"55_40_DD_DD_DD_DD_DD_40",
                      2 => x"00_45_00_08_01_55_55_55",
                      3 => x"11_00_00_00_00_00_00_00",
                      4 => x"DD_DD_55_55_55_55_00_00",
                      5 => x"20_00_00_30_00_01_DD_DD",  -- UDPLen = (3+5)*4 = x20
                      6 => x"00_A0_00_05_05_01_00_00",
                      7 => x"56_78_00_00_00_03_00_10",
                      8 => x"43_21_9A_BC_DE_F0_12_34",
                      others => x"00_00_00_00_00_00_87_65" ),
            crqb_fifo => x"00_0A_00_10_00_A0_00_03_05_05",
            crqb_ram_len => 4,
            crqb_ram => ( 1 => x"00_00_01_55_55_55_55_40",
                    2 => x"00_00_00_01_55_55_55_55",
                    3 => x"9A_BC_DE_F0_12_34_56_78",
                    others => x"00_00_00_00_87_65_43_21" ) )

    );

    SIGNAL rst : STD_LOGIC;
    SIGNAL clk : STD_LOGIC := '1';
    SIGNAL tb_end : STD_LOGIC := '0';
    SIGNAL tod : UNSIGNED(7 DOWNTO 0);
    SIGNAL ethrx_valid : STD_LOGIC;
    SIGNAL ethrx_ready : STD_LOGIC;
    SIGNAL ethrx_data : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL ethrx_strb : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ethrx_keep : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ethrx_last : STD_LOGIC;
    SIGNAL buff_data : STD_LOGIC_VECTOR(63 DOWNTO 0);
    SIGNAL buff_wr : STD_LOGIC;
    SIGNAL buff_addr : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL buff_sel : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL fifo_full : STD_LOGIC_VECTOR(3 DOWNTO 1);
    SIGNAL fifo_wr : STD_LOGIC_VECTOR(3 DOWNTO 1);
    SIGNAL fifo_data : STD_LOGIC_VECTOR(79 DOWNTO 0);

BEGIN

    clk <= NOT clk OR tb_end AFTER c_clk_period/2;
    rst <= '1', '0' AFTER 3*c_clk_period;
  
    p_tod : PROCESS(clk)
    BEGIN
        IF rst = '0' THEN
            tod <= (others=>'0');
        ELSIF RISING_EDGE(clk) THEN
            tod <= tod + TO_UNSIGNED(1,tod'length);
        END IF;
    END PROCESS;

    p_stimuli : PROCESS
    BEGIN
        
        ethrx_valid <= '0';
        ethrx_last <= '0';
        ethrx_strb <= x"00";
        ethrx_keep <= x"FF";
        ethrx_data <= (others=>'0');
        fifo_full <= (others=>'0');

        -- Initialization
        WAIT UNTIL rst='0';
        WAIT UNTIL RISING_EDGE(clk);

        FOR I IN c_test_vec'range LOOP

            -- Send a test Gemini PDU Ethernet packet into the DUT
            ethrx_last <= '0';
            ethrx_valid <= '1';

            FOR J IN 1 TO c_test_vec(I).gem_len LOOP
                ethrx_data <= c_test_vec(I).gem(J);
                IF J = c_test_vec(I).gem_len THEN
                    ethrx_last <= '1';
                END IF;
                WAIT UNTIL ethrx_ready = '1' AND RISING_EDGE(clk);
            END LOOP;

            ethrx_valid <= '0';
            ethrx_last <= '0';
            
            -- Worst case is full line rate input Ethernet packets
            -- In this case the request_decoder module should use TREADY
            --WAIT FOR 3 * c_clk_period; 
            
        END LOOP;

        WAIT;

    END PROCESS;
    
    p_response : PROCESS
        VARIABLE ram_addr : INTEGER := 0;
    BEGIN
        
        -- Initialization
        WAIT UNTIL rst='1';
        WAIT UNTIL RISING_EDGE(clk);

        
        FOR I IN c_test_vec'range LOOP

            FOR J IN 1 TO c_test_vec(I).crqb_ram_len LOOP
                WAIT UNTIL buff_wr = '1' AND RISING_EDGE(clk);
                ASSERT UNSIGNED(buff_addr) = TO_UNSIGNED(ram_addr,buff_addr'length) REPORT "Wrong CRQB RAM_addr" SEVERITY FAILURE;
                ASSERT buff_data = c_test_vec(I).crqb_ram(J) REPORT "Wrong CRQB RAM data" SEVERITY FAILURE;
                ram_addr := ram_addr + 1;
                IF ram_addr = c_crqb_len THEN
                    ram_addr := 0;
                END IF;
            END LOOP;
            
            -- FIFO word can be written either alongside last buff_wr or
            -- afterwards
            IF fifo_wr /= "000" THEN
                ASSERT fifo_data = c_test_vec(I).crqb_fifo REPORT "Wrong CRQB FIFO word" SEVERITY FAILURE;
            ELSE
                -- Check the FIFO word that the DUT outputs
                WAIT UNTIL fifo_wr /= "000" AND RISING_EDGE(clk);
                ASSERT fifo_data = c_test_vec(I).crqb_fifo REPORT "Wrong CRQB FIFO word" SEVERITY FAILURE;
            END IF;
            
        END LOOP;

        tb_end <= '1';
        ASSERT FALSE REPORT "Simulation completed with no errors." SEVERITY NOTE;
        WAIT;

    END PROCESS;

    u_dut : ENTITY gemini_server_lib.request_decoder
    GENERIC MAP (
        g_data_w => 64,
        g_noof_clnts => 2,
        g_max_nregs => c_max_nregs,
        g_key_w => 2, 
        g_tod_w => 8,
        g_crqb_len => c_crqb_len,
        g_crqb_addr_w => 12,
        g_crqb_fifo_w => 80, 
        g_min_recycle_secs => 8 )
    PORT MAP (
        clk => clk,
        rst => rst,
        ethrx_tvalid_in => ethrx_valid,
        ethrx_tready_out => ethrx_ready,
        ethrx_tdata_in => ethrx_data,
        ethrx_tstrb_in => ethrx_strb,
        ethrx_tkeep_in => ethrx_keep,
        ethrx_tlast_in => ethrx_last,
        crqb_data_out => buff_data,
        crqb_wr_out => buff_wr,
        crqb_addr_out => buff_addr,
        crqb_fifo_data_out => fifo_data,
        crqb_fifo_full_in => fifo_full,
        crqb_fifo_wr_out => fifo_wr,
        tod_in => STD_LOGIC_VECTOR(tod) );

END tb;
