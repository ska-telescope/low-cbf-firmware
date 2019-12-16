---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Test Bench for the Main HBM Buffer
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@aut.ac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Simulates the Fine Corner Turner in the Main HBM Buffer
-- 
-- Creates stimuli and checks the DUT's output response
--
---------------------------------------------------------------------------------------------------
-- NOTE:
-- There are plenty of generics in play. However, not every combination is supported by the code.
-- The validity of generics is checked by assertions.
--
-- The data bus format supports a metadata part that is only used in simulation to ease debugging.
-- It is explicitly excluded from synthesis using pragmas.
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library work;
use work.ctf_pkg.all;

entity tb_ctf_hbm_buffer is
    generic (
        g_USE_HBM         : boolean := TRUE;
        g_INPUT_STUTTER   : boolean := FALSE;
        g_PROVOKE_EMPTY   : boolean := FALSE;
        g_OUTPUT_STUTTER  : boolean := FALSE;
        g_COARSE_CHANNELS : integer := 64;        --PISA: 128
        g_STATION_GROUPS  : integer := 3;         --PISA: 3
        g_TIME_STAMPS     : integer := 128;       --PISA: 204
        g_FINE_CHANNELS   : integer := 256;       --PISA: 3456
        g_ATOM_SIZE       : integer := 4          --PISA: 4
    );
end tb_ctf_hbm_buffer;

architecture sim of tb_ctf_hbm_buffer is

    
    signal hbm_clk : std_logic := '0';
    signal apb_clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal data_in      : t_ctf_hbm_data;
    signal data_in_vld  : std_logic := '0';
    signal data_in_stop : std_logic;
    signal data_in_rdy  : std_logic;

    signal data_out      : t_ctf_hbm_data;
    signal data_out_vld  : std_logic := '0';
    signal data_out_stop : std_logic := '0';

    signal clk_en : std_logic := '1';

