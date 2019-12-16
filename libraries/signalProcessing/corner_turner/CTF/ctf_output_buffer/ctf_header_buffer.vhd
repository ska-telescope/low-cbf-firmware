---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Header buffer
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This module takes the input header coming from the Input Decoder, stores it,
-- performs a corner turn on the header data and outputs it in parallel to the data.
-- Every single data item has its own header information.
-- 
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.ctf_pkg.all;

Library xpm;
use xpm.vcomponents.all;

entity ctf_header_buffer is
    Generic (
        g_FINE_CHANNELS  : natural := 3456;
        g_TIME_STAMPS    : natural := 204;
        g_BUFFER_FACTOR  : natural := 2;
        g_STATION_GROUPS : natural := 3
    );
    Port ( 
        i_clk             : in  std_logic;
        i_rst             : in  std_logic;
        i_data_in         : in  t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
        i_data_in_vld     : in  std_logic;
        i_header_in       : in  t_ctf_input_header;
        i_header_in_vld   : in  std_logic;
        o_station_addr    : out std_logic_vector(09 downto 0);
        i_station_value   : in  std_logic_vector(31 downto 0);                
        o_header_out      : out t_ctf_output_header_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
        o_data_out        : out t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
        o_data_out_vld    : out std_logic                                                 --refers to both, data & header output
    );
end ctf_header_buffer;

architecture Behavioral of ctf_header_buffer is

    constant g_BUFFER_DEPTH : natural := (2**log2_ceil(2 * g_BUFFER_FACTOR * g_STATION_GROUPS * g_TIME_STAMPS)); --times two to guarantee that an overflow does not happen
    constant g_BUFFER_WIDTH : natural := 44 + 9; --timestamp + virtual channel
    
    signal wa : unsigned(log2_ceil(g_BUFFER_DEPTH)-1 downto 0);
    signal ra : unsigned(log2_ceil(g_BUFFER_DEPTH)-1 downto 0);
    
    signal in_frame       : unsigned(log2_ceil(g_BUFFER_DEPTH)-1 downto 0);
    signal ra_frame_start : unsigned(log2_ceil(g_BUFFER_DEPTH)-1 downto 0);
    
    signal fine_channel     : unsigned(log2_ceil(g_FINE_CHANNELS)-1 downto 0);
    signal fine_channel_p1  : unsigned(log2_ceil(g_FINE_CHANNELS)-1 downto 0);
    signal fine_channel_p2  : unsigned(log2_ceil(g_FINE_CHANNELS)-1 downto 0);
    
    signal station_group    : unsigned(log2_ceil(g_STATION_GROUPS)-1 downto 0);
    signal station_group_p1 : unsigned(log2_ceil(g_STATION_GROUPS)-1 downto 0);
    
    signal header_in_slv  : std_logic_vector(pc_CTF_HEADER_WIDTH-1 downto 0);
    signal header_out_slv : std_logic_vector(g_BUFFER_WIDTH-1 downto 0);
    constant dummy_slv    : std_logic_vector(pc_CTF_HEADER_WIDTH-1 downto g_BUFFER_WIDTH) := (others => '0');
    
    signal data_p1     : t_ctf_output_data_a(pc_CTF_OUTPUT_NUMBER-1 downto 0);
    signal data_vld_p1 : std_logic;
    
