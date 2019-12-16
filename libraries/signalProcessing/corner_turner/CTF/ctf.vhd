---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Main File
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@autac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Implements the Fine Corner Turner
-- 
-- The basic structure of the Fine Corner Turner is as follows:
-- 
-- => INPUT_BUFFER => HBM_BUFFER => OUTPUT_BUFFER =>
--
-- Each of the 3 buffers performs a corner turn in itself.
-- The HBM_BUFFER realises the main corner turn, whilst the input and output buffer
-- perform helper corner turns that allow for longer bursts on the HBM.
--
-- INPUT DATA: 
-- for coarse = 1:128
--   for station_group = 1:3
--    for time = 1:204
--      for fine = 1:3456
--        if station_group == 1: [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1] (16 bit per input port)
--        if station_group == 2: [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--        if station_group == 3: [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1] 
--
-- OUTPUT DATA PER OUTPUT PORT:
-- for coarse = 1:128
--  for fine = output_port:4:(3456/4)
--    for time = 1:204
--      [station0, pol0], [station0, pol1], [station1, pol0], [station1, pol1] (64bit per output port)
--      [station2, pol0], [station2, pol1], [station3, pol0], [station3, pol1]
--      [station4, pol0], [station4, pol1], [station5, pol0], [station5, pol1]
--
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

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;
use axi4_lib.axi4_full_pkg.all;

entity ctf is
    generic (
        g_USE_HBM           : boolean := true;                    -- Turn off to use the Alternative HBM Simulation model, always turn on for synthesis
        g_HBM_AXI_PORT      : natural := 0;                       -- Address offset (highest 5 bits) to use by CTF
        g_HBM_EMU_STUTTER   : boolean := false;                   -- If using the Alternative HBM Simulator: emulate some stutter
        g_HBM_BURST_LENGTH  : integer := 4;                       -- 1,2 or 4 (determines burst length for HBM)
        g_COARSE_CHANNELS   : integer := 6;                       -- PISA: 128
        g_STATION_GROUPS    : integer := 12/pc_CTF_INPUT_NUMBER;  -- PISA: 3
        g_TIME_STAMPS       : integer := 204;                     -- PISA: 204
        g_FINE_CHANNELS     : integer := 3456;                    -- PISA: 3456
        g_OUTPUT_BURST_SIZE : integer := g_TIME_STAMPS            -- requirement of the correlator
    );
    Port ( 
        i_mace_clk       : in  std_logic;                        -- MACE clock
        i_mace_clk_rst   : in  std_logic;                        -- MACE rst - this is the only reset input - all others resets are generated internally
        --MACE:
        i_saxi_mosi       : IN  t_axi4_lite_mosi;                -- MACE IN    
        o_saxi_miso       : OUT t_axi4_lite_miso;                -- MACE OUT
        --ingress:          
        i_input_clk      : in  std_logic;                        -- clock for the ingress
        i_data_in        : in  std_logic_vector(63 downto 0);    -- ingress data (2 words header + data) 
        i_data_in_vld    : in  std_logic;                        -- ingress vld
        o_data_in_stop   : out std_logic;                        -- stop ingress (if this is '1', stop before the next packet starts)
        --egress:
        i_hbm_clk        : in  std_logic;                        -- HBM clock - also output clock
        o_data_out       : out t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);   --egress data -- all egress ports are in lock-step!
        o_header_out     : out t_ctf_output_header_a(pc_CTF_OUTPUT_NUMBER-1 downto 0); --egress header (changes for each data word)
        o_data_out_vld   : out std_logic;                                              --egress vld (applies to header & data) -- all egress ports are in lock-step!
        i_data_out_stop  : in  std_logic;                                              --egress stop (it's a STOP_4)
        --DEBUG SIM:
        i_data_in_record          : in  t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0) := (others => (data => (others => (others => '0')), meta => (others => (others => '0'))));
        o_hbm_buffer_data_out     : out t_ctf_hbm_data;
        o_hbm_buffer_data_out_vld : out std_logic;
        --HBM INTERFACE:
        o_hbm_clk_rst : out std_logic;                          -- reset going to the HBM core
        o_hbm_mosi    : out t_axi4_full_mosi;                   -- data going to the HBM core
        i_hbm_miso    : in  t_axi4_full_miso;                   -- data coming from the HBM core
        i_hbm_ready   : in  std_logic                           -- HBM reset finished? (=apb_complete)
    );  
