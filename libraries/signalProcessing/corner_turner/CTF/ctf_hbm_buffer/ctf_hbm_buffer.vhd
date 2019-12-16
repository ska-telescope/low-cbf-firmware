---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - HBM Main Buffer
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
-- The HBM Buffer has been implemented using the Floating Buffer architecture
-- 
-- A FRAME is one sub-buffer. 
-- A BLOCK is one row in a FRAME.
-- An ATOM represents a series of addresses that are read and written atomicly (always together).
-- In terms of permutation they are treated like one single address.
-- A GROUP is a number of BLOCKs that form a SUB-FRAME.
--
-- We access memory in the following order:
--        [GROUP                                         ][                                             ]
--        [BLOCK                 ][BLOCK                 ][BLOCK                 ][BLOCK                ]
--        [Atom      ][          ][          ][          ][          ][          ][          ][         ]
-- Write: 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
--
--         next Frame  next Group  next Block  next Group  next Atom   next Group  next Block  next Group
--        [Atom      ][          ][          ][          ][          ][          ][          ][         ]
-- Read:  00 01 02 03 16 17 18 19 08 09 10 11 24 25 26 27 04 05 06 07 20 21 22 23 12 13 14 15 28 29 30 31 
--
-- This are two corner turns in one.
-- The Blocks & Atoms realise the first corner turn: fine vs. time
-- The Groups realise the second corner turn: station_group vs. (fine&time)
--
-- g_BUFFER_FACTOR determines how many FRAMES are to be stored at least (minimum is 2).
-- However, the resulting used address space is always a power of 2.
--
--
--    Input data order:
--    
--    for coarse = 1:128
--      for station_group = 1:3
--        for outer_time = 1:4:(204/4)
--          for outer_fine = 1:4:(3456/4)
--            //This is the start of the HBM burst
--            for inner_time = 1:4
--              //This is the start of one 256bit word
--              for inner_fine = 1:4
--              time = outer_time * 4 + inner_time
--              fine = outer_fine * 4 + inner_fine
--              if station_group == 1: [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1]
--              if station_group == 2: [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--              if station_group == 3: [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1] 
--    
--    
--    Output data order:
--    
--    for coarse = 1:128
--      for outer_fine = 1:4:(3456/4)
--        for outer_time = 1:4:(204/4)
--          for station_group = 1:3 
--            //This is the start of the HBM burst
--            for inner_time = 1:4
--              //This is the start of one 256bit word
--              for inner_fine = 1:4
--                time = outer_time * 4 + inner_time
--                fine = outer_fine * 4 + inner_fine
--                if station_group == 1: [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1]
--                if station_group == 2: [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--                if station_group == 3: [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1] 
--
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

library work;
use work.ctf_pkg.all;

library axi4_lib;
use axi4_lib.axi4_full_pkg.all;

entity ctf_hbm_buffer is
    Generic (
        g_USE_HBM           : boolean;
        g_HBM_AXI_PORT      : natural;
        g_HBM_EMU_STUTTER   : boolean;
        g_BLOCK_SIZE        : integer range 2 to integer'HIGH := 3456;
        g_BLOCK_COUNT       : integer range 2 to integer'HIGH := 4;
        g_GROUP_COUNT       : integer range 1 to integer'HIGH := 3;
        g_ATOM_SIZE         : integer range 1 to g_BLOCK_SIZE := 1;
        g_BUFFER_FACTOR     : integer range 2 to integer'HIGH := 2;
        g_INPUT_STOP_WORDS  : integer range 1 to g_BLOCK_SIZE;
        g_OUTPUT_STOP_WORDS : integer --todo: how many are it?
    );
    Port ( 
        i_hbm_clk       : in  STD_LOGIC;
        i_hbm_rst       : in  STD_LOGIC;
        o_hbm_ready     : out std_logic;
        i_data_in       : in  t_ctf_hbm_data;
        i_data_in_vld   : in  std_logic;
        o_data_in_stop  : out std_logic;      
        o_data_in_rdy   : out std_logic;
        o_data_out      : out t_ctf_hbm_data;
        o_data_out_vld  : out std_logic;
        i_data_out_stop : in  std_logic;
        --REPORTING:
        o_debug_ctf_empty : out std_logic;
        o_debug_wa        : out std_logic_vector(31 downto 0);
        o_debug_ra        : out std_logic_vector(31 downto 0);
        --HBM INTERFACE:
        o_hbm_mosi  : out t_axi4_full_mosi;
        i_hbm_miso  : in  t_axi4_full_miso;
        i_hbm_ready : in  std_logic        
    );  
end ctf_hbm_buffer;

architecture Behavioral of ctf_hbm_buffer is

    constant g_BUFFER_FACTOR_LOG2       : natural := log2_ceil(g_BUFFER_FACTOR);
    constant g_BLOCKS_PER_GROUP         : natural := g_BLOCK_COUNT/g_GROUP_COUNT;
    constant g_GROUP_COUNT_LOG2         : natural := log2_ceil(g_GROUP_COUNT);
    constant g_BLOCK_COUNT_LOG2         : natural := log2_ceil(g_BLOCK_COUNT);
    constant g_ATOM_SIZE_LOG2           : natural := log2_ceil(g_ATOM_SIZE);
    constant g_BLOCK_SIZE_IN_ATOMS      : natural := g_BLOCK_SIZE/g_ATOM_SIZE;
    constant g_ADDR_RANGE_IN_ATOMS      : natural := g_BUFFER_FACTOR*g_BLOCK_SIZE_IN_ATOMS*g_BLOCK_COUNT; 
    constant g_ADDR_RANGE_IN_ATOMS_LOG2 : natural := log2_ceil(g_ADDR_RANGE_IN_ATOMS);
    
    constant g_ALMOST_FULL_THRESHOLD    : natural := (1+((g_INPUT_STOP_WORDS-1)/g_ATOM_SIZE))*g_ATOM_SIZE; --round up to the next multiple of g_ATOM_SIZE

    --read:
    signal atom_count   : unsigned(maxi(g_ATOM_SIZE_LOG2-1,0) downto 0);
    signal frame_ra     : unsigned(g_BUFFER_FACTOR_LOG2+1 downto 0);
    signal ra           : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal rx           : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2-1 downto 0); --counts in atoms
    signal rblock       : unsigned(g_BLOCK_COUNT_LOG2-1 downto 0);
    signal rgroup       : unsigned(g_GROUP_COUNT_LOG2-1 downto 0);

    --the following 3 signals refer to the acknowledged reads:
    signal write_limit  : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal r_ack_x      : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal new_frame    : std_logic;

    --frame_wa and wx refer to the acknowledged writes:
    signal frame_wa     : unsigned(g_BUFFER_FACTOR_LOG2+1 downto 0);
    signal wx           : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);

    --write:
    signal wa           : unsigned(g_ADDR_RANGE_IN_ATOMS_LOG2+g_ATOM_SIZE_LOG2-1 downto 0);
    signal w_ack        : std_logic;
    signal rst_p1       : std_logic;
    signal burst_count  : unsigned(maxi(g_ATOM_SIZE_LOG2-1,0) downto 0);
    
    
    signal data_out_vld : std_logic;

    signal read_ready   : std_logic;
    signal write_ready  : std_logic; 
    signal wa_ready     : std_logic; 

    signal empty        : std_logic;
    signal almost_full  : std_logic;
        
    signal read_enable     : std_logic;
    signal write_enable    : std_logic := '0';
    signal wa_write_enable : std_logic;
    signal w_last          : std_logic;
    
    signal reset_counter   : unsigned(7 downto 0) := X"00";

