
-------------------------------------------------------------------------------
-- (c) Copyright - Commonwealth Scientific and Industrial Research Organisation
-- (CSIRO) - 2017
--
-- All Rights Reserved.
--
-- Restricted Use.
--
-- Copyright protects this code. Except as permitted by the Copyright Act, you
-- may only use the code as expressly permitted under the terms on which the
-- code was licensed to you.
--
-------------------------------------------------------------------------------



LIBRARY IEEE, common_lib, axi4_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE axi4_lib.axi4_stream_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE work.all;


ENTITY arp_responder IS
	GENERIC (
		g_technology        : t_technology := c_tech_select_default
	);
	PORT (
		clk					: IN 	STD_LOGIC;
		rst					: IN 	STD_LOGIC;
		
		eth_addr_ip			: IN 	STD_LOGIC_VECTOR(31 downto 0);
		eth_addr_mac		: IN 	STD_LOGIC_VECTOR(47 downto 0);
		
		frame_in_sosi  		: IN 	t_axi4_sosi;
		frame_in_siso		: OUT 	t_axi4_siso;
		
		frame_out_siso 		: IN 	t_axi4_siso;
		frame_out_sosi		: OUT 	t_axi4_sosi
        
	);
END arp_responder;

ARCHITECTURE rtl OF arp_responder IS

	TYPE t_rom				IS ARRAY (1 downto 0) OF STD_LOGIC_VECTOR(31 downto 0);
	TYPE t_enum_states		IS (s_idle, s_build, s_wait); 

    -- Ethernet MAC constants
    CONSTANT ARP_ETYPE      : STD_LOGIC_VECTOR(15 downto 0) := x"0608";
    -- ARP payload constants
	CONSTANT HTYPE_ETH		: STD_LOGIC_VECTOR(15 downto 0) := x"0100";
	CONSTANT PTYPE_IPV4		: STD_LOGIC_VECTOR(15 downto 0) := x"0008";
	CONSTANT HLEN_ETH 		: STD_LOGIC_VECTOR(7 downto 0) := x"06";
	CONSTANT PLEN_IPV4		: STD_LOGIC_VECTOR(7 downto 0) := x"04";
	CONSTANT OP_REQ			: STD_LOGIC_VECTOR(15 downto 0) := x"0100";
	CONSTANT OP_RESP		: STD_LOGIC_VECTOR(15 downto 0) := x"0200";
	CONSTANT ARP_REQ		: STD_LOGIC_VECTOR(63 downto 0) := (OP_REQ & PLEN_IPV4 & HLEN_ETH & PTYPE_IPV4 & HTYPE_ETH);
	CONSTANT ARP_RESP		: STD_LOGIC_VECTOR(63 downto 0) := (OP_RESP & PLEN_IPV4 & HLEN_ETH & PTYPE_IPV4 & HTYPE_ETH);
	
    
	SIGNAL fifo_data		: STD_LOGIC_VECTOR(72 downto 0);
    ATTRIBUTE keep : string; 
    ATTRIBUTE keep of fifo_data : signal is "true";
	SIGNAL fifo_read		: STD_LOGIC;
	SIGNAL fifo_write		: STD_LOGIC;
	SIGNAL fifo_empty		: STD_LOGIC;
	SIGNAL fifo_full		: STD_LOGIC;
	SIGNAL fifo_valid		: STD_LOGIC;
	SIGNAL states_tx		: t_enum_states;
    ATTRIBUTE keep of states_tx : signal is "true";
	SIGNAL source_ip		: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL dest_ip			: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL temp_ip			: STD_LOGIC_VECTOR(31 downto 0);
	SIGNAL source_mac		: STD_LOGIC_VECTOR(47 downto 0);
	SIGNAL dest_mac			: STD_LOGIC_VECTOR(47 downto 0);
	SIGNAL temp_mac			: STD_LOGIC_VECTOR(47 downto 0);
    SIGNAL tvalid_ely       : STD_LOGIC;
	
	SIGNAL frame_in_tkeep	: STD_LOGIC_VECTOR(7 downto 0);
	SIGNAL frame_in_tlast	: STD_LOGIC;
    
    SIGNAL i_frame_out_siso : t_axi4_siso;
    SIGNAL i_frame_out_sosi : t_axi4_sosi;
	
	SIGNAL check_word		: UNSIGNED(2 downto 0);
    ATTRIBUTE keep of check_word : signal is "true";    
    SIGNAL build_word       : UNSIGNED(3 downto 0);
    ATTRIBUTE keep of build_word : signal is "true";    
    SIGNAL arp_match        : STD_LOGIC;

	FUNCTION f_our_arp(frame : STD_LOGIC_VECTOR(63 downto 0); check_word : UNSIGNED; addr_ip : STD_LOGIC_VECTOR) RETURN BOOLEAN IS
	BEGIN
		IF 
            -- (check_word = 1 AND frame(47 downto 0) /= x"FFFFFFFFFFFF") OR -- 63 downto 48 is SOURCE_MAC(15 downto 0)
            (check_word = 2 AND frame(63 downto 32) /= ARP_REQ(15 downto 0) & ARP_ETYPE) OR -- 31 downto 0 is SOURCE MAC (47 downto 16)
			(check_word = 3 AND frame(47 downto 0) /= ARP_REQ(63 downto 16)) OR -- frame(63 downto 48) is SOURCE_MAC(15 downto 0)
             -- frame(63 downto 32) is SOURCE_IP frame(31 downto 0) is SOURCE_MAC(47 downto 16)
			(check_word = 5 AND frame(63 downto 48) /=(addr_ip(23 downto 16) & addr_ip(31 downto 24)))  OR 
			(check_word = 6 AND frame(15 downto 0) /= (addr_ip(7 downto 0) & addr_ip(15 downto 8)))
		THEN
			RETURN FALSE;
		ELSE
			RETURN TRUE;
		END IF;
	END FUNCTION f_our_arp;
    
	
