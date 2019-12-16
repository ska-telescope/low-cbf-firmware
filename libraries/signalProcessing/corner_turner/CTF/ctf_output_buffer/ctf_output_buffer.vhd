---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Output Buffer
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
-- The output Buffer has been implemented using the Floating Buffer architecture
-- 
-- A  BLOCK is one row in a FRAME.
-- An ATOM represents a series of addresses that are read and written atomicly (always together).
-- In terms of permutation they are treated like one single address.
-- g_BUFFER_FACTOR determines how many FRAMES are to be stored at least (minimum is 2).
-- However, the resulting used address space is always a power of 2.
-- 
--
--    Input data order:
--    
--    for coarse = 1:128
--      for fine = 1:4:(3456/4)
--        for outer_time = 1:4:(204/4)
--          for station_group = 1:3 
--            for inner_time = 1:4
--              time = outer_time * 4 + inner_time
--              if station_group == 1: [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1]
--              if station_group == 2: [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--              if station_group == 3: [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1] 
--    
--    
--    Output data order:
--    
--    for coarse = 1:128
--      for fine = 1:4:(3456/4)
--        for time = 1:204
--          [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1]
--          [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--          [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1] 
--    
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library work;
use work.ctf_pkg.all;

entity ctf_output_buffer is
    Generic (
        g_BLOCK_SIZE        : integer range 1 to integer'HIGH := 3456;
        g_BLOCK_COUNT       : integer range 1 to integer'HIGH := 4;
        g_ATOM_SIZE         : integer range 1 to g_BLOCK_SIZE := 1; --has to be a power of 2
        g_BUFFER_FACTOR     : integer range 2 to integer'HIGH := 2;
        g_INPUT_STOP_WORDS  : integer;
        g_OUTPUT_BURST_SIZE : integer
    );
    Port (
        i_clk           : in  STD_LOGIC;
        i_rst           : in  STD_LOGIC;
        i_data_in       : in  t_ctf_output_data;
        i_data_in_vld   : in  std_logic;
        o_data_in_stop  : out std_logic;  
        o_data_out      : out t_ctf_output_data;
        o_data_out_vld  : out std_logic;
        i_data_out_stop : in  std_logic;
        o_empty         : out std_logic;
        i_empty         : in  std_logic
    );  
end ctf_output_buffer;

architecture Behavioral of ctf_output_buffer is

    constant g_BUFFER_FACTOR_LOG2       : natural := log2_ceil(g_BUFFER_FACTOR);
    constant g_BLOCK_COUNT_LOG2         : natural := log2_ceil(g_BLOCK_COUNT);
    constant g_ATOM_SIZE_LOG2           : natural := log2_ceil(g_ATOM_SIZE);
    constant g_BLOCK_SIZE_IN_ATOMS      : natural := g_BLOCK_SIZE/g_ATOM_SIZE;
    constant g_ADDR_RANGE_IN_ATOMS      : natural := g_BUFFER_FACTOR*g_BLOCK_SIZE_IN_ATOMS*g_BLOCK_COUNT;         
    constant g_ADDR_RANGE_IN_ATOMS_LOG2 : natural := log2_ceil(g_ADDR_RANGE_IN_ATOMS);
    
    signal atom_count   : unsigned(maxi(g_ATOM_SIZE_LOG2-1,0) downto 0);
            
    signal frame_ra     : unsigned(g_BUFFER_FACTOR_LOG2+1 downto 0);   
    signal write_limit  : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal ra           : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal rx           : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2-1 downto 0); --counts in atoms
    signal rblock       : unsigned(g_BLOCK_COUNT_LOG2-1 downto 0);
    
    signal new_frame    : std_logic;
    signal empty        : std_logic;
    signal almost_full  : std_logic;
    
    
    signal read_enable  : std_logic;
    signal write_enable : std_logic;
    
    signal frame_wa     : unsigned(g_BUFFER_FACTOR_LOG2+1 downto 0);
    signal wx           : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal wa           : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal diff         : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal rst_p1       : std_logic;

    signal output_count : unsigned(log2_ceil(g_OUTPUT_BURST_SIZE) downto 0);

begin

    assert (G_BLOCK_SIZE rem g_ATOM_SIZE) = 0  report "g_BLOCK_SIZE has to be a multiple of g_ATOM_SIZE" severity FAILURE;
    assert 2**(g_ADDR_RANGE_IN_ATOMS_LOG2) - g_ADDR_RANGE_IN_ATOMS > g_INPUT_STOP_WORDS+2 report "g_BLOCKSIZE is very close (or equal) to a power of 2. Throughput might not be 100%." severity WARNING; 
    
    ----------------------------------------------------------------------------
    -- actual BRAM memory
    ----------------------------------------------------------------------------
    E_BUFFER: entity work.ctf_output_buffer_ram
    generic map(
        g_DEPTH       => (2**g_ADDR_RANGE_IN_ATOMS_LOG2)*g_ATOM_SIZE
    ) port map (
           i_clk      => i_clk,
           i_rst      => i_rst,
           i_we       => write_enable,
           i_wa       => std_logic_vector(wa),
           i_data_in  => i_data_in,
           i_ra       => std_logic_vector(ra),
           o_data_out => o_data_out
    );

         
    ----------------------------------------------------------------------------
    -- WRITE LOGIC
    ----------------------------------------------------------------------------
    write_enable <= i_data_in_vld;  

    P_WRITE: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                wa       <= (others => '0');
                wx       <= (others => '0');
                frame_wa <= (others => '0');
            elsif i_data_in_vld='1' then
                wa <= wa + 1;                                --this only works if wa operates in a power-of-2 range
                if wx=g_BLOCK_SIZE*g_BLOCK_COUNT-1 then
                    wx       <= (others => '0');
                    frame_wa <= frame_wa + 1;                --this only works if block_wa operates in a power-of-2 range
                else
                    wx <= wx + 1;
                end if;                                            
            end if;
        end if;
    end process;
    

    ----------------------------------------------------------------------------
    -- EMPTY LOGIC
    ----------------------------------------------------------------------------
    P_EMPTY: process (i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                empty <= '1';
            else
                if (frame_wa=frame_ra) or (frame_wa-1=frame_ra and wx=0 and rx=g_BLOCK_SIZE_IN_ATOMS*g_BLOCK_COUNT-1 and read_enable='1') then  --this only works if block_ra operates in a power-of-2 range
                    empty<='1';
                else
                    empty<='0';
                end if;    
            end if;                    
        end if;
    end process;
    

    ----------------------------------------------------------------------------
    -- FULL LOGIC
    ----------------------------------------------------------------------------
    P_FULL: process (i_clk)
    begin
        if rising_edge(i_clk) then
            rst_p1<= i_rst;
            if i_rst='1' then
                almost_full <= '1';
            else
                --this more complex almost full logic allows for g_INPUT_STOP_WORDS to exceed FRAME size
                diff <= write_limit - wa;
                if diff /= 0 and diff < g_INPUT_STOP_WORDS+2 then
                    almost_full<='1';
                else    
                    almost_full<='0';
                end if;           
            end if;                    
        end if;
    end process;
    
    o_data_in_stop <= almost_full;
    o_empty        <= empty;

    ----------------------------------------------------------------------------
    -- READ LOGIC
    ----------------------------------------------------------------------------
    read_enable  <= '1' when i_empty='0' and not (i_data_out_stop='1' and output_count=g_OUTPUT_BURST_SIZE) else '0';
    
    P_READ: process (i_clk)
    begin
        if rising_edge(i_clk) then
            
            --defaults:
            o_data_out_vld <= '0';
            new_frame      <= '0';
                    
            if i_rst='1' then
                ra           <= (others=>'0');
                rx           <= (others=>'0');
                frame_ra     <= (others=>'0');
                rblock       <= (others=>'0');
                write_limit  <= (others=>'0');
                atom_count   <= (others=>'0');
                output_count <= (others=>'0');
            else
                if read_enable='1' then
                    if output_count=g_OUTPUT_BURST_SIZE then
                        output_count <= (0=>'1', others=>'0');
                    else
                        output_count <= output_count + 1;
                    end if;    
                    o_data_out_vld <= '1';
                    if atom_count=g_ATOM_SIZE-1 then
                        --NEXT ATOM
                        atom_count <= (others => '0');
                        rx         <= rx + 1;
                        if rblock=g_BLOCK_COUNT-1 then
                            --NEXT ADDR IN FIRST BLOCK
                            rblock <= (others => '0');
                            if rx = g_BLOCK_SIZE_IN_ATOMS*g_BLOCK_COUNT-1 then
                                --NEW FRAME
                                ra <= ra + 1;
                                rx <= (others => '0');
                                new_frame   <= '1';
                                frame_ra    <= frame_ra + 1;
                                write_limit <= write_limit+(g_BLOCK_SIZE*g_BLOCK_COUNT);
                            else
                                --SAME FRAME
                                ra <= ra - (g_ATOM_SIZE-1) - g_BLOCK_SIZE*(g_BLOCK_COUNT-1) + g_ATOM_SIZE;
                            end if;    
                        else
                            --NEXT BLOCK
                            rblock <= rblock + 1;
                            ra    <= ra - (g_ATOM_SIZE-1) + g_BLOCK_SIZE;
                        end if;
                    else
                        --IN ATOM
                        atom_count <= atom_count + 1;
                        ra         <= ra + 1;    
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
