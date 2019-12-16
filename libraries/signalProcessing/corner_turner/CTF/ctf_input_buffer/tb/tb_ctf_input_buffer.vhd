---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Test Bench for the Input Buffer
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@aut.ac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Simulates the Fine Corner Turner in the Input Buffer
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

entity tb_ctf_input_buffer is
    generic (
        g_INPUT_STUTTER   : boolean := TRUE;
        g_PROVOKE_EMPTY   : boolean := FALSE;
        g_OUTPUT_STUTTER  : boolean := TRUE;
        g_BLOCK_COUNT     : integer := 4;
        g_COARSE_CHANNELS : integer := 1;         --PISA: 128
        g_STATION_GROUPS  : integer := 3;         --PISA: 3
        g_TIME_STAMPS     : integer := 204;       --PISA: 204
        g_FINE_CHANNELS   : integer := 3456;      --PISA: 3456
        g_ATOM_SIZE       : integer := 4          --PISA: 4
    );
end tb_ctf_input_buffer;

architecture sim of tb_ctf_input_buffer is

    
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal data_in      : t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
    signal data_in_vld  : std_logic_vector(pc_CTF_INPUT_NUMBER-1 downto 0) := (others => '0');
    signal data_in_stop : std_logic;

    signal data_out      : t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
    signal data_out_vld  : std_logic := '0';
    signal data_out_stop : std_logic := '0';

    signal clk_en : std_logic := '1';