begin
    
    assert (G_BLOCK_SIZE rem g_ATOM_SIZE) = 0  report "g_BLOCK_SIZE has to be a multiple of g_ATOM_SIZE" severity FAILURE;
    assert 2**(g_ADDR_RANGE_IN_ATOMS_LOG2) - g_ADDR_RANGE_IN_ATOMS > g_ALMOST_FULL_THRESHOLD+2 report "g_BLOCKSIZE is very close (or equal) to a power of 2. Throughput might not be 100%." severity WARNING; 
    
    o_debug_ctf_empty <= empty;
    o_hbm_ready       <= read_ready and write_ready and wa_ready;

    P_DEBUG_OUT: process (all)
    begin
        o_debug_wa <= (others => '0');
        o_debug_wa(wa'range) <= std_logic_vector(wa);
        o_debug_ra <= (others => '0');
        o_debug_ra(ra'range) <= std_logic_vector(ra);
    end process;
    
    ----------------------------------------------------------------------------
    -- HBM memory
    ----------------------------------------------------------------------------
    E_BUFFER: entity work.ctf_hbm_buffer_ram
    generic map(
        g_USE_HBM          => g_USE_HBM,
        g_HBM_AXI_PORT     => g_HBM_AXI_PORT,
        g_HBM_EMU_STUTTER  => g_HBM_EMU_STUTTER,
        g_DEPTH            => (2**g_ADDR_RANGE_IN_ATOMS_LOG2) * (2**log2_ceil(g_ATOM_SIZE)),
        g_BURST_LEN        => g_ATOM_SIZE
    ) port map (
           i_hbm_clk       => i_hbm_clk,
           i_hbm_rst       => i_hbm_rst,
           o_read_ready    => read_ready,
           o_write_ready   => write_ready,
           o_wa_ready      => wa_ready,
           --write
           i_we            => write_enable,
           i_wa            => std_logic_vector(wa),
           i_wae           => wa_write_enable,
           o_w_ack         => w_ack,
           i_data_in       => i_data_in,
           i_last          => w_last,
           --read
           i_re            => read_enable,
           i_ra            => std_logic_vector(ra),
           o_data_out_vld  => data_out_vld,
           o_data_out      => o_data_out,
           i_data_out_stop => i_data_out_stop,
           --HBM INTERFACE:
           o_hbm_mosi      => o_hbm_mosi, 
           i_hbm_miso      => i_hbm_miso, 
           i_hbm_ready     => i_hbm_ready
    );
         
    ----------------------------------------------------------------------------
    -- Write Logic
    --
    -- The adressing is as simple as possible: keep increasing by 1.
    ----------------------------------------------------------------------------
    write_enable    <= i_data_in_vld;
    wa_write_enable <= not i_hbm_rst when reset_counter=X"FF" else '0';
    w_last          <= '1' when write_enable='1' and burst_count=g_ATOM_SIZE-1 else '0';

    P_WRITE_ADDRESS: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
                wa            <= (others => '0');
                reset_counter <= X"00";
            elsif reset_counter=X"00" and i_hbm_ready='1' then
                reset_counter <= X"01";
            elsif wa_ready='1' and reset_counter=X"FF" then
                wa          <= wa + g_ATOM_SIZE;   --this only works if wa operates in a power-of-2 range
            elsif reset_counter>=X"01" and reset_counter/=X"FF" then
                reset_counter <= reset_counter + 1;    
            end if;
        end if;
    end process;

    P_WRITE: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
                burst_count <= (others => '0');
            elsif write_enable='1' and write_ready='1' then
                burst_count <= burst_count + 1;
                if burst_count=g_ATOM_SIZE-1 then
                    burst_count <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    P_WRITE_ACK: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
                wx       <= (others => '0');
                frame_wa <= (others => '0');
            elsif w_ack='1' then
                if wx=g_BLOCK_SIZE_IN_ATOMS*g_BLOCK_COUNT-1 then
                    wx  <= (others => '0');
                    frame_wa <= frame_wa + 1;                --this only works if frame_wa operates in a power-of-2 range
                else
                    wx <= wx + 1;
                end if;                                            
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- Empty Logic
    --
    -- Reading of a Frame is only allowed if we are not writing
    -- to this Frame anymore.
    ----------------------------------------------------------------------------
    P_EMPTY: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
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
    -- Full Logic
    -- 
    -- The pointer write_limit tells us up to which address we can write.
    -- It is only incresed by the size of a Frame,
    -- once a full Frame has been read. 
    ----------------------------------------------------------------------------
    P_FULL: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            rst_p1<= i_hbm_rst;
            if i_hbm_rst='1' then
                almost_full <= '1';
            else
                if wa=(write_limit-(g_ALMOST_FULL_THRESHOLD+g_ATOM_SIZE)) or rst_p1='1' or new_frame='1' then                      --this only works if write_limit operates in a power-of-2 range
                    -- new_frame='1' indicates that read just finished a frame and the corresponding space is now free to use => we are definitely not full 
                    almost_full <= '0';
                elsif wa=(write_limit-g_ALMOST_FULL_THRESHOLD) then                                                                --this only works, if write_limit operates in a power-of-2 range
                    almost_full <= '1';
                end if;
            end if;                    
        end if;
    end process;

    o_data_in_stop <= almost_full;
    o_data_in_rdy  <= write_ready;

    ----------------------------------------------------------------------------
    -- Read Logic
    --
    -- The addressing reflects the two corner turns, using
    -- ATOMS, GROUPS, BLOCKS & FRAMES
    ----------------------------------------------------------------------------
    read_enable <= '1' when empty='0' else '0';

    P_READ: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if i_hbm_rst='1' then
                ra          <= (others=>'0');
                rx          <= (others=>'0');
                rgroup      <= (others=>'0');
                frame_ra    <= (others=>'0');
                rblock      <= (others=>'0');
                atom_count  <= (others=>'0');
            else
                if read_ready='1' then
                    if read_enable='1' then
                        rx         <= rx + 1;
                        if rgroup=g_GROUP_COUNT-1 then
                            --NEXT BLOCK IN FIRST GROUP
                            rgroup <= (others=>'0');
                            if rblock=g_BLOCKS_PER_GROUP-1 then
                                --NEXT ADDR IN FIRST BLOCK
                                rblock <= (others => '0');
                                if rx = g_BLOCK_SIZE_IN_ATOMS*g_BLOCK_COUNT-1 then
                                    --NEW FRAME
                                    ra <= ra + g_ATOM_SIZE;
                                    rx <= (others => '0');
                                    frame_ra    <= frame_ra + 1;
                                else
                                    --SAME FRAME
                                    ra <= ra - g_BLOCK_SIZE*g_BLOCKS_PER_GROUP*(g_GROUP_COUNT-1) - g_BLOCK_SIZE*(g_BLOCKS_PER_GROUP-1) + g_ATOM_SIZE;
                                end if;    
                            else
                                --NEXT BLOCK
                                rblock <= rblock + 1;
                                ra    <= ra - g_BLOCK_SIZE*g_BLOCKS_PER_GROUP*(g_GROUP_COUNT-1) + g_BLOCK_SIZE;
                            end if;
                        else
                            --NEXT GROUP
                            rgroup <= rgroup + 1;    
                            ra     <= ra + g_BLOCK_SIZE*g_BLOCKS_PER_GROUP;
                        end if;
                    end if;
                end if;    
            end if;
        end if;
    end process;

    P_READ_ACK: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            
            --defaults:
            new_frame <= '0';
                        
            if i_hbm_rst='1' then
                write_limit <= (others => '0');
                r_ack_x     <= (others => '0');
            else
                if data_out_vld='1' then
                    r_ack_x <= r_ack_x + 1;
                    if r_ack_x = g_BLOCK_SIZE*g_BLOCK_COUNT-1 then
                        r_ack_x     <= (others => '0');
                        new_frame   <= '1';
                        write_limit <= write_limit+(g_BLOCK_SIZE*g_BLOCK_COUNT);
                    end if;    
                end if;
            end if;
        end if;
    end process;


    o_data_out_vld <= data_out_vld;
    
end Behavioral;
