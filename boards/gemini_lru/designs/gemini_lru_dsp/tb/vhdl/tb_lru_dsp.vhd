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


-- Purpose: Testbench for Gemini Server
-- Description:
--

LIBRARY IEEE, common_lib, technology_lib, gemini_server_lib, tech_axi4dm_lib, axi4_lib, lru_test_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE gemini_server_lib.gemini_server_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE axi4_lib.axi4_full_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE tech_axi4dm_lib.tech_axi4dm_component_pkg.ALL;
USE IEEE.std_logic_textio.ALL;
USE IEEE.math_real.ALL;
USE lru_test_lib.lru_test_bus_pkg.ALL;


LIBRARY STD;
USE STD.textio.ALL;

ENTITY tb_lru_dsp IS
END tb_lru_dsp;

ARCHITECTURE tb OF tb_lru_dsp IS

    -- Header length assumptions: 14 bytes MAC, 20 bytes IP, 8 bytes UDP, 12 bytes Gemini PDU
    CONSTANT c_clk_period : TIME := 10 ns;  -- 100 MHz
    CONSTANT c_max_clients : NATURAL := 3;
    CONSTANT c_noof_clients : NATURAL := 3;
    CONSTANT c_data_w : NATURAL := 64;
    CONSTANT c_max_pipeline : NATURAL := 8;
    CONSTANT c_mm_data_w : NATURAL := 32;
    CONSTANT c_tod_w : NATURAL := 14;
    CONSTANT c_mtu : NATURAL := 8000;
    CONSTANT c_max_nregs : NATURAL := (c_mtu - (20+8+12))/4;

    TYPE t_pkt_data_arr IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);

    TYPE t_client IS RECORD
        mac : STD_LOGIC_VECTOR(47 DOWNTO 0);
        ipaddr : STD_LOGIC_VECTOR(31 DOWNTO 0);
        udppt : STD_LOGIC_VECTOR(15 DOWNTO 0);
    END RECORD t_client;

    TYPE t_client_arr IS ARRAY (INTEGER RANGE<>) OF t_client;
    CONSTANT c_clients : t_client_arr(1 TO c_max_clients+1) := (
            1 => ( mac => x"11_11_11_11_11_11", ipaddr => x"11_11_11_11", udppt => x"11_11" ),
            2 => ( mac => x"21_22_23_24_25_26", ipaddr => x"27_28_29_2A", udppt => x"2B_2C" ),
            3 => ( mac => x"31_32_33_34_35_36", ipaddr => x"37_38_39_3A", udppt => x"3B_3C" ),
            4 => ( mac => x"31_32_33_34_35_36", ipaddr => x"37_38_39_3A", udppt => x"4B_4C" ) ); -- Second SW client instance on same server as client 3

    TYPE t_test IS RECORD
        client : NATURAL RANGE 1 TO c_max_clients+1;
        req_cmd: STD_LOGIC_VECTOR(7 DOWNTO 0);
        rsp_cmd :STD_LOGIC_VECTOR(7 DOWNTO 0);
        csn : NATURAL RANGE 0 TO 255;
        ssn : NATURAL RANGE 0 TO 255;
        mmaddr : NATURAL;
        req_nregs: NATURAL;
        rsp_nregs: NATURAL;
        ipg : NATURAL; -- Inter-packet gap in clocks
    END RECORD t_test;

    TYPE t_test_vec IS ARRAY (INTEGER RANGE <>) OF t_test;

    SIGNAL rst : STD_LOGIC;
    SIGNAL rstn : STD_LOGIC;
    SIGNAL clk : STD_LOGIC := '1';
    SIGNAL tb_end : STD_LOGIC := '0';
    SIGNAL ethrx_in : t_axi4_sosi;
    SIGNAL ethrx_out : t_axi4_siso;
    SIGNAL ethtx_in : t_axi4_siso;
    SIGNAL ethtx_out : t_axi4_sosi;
    SIGNAL mm_in : t_axi4_full_miso;
    SIGNAL mm_out : t_axi4_full_mosi;
    SIGNAL tod : UNSIGNED(c_tod_w-1 DOWNTO 0);
    SIGNAL tod_sl : STD_LOGIC_VECTOR(c_tod_w-1 DOWNTO 0);
    SIGNAL stim_pkt : t_integer_arr(1 TO c_max_clients+1) := (others=>0);
    SIGNAL resp_pkt : t_integer_arr(1 TO c_max_clients+1) := (others=>0);
    SIGNAL pipeline_depth : t_integer_arr(1 TO c_max_clients+1);
    SIGNAL test_vec : t_test_vec(1 TO 100);
    SIGNAL test_vec_len : NATURAL;

   SIGNAL mc_master_mosi         : t_axi4_full_mosi;
   SIGNAL mc_master_miso         : t_axi4_full_miso;
   SIGNAL mc_lite_miso           : t_axi4_lite_miso_arr(c_nof_lite_slaves-1 DOWNTO 0);
   SIGNAL mc_lite_mosi           : t_axi4_lite_mosi_arr(c_nof_lite_slaves-1 DOWNTO 0);
   SIGNAL mc_full_miso           : t_axi4_full_miso_arr(c_nof_full_slaves-1 downto 0);
   SIGNAL mc_full_mosi           : t_axi4_full_mosi_arr(c_nof_full_slaves-1 downto 0);

    -- Build Ethernet packet containing Gemini Request PDU
    PROCEDURE mk_request(client : IN NATURAL RANGE 1 TO c_max_clients+1;
                        cmd: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
                        csn : IN NATURAL RANGE 0 TO 255;
                        mmaddr : IN NATURAL;
                        nregs: IN NATURAL;
                        seed1 : INOUT POSITIVE;
                        seed2 : INOUT POSITIVE;
                        data : OUT t_pkt_data_arr ) IS
        VARIABLE udplen : INTEGER := 20;
        VARIABLE udplen_sl : STD_LOGIC_VECTOR(15 DOWNTO 0);
        VARIABLE csum : UNSIGNED(15 DOWNTO 0) := TO_UNSIGNED(0,16);
        VARIABLE rand : REAL;
        VARIABLE hword : UNSIGNED(15 DOWNTO 0);
        VARIABLE mmaddr_sl : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE mac : STD_LOGIC_VECTOR(47 DOWNTO 0);
        VARIABLE ipaddr : STD_LOGIC_VECTOR(31 DOWNTO 0);
        VARIABLE udppt : STD_LOGIC_VECTOR(15 DOWNTO 0);
    BEGIN

        IF cmd = c_gemreq_write_inc OR cmd = c_gemreq_write_rep THEN
            udplen := ( nregs + 5 ) * 4;
        END IF;
        udplen_sl := STD_LOGIC_VECTOR(TO_UNSIGNED(udplen,16));
        mmaddr_sl := STD_LOGIC_VECTOR(TO_UNSIGNED(mmaddr,32));

        mac := c_clients(client).mac;
        ipaddr := c_clients(client).ipaddr;
        udppt := c_clients(client).udppt;

        data(1) := mac(15 DOWNTO 0) & x"00_00_00_00_00_00";
        data(2) := x"00_45_00_08" & mac(47 DOWNTO 16);
        data(3) := x"11_00_00_00_00_00_00_00";
        data(4) := x"00_00" & ipaddr & x"00_00";
        data(5) := udplen_sl(7 DOWNTO 0) & udplen_sl(15 DOWNTO 8) & x"30_75" & udppt & x"00_00";
        data(6) := mmaddr_sl(15 DOWNTO 0) & x"00" & STD_LOGIC_VECTOR(TO_UNSIGNED(csn,8)) & cmd & x"01_00_00";
        FOR I in 0 TO (udplen-23)/8 LOOP
            FOR B in 0 TO 3 LOOP
                IF 22+I*8+(B+1)*2 <= udplen THEN
                    uniform(seed1,seed2,rand);
                    hword := TO_UNSIGNED(INTEGER(rand*REAL(2**16-1)),16);
                    data(I+8)((B+1)*16-1 DOWNTO B*16) := STD_LOGIC_VECTOR(hword);
                    csum := csum + hword;
                END IF;
            END LOOP;
        END LOOP;
        csum := TO_UNSIGNED(0,16) - csum;
        data(7) := STD_LOGIC_VECTOR(csum(15 DOWNTO 0)) & x"00_00" & STD_LOGIC_VECTOR(TO_UNSIGNED(nregs,16)) & mmaddr_sl(31 DOWNTO 16);
    END mk_request;

