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


-- Purpose: Testbench for Response Encoder module
-- Description:
--

LIBRARY IEEE, gemini_server_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.std_logic_textio.ALL;
USE technology_lib.technology_pkg.ALL;

LIBRARY STD;
USE STD.textio.ALL;

ENTITY tb_response_encoder IS
END tb_response_encoder;

ARCHITECTURE tb OF tb_response_encoder IS

    CONSTANT c_clk_period : TIME := 10 ns;
    CONSTANT c_data_w : NATURAL := 64;
    CONSTANT c_mm_data_w : NATURAL := 32;
    CONSTANT c_crsb_addr_w : NATURAL := 4;
    CONSTANT c_clnt_addr_w : NATURAL := 48;
    CONSTANT c_clnt1_mac : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0) := x"DD_DD_DD_DD_DD_40";
    CONSTANT c_clnt1_ipudp : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0) := x"DE_FC_ED_ED_DE_40";
    CONSTANT c_crsb_low_addr : NATURAL := 3;
    CONSTANT c_crsb_high_addr : NATURAL := 9;
    CONSTANT c_max_nregs : NATURAL := 7;
    CONSTANT c_max_pipeline : NATURAL := 3;
    CONSTANT c_key_w : NATURAL := 2;

    TYPE t_mm_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_mm_data_w-1 DOWNTO 0);
    TYPE t_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);

    TYPE t_test IS RECORD
        cmd : STD_LOGIC_VECTOR(7 DOWNTO 0);
        csn : STD_LOGIC_VECTOR(7 DOWNTO 0);
        nregs : INTEGER;
        connect : STD_LOGIC;
        fc : STD_LOGIC_VECTOR(15 DOWNTO 0);
        crsb_addr : INTEGER;
        frame_len : INTEGER;
        crsb_frame : t_data_arr(1 TO 7);
    END RECORD t_test;

    TYPE t_test_vec IS ARRAY (INTEGER RANGE <>) OF t_test;
    CONSTANT c_test_vec : t_test_vec(1 TO 6) := (

            ( cmd => x"01", csn => x"77", nregs => 0, connect => '0', fc => x"0123", crsb_addr => 3,
                frame_len => 4, crsb_frame => ( 1 => x"00_00_DD_DD_DD_DD_DD_40",
                                               2 => x"00_00_DE_FC_ED_ED_DE_40",
                                               3 => x"00_00_00_00_00_77_01_01",
                                               others => x"00_00_00_00_01_23_00_00" ) ),

            ( cmd => x"02", csn => x"88", nregs => 1, connect => '0', fc => x"4567", crsb_addr => 3,
                frame_len => 4, crsb_frame => ( 1 => x"00_01_DD_DD_DD_DD_DD_40",
                                               2 => x"00_00_DE_FC_ED_ED_DE_40",
                                               3 => x"00_00_00_00_00_88_02_01",
                                               others => x"01_02_03_04_45_67_00_01" ) ),

            ( cmd => x"03", csn => x"99", nregs => 2, connect => '0', fc => x"89AB", crsb_addr => 4,
                frame_len => 5, crsb_frame => ( 1 => x"00_02_DD_DD_DD_DD_DD_40",
                                               2 => x"00_00_DE_FC_ED_ED_DE_40",
                                               3 => x"00_00_00_00_00_99_03_01",
                                               4 => x"01_02_03_04_89_AB_00_02",
                                               others => x"00_00_00_00_11_12_13_14" ) ),

            ( cmd => x"04", csn => x"AA", nregs => 3, connect => '0', fc => x"CDEF", crsb_addr => 5,
                frame_len => 5, crsb_frame => ( 1 => x"00_03_DD_DD_DD_DD_DD_40",
                                               2 => x"00_00_DE_FC_ED_ED_DE_40",
                                               3 => x"00_00_00_00_00_AA_04_01",
                                               4 => x"01_02_03_04_CD_EF_00_03",
                                               others => x"21_22_23_24_11_12_13_14" ) ),

            ( cmd => x"05", csn => x"BB", nregs => 7, connect => '0', fc => x"EEEE", crsb_addr => 7,
                frame_len => 7, crsb_frame => ( 1 => x"00_07_DD_DD_DD_DD_DD_40",
                                               2 => x"00_00_DE_FC_ED_ED_DE_40",
                                               3 => x"00_00_00_00_00_BB_05_01",
                                               4 => x"01_02_03_04_EE_EE_00_07",
                                               5 => x"21_22_23_24_11_12_13_14",
                                               6 => x"41_42_43_44_31_32_33_34",
                                               7 => x"61_62_63_64_51_52_53_54" ) ),

            ( cmd => x"06", csn => x"BB", nregs => 3, connect => '1', fc => x"EEEE", crsb_addr => 7,
                frame_len => 5, crsb_frame => ( 1 => x"00_03_DD_DD_DD_DD_DD_40",
                                                2 => x"00_00_DE_FC_ED_ED_DE_40",
                                                3 => x"00_00_00_00_00_BB_06_01",
                                                4 => x"00_00_00_07_EE_EE_00_03",
                                           others => x"00_00_00_01_00_00_00_08" ) )

                    );

    SIGNAL rst : STD_LOGIC;
    SIGNAL clk : STD_LOGIC := '1';
    SIGNAL mm2s_mem : t_mm_data_arr(0 TO 7) := ( x"01_02_03_04", x"11_12_13_14", x"21_22_23_24",
                                                 x"31_32_33_34", x"41_42_43_44", x"51_52_53_54",
                                                 x"61_62_63_64", x"71_72_73_74" );
    SIGNAL tb_end : STD_LOGIC := '0';
    SIGNAL crsb_data : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    SIGNAL crsb_mem : t_data_arr(0 TO 2**c_crsb_addr_w-1);
    SIGNAL crsb_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);
    SIGNAL crsb_wr : STD_LOGIC;
    SIGNAL mm2s_tdata : STD_LOGIC_VECTOR ( c_mm_data_w-1 DOWNTO 0 );
    SIGNAL mm2s_tkeep : STD_LOGIC_VECTOR ( c_mm_data_w/8-1 DOWNTO 0 );
    SIGNAL mm2s_tlast : STD_LOGIC;
    SIGNAL mm2s_tready : STD_LOGIC;
    SIGNAL mm2s_tvalid : STD_LOGIC;
    SIGNAL mm2s_len : INTEGER;
    SIGNAL mm2s_addr : INTEGER := 1;
    SIGNAL clnt_addr_mac : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0);
    SIGNAL clnt_addr_ipudp : STD_LOGIC_VECTOR(c_clnt_addr_w-1 DOWNTO 0);
    SIGNAL crsb_low_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(c_crsb_low_addr,c_crsb_addr_w));
    SIGNAL crsb_high_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(c_crsb_high_addr,c_crsb_addr_w));
    SIGNAL mm_start : STD_LOGIC;
    SIGNAL mm_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);
    SIGNAL mm_complete : STD_LOGIC;
    SIGNAL mm_cmd : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mm_csn : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL mm_nregs : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL mm_connect : STD_LOGIC;
    SIGNAL mm_key : STD_LOGIC_VECTOR(c_key_w-1 DOWNTO 0) := "01";
    SIGNAL mm_fc : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL mm_crsb_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);
    SIGNAL mm_crsb_low_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);
    SIGNAL mm_crsb_high_addr : STD_LOGIC_VECTOR(c_crsb_addr_w-1 DOWNTO 0);