begin

    E_DUT: entity work.ctf_input_buffer
    generic map (
        g_BLOCK_SIZE        => g_FINE_CHANNELS,
        g_BLOCK_COUNT       => g_BLOCK_COUNT,
        g_ATOM_SIZE         => g_ATOM_SIZE,
        g_INPUT_STOP_WORDS  => 1,
        g_OUTPUT_STOP_WORDS => 5
    ) port map (
        i_clk           => clk,
        i_rst           => rst,
        i_data_in       => data_in,
        i_data_in_vld   => data_in_vld(0), --all 4 input ports have to behave the same regarding vld
        o_data_in_stop  => data_in_stop,   --all 4 input ports have to behave the same regarding vld
        o_data_out      => data_out,
        o_data_out_vld  => data_out_vld,
        i_data_out_stop => data_out_stop
    );
    

    rst <= '1', '0' after 10 ns;  

    clk <= clk_en and not clk after 2 ns;

    GEN_STIMULUS: for in_port in 0 to pc_CTF_INPUT_NUMBER-1 generate
    begin
        P_STIMULUS: process
            variable seed1: positive := 1;
            variable seed2: positive := 1; -- all 4 ports have to behave the same in terms of stutter 
            variable rand: real;
            variable dice: integer;
        begin
            wait until rst='0';
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            
            for coarse in 0 to g_COARSE_CHANNELS-1 loop
                for st_group in 0 to g_STATION_GROUPS-1 loop
                    for ts in 0 to g_TIME_STAMPS-1 loop
                        for fine in 0 to g_FINE_CHANNELS-1 loop
                            
                            --stutter & stop logic
                            uniform(seed1, seed2, rand);
                            if g_PROVOKE_EMPTY then
                                dice := integer(rand*2.0);
                            else    
                                dice := integer(rand*10.0);
                            end if;    
                            while data_in_stop='1' or (g_PROVOKE_EMPTY and dice/=1) or (g_INPUT_STUTTER and not g_PROVOKE_EMPTY and dice=1) loop
                                data_in_vld(in_port) <= '0';
                                wait until rising_edge(clk);
                                uniform(seed1, seed2, rand);
                                if g_PROVOKE_EMPTY then
                                    dice := integer(rand*2.0);
                                else
                                    dice := integer(rand*10.0);
                                end if;    
                            end loop;
                            
                            --data generator
                            data_in(in_port).data.im       <= std_logic_vector(to_unsigned(in_port  + ts*8, 8));
                            data_in(in_port).data.re       <= std_logic_vector(to_unsigned(st_group + fine*2, 8));
                            data_in(in_port).meta.coarse   <= coarse;
                            data_in(in_port).meta.st_group <= st_group;
                            data_in(in_port).meta.station  <= (in_port/2)+(st_group*6/g_STATION_GROUPS);
                            data_in(in_port).meta.pol      <= (in_port rem 2);
                            data_in(in_port).meta.ts       <= ts;
                            data_in(in_port).meta.fine     <= fine;
                            data_in_vld(in_port) <= '1';
                            wait until rising_edge(clk);
                            
                        end loop;        
                    end loop;        
                end loop;
            end loop;
            
            data_in_vld(in_port) <= '0';
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            wait until rising_edge(clk);
            
            wait;
                
        end process; 
    
    end generate;
    
    
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
            wait until rising_edge(clk);    
        end process;
    end generate;
        
        
    P_CHECKER: process
        variable ts    : integer;
        variable fine  : integer;
        variable gaps  : integer := 0;
    begin
        wait until rst='0';
        wait until rising_edge(clk);
        
        report "SIMULATION STARTED." severity NOTE;
        
        while data_out_vld='0' loop
            wait until rising_edge(clk);
        end loop;
        for coarse in 0 to g_COARSE_CHANNELS-1 loop
           for st_group in 0 to g_STATION_GROUPS-1 loop
               for outer_ts in 0 to g_TIME_STAMPS/g_BLOCK_COUNT-1 loop
                   for outer_fine in 0 to g_FINE_CHANNELS/g_ATOM_SIZE-1 loop
                       for inner_ts in 0 to g_BLOCK_COUNT-1 loop
                           for inner_fine in 0 to g_ATOM_SIZE-1 loop
                               ts   := outer_ts*g_BLOCK_COUNT+inner_ts;
                               fine := outer_fine*g_ATOM_SIZE+inner_fine;     
                               if data_out_vld='0' then
                                   gaps:=gaps+1;
                               end if;                               
                               while data_out_vld='0' loop
                                   wait until rising_edge(clk);
                               end loop;
                               for out_port in 0 to pc_CTF_INPUT_NUMBER-1 loop
                                   assert data_out(out_port).meta.coarse   = coarse                                               report "Coarse Channel wrong!"  severity FAILURE;
                                   assert data_out(out_port).meta.st_group = st_group                                             report "Station Group wrong!"   severity FAILURE;
                                   assert data_out(out_port).meta.station  = (out_port/2)+(st_group*6/g_STATION_GROUPS)           report "Station wrong!"         severity FAILURE;
                                   assert data_out(out_port).meta.pol      = (out_port rem 2)                                     report "Polarity wrong!"        severity FAILURE;
                                   assert data_out(out_port).meta.ts       = ts                                                   report "Timestamp wrong!"       severity FAILURE;
                                   assert data_out(out_port).meta.fine     = fine                                                 report "Fine Channel wrong!"    severity FAILURE;
                                   assert data_out(out_port).data.im       = std_logic_vector(to_unsigned(out_port  + (ts*8), 8)) report "Imaginary value wrong!" severity FAILURE;
                                   assert data_out(out_port).data.re       = std_logic_vector(to_unsigned(st_group + fine*2, 8))  report "Real value wrong!"      severity FAILURE;
                               end loop;    
                               wait until rising_edge(clk);
                           end loop;    
                       end loop;
                   end loop;        
               end loop;        
           end loop;
       end loop;    
       
       wait for 1 us;
       
       report "SIMULATION ENDED." severity NOTE;
       assert gaps<2 or g_INPUT_STUTTER or g_PROVOKE_EMPTY or g_OUTPUT_STUTTER report "Not at 100% throughput!" severity WARNING;

       clk_en <= '0';
       
       wait;
       
           
    end process;
    
end sim;