BEGIN

    frame_out_sosi <= i_frame_out_sosi;
    i_frame_out_siso <= frame_out_siso;

-- input FIFO 
-- 
    fifo_write <= not(fifo_full) and frame_in_sosi.tvalid;
    frame_in_siso.tready <= not(fifo_full);
    
	input_fifo: ENTITY common_lib.common_fifo_sc 
	GENERIC MAP (g_technology    => g_technology,
				 g_use_lut       => TRUE,
				 g_dat_w         => 73,
				 g_nof_words     => 32,
				 g_fifo_latency  => 1)
	PORT MAP (rst                    => rst,
			  clk                    => clk, 
			  wr_dat(63 downto 0)    => frame_in_sosi.tdata(63 downto 0),
			  wr_dat(71 downto 64)   => frame_in_sosi.tkeep(7 downto 0),
			  wr_dat(72)             => frame_in_sosi.tlast,
			  wr_req                 => fifo_write,
			  wr_ful                 => fifo_full,
			  wr_prog_ful            => OPEN,
			  wr_aful                => OPEN,
			  rd_dat                 => fifo_data(72 downto 0),
			  rd_req                 => fifo_read,
			  rd_emp                 => fifo_empty,
			  rd_prog_emp            => OPEN,
			  rd_val                 => fifo_valid,
			  usedw                  => OPEN);
		
	frame_in_tkeep <= fifo_data(71 downto 64);
	frame_in_tlast <= fifo_data(72);

	p_main: PROCESS(clk)
	BEGIN
		IF RISING_EDGE(clk) THEN
            source_ip	<= eth_addr_ip;
            source_mac	<= eth_addr_mac;
		END IF;
	END PROCESS;
	
	p_fifo_ctrl : PROCESS(clk) 
	BEGIN
		IF RISING_EDGE(clk) THEN
			IF rst = '1' THEN
                fifo_read <= '0';
			ELSE 
				IF  fifo_empty = '0'  THEN 
                    fifo_read <= '1';
				ELSE
                    fifo_read <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