end ctf;

architecture Behavioral of ctf is
    
    constant c_HBM_DATA_WIDTH          : natural := 256; 
    constant c_INPUT_TO_HBM_RATIO      : natural := c_HBM_DATA_WIDTH/pc_CTF_DATA_WIDTH/pc_CTF_INPUT_NUMBER; -- 256/16/4 = 4
    constant c_INPUT_TO_HBM_RATIO_LOG2 : natural := log2_ceil(c_INPUT_TO_HBM_RATIO);
    
    constant c_BUFFER_FACTOR           : natural := 2;
    
    signal input_clk_rst : std_logic;
    
    signal ibuffer_data_in        : t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
    signal ibuffer_data_in_vld    : std_logic;
    signal ibuffer_data_in_stop   : std_logic;
    signal ibuffer_data_out       : t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
    signal ibuffer_data_out_vld   : std_logic;

    signal ibuf_stop              : std_logic;
    signal ibuf2hbm_count         : unsigned(c_INPUT_TO_HBM_RATIO_LOG2-1 downto 0);
    
    signal hbm_buffer_data_in         : t_ctf_hbm_data;
    signal hbm_buffer_data_in_vld     : std_logic;
    signal hbm_buffer_data_in_stop    : std_logic;
    signal hbm_buffer_data_in_rdy     : std_logic;
    signal hbm_buffer_data_in_p1      : t_ctf_hbm_data;
    signal hbm_buffer_data_in_vld_p1  : std_logic;
    signal hbm_buffer_data_in_p2      : t_ctf_hbm_data;
    signal hbm_buffer_data_in_vld_p2  : std_logic;

    signal hbm_buffer_data_out        : t_ctf_hbm_data;
    signal hbm_buffer_data_out_vld    : std_logic;
    signal hbm_buffer_data_out_stop   : std_logic;

    signal output_buffer_data_in        : t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal output_buffer_data_in_vld    : std_logic_vector(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal output_buffer_data_in_stop   : std_logic_vector(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    
    signal header_in     : t_ctf_input_header;
    signal header_in_vld : std_logic;

    signal input_halt_ts : std_logic_vector(43 downto 0);
    signal input_stopped : std_logic;
    
    signal debug_ctf_empty : std_logic;
    
    signal station_addr  : std_logic_vector(09 downto 0);
    signal station_value : std_logic_vector(31 downto 0);
    
    signal hbm_mosi  : t_axi4_full_mosi;
    signal hbm_ready : std_logic;
    
    signal debug_wa : std_logic_vector(31 downto 0);
    signal debug_ra : std_logic_vector(31 downto 0);

    signal outbuf_data_out     : t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal outbuf_data_out_vld : std_logic_vector(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal empty_vector        : std_logic_vector(pc_CTF_OUTPUT_NUMBER-1 downto 0);
     
begin

    E_CONFIG: entity work.ctf_config
    port map( 
        i_mace_clk      => i_mace_clk,
        i_mace_clk_rst  => i_mace_clk_rst,
        i_input_clk     => i_input_clk,             
        o_input_clk_rst => input_clk_rst,            
        i_hbm_clk       => i_hbm_clk, 
        o_hbm_clk_rst   => o_hbm_clk_rst,
        --MACE:
        i_saxi_mosi     => i_saxi_mosi,
        o_saxi_miso     => o_saxi_miso,
        
        -- input buffer config (input_clk):
        o_input_halt_ts => input_halt_ts,            
        i_input_stopped => input_stopped,
        
        -- CTF status (hbm_clk)
        i_hbm_ready       => hbm_ready,
        i_debug_ctf_empty => debug_ctf_empty,
        i_debug_wa        => debug_wa,
        i_debug_ra        => debug_ra,
        
        --station-table (hbm_clk):
        i_station_addr    => station_addr, 
        o_station_value   => station_value
    );            
    
   
    
    
    --------------------------------------------
    -- INPUT DECODER
    --------------------------------------------
    E_INPUT_DECODER: entity work.ctf_input_decoder
    generic map(
        g_INPUT_PACKET_SIZE => g_FINE_CHANNELS
    ) port map ( 
        i_input_clk       => i_input_clk,
        i_input_clk_rst   => input_clk_rst,
        i_input_halt_ts   => input_halt_ts,
        o_input_stopped   => input_stopped,
        i_hbm_clk         => i_hbm_clk,
        i_hbm_clk_rst     => o_hbm_clk_rst,
        i_data_in_record  => i_data_in_record,
        i_data_in_slv     => i_data_in,
        i_data_in_vld     => i_data_in_vld,
        o_data_in_stop    => o_data_in_stop,
        o_data_out        => ibuffer_data_in,
        o_data_out_vld    => ibuffer_data_in_vld,
        i_data_out_stop   => ibuffer_data_in_stop,
        o_header_out      => header_in,
        o_header_out_vld  => header_in_vld        
    );
    

    --------------------------------------------
    -- INPUT BUFFER
    --------------------------------------------
    E_INPUT_BUFFER: entity work.ctf_input_buffer
    generic map (
        g_BLOCK_SIZE        => g_FINE_CHANNELS,
        g_BLOCK_COUNT       => g_HBM_BURST_LENGTH,
        g_ATOM_SIZE         => pc_CTF_OUTPUT_NUMBER,
        g_INPUT_STOP_WORDS  => 1,
        g_OUTPUT_STOP_WORDS => 4
    ) port map (
       i_clk           => i_hbm_clk,
       i_rst           => o_hbm_clk_rst,
       i_data_in       => ibuffer_data_in,
       i_data_in_vld   => ibuffer_data_in_vld,
       o_data_in_stop  => ibuffer_data_in_stop,  
       o_data_out      => ibuffer_data_out,
       o_data_out_vld  => ibuffer_data_out_vld,
       i_data_out_stop => ibuf_stop
    );  

    ibuf_stop <= hbm_buffer_data_in_stop or not hbm_buffer_data_in_rdy;
    
    --------------------------------------------
    -- COMBINE
    --------------------------------------------
    -- 4x16bit input => 256bit HBM input
    -- realised via a shift register 
    --------------------------------------------
    assert (c_HBM_DATA_WIDTH/pc_CTF_DATA_WIDTH) rem pc_CTF_INPUT_NUMBER = 0 report "The logic below is too simple for the given pc_CTF_INPUT_NUMBER!" severity FAILURE;   
    P_BUILD_HBM_DATA: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            
            --defaults
            hbm_buffer_data_in_vld     <= '0';
            
            if o_hbm_clk_rst='1' then
                ibuf2hbm_count<=(others =>'0');
            else
                if ibuffer_data_out_vld='1' then
                    
                    ibuf2hbm_count<=ibuf2hbm_count+1;
                    
                    --shift left:
                    hbm_buffer_data_in.data(c_HBM_DATA_WIDTH-1 downto (pc_CTF_INPUT_NUMBER*pc_CTF_DATA_WIDTH)) <= hbm_buffer_data_in.data(c_HBM_DATA_WIDTH-1-(pc_CTF_INPUT_NUMBER*pc_CTF_DATA_WIDTH) downto 0);
                    
                    --fill rightmost part:
                    for buf in 0 to pc_CTF_INPUT_NUMBER-1 loop
                        hbm_buffer_data_in.data((buf+1)*pc_CTF_DATA_WIDTH-1 downto buf*pc_CTF_DATA_WIDTH) <= ibuffer_data_out(pc_CTF_INPUT_NUMBER-1-buf).data.re & ibuffer_data_out(pc_CTF_INPUT_NUMBER-1-buf).data.im;
                        -- synthesis translate_off
                        hbm_buffer_data_in.meta(c_HBM_DATA_WIDTH/pc_CTF_DATA_WIDTH-1-(buf+to_integer(ibuf2hbm_count)*c_INPUT_TO_HBM_RATIO)) <= ibuffer_data_out(buf).meta;
                        -- synthesis translate_on
                    end loop;
                    
                    --write out:
                    if ibuf2hbm_count=c_INPUT_TO_HBM_RATIO-1 then
                        ibuf2hbm_count<=(others =>'0');
                        hbm_buffer_data_in_vld <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    --The following logic is based on the fact that it takes 4 cycles to assemble one HBM word.                     
    P_READY_TO_STOP4_BUFFER: process (i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
            if o_hbm_clk_rst='1' then
                hbm_buffer_data_in_vld_p1 <= '0';
                hbm_buffer_data_in_vld_p2 <= '0';
            elsif hbm_buffer_data_in_vld='1' and hbm_buffer_data_in_rdy='0' then 
                hbm_buffer_data_in_p1     <= hbm_buffer_data_in;
                hbm_buffer_data_in_vld_p1 <= hbm_buffer_data_in_vld;
                assert hbm_buffer_data_in_vld_p1='0' report "STOP BUFFER OVERFLOW!" severity FAILURE;
            elsif hbm_buffer_data_in_vld_p1='1' and hbm_buffer_data_in_rdy='1' then
                hbm_buffer_data_in_p2     <= hbm_buffer_data_in_p1;
                hbm_buffer_data_in_vld_p2 <= hbm_buffer_data_in_vld_p1;
                hbm_buffer_data_in_p1     <= hbm_buffer_data_in;
                hbm_buffer_data_in_vld_p1 <= hbm_buffer_data_in_vld;
            elsif hbm_buffer_data_in_rdy='1' then
                hbm_buffer_data_in_p2     <= hbm_buffer_data_in;
                hbm_buffer_data_in_vld_p2 <= hbm_buffer_data_in_vld;
            end if;                    
        end if;
    end process;


    --------------------------------------------
    -- HBM Buffer
    --------------------------------------------
    assert (g_TIME_STAMPS rem g_HBM_BURST_LENGTH) = 0 report "g_TIME_STAMPS must be a multiple of g_HBM_BURST_LENGTH!" severity FAILURE;   
    assert (g_FINE_CHANNELS rem pc_CTF_OUTPUT_NUMBER) = 0 report "g_FINE_CHANNELS must be a multiple of pc_CTF_OUTPUT_NUMBER!" severity FAILURE;   
    E_HBM_BUFFER: entity work.ctf_hbm_buffer
    generic map (
        g_USE_HBM           => g_USE_HBM,
        g_HBM_AXI_PORT      => g_HBM_AXI_PORT,
        g_HBM_EMU_STUTTER   => g_HBM_EMU_STUTTER,
        g_BLOCK_SIZE        => g_FINE_CHANNELS/c_INPUT_TO_HBM_RATIO*g_HBM_BURST_LENGTH,   --The HBM BURST LENGTH refers to times, not fine channels 
        g_BLOCK_COUNT       => g_TIME_STAMPS/g_HBM_BURST_LENGTH*g_STATION_GROUPS,       
        g_GROUP_COUNT       => g_STATION_GROUPS,
        g_ATOM_SIZE         => g_HBM_BURST_LENGTH,
        g_BUFFER_FACTOR     => c_BUFFER_FACTOR,
        g_INPUT_STOP_WORDS  => 8,
        g_OUTPUT_STOP_WORDS => 8
    ) port map (
        i_hbm_clk         => i_hbm_clk,
        i_hbm_rst         => o_hbm_clk_rst,
        o_hbm_ready       => hbm_ready,
        i_data_in         => hbm_buffer_data_in_p2,
        i_data_in_vld     => hbm_buffer_data_in_vld_p2,
        o_data_in_stop    => hbm_buffer_data_in_stop,
        o_data_in_rdy     => hbm_buffer_data_in_rdy,
        o_data_out        => hbm_buffer_data_out,
        o_data_out_vld    => hbm_buffer_data_out_vld,
        i_data_out_stop   => hbm_buffer_data_out_stop,
        o_debug_ctf_empty => debug_ctf_empty,
        o_debug_wa        => debug_wa,
        o_debug_ra        => debug_ra,
        o_hbm_mosi        => o_hbm_mosi, 
        i_hbm_miso        => i_hbm_miso, 
        i_hbm_ready       => i_hbm_ready       
    );  
    
    --FOR SIM:
    o_hbm_buffer_data_out     <= hbm_buffer_data_out;
    o_hbm_buffer_data_out_vld <= hbm_buffer_data_out_vld;
    


    --------------------------------------------
    -- Output Buffer
    --------------------------------------------
    hbm_buffer_data_out_stop  <= '0' when output_buffer_data_in_stop=(output_buffer_data_in_stop'range=>'0') else '1';
       
    assert pc_CTF_OUTPUT_FACTOR = c_INPUT_TO_HBM_RATIO report "The logic below is too simple for the given c_INPUT_TO_HBM_RATIO and pc_CTF_OUTPUT_FACTOR" severity FAILURE;

    GEN_OUTPUT_BUFFER: for out_port in 0 to pc_CTF_OUTPUT_NUMBER-1 generate
    begin
        
        --2 stations + 2 polarisations in parallel
        GEN_SEGMENT: for station in 0 to pc_CTF_OUTPUT_FACTOR-1 generate
        begin
            output_buffer_data_in(out_port)(pc_CTF_OUTPUT_FACTOR-1-station).data.re <= 
                             hbm_buffer_data_out.data(pc_CTF_DATA_WIDTH-1  +((pc_CTF_OUTPUT_NUMBER-1-out_port)*pc_CTF_OUTPUT_FACTOR+station)*pc_CTF_DATA_WIDTH
                      downto pc_CTF_DATA_WIDTH/2+((pc_CTF_OUTPUT_NUMBER-1-out_port)*pc_CTF_OUTPUT_FACTOR+station)*pc_CTF_DATA_WIDTH);
                      
            output_buffer_data_in(out_port)(pc_CTF_OUTPUT_FACTOR-1-station).data.im <= 
                             hbm_buffer_data_out.data(pc_CTF_DATA_WIDTH/2-1+((pc_CTF_OUTPUT_NUMBER-1-out_port)*pc_CTF_OUTPUT_FACTOR+station)*pc_CTF_DATA_WIDTH
                      downto 0                  +((pc_CTF_OUTPUT_NUMBER-1-out_port)*pc_CTF_OUTPUT_FACTOR+station)*pc_CTF_DATA_WIDTH);
            
            --synthesis translate_off
            output_buffer_data_in(pc_CTF_OUTPUT_NUMBER-1-out_port)(pc_CTF_OUTPUT_FACTOR-1-station).meta <= hbm_buffer_data_out.meta(out_port*pc_CTF_OUTPUT_FACTOR+station);
            --synthesis translate_on
        end generate;
        
        output_buffer_data_in_vld(out_port) <= hbm_buffer_data_out_vld;
        
        --Optimisations:
        --When connecting to Correlator: replace buffer by simple FIFO, create address and leave final corner turn to Correlator Input Buffer
        E_OUTPUT_BUFFER: entity work.ctf_output_buffer
        generic map (
            g_BLOCK_SIZE        => g_HBM_BURST_LENGTH,
            g_BLOCK_COUNT       => g_STATION_GROUPS,
            g_ATOM_SIZE         => 1,
            g_BUFFER_FACTOR     => 24, --BRAM depth @ 64bit input: 512 -- 512/(6*3) = 28
            g_INPUT_STOP_WORDS  => 8,
            g_OUTPUT_BURST_SIZE => g_OUTPUT_BURST_SIZE
        ) port map ( 
               i_clk           => i_hbm_clk,
               i_rst           => o_hbm_clk_rst,
               i_data_in       => output_buffer_data_in(out_port),
               i_data_in_vld   => output_buffer_data_in_vld(out_port),
               o_data_in_stop  => output_buffer_data_in_stop(out_port),  
               o_data_out      => outbuf_data_out(out_port),
               o_data_out_vld  => outbuf_data_out_vld(out_port),
               i_data_out_stop => i_data_out_stop,
               o_empty         => empty_vector(out_port),
               i_empty         => OR(empty_vector)
        );  
        
    end generate;
    
    E_HEADER_BUFFER: entity work.ctf_header_buffer
    generic map(
        g_FINE_CHANNELS  => g_FINE_CHANNELS,
        g_TIME_STAMPS    => g_TIME_STAMPS,
        g_BUFFER_FACTOR  => c_BUFFER_FACTOR,
        g_STATION_GROUPS => g_STATION_GROUPS
    ) port map ( 
        i_clk            => i_hbm_clk,
        i_rst            => o_hbm_clk_rst,
        i_data_in        => outbuf_data_out,
        i_data_in_vld    => outbuf_data_out_vld(0),  --all 4 are in lock-step!
        i_header_in      => header_in,
        i_header_in_vld  => header_in_vld,        
        o_station_addr   => station_addr,
        i_station_value  => station_value, 
        o_header_out     => o_header_out,
        o_data_out       => o_data_out,
        o_data_out_vld   => o_data_out_vld
    );


end Behavioral;