BEGIN

    clk <= NOT clk OR tb_end AFTER c_clk_period/2;
    rst <= '1', '0' AFTER 3*c_clk_period;

    p_stimuli : PROCESS
        VARIABLE addr : INTEGER;
        VARIABLE dat : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
    BEGIN

        -- Initialization
        mm_start <= '0';
        mm_complete <= '0';
        WAIT UNTIL rst='0';
        WAIT UNTIL RISING_EDGE(clk);

        FOR T IN c_test_vec'range LOOP

            mm_start <= '1';
            mm_complete <= '0';
            mm_cmd <= x"FF";
            mm_csn <= c_test_vec(T).csn;
            mm_connect <= c_test_vec(T).connect;
            mm_nregs <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_test_vec(T).nregs,mm_nregs'length));
            mm_fc <= x"FFFF";
            clnt_addr_mac <= (others=>'1');
            clnt_addr_ipudp <= (others=>'1');
            mm_crsb_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(c_test_vec(T).crsb_addr,c_crsb_addr_w));
            WAIT UNTIL RISING_EDGE(clk);
            mm_start <= '0';

            WAIT FOR c_clk_period*(5+c_test_vec(T).frame_len);
            mm_complete <= '1';
            mm_cmd <= c_test_vec(T).cmd;
            mm_fc <= c_test_vec(T).fc;
            clnt_addr_mac <= c_clnt1_mac;
            clnt_addr_ipudp <= c_clnt1_ipudp;
            WAIT UNTIL RISING_EDGE(clk);

            mm_complete <= '0';
            WAIT FOR c_clk_period*7;
            WAIT UNTIL RISING_EDGE(clk);

            -- Check what's written to the CRSB
            FOR J IN 1 TO c_test_vec(T).frame_len LOOP
                addr := J+c_test_vec(T).crsb_addr-1;
                IF addr > c_crsb_high_addr THEN
                    addr := addr - ( c_crsb_high_addr - c_crsb_low_addr + 1 );
                END IF;
                dat := crsb_mem(addr);
                IF J=2 THEN
                    ASSERT dat(c_clnt_addr_w-1 DOWNTO 0) = c_test_vec(T).crsb_frame(J)(c_clnt_addr_w-1 DOWNTO 0) REPORT "Incorrect CRSB data" SEVERITY FAILURE;
                ELSIF J=c_test_vec(T).frame_len AND TO_UNSIGNED(c_test_vec(T).nregs,1)(0) = '0' THEN
                    ASSERT dat(c_mm_data_w-1 DOWNTO 0) = c_test_vec(T).crsb_frame(J)(c_mm_data_w-1 DOWNTO 0) REPORT "Incorrect CRSB data" SEVERITY FAILURE;
                ELSIF J=c_test_vec(T).frame_len AND TO_UNSIGNED(c_test_vec(T).nregs,1)(0) = '1' THEN
                    ASSERT dat(2*c_mm_data_w-1 DOWNTO c_mm_data_w) = c_test_vec(T).crsb_frame(J)(2*c_mm_data_w-1 DOWNTO c_mm_data_w) REPORT "Incorrect CRSB data" SEVERITY FAILURE;
                ELSE
                    ASSERT dat = c_test_vec(T).crsb_frame(J) REPORT "Incorrect CRSB data" SEVERITY FAILURE;
                END IF;
            END LOOP;

        END LOOP;

        tb_end <= '1';
        ASSERT FALSE REPORT "Simulation completed with no errors." SEVERITY NOTE;
        WAIT;

    END PROCESS;

    -- Emulate the CRSB RAM
    p_crsb : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF crsb_wr = '1' THEN
                crsb_mem(TO_INTEGER(UNSIGNED(crsb_addr))) <= crsb_data;
            END IF;
        END IF;
    END PROCESS;

    -- Provide MM2S data
    p_mm2s : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF mm_start = '1' THEN
                mm2s_len <= TO_INTEGER(UNSIGNED(mm_nregs));
                mm2s_addr <= 0;
            ELSIF mm2s_len > 0 AND mm2s_tready = '1' THEN
                mm2s_len <= mm2s_len - 1;
                mm2s_addr <= mm2s_addr + 1;
            END IF;
        END IF;
    END PROCESS;

    mm2s_tvalid <= '1' WHEN mm2s_len > 0 ELSE '0';
    mm2s_tkeep <= (others=>'1');
    mm2s_tdata <= mm2s_mem(mm2s_addr);
    mm2s_tlast <= '1' WHEN mm2s_len = 1 ELSE '0';

    u_dut : ENTITY gemini_server_lib.response_encoder
    GENERIC MAP (
        g_max_nregs => c_max_nregs,
        g_key_w => c_key_w,
        g_max_pipeline => c_max_pipeline,
        g_data_w => c_data_w,
        g_mm_data_w => c_mm_data_w,
        g_clnt_addr_w => c_clnt_addr_w,
        g_crsb_addr_w => c_crsb_addr_w )
    PORT MAP (
        clk => clk,
        rst => rst,
        mm_start_in => mm_start,
        mm_cmd_in => mm_cmd,
        mm_csn_in => mm_csn,
        mm_nregs_in => mm_nregs,
        mm_connect_in => mm_connect,
        mm_key_in => mm_key,
        mm_fc_in => mm_fc,
        mm_crsb_addr_in => mm_crsb_addr,
        mm_crsb_low_addr_in => crsb_low_addr,
        mm_crsb_high_addr_in => crsb_high_addr,
        mm_complete_in => mm_complete,
        crsb_data_out => crsb_data,
        crsb_wr_out => crsb_wr,
        crsb_addr_out => crsb_addr,
        clnt_addr_mac_in => clnt_addr_mac,
        clnt_addr_ipudp_in => clnt_addr_ipudp,
        mm2s_error => '0',
        mm2s_tdata_in => mm2s_tdata,
        mm2s_tkeep_in => mm2s_tkeep,
        mm2s_tlast_in => mm2s_tlast,
        mm2s_tready_out => mm2s_tready,
        mm2s_tvalid_in => mm2s_tvalid );


END tb;