-- check input frame
	p_frame_checker: PROCESS(clk)
	BEGIN
		IF RISING_EDGE(clk) THEN
			IF rst = '1' THEN
                dest_mac    <= (others => '0');
                temp_mac    <= (others => '0');
                dest_ip     <= (others => '1');
                temp_ip     <= (others => '1');
                arp_match   <= '0';
                check_word <= (others => '0');
			ELSE
                IF f_our_arp(fifo_data(63 downto 0), check_word, source_ip) and fifo_valid = '1' THEN
                    IF check_word /= 6 THEN
                        check_word <= check_word + 1;
                    ELSE
                        check_word <= "001";
                    END IF;

                    IF check_word = 3 THEN
                        temp_mac(15 downto 0) <= fifo_data(63 downto 48); -- get REQ sender MAC 
                    ELSIF check_word = 4 THEN
                        temp_mac(47 downto 16) <= fifo_data(31 downto 0);
                        temp_ip <= fifo_data(63 downto 32); -- get REQ sender IP
                    END IF;
                    
                    IF check_word /= 6 THEN
                        arp_match <= '0';
                    ELSE -- 
                        arp_match <= '1';
                        dest_mac <= temp_mac;
                        dest_ip <= temp_ip;
                    END IF;
                ELSE
                    arp_match <= '0';
                    check_word <= "001";
                END IF;

			END IF;
		END IF;
	END PROCESS;
    
    valid_pipe: ENTITY common_lib.common_pipeline
    GENERIC MAP (g_pipeline  => 1,
                 g_in_dat_w  => 1,
                 g_out_dat_w => 1)
    PORT MAP (clk          => clk,
              rst          => '0',
              in_en        => i_frame_out_siso.tready,
              in_dat(0)    => tvalid_ely,
              out_dat(0)   => i_frame_out_sosi.tvalid); 

    -- Output 64 bit words using AXI4-Stream interface 
	p_resp_builder: PROCESS(clk)
	BEGIN
		IF RISING_EDGE(clk) THEN
			IF rst = '1' THEN
                states_tx   <= s_idle;
				build_word <= (others => '0');
                tvalid_ely <= '0';
			ELSE
				CASE states_tx IS
				
					WHEN s_idle => 

                        IF arp_match = '1' THEN
                            states_tx <= s_build;
                            tvalid_ely <= '1';
							build_word  <= "0001";
                        ELSE
                            states_tx <= s_idle;
                            tvalid_ely <= '0';
                            build_word <= (others => '0');
                        END IF;
                    
                    WHEN s_build => 

                        IF build_word < 8 THEN
                            tvalid_ely <= '1';
                        ELSE
                            tvalid_ely <= '0';
                        END IF;

                        IF i_frame_out_siso.tready = '1' THEN 
                            IF build_word /= 8 THEN 
                                build_word 	<= build_word + 1;
                                states_tx <= s_build;
                            ELSE
                                build_word <= (others => '0');
                                states_tx <= s_idle;
                            END IF;
                        END IF;
                        
                    WHEN others =>
                        null;
                    
				END CASE;
			END IF;
		END IF;
	END PROCESS;
	
	p_tdata_out: PROCESS(clk)
	BEGIN
		IF RISING_EDGE(clk) THEN
			CASE build_word IS
				WHEN "0000" => 
					i_frame_out_sosi.tdata(63 downto 0) <= (others => '0');
                    i_frame_out_sosi.tkeep(7 downto 0)  <= (others => '0');
                    i_frame_out_sosi.tlast  <= '0';
				WHEN "0001" => 
					i_frame_out_sosi.tdata(63 downto 0) <= source_mac(39 downto 32)& source_mac(47 downto 40) & dest_mac; --source_mac(15 downto 0) & dest_mac;
                    i_frame_out_sosi.tkeep(7 downto 0)  <= x"FF";
                    i_frame_out_sosi.tlast  <= '0';
				WHEN "0010" => 
					i_frame_out_sosi.tdata(63 downto 0) <= ARP_RESP(15 downto 0) & ARP_ETYPE & source_mac(7 downto 0) & source_mac(15 downto 8) & source_mac(23 downto 16) & source_mac(31 downto 24);--source_mac(47 downto 16);
                    i_frame_out_sosi.tkeep(7 downto 0)  <= x"FF";
                    i_frame_out_sosi.tlast  <= '0';				
				WHEN "0011" => 
					i_frame_out_sosi.tdata(63 downto 0) <= source_mac(39 downto 32) & source_mac(47 downto 40) & ARP_RESP(63 downto 16);-- source_mac(15 downto 0) & ARP_RESP(63 downto 16);
                    i_frame_out_sosi.tkeep(7 downto 0)  <= x"FF";
                    i_frame_out_sosi.tlast  <= '0';
				WHEN "0100" =>
					i_frame_out_sosi.tdata(63 downto 0) <= source_ip(7 downto 0) & source_ip(15 downto 8)& source_ip(23 downto 16) & source_ip(31 downto 24) & source_mac(7 downto 0) & source_mac(15 downto 8) & source_mac(23 downto 16) & source_mac(31 downto 24);-- source_ip &source_mac(47 downto 16) ;
                    i_frame_out_sosi.tkeep(7 downto 0)  <= x"FF";
                    i_frame_out_sosi.tlast  <= '0';
				WHEN "0101" =>
					i_frame_out_sosi.tdata(63 downto 0) <= dest_ip(15 downto 0) & dest_mac;
                    i_frame_out_sosi.tkeep(7 downto 0)  <= x"FF";
                    i_frame_out_sosi.tlast  <= '0';
				WHEN "0110" =>
					i_frame_out_sosi.tdata(63 downto 0) <= x"000000000000" & dest_ip(31 downto 16);
                    i_frame_out_sosi.tkeep(7 downto 0)  <= x"FF";
                    i_frame_out_sosi.tlast  <= '0';
				WHEN "0111" =>
					i_frame_out_sosi.tdata(63 downto 0) <= x"0000000000000000"; -- padding
                    i_frame_out_sosi.tkeep(7 downto 0)  <= x"FF";
                    i_frame_out_sosi.tlast  <= '0';         
				WHEN "1000" =>
					i_frame_out_sosi.tdata(63 downto 0) <= x"0000000000000000"; -- padding
                    i_frame_out_sosi.tkeep(7 downto 0)  <= x"FF";
                    i_frame_out_sosi.tlast  <= '1';     
                WHEN others =>
                    i_frame_out_sosi.tdata(63 downto 0) <= (others => '0');
                    i_frame_out_sosi.tkeep(7 downto 0)  <= (others => '0');
                    i_frame_out_sosi.tlast  <= '0';                

			END CASE;
		END IF;	
	END PROCESS;


END rtl;