BEGIN

    gen_test_vec_3 : IF c_noof_clients = 3 AND c_max_pipeline = 8 GENERATE

        -- Note that maddr is a byte address. DataMover expects this to be aligned such that mmaddr rem 4 = 0
        CONSTANT c_test_vec : t_test_vec(1 TO 100) := (

                 -- Test case 1 : 3 client connect, interleaved write and read
                1 => ( client=>1,  req_cmd=>c_gemreq_connect,   rsp_cmd=>c_gemresp_ack,   csn=>1,  ssn=>1,  mmaddr=>0,   req_nregs=>3,              rsp_nregs=>3,           ipg=>1 ),
                2 => ( client=>2,  req_cmd=>c_gemreq_connect,   rsp_cmd=>c_gemresp_ack,   csn=>1,  ssn=>1,  mmaddr=>0,   req_nregs=>3,              rsp_nregs=>3,           ipg=>0 ),
                3 => ( client=>1,  req_cmd=>c_gemreq_write_inc, rsp_cmd=>c_gemresp_ack,   csn=>2,  ssn=>2,  mmaddr=>0,   req_nregs=>1,              rsp_nregs=>1,           ipg=>3 ),
                4 => ( client=>1,  req_cmd=>c_gemreq_read_inc,  rsp_cmd=>c_gemresp_ack,   csn=>3,  ssn=>3,  mmaddr=>0,   req_nregs=>1,              rsp_nregs=>1,           ipg=>2 ),
                5 => ( client=>2,  req_cmd=>c_gemreq_write_inc, rsp_cmd=>c_gemresp_ack,   csn=>2,  ssn=>2,  mmaddr=>4,   req_nregs=>1,              rsp_nregs=>1,           ipg=>4 ),
                6 => ( client=>3,  req_cmd=>c_gemreq_connect,   rsp_cmd=>c_gemresp_ack,   csn=>1,  ssn=>1,  mmaddr=>0,   req_nregs=>3,              rsp_nregs=>3,           ipg=>8 ),
                7 => ( client=>2,  req_cmd=>c_gemreq_read_inc,  rsp_cmd=>c_gemresp_ack,   csn=>3,  ssn=>3,  mmaddr=>4,   req_nregs=>1,              rsp_nregs=>1,           ipg=>0 ),
                8 => ( client=>3,  req_cmd=>c_gemreq_write_inc, rsp_cmd=>c_gemresp_ack,   csn=>2,  ssn=>2,  mmaddr=>8,   req_nregs=>1,              rsp_nregs=>1,           ipg=>4 ),
                9 => ( client=>3,  req_cmd=>c_gemreq_read_inc,  rsp_cmd=>c_gemresp_ack,   csn=>3,  ssn=>3,  mmaddr=>0,   req_nregs=>1,              rsp_nregs=>1,           ipg=>2 ), -- Read data that was written by client 1

                -- Test case 2 : 8000 byte MTU write and read
                10 => ( client=>1, req_cmd=>c_gemreq_write_inc, rsp_cmd=>c_gemresp_ack,   csn=>4,  ssn=>4,  mmaddr=>4,   req_nregs=>c_max_nregs,    rsp_nregs=>c_max_nregs, ipg=>1 ), -- Client 1 already connected
                11 => ( client=>1, req_cmd=>c_gemreq_read_inc,  rsp_cmd=>c_gemresp_ack,   csn=>5,  ssn=>5,  mmaddr=>4,   req_nregs=>c_max_nregs,    rsp_nregs=>c_max_nregs, ipg=>100 ),

                -- Test case 3 : Server must be able to buffer at least c_max_pipeline packets (assume that c_max_pipeline is 8)
                -- All responses for client 2 must have been received before this point (ie depth is 0)
                12 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>4,  ssn=>4,  mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ), -- Client 2 already connected
                13 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>5,  ssn=>5,  mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                14 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>6,  ssn=>6,  mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                15 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>7,  ssn=>7,  mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                16 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>8,  ssn=>8,  mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                17 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>9,  ssn=>9,  mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                18 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>10, ssn=>10, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                19 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>11, ssn=>11, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>6500 ), -- Catchup from test 2

                -- Test case 4 : Multiple clients per server
                -- All responses for client 2 must have been received before this point (ie depth is 0)
                20 => ( client=>3, req_cmd=>c_gemreq_write_inc, rsp_cmd=>c_gemresp_ack,   csn=>4,  ssn=>4,  mmaddr=>32,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ), -- Client 2 already connected
                21 => ( client=>3, req_cmd=>c_gemreq_read_inc,  rsp_cmd=>c_gemresp_ack,   csn=>5,  ssn=>5,  mmaddr=>32,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                22 => ( client=>4, req_cmd=>c_gemreq_connect,   rsp_cmd=>c_gemresp_ack,   csn=>1,  ssn=>1,  mmaddr=>0,    req_nregs=>3,             rsp_nregs=>3,           ipg=>1 ),  -- Client 1 connection should be recycled
                23 => ( client=>4, req_cmd=>c_gemreq_write_inc, rsp_cmd=>c_gemresp_ack,   csn=>2,  ssn=>2,  mmaddr=>0,    req_nregs=>113,           rsp_nregs=>113,         ipg=>1 ),
                24 => ( client=>4, req_cmd=>c_gemreq_read_inc,  rsp_cmd=>c_gemresp_ack,   csn=>3,  ssn=>3,  mmaddr=>0,    req_nregs=>113,           rsp_nregs=>113,         ipg=>80 ),

                -- Test case 5 : The server must respond with a NACK-P if the request command is not a Connect and the client does
                -- not exist in the server's connection table
                25 => ( client=>1, req_cmd=>c_gemreq_read_inc,  rsp_cmd=>c_gemresp_nackp, csn=>6,  ssn=>6,  mmaddr=>0,    req_nregs=>113,           rsp_nregs=>0,           ipg=>400 ), -- Client 1's previous connection was replaced by client 4

                -- Test case 6 : The server must respond with a NACK-P if the request command is not supported
                -- Note that Request Decoder only looks at b<3:0>
                26 => ( client=>4, req_cmd=>x"00",              rsp_cmd=>c_gemresp_nackp, csn=>4,  ssn=>4,  mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                27 => ( client=>4, req_cmd=>x"04",              rsp_cmd=>c_gemresp_nackp, csn=>5,  ssn=>5,  mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                28 => ( client=>4, req_cmd=>x"07",              rsp_cmd=>c_gemresp_nackp, csn=>6,  ssn=>6,  mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                29 => ( client=>4, req_cmd=>x"08",              rsp_cmd=>c_gemresp_nackp, csn=>7,  ssn=>7,  mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                30 => ( client=>4, req_cmd=>x"09",              rsp_cmd=>c_gemresp_nackp, csn=>8,  ssn=>8,  mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>60 ),
                31 => ( client=>2, req_cmd=>x"0A",              rsp_cmd=>c_gemresp_nackp, csn=>12, ssn=>12, mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                32 => ( client=>2, req_cmd=>x"0B",              rsp_cmd=>c_gemresp_nackp, csn=>13, ssn=>13, mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                33 => ( client=>2, req_cmd=>x"0C",              rsp_cmd=>c_gemresp_nackp, csn=>14, ssn=>14, mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                34 => ( client=>2, req_cmd=>x"0D",              rsp_cmd=>c_gemresp_nackp, csn=>15, ssn=>15, mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                35 => ( client=>2, req_cmd=>x"0E",              rsp_cmd=>c_gemresp_nackp, csn=>16, ssn=>16, mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),
                36 => ( client=>2, req_cmd=>x"0F",              rsp_cmd=>c_gemresp_nackp, csn=>17, ssn=>17, mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>80 ),

                -- Test case 7 : The server must respond with a NACK-P if nregs would result in a response packet with length that exceeds the MTU
                37 => ( client=>2, req_cmd=>c_gemreq_read_inc,  rsp_cmd=>c_gemresp_nackp, csn=>18, ssn=>18, mmaddr=>0,    req_nregs=>c_max_nregs+1, rsp_nregs=>0,           ipg=>1 ),

                -- Test case 8 : The server must respond with a NACK-P if the server is unable to replay the response for the request PDU's CSN.
                38 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>19, ssn=>19, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                39 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>20, ssn=>20, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                40 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>21, ssn=>21, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                41 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>22, ssn=>22, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                42 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>23, ssn=>23, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                43 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>24, ssn=>24, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                44 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>25, ssn=>25, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ),
                45 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>26, ssn=>26, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>6500 ),
                46 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>27, ssn=>27, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>2 ),
                47 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>20, ssn=>27, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>2,           ipg=>1 ), -- Successful replay
                48 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_nackp, csn=>19, ssn=>27, mmaddr=>16,   req_nregs=>2,             rsp_nregs=>0,           ipg=>1 ), -- Replay should fail

                -- Test case 9 : The server must respond with a NACK-P if the MM bus operation fails because all, or part of, the BaseAddress
                --                 to BaseAddress + NumRegisters - 1 address range is not valid.
                49 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_nackp, csn=>28, ssn=>28, mmaddr=>8193, req_nregs=>1,             rsp_nregs=>0,           ipg=>1 ),

                -- Test case 10 : The server must respond with a NACK-T if the request CSN is not equal to the per-client state receive sequence
                --                 counter value.
                50 => ( client=>2, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_nackt, csn=>30, ssn=>28, mmaddr=>0,    req_nregs=>1,             rsp_nregs=>0,           ipg=>50 ),

                -- Test case 11 : The server must respond with a NACK-T if the request is a Connect command and the server is unable to assign
                --    a connection table row to the client at this time.
                51 => ( client=>4, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>9,  ssn=>9,  mmaddr=>0,    req_nregs=>1,            rsp_nregs=>1,            ipg=>1 ),
                52 => ( client=>3, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack,   csn=>6,  ssn=>6,  mmaddr=>0,    req_nregs=>1,            rsp_nregs=>1,            ipg=>1 ),

                -- Test Case 12 : Talk to an unresponsive AXI slave
                53 => ( client=>2, req_cmd=>c_gemreq_read_inc, rsp_cmd=>c_gemresp_nackp, csn=>29, ssn=>29,   mmaddr=>2048,  req_nregs=>1,          rsp_nregs=>1,            ipg=>3000 ),   -- Should fail but will return 1 junk piece of data (wait to allow connection recycle)

            others => ( client=>1, req_cmd=>c_gemreq_connect,  rsp_cmd=>c_gemresp_nackt,  csn=>1, ssn=>6,   mmaddr=>0,     req_nregs=>1,           rsp_nregs=>3,            ipg=>1 )  -- Note invalid SSN passes ok
        );

    BEGIN

        test_vec <= c_test_vec;
        test_vec_len <= 54;

    END GENERATE;

    gen_test_vec_1 : IF c_noof_clients = 1  AND c_max_pipeline = 8 GENERATE

        -- Note that maddr is a byte address. DataMover expects this to be aligned such that mmaddr rem 4 = 0
        CONSTANT c_test_vec : t_test_vec(1 TO 100) := (

                 -- Test case 1 : 1 client connect, interleaved write and read
                1 => ( client=>1, req_cmd=>c_gemreq_connect, rsp_cmd=>c_gemresp_ack, csn=>1, ssn=>1, mmaddr=>0, req_nregs=>3, rsp_nregs=>3, ipg=>1 ),
                2 => ( client=>1, req_cmd=>c_gemreq_write_inc, rsp_cmd=>c_gemresp_ack, csn=>2, ssn=>2, mmaddr=>0, req_nregs=>1, rsp_nregs=>1, ipg=>3 ),
                3 => ( client=>1, req_cmd=>c_gemreq_read_inc, rsp_cmd=>c_gemresp_ack, csn=>3, ssn=>3, mmaddr=>0, req_nregs=>1, rsp_nregs=>1, ipg=>2 ),

                -- Test case 2 : 8000 byte MTU write and read
                4 => ( client=>1, req_cmd=>c_gemreq_write_inc, rsp_cmd=>c_gemresp_ack, csn=>4, ssn=>4, mmaddr=>4, req_nregs=>c_max_nregs, rsp_nregs=>c_max_nregs, ipg=>1 ),
                5 => ( client=>1, req_cmd=>c_gemreq_read_inc, rsp_cmd=>c_gemresp_ack, csn=>5, ssn=>5, mmaddr=>4, req_nregs=>c_max_nregs, rsp_nregs=>c_max_nregs,  ipg=>100 ),

                -- Test case 3 : Server must be able to buffer at least c_max_pipeline packets (assume that c_max_pipeline is 8)
                -- All responses for client 2 must have been received before this point (ie depth is 0)
                6 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>6, ssn=>6, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                7 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>7, ssn=>7, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                8 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>8, ssn=>8, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                9 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>9, ssn=>9, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                10 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>10, ssn=>10, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                11 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>11, ssn=>11, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                12 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>12, ssn=>12, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                13 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>13, ssn=>13, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>6500 ),

                -- Test case 4 : Multiple clients per server  N/A

                -- Test case 5 : The server must respond with a NACK-P if the request command is not a Connect and the client does
                -- not exist in the server's connection table
                14 => ( client=>2, req_cmd=>c_gemreq_read_inc, rsp_cmd=>c_gemresp_nackp, csn=>14, ssn=>14, mmaddr=>0, req_nregs=>113, rsp_nregs=>0, ipg=>400 ),

                -- Test case 6 : The server must respond with a NACK-P if the request command is not supported
                -- Note that Request Decoder only looks at b<3:0>
                15 => ( client=>1, req_cmd=>x"00", rsp_cmd=>c_gemresp_nackp, csn=>14, ssn=>14, mmaddr=>0, req_nregs=>1, rsp_nregs=>0, ipg=>1 ),

                -- Test case 7 : The server must respond with a NACK-P if nregs would result in a response packet with length that exceeds the MTU
                16 => ( client=>1, req_cmd=>c_gemreq_read_inc, rsp_cmd=>c_gemresp_nackp, csn=>15, ssn=>15, mmaddr=>0, req_nregs=>c_max_nregs+1,rsp_nregs=>0, ipg=>1 ),

                -- Test case 8 : The server must respond with a NACK-P if the server is unable to replay the response for the request PDU's CSN.
                17 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>16, ssn=>16, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                18 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>17, ssn=>17, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                19 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>18, ssn=>18, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                20 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>19, ssn=>19, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                21 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>20, ssn=>20, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                22 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>21, ssn=>21, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                23 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>22, ssn=>22, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ),
                24 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>23, ssn=>23, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>6500 ),
                25 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>24, ssn=>24, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>2 ),
                26 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>17, ssn=>24, mmaddr=>16, req_nregs=>2, rsp_nregs=>2, ipg=>1 ), -- Successful replay
                27 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_nackp, csn=>16, ssn=>24, mmaddr=>16, req_nregs=>2, rsp_nregs=>0, ipg=>1 ), -- Replay should fail

                -- Test case 9 : The server must respond with a NACK-P if the MM bus operation fails because all, or part of, the BaseAddress
                --                 to BaseAddress + NumRegisters - 1 address range is not valid.
                28 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_nackp, csn=>25, ssn=>25, mmaddr=>8193, req_nregs=>1,rsp_nregs=>0, ipg=>1 ),

                -- Test case 10 : The server must respond with a NACK-T if the request CSN is not equal to the per-client state receive sequence
                --                 counter value.
                29 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_nackt, csn=>27, ssn=>27, mmaddr=>0, req_nregs=>1, rsp_nregs=>0, ipg=>50 ),

                -- Test case 11 : The server must respond with a NACK-T if the request is a Connect command and the server is unable to assign
                --    a connection table row to the client at this time.
                30 => ( client=>1, req_cmd=>c_gemreq_write_rep, rsp_cmd=>c_gemresp_ack, csn=>26, ssn=>26, mmaddr=>0, req_nregs=>1, rsp_nregs=>2, ipg=>1 ),
            others => ( client=>2, req_cmd=>c_gemreq_connect, rsp_cmd=>c_gemresp_nackt, csn=>1, ssn=>26, mmaddr=>0, req_nregs=>1, rsp_nregs=>0, ipg=>1 )  -- Note invalid SSN passes ok
        );

    BEGIN

        test_vec <= c_test_vec;
        test_vec_len <= 30;

    END GENERATE;

    clk <= NOT clk OR tb_end AFTER c_clk_period/2;
    rst <= '1', '0' AFTER 3*c_clk_period;

    p_tod : PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF rst = '1' THEN
                tod <= (others=>'0');
            ELSE
                tod <= tod + TO_UNSIGNED(1,tod'length);
            END IF;
        END IF;
    END PROCESS;

    p_stimulus : PROCESS
        VARIABLE len : NATURAL;
        VARIABLE align_last : STD_LOGIC_VECTOR(c_data_w/8-1 DOWNTO 0);
        VARIABLE pkt : t_pkt_data_arr(1 TO 1+(c_mtu+14-1)/(c_data_w/8));
        VARIABLE seed1 : POSITIVE := 2382372;
        VARIABLE seed2 : POSITIVE := 639684;
        VARIABLE rand : REAL;

    BEGIN

        -- Initialization
        ethrx_in.tvalid <= '0';
        ethrx_in.tstrb(c_data_w/8-1 DOWNTO 0) <= x"00";
        ethtx_in.tready <= '1';
        WAIT UNTIL rst='0';
        WAIT UNTIL RISING_EDGE(clk);

        FOR T IN 1 TO test_vec_len LOOP

            mk_request(test_vec(T).client,
                       test_vec(T).req_cmd,
                       test_vec(T).csn,
                       test_vec(T).mmaddr,
                       test_vec(T).req_nregs,
                       seed1,
                       seed2,
                       pkt);

            -- Send a test Ethernet packet into the DUT
            len := 7;
            align_last := x"3F";
            IF test_vec(T).req_cmd = c_gemreq_write_inc OR test_vec(T).req_cmd = c_gemreq_write_rep THEN
                len := ( test_vec(T).req_nregs + 15 ) / 2;
                IF ( test_vec(T).req_nregs REM 2 ) = 1 THEN
                    align_last := x"03";
                END IF;
            END IF;
            FOR J IN 1 TO len LOOP
                ethrx_in.tdata(c_data_w-1 DOWNTO 0) <= pkt(J);
                IF J = len THEN
                    ethrx_in.tlast <= '1';
                    ethrx_in.tkeep(c_data_w/8-1 DOWNTO 0) <= align_last;
                ELSE
                    ethrx_in.tlast <= '0';
                    ethrx_in.tkeep(c_data_w/8-1 DOWNTO 0) <= x"FF";
                END IF;
                ethrx_in.tvalid <= '1';
                WAIT UNTIL ethrx_out.tready = '1' AND RISING_EDGE(clk);
            END LOOP;

            stim_pkt(test_vec(T).client) <= test_vec(T).csn;
            REPORT "Client " & INTEGER'IMAGE(test_vec(T).client) & " sent request CSN=" & INTEGER'IMAGE(test_vec(T).csn) & CR;

            -- Delay next request by inter-packet gap
            -- DUT is designed with limited buffering. IPG is necessary to
            -- prevent packet loss that is expected when more than c_max_pipeline
            -- packets need to be buffered for any one client.
            ethrx_in.tvalid <= '0';
            FOR I IN 1 TO test_vec(T).ipg LOOP
                WAIT UNTIL RISING_EDGE(clk);
            END LOOP;

        END LOOP;

        WAIT;

    END PROCESS;

    p_response : PROCESS
        VARIABLE len : NATURAL;
        VARIABLE align_last : STD_LOGIC_VECTOR(c_data_w/8-1 DOWNTO 0);
        VARIABLE tdata : STD_LOGIC_VECTOR(c_data_w-1 DOWNTO 0);
        VARIABLE c : NATURAL;
        VARIABLE udplen : UNSIGNED(15 DOWNTO 0);
        VARIABLE exp_udplen : NATURAL;
        VARIABLE csum : UNSIGNED(15 DOWNTO 0);
        VARIABLE tkeep : STD_LOGIC_VECTOR(c_data_w/8-1 DOWNTO 0);
    BEGIN

        -- Initialization
        WAIT UNTIL rst='1';
        WAIT UNTIL RISING_EDGE(clk);

        FOR T IN 1 TO test_vec_len LOOP

            c := test_vec(T).client;
            csum := TO_UNSIGNED(0,16);

            len := 7;
            align_last := x"3F";
            exp_udplen := 20;
            IF test_vec(T).req_cmd = c_gemreq_connect THEN
                len := ( 3 + 15 ) / 2;
                exp_udplen := 20 + 4*3;
                align_last := x"03";
            ELSIF ( test_vec(T).req_cmd = c_gemreq_read_inc OR test_vec(T).req_cmd = c_gemreq_read_rep ) THEN
                len := ( test_vec(T).rsp_nregs + 15 ) / 2;
                exp_udplen := 20 + 4*test_vec(T).rsp_nregs;
                IF ( test_vec(T).rsp_nregs REM 2 ) = 1 THEN
                    align_last := x"03";
                END IF;
            END IF;

            -- Validate next Ethernet packet from DUT
            FOR J IN 1 TO len LOOP

                WAIT UNTIL ethtx_out.tvalid = '1' AND ethtx_in.tready = '1' AND RISING_EDGE(clk);

                IF J=1 THEN
                    REPORT "Client " & INTEGER'IMAGE(C) & " receiving response CSN=" & INTEGER'IMAGE(test_vec(T).csn) & " (depth " & INTEGER'IMAGE(pipeline_depth(C)) & ")" & CR;
                    IF pipeline_depth(C) > c_max_pipeline THEN
                        REPORT "Server buffering exceeded for client " & INTEGER'IMAGE(C) & " - expect packet loss" & CR SEVERITY WARNING;
                    END IF;
                END IF;

                tdata := ethtx_out.tdata(c_data_w-1 DOWNTO 0);
                tkeep := ethtx_out.tkeep(c_data_w/8-1 DOWNTO 0);

                IF J = len THEN
                    ASSERT ethtx_out.tlast = '1' REPORT "Wrong TLAST" SEVERITY FAILURE;
                    ASSERT tkeep = align_last REPORT "Wrong TKEEP" SEVERITY FAILURE;
                ELSE
                    ASSERT ethtx_out.tlast = '0' REPORT "Wrong TLAST" SEVERITY FAILURE;
                    ASSERT tkeep = x"FF" REPORT "Wrong TKEEP" SEVERITY FAILURE;
                END IF;

                CASE J IS
                    WHEN 1 =>
                        ASSERT tdata(47 DOWNTO 0) = c_clients(c).mac REPORT "Wrong MACDst" SEVERITY FAILURE;
                    WHEN 2 | 3 =>
                        null;
                    WHEN 4 =>
                        ASSERT tdata(63 DOWNTO 48) = c_clients(c).ipaddr(15 DOWNTO 0) REPORT "Wrong IPDstAddr" SEVERITY FAILURE;
                    WHEN 5 =>
                        ASSERT tdata(15 DOWNTO 0) = c_clients(c).ipaddr(31 DOWNTO 16) REPORT "Wrong IPDstAddr" SEVERITY FAILURE;
                        ASSERT tdata(47 DOWNTO 32) = c_clients(c).udppt REPORT "Wrong UDPDstPt" SEVERITY FAILURE;
                        udplen := UNSIGNED(tdata(55 DOWNTO 48)) & UNSIGNED(tdata(63 DOWNTO 56));
                        ASSERT udplen = TO_UNSIGNED(exp_udplen,16) REPORT "Wrong UDPLen" SEVERITY FAILURE;
                    WHEN 6 =>
                        ASSERT tdata(23 DOWNTO 16) <= x"01" REPORT "Wrong GemVer" SEVERITY FAILURE;
                        ASSERT tdata(31 DOWNTO 24) <= test_vec(T).rsp_cmd REPORT "Wrong GemCmd" SEVERITY FAILURE;
                        ASSERT UNSIGNED(tdata(39 DOWNTO 32)) <= TO_UNSIGNED(test_vec(T).csn,8) REPORT "Wrong GemCSN" SEVERITY FAILURE;
                        ASSERT UNSIGNED(tdata(47 DOWNTO 40)) <= TO_UNSIGNED(test_vec(T).ssn,8) REPORT "Wrong GemSSN" SEVERITY FAILURE;
                        resp_pkt(C) <= TO_INTEGER(UNSIGNED(tdata(47 DOWNTO 40)));
                    WHEN 7 =>
                        ASSERT UNSIGNED(tdata(31 DOWNTO 16)) <= TO_UNSIGNED(test_vec(T).rsp_nregs,16) REPORT "Wrong GemNRegs" SEVERITY FAILURE;
                        IF test_vec(T).req_cmd = c_gemreq_connect AND NOT ( test_vec(T).rsp_cmd = c_gemresp_nackt OR test_vec(T).rsp_cmd = c_gemresp_nackp ) THEN
                            ASSERT UNSIGNED(tdata(63 DOWNTO 48)) = TO_UNSIGNED(c_max_nregs,16) REPORT "Wrong max_nregs in connect response" SEVERITY FAILURE;
                        END IF;
                        IF tkeep = x"FF" THEN
                            csum := UNSIGNED(tdata(63 DOWNTO 48));
                        END IF;
                    WHEN OTHERS =>
                        IF J=8 AND test_vec(T).req_cmd = c_gemreq_connect THEN
                            ASSERT UNSIGNED(tdata(47 DOWNTO 16)) = TO_UNSIGNED(c_max_pipeline,32) REPORT "Wrong max_pipeline in connect response" SEVERITY FAILURE;
                        END IF;
                        IF tkeep = x"03" THEN
                            csum := csum + UNSIGNED(tdata(15 DOWNTO 0));
                        ELSIF tkeep = x"3F" THEN
                            csum := csum + UNSIGNED(tdata(15 DOWNTO 0));
                            csum := csum + UNSIGNED(tdata(31 DOWNTO 16));
                            csum := csum + UNSIGNED(tdata(47 DOWNTO 32));
                        ELSIF tkeep = x"FF" THEN
                             csum := csum + UNSIGNED(tdata(15 DOWNTO 0));
                            csum := csum + UNSIGNED(tdata(31 DOWNTO 16));
                            csum := csum + UNSIGNED(tdata(47 DOWNTO 32));
                            csum := csum + UNSIGNED(tdata(63 DOWNTO 48));
                        END IF;
                END CASE;

            END LOOP;

            IF test_vec(T).req_cmd /= c_gemreq_connect AND test_vec(T).rsp_cmd = c_gemresp_ack THEN
                ASSERT csum = TO_UNSIGNED(0,16) REPORT "Wrong TDATA" SEVERITY FAILURE;
            END IF;

        END LOOP;

        tb_end <= '1';

        ASSERT FALSE REPORT "Simulation completed with no errors." SEVERITY NOTE;

        WAIT;

    END PROCESS;

    gen_pipeline_depth : FOR C IN 1 TO c_max_clients+1 GENERATE
        pipeline_depth(C) <= stim_pkt(C) - resp_pkt(C);
    END GENERATE;

    u_dut : ENTITY gemini_server_lib.gemini_server
    GENERIC MAP (
        g_technology => c_tech_gemini,
        g_noof_clnts => c_noof_clients,
        g_data_w => c_data_w,
        g_mm_data_w => c_mm_data_w,
        g_tod_w => c_tod_w,
        g_max_pipeline => c_max_pipeline,
        g_mtu => c_mtu,
        g_min_recycle_secs => 2000,  -- 20us simulation time
        g_txfr_timeout => 400 )
    PORT MAP (
        clk => clk,
        rst => rst,
        ethrx_in => ethrx_in,
        ethrx_out => ethrx_out,
        ethtx_in => ethtx_in,
        ethtx_out => ethtx_out,
        mm_in => mc_master_miso,
        mm_out => mc_master_mosi,
        tod_in => tod_sl );

    tod_sl <= STD_LOGIC_VECTOR(tod);

   rstn <= NOT(rst);


   u_interconnect: ENTITY lru_test_lib.gemini_server_test_wrapper
   PORT MAP (
      ACLK                       => clk,
      ARESETN                    => rstn,
      M02_AXI_LITE_araddr        => OPEN,
      M02_AXI_LITE_arprot        => OPEN,
      M02_AXI_LITE_arready       => '1',
      M02_AXI_LITE_arvalid       => OPEN,
      M02_AXI_LITE_awaddr        => OPEN,
      M02_AXI_LITE_awprot        => OPEN,
      M02_AXI_LITE_awready       => '1',
      M02_AXI_LITE_awvalid       => OPEN,
      M02_AXI_LITE_bready        => OPEN,
      M02_AXI_LITE_bresp         => "00",
      M02_AXI_LITE_bvalid        => '0',
      M02_AXI_LITE_rdata         => X"00000000",
      M02_AXI_LITE_rready        => OPEN,
      M02_AXI_LITE_rresp         => "00",
      M02_AXI_LITE_rvalid        => '0',
      M02_AXI_LITE_wdata         => OPEN,
      M02_AXI_LITE_wready        => '1',
      M02_AXI_LITE_wstrb         => OPEN,
      M02_AXI_LITE_wvalid        => OPEN,
      M03_AXI_LITE_araddr        => OPEN,
      M03_AXI_LITE_arprot        => OPEN,
      M03_AXI_LITE_arready       => '1',
      M03_AXI_LITE_arvalid       => OPEN,
      M03_AXI_LITE_awaddr        => OPEN,
      M03_AXI_LITE_awprot        => OPEN,
      M03_AXI_LITE_awready       => '1',
      M03_AXI_LITE_awvalid       => OPEN,
      M03_AXI_LITE_bready        => OPEN,
      M03_AXI_LITE_bresp         => "00",
      M03_AXI_LITE_bvalid        => '0',
      M03_AXI_LITE_rdata         => X"00000000",
      M03_AXI_LITE_rready        => OPEN,
      M03_AXI_LITE_rresp         => "00",
      M03_AXI_LITE_rvalid        => '0',
      M03_AXI_LITE_wdata         => OPEN,
      M03_AXI_LITE_wready        => '1',
      M03_AXI_LITE_wstrb         => OPEN,
      M03_AXI_LITE_wvalid        => OPEN,
      S00_AXI_araddr                => mc_master_mosi.araddr(14 downto 0),
      S00_AXI_arprot(c_axi4_full_prot_w-1 downto 0)      => mc_master_mosi.arprot(c_axi4_full_prot_w-1 downto 0),
      S00_AXI_arvalid(0)                                 => mc_master_mosi.arvalid  ,
      S00_AXI_awaddr                 => mc_master_mosi.awaddr(14 downto 0),
      S00_AXI_awprot(c_axi4_full_prot_w-1 downto 0)      => mc_master_mosi.awprot(c_axi4_full_prot_w-1 downto 0),
      S00_AXI_awvalid(0)                                 => mc_master_mosi.awvalid  ,
      S00_AXI_bready(0)                                  => mc_master_mosi.bready  ,
      S00_AXI_rready(0)                                  => mc_master_mosi.rready  ,
      S00_AXI_wdata                 => mc_master_mosi.wdata(31 downto 0),
      S00_AXI_wstrb                => mc_master_mosi.wstrb(3 downto 0),
      S00_AXI_wvalid(0)                                  => mc_master_mosi.wvalid  ,
      S00_AXI_arburst(c_axi4_full_aburst_w-1 downto 0)   => mc_master_mosi.arburst(c_axi4_full_aburst_w-1 downto 0),
      S00_AXI_awburst(c_axi4_full_aburst_w-1 downto 0)   => mc_master_mosi.awburst(c_axi4_full_aburst_w-1 downto 0),
      S00_AXI_arcache(c_axi4_full_acache_w-1 downto 0)   => mc_master_mosi.arcache(c_axi4_full_acache_w-1 downto 0),
      S00_AXI_awcache(c_axi4_full_acache_w-1 downto 0)   => mc_master_mosi.awcache(c_axi4_full_acache_w-1 downto 0),
      S00_AXI_arlen(c_axi4_full_alen_w-1 downto 0)       => mc_master_mosi.arlen(c_axi4_full_alen_w-1 downto 0),
      S00_AXI_arsize(c_axi4_full_asize_w-1 downto 0)     => mc_master_mosi.arsize(c_axi4_full_asize_w-1 downto 0),
      S00_AXI_awsize(c_axi4_full_asize_w-1 downto 0)     => mc_master_mosi.awsize(c_axi4_full_asize_w-1 downto 0),
      S00_AXI_awlen(c_axi4_full_alen_w-1 downto 0)       => mc_master_mosi.awlen(c_axi4_full_alen_w-1 downto 0),
      S00_AXI_arlock(0)                                  => mc_master_mosi.arlock,
      S00_AXI_awlock(0)                                  => mc_master_mosi.awlock,
      S00_AXI_wlast(0)                                   => mc_master_mosi.wlast  ,
      S00_AXI_awqos(c_axi4_full_aqos_w-1 downto 0)       => mc_master_mosi.awqos(c_axi4_full_aqos_w-1 downto 0),
      S00_AXI_arqos(c_axi4_full_aqos_w-1 downto 0)       => mc_master_mosi.arqos(c_axi4_full_aqos_w-1 downto 0),
      S00_AXI_awready(0)                                 => mc_master_miso.awready  ,
      S00_AXI_wready(0)                                  => mc_master_miso.wready ,
      S00_AXI_bresp(c_axi4_full_resp_w-1 downto 0)       => mc_master_miso.bresp(c_axi4_full_resp_w-1 downto 0),
      S00_AXI_bvalid(0)                                  => mc_master_miso.bvalid  ,
      S00_AXI_arready(0)                                 => mc_master_miso.arready  ,
      S00_AXI_rdata                 => mc_master_miso.rdata(31 downto 0),
      S00_AXI_rresp(c_axi4_full_resp_w-1 downto 0)       => mc_master_miso.rresp(c_axi4_full_resp_w-1 downto 0),
      S00_AXI_rvalid(0)                                  => mc_master_miso.rvalid  ,
      S00_AXI_rlast(0)                                   => mc_master_miso.rlast);


--u_interconnect: ENTITY lru_test_lib.lru_test_bus_top
--                PORT MAP (CLK             => clk,
--                          RST             => rst,
--                          SLA_IN          => mc_master_mosi,
--                          SLA_OUT         => mc_master_miso,
--                          MSTR_IN_LITE    => mc_lite_miso,
--                          MSTR_OUT_LITE   => mc_lite_mosi,
--                          MSTR_IN_FULL    => mc_full_miso,
--                          MSTR_OUT_FULL   => mc_full_mosi);


END tb;