begin

    E_DUT: entity work.ctf_hbm_buffer
    generic map (
        g_USE_HBM           => g_USE_HBM,
        g_BLOCK_SIZE        => g_FINE_CHANNELS/4*g_ATOM_SIZE,               --The ATOMs refer to times, not fine channels; /4 because of the 256 bit input (=4 fine channels at once) 
        g_BLOCK_COUNT       => g_TIME_STAMPS/g_ATOM_SIZE*g_STATION_GROUPS,  --The ATOMs refer to times, not fine channels; GROUPS are a group of BLOCKS inside a FRAME
        g_GROUP_COUNT       => g_STATION_GROUPS,
        g_ATOM_SIZE         => g_ATOM_SIZE,
        g_INPUT_STOP_WORDS  => 1,
        g_OUTPUT_STOP_WORDS => 60
    ) port map (
        i_hbm_ref_clk   => apb_clk,
        i_hbm_clk       => hbm_clk,
        i_apb_clk       => apb_clk,
        i_hbm_rst       => rst,
        i_data_in       => data_in,
        i_data_in_vld   => data_in_vld,
        o_data_in_stop  => data_in_stop,
        o_data_in_rdy   => data_in_rdy,
        o_data_out      => data_out,
        o_data_out_vld  => data_out_vld,
        i_data_out_stop => data_out_stop
    );
    

    rst <= '0', '1' after 10 ns, '0' after 20 ns;  

    --450MHz
    hbm_clk <= clk_en and not hbm_clk after 1.111 ns;

    --100MHz
    apb_clk <= clk_en and not apb_clk after 5 ns;

    P_STIMULUS: process
        variable seed1 : positive := 1;
        variable seed2 : positive := 1;
        variable rand  : real;
        variable dice  : integer;
        variable o     : natural;  
        variable u     : natural;
        variable seg   : natural;
        variable fine  : natural;
        variable ts    : natural;
        variable num   : natural;
    begin
        
        data_in.data <= X"4711AFFE_00000000_12345678_00000000_4711AFFE_00000000_12345678_00000000";
        
        wait until rst='1';
        wait until rst='0';
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        
        while (data_in_rdy='0' or data_in_stop='1') loop
               wait until rising_edge(hbm_clk);
        end loop;

        --give time for the addresses to be written -- todo: fix this by counting data vs. addresses?
        wait for 1 us;

        while (data_in_rdy='0' or data_in_stop='1') loop
               wait until rising_edge(hbm_clk);
        end loop;

        num := 0;
            
        for coarse in 0 to g_COARSE_CHANNELS-1 loop
            for st_group in 0 to g_STATION_GROUPS-1 loop
                for outer_ts in 0 to g_TIME_STAMPS/g_ATOM_SIZE-1 loop
                    for outer_fine in 0 to g_FINE_CHANNELS/4-1 loop
                        for inner_ts in 0 to g_ATOM_SIZE-1 loop
    
                            ts := (outer_ts*g_ATOM_SIZE)+inner_ts;
    
                            --stutter & stop logic
                            uniform(seed1, seed2, rand);
                            if g_PROVOKE_EMPTY then
                                dice := integer(rand*2.0);
                            else    
                                dice := integer(rand*10.0);
                            end if;    
                            while data_in_stop='1' or (g_PROVOKE_EMPTY and dice/=1) or (g_INPUT_STUTTER and not g_PROVOKE_EMPTY and dice=1) loop
                                data_in_vld <= '0';
                                wait until rising_edge(hbm_clk);
                                uniform(seed1, seed2, rand);
                                if g_PROVOKE_EMPTY then
                                    dice := integer(rand*2.0);
                                else
                                    dice := integer(rand*10.0);
                                end if;    
                            end loop;
    
                            for inner_fine in 0 to 3 loop
                                for station in 0 to 3 loop
                                    
                                    fine := (outer_fine*4) + inner_fine; 
                                    seg  := (inner_fine*4) + station;
                                    o    := (15-seg)*16+15;
                                    u    := (15-seg)*16;
                                    
                                    --data generator
                                    --data_in.data(o-8 downto u+0)   <= std_logic_vector(to_unsigned(num,     8));  --im
                                    --data_in.data(o-0 downto u+8)   <= std_logic_vector(to_unsigned(num/256, 8));  --re
                                    data_in.data(o-8 downto u+0)   <= std_logic_vector(to_unsigned(station  + (ts*16),   8));  --im
                                    data_in.data(o-0 downto u+8)   <= std_logic_vector(to_unsigned(st_group + (fine*16), 8));  --re
                                    data_in.meta(15-seg).coarse    <= coarse;
                                    data_in.meta(15-seg).st_group  <= st_group;
                                    data_in.meta(15-seg).station   <= (station/2)+(st_group*2);
                                    data_in.meta(15-seg).pol       <= (station rem 2);
                                    data_in.meta(15-seg).ts        <= ts;
                                    data_in.meta(15-seg).fine      <= fine;
                                    data_in_vld <= '1';
                                    num := num + 1;
                                end loop;
                            end loop;                        
    
                            wait until rising_edge(hbm_clk);
                            while (data_in_rdy='0') loop
                                wait until rising_edge(hbm_clk);
                            end loop;    
                            
                        end loop;
                    end loop;            
                end loop;        
            end loop;
        end loop;
        
        data_in_vld <= '0';
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        wait until rising_edge(hbm_clk);
        
        wait;
            
    end process; 
   
    
    
    
    GEN_OUTPUT_STUTTER: if g_OUTPUT_STUTTER generate
    begin 
        P_OUTPUT_STUTTER: process
            variable seed1: positive := 2;
            variable seed2: positive := 1;
            variable rand: real;
            variable dice: integer;
        begin
            uniform(seed1, seed2, rand);
            dice := integer(rand*2.0);
            if dice=1 then
                data_out_stop <= '1';
            else
                data_out_stop <= '0';
            end if;
            wait until rising_edge(hbm_clk);    
        end process;
    end generate;
        
    P_CHECKER: process
        variable o  : natural;  
        variable u  : natural;
        variable fine : natural;
        variable seg  : natural;
        variable ts   : natural;
    begin
        wait until rst='1';
        wait until rst='0';
        wait until rising_edge(hbm_clk);
        
        report "SIMULATION STARTED." severity NOTE;
        
        while data_out_vld='0' loop
            wait until rising_edge(hbm_clk);
        end loop;
        for coarse in 0 to g_COARSE_CHANNELS-1 loop
           for outer_fine in 0 to g_FINE_CHANNELS/pc_CTF_OUTPUT_NUMBER-1 loop
               for outer_ts in 0 to g_TIME_STAMPS/g_ATOM_SIZE-1 loop
                   for st_group in 0 to g_STATION_GROUPS-1 loop
                       for inner_ts in 0 to g_ATOM_SIZE-1 loop
                           ts := outer_ts*g_ATOM_SIZE + inner_ts;
                           while data_out_vld='0' loop
                               wait until rising_edge(hbm_clk);
                           end loop;
                           for inner_fine in 0 to pc_CTF_OUTPUT_NUMBER-1 loop
                               fine := pc_CTF_OUTPUT_NUMBER*outer_fine + inner_fine;
                               for segment in 0 to (16/pc_CTF_OUTPUT_NUMBER)-1 loop
                                   seg := inner_fine*(16/pc_CTF_OUTPUT_NUMBER) + segment;
                                   o := (15-seg)*16+15;
                                   u := (15-seg)*16;
                                   assert data_out.meta(15-seg).coarse   = coarse                                           report "Coarse Channel wrong!"  severity FAILURE;
                                   assert data_out.meta(15-seg).st_group = st_group                                         report "Station Group wrong!"   severity FAILURE;
                                   assert data_out.meta(15-seg).station  = (segment/2)+(st_group*2)                         report "Station wrong!"         severity FAILURE;
                                   assert data_out.meta(15-seg).pol      = (segment rem 2)                                  report "Polarity wrong!"        severity FAILURE;
                                   assert data_out.meta(15-seg).ts       = ts                                               report "Timestamp wrong!"       severity FAILURE;
                                   assert data_out.meta(15-seg).fine     = fine                                             report "Fine Channel wrong! Got: " & integer'image(data_out.meta(15-seg).fine) & "  Expected: " & integer'image(fine) severity FAILURE;
                                   assert data_out.data(o-8 downto u+0) = std_logic_vector(to_unsigned(segment  + (ts*16), 8))  report "Imaginary value " & integer'image(to_integer(unsigned(data_out.data(o-8 downto u+0)))) & " is wrong!" severity FAILURE;
                                   assert data_out.data(o-0 downto u+8) = std_logic_vector(to_unsigned(st_group + fine*16, 8))  report "Real value "      & integer'image(to_integer(unsigned(data_out.data(o-0 downto u+8)))) & " is wrong!" severity FAILURE;
                               end loop;
                           end loop;        
                           wait until rising_edge(hbm_clk);
                        end loop;        
                    end loop;
               end loop;             
           end loop;
       end loop;    
        
       wait for 1 us;
       
       report "SIMULATION ENDED." severity NOTE;

       clk_en <= '0';
       
       wait;
       
           
    end process;
    
end sim;