begin

    P_INPUT: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_rst='1' then
                wa <= (others => '0');                
            elsif i_header_in_vld='1' then
                wa <= wa + 1;
            end if;
        end if;
    end process;

    header_in_slv <= header_to_slv(i_header_in);

    BRAM : xpm_memory_sdpram
    generic map (
        ADDR_WIDTH_A => log2_ceil(g_BUFFER_DEPTH),     
        ADDR_WIDTH_B => log2_ceil(g_BUFFER_DEPTH),     
        AUTO_SLEEP_TIME => 0,            
        BYTE_WRITE_WIDTH_A => g_BUFFER_WIDTH,   
        CLOCKING_MODE => "common_clock", 
        ECC_MODE => "no_ecc",            
        MEMORY_INIT_FILE => "none",      
        MEMORY_INIT_PARAM => "0",        
        MEMORY_OPTIMIZATION => "true",   
        MEMORY_PRIMITIVE => "ultra",      
        MEMORY_SIZE => g_BUFFER_DEPTH*g_BUFFER_WIDTH,   
        MESSAGE_CONTROL => 0,           
        READ_DATA_WIDTH_B => g_BUFFER_WIDTH,   
        READ_LATENCY_B => 2,            
        READ_RESET_VALUE_B => "0",      
        USE_EMBEDDED_CONSTRAINT => 0,   
        USE_MEM_INIT => 0,              
        WAKEUP_TIME => "disable_sleep", 
        WRITE_DATA_WIDTH_A => g_BUFFER_WIDTH,  
        WRITE_MODE_B => "read_first"     
    )
    port map (
        clka  => i_clk,           
        clkb  => i_clk,           
        rstb  => i_rst,           
        addra => std_logic_vector(wa),            
        wea   => (others=>i_header_in_vld),   
        dina  => header_in_slv(g_BUFFER_WIDTH-1 downto 0), --ts & virtual channel         
        addrb => std_logic_vector(ra),            
        doutb => header_out_slv,        
        ena   => '1',             
        enb   => '1',             
        sleep => '0',
        injectsbiterra => '0',
        injectdbiterra => '0',
        regceb         => '1'
    );

    GEN_PORTS: for op in 0 to pc_CTF_OUTPUT_NUMBER-1 generate
    begin
        P_HEADER_OUT: process(all)
            variable tmp : t_ctf_input_header;
        begin
            tmp := slv_to_header(dummy_slv & header_out_slv);
            o_header_out(op).timestamp       <= tmp.timestamp;
            o_header_out(op).virtual_channel <= tmp.virtual_channel;
            o_header_out(op).station_id_1    <= i_station_value(8 downto 0);
            o_header_out(op).station_id_2    <= i_station_value(16+8 downto 16+0);
            o_header_out(op).fine            <= std_logic_vector(to_unsigned(to_integer(fine_channel_p2)+op, o_header_out(op).fine'LENGTH));
        end process;
    end generate;    
    
    P_OUTPUT: process(i_clk)
    begin
        if rising_edge(i_clk) then

            --pipeline:
            data_p1         <= i_data_in;
            o_data_out      <= data_p1;
            data_vld_p1     <= i_data_in_vld;
            o_data_out_vld  <= data_vld_p1;
            o_station_addr  <= std_logic_vector(to_unsigned(to_integer(station_group), o_station_addr'LENGTH)) ;
            fine_channel_p1 <= fine_channel;
            fine_channel_p2 <= fine_channel_p1;

            if i_rst='1' then
                ra             <= (others => '0');                
                in_frame       <= (others => '0');        
                ra_frame_start <= (others => '0');        
                fine_channel   <= (others => '0');
                station_group  <= (others => '0');
            else
                if i_data_in_vld='1' then
                    station_group  <= station_group + 1;
                    ra       <= ra + g_TIME_STAMPS;
                    in_frame <= in_frame + 1;
                    if station_group=g_STATION_GROUPS-1 then
                        station_group <= (others => '0');
                        ra   <= ra - g_TIME_STAMPS*(g_STATION_GROUPS-1) + 1;
                        if in_frame=g_STATION_GROUPS*g_TIME_STAMPS-1 then
                            ra           <= ra_frame_start;
                            in_frame     <= (others => '0');
                            fine_channel <= fine_channel + pc_CTF_OUTPUT_NUMBER;
                            if fine_channel=g_FINE_CHANNELS-pc_CTF_OUTPUT_NUMBER then
                                fine_channel   <= (others => '0');
                                ra             <= ra + 1;
                                ra_frame_start <= ra + 1;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;


    
end Behavioral;
