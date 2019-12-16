---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Input Buffer
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@autac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- The basic structure of the Fine Corner Turner is as follows:
-- => INPUT_BUFFER => HBM_BUFFER => OUTPUT_BUFFER =>
--
-- Each of the 3 buffers performs a corner turn in itself.
-- The HBM_BUFFER realises the main corner turn, whilst the input and output buffer
-- perform helper corner turns that allow for longer bursts on the HBM.
--
-- The Input Buffer has been implemented using the Recursive Permutation architecture
-- 
-- A  BLOCK is one row in a FRAME.
-- An ATOM represents a series of addresses that are read and written atomicly (always together).
-- In terms of permutation they are treated like one single address.
--
-- Input data order:
--
-- for coarse = 1:128
--   for station_group = 1:3
--     for time = 1:204
--       for fine = 1:3456
--         if station_group == 1: [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1]
--         if station_group == 2: [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--         if station_group == 3: [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1] 
--
-- Output data order:
-- 
-- for coarse = 1:128
--   for station_group = 1:3
--     for outer_time = 1:4:(204/4)
--       for outer_fine = 1:4:(3456/4)
--         for inner_time = 1:4
--           for inner_fine = 1:4
--           time = outer_time * 4 + inner_time
--           fine = outer_fine * 4 + inner_fine
--           if station_group == 1: [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1]
--           if station_group == 2: [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--           if station_group == 3: [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1]  
---------------------------------------------------------------------------------------------------
-- NOTE:
-- All input ports are assumed to be valid at the same time, hence a single bit i_data_in_vld.
--
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library work;
use work.ctf_pkg.all;

entity ctf_input_buffer is
    Generic (
        g_BLOCK_SIZE        : integer range 8 to integer'HIGH := 3456;
        g_BLOCK_COUNT       : integer range 2 to integer'HIGH := 4;
        g_ATOM_SIZE         : integer range 1 to g_BLOCK_SIZE := 1; --has to be a power of 2
        g_INPUT_STOP_WORDS  : integer;
        g_OUTPUT_STOP_WORDS : integer range 1 to integer'HIGH
    );
    Port ( i_clk           : in  STD_LOGIC;
           i_rst           : in  STD_LOGIC;
           i_data_in       : in  t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
           i_data_in_vld   : in  std_logic;
           o_data_in_stop  : out std_logic;  
           o_data_out      : out t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
           o_data_out_vld  : out std_logic;
           i_data_out_stop : in  std_logic
         );  
end ctf_input_buffer;

architecture Behavioral of ctf_input_buffer is

    constant g_RAM_OUT_LATENCY : natural := 4;
    -- A latency of 2 uses internal output registers,
    -- but this is not enough to allow 450MHz when URAMs are being cascaded.
    -- In that case we also need the cascade out registers OREG_CAS as well,
    -- which are fully instantiated if the latency is 4.

    constant g_ATOM_SIZE_LOG2           : natural := log2_ceil(g_ATOM_SIZE);
    constant g_BLOCK_SIZE_IN_ATOMS      : natural := g_BLOCK_SIZE/g_ATOM_SIZE;
    constant g_ADDR_RANGE_IN_ATOMS      : natural := g_BLOCK_SIZE_IN_ATOMS*g_BLOCK_COUNT;
    constant g_ADDR_RANGE_IN_ATOMS_LOG2 : natural := log2_ceil(g_ADDR_RANGE_IN_ATOMS);
    
    signal r_x          : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2-1 downto 0); -- x represents the position in the permutation vector (r_addr is the r_x'th address in the FRAME)
    signal r_atom_count : unsigned(maxi(g_ATOM_SIZE_LOG2-1,0) downto 0);       
    signal r_addr       : std_logic_vector(g_ADDR_RANGE_IN_ATOMS_LOG2-1 downto 0);
    
    signal data_out_vld : std_logic;
    signal data_out     : t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
    
    signal empty         : std_logic;
    signal full          : std_logic;
    signal read_enable   : std_logic;
    
    signal w_x             : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2-1 downto 0); -- x represents the position in the permutation vector (w_addr is the w_x'th address in the FRAME) 
    signal w_addr          : std_logic_vector(g_ADDR_RANGE_IN_ATOMS_LOG2-1   downto 0);
    signal w_atom_count    : unsigned(maxi(g_ATOM_SIZE_LOG2-1,0) downto 0);
    signal write_enable    : std_logic;
    signal wa, ra          : std_logic_vector(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal read_out_delay  : std_logic_vector(g_RAM_OUT_LATENCY-1 downto 0);

begin
    
    assert (G_BLOCK_SIZE rem g_ATOM_SIZE) = 0     report "g_BLOCK_SIZE has to be a multiple of g_ATOM_SIZE"           severity FAILURE;
    assert g_OUTPUT_STOP_WORDS>=g_RAM_OUT_LATENCY report "g_OUTPUT_STOP_WORDS too small for used BRAM implementation" severity FAILURE;

    write_enable <= i_data_in_vld;  
    
    E_BUFFER: entity work.ctf_input_buffer_ram
    generic map(
        g_DEPTH       => g_ADDR_RANGE_IN_ATOMS*g_ATOM_SIZE,
        g_LATENCY     => g_RAM_OUT_LATENCY
    ) port map (
           i_clk      => i_clk,
           i_rst      => i_rst,
           i_we       => write_enable,
           i_wa       => wa,
           i_data_in  => i_data_in,
           i_ra       => ra,
           o_data_out => data_out
    );
             
    GEN_ADDR: if g_ATOM_SIZE=1 generate
        wa <= std_logic_vector(w_addr(g_ADDR_RANGE_IN_ATOMS_LOG2-1 downto 0));
        ra <= r_addr;
    else generate
        assert (2**g_ATOM_SIZE_LOG2) = g_ATOM_SIZE report "g_ATOM_SIZE has to be a power of 2" severity FAILURE;
        wa <= w_addr & std_logic_vector(w_atom_count);
        ra <= r_addr & std_logic_vector(r_atom_count);
    end generate;

    E_W_ADDR: entity work.address_permuter
    generic map(
        g_ADDR_RANGE      => g_ADDR_RANGE_IN_ATOMS,
        g_BLOCK_SIZE      => g_BLOCK_SIZE_IN_ATOMS,
        g_ATOM_SIZE       => g_ATOM_SIZE,
        g_INITIAL_INC     => 1
    ) port map (
        i_clk        => i_clk,
        i_rst        => i_rst,
        i_next       => write_enable,
        o_addr       => w_addr,
        o_x          => w_x,
        o_atom_count => w_atom_count
    );
            
    E_FULL_EMPTY: entity work.buffer_level_indicator
        generic map (
            g_ADDR_RANGE       => g_ADDR_RANGE_IN_ATOMS,
            g_ATOM_SIZE        => g_ATOM_SIZE,
            g_INPUT_STOP_WORDS => g_INPUT_STOP_WORDS
        ) port map (
               i_clk          => i_clk,
               i_rst          => i_rst,
               i_write_enable => write_enable,
               i_w_x          => w_x,
               i_w_atom_count => w_atom_count,
               i_read_enable  => read_enable,
               i_r_x          => r_x,
               i_r_atom_count => r_atom_count,
               o_empty        => empty,
               o_full         => full
             );
    
    o_data_in_stop <= full;
    
    E_R_ADDR: entity work.address_permuter
    generic map(
        g_ADDR_RANGE      => g_ADDR_RANGE_IN_ATOMS,
        g_BLOCK_SIZE      => g_BLOCK_SIZE_IN_ATOMS,
        g_ATOM_SIZE       => g_ATOM_SIZE,
        g_INITIAL_INC     => g_BLOCK_SIZE_IN_ATOMS
    ) port map (
        i_clk        => i_clk,
        i_rst        => i_rst,
        i_next       => read_enable,
        o_addr       => r_addr,
        o_x          => r_x,
        o_atom_count => r_atom_count
    );

    read_enable <= '1' when empty='0' and i_data_out_stop='0' else '0';

    P_DATA_OUT_VLD: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                read_out_delay <= (others => '0');
            else
                read_out_delay(0) <= read_enable;
                for idx in g_RAM_OUT_LATENCY-2 downto 0 loop
                    read_out_delay(idx+1) <= read_out_delay(idx);
                end loop;
            end if;
        end if;
    end process;

    data_out_vld  <= read_out_delay(g_RAM_OUT_LATENCY-1);
    
    o_data_out     <= data_out;
    o_data_out_vld <= data_out_vld;
        
end Behavioral;
