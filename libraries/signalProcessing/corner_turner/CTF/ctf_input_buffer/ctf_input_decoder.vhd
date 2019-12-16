---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Input Decoder
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This module takes the input data stream in form of a 64 bit std_logic_vector,
-- extracts the header (2 words) and turns the header and the data into a record.
-- 
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.ctf_pkg.all;

Library xpm;
use xpm.vcomponents.all;

entity ctf_input_decoder is
    Generic (
        g_INPUT_PACKET_SIZE : natural := 3456
    );
    Port ( 
        i_hbm_clk         : in  std_logic;
        i_hbm_clk_rst     : in  std_logic;
        i_input_clk       : in  std_logic;
        i_input_clk_rst   : in  std_logic;
        i_input_halt_ts   : in  std_logic_vector(43 downto 0);
        o_input_stopped   : out std_logic;
        i_data_in_record  : in  t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
        i_data_in_slv     : in  std_logic_vector(63 downto 0);
        i_data_in_vld     : in  std_logic;
        o_data_in_stop    : out std_logic;
        o_data_out        : out t_ctf_input_data_a(pc_CTF_INPUT_NUMBER-1 downto 0);
        o_data_out_vld    : out std_logic;
        i_data_out_stop   : in  std_logic;
        o_header_out      : out t_ctf_input_header;
        o_header_out_vld  : out std_logic        
    );
end ctf_input_decoder;

architecture Behavioral of ctf_input_decoder is

    constant g_FIFO_DEPTH : natural := 2**log2_ceil(g_INPUT_PACKET_SIZE+1);

    type t_state is (s_HEADER1, s_HEADER2, s_DATA, s_STOPPED);
    signal state : t_state := s_HEADER1; 

    signal header_1      : std_logic_vector(63 downto 0);
    signal header_in     : t_ctf_input_header;
    signal header_in_vld : std_logic;

    signal header_out    : std_logic_vector(pc_CTF_HEADER_WIDTH-1 downto 0);
    signal header_rd_en  : std_logic;
    signal header_empty  : std_logic;
    
    signal input_count  : unsigned(log2_ceil(g_INPUT_PACKET_SIZE)-1 downto 0);
    signal output_count : unsigned(log2_ceil(g_INPUT_PACKET_SIZE)-1 downto 0);
    signal wr_en        : std_logic;
    signal rd_en        : std_logic;
    signal full         : std_logic;
    signal empty        : std_logic;
    
    signal data_out     : std_logic_vector(16*pc_CTF_INPUT_NUMBER-1 downto 0);
    
    signal meta_in      : std_logic_vector(pc_CTF_INPUT_NUMBER*pc_CTF_META_WIDTH-1 downto 0);
    signal meta_out     : std_logic_vector(pc_CTF_INPUT_NUMBER*pc_CTF_META_WIDTH-1 downto 0);
    
begin

    P_FSM: process(i_input_clk)
        variable header_v : std_logic_vector(pc_CTF_HEADER_WIDTH-1 downto 0);
    begin
        if rising_edge(i_input_clk) then
            
            --defaults:
            header_in_vld   <= '0';
            o_input_stopped <= '0';
            
            if i_input_clk_rst='1' then
                state <= s_HEADER1;
            else
                case state is
                when s_HEADER1 =>
                    if i_data_in_vld='1' then
                        header_1 <= i_data_in_slv;
                        state <= s_HEADER2;
                    end if;                    
                when s_HEADER2 =>
                    if i_data_in_vld='1' then
                        header_v      := i_data_in_slv & header_1;
                        if header_v(43 downto 0) >= i_input_halt_ts and OR(i_input_halt_ts)/='0' then                        
                            state <= s_STOPPED;
                        else
                            header_in     <= slv_to_header(header_v);
                            header_in_vld <= '1';
                            state         <= s_DATA;
                            input_count   <= (others => '0');
                        end if;    
                    end if;                    
                when s_DATA =>
                    if i_data_in_vld='1' then
                        input_count <= input_count + 1;
                        if input_count=g_INPUT_PACKET_SIZE-1 then
                            state <= s_HEADER1;
                        end if;
                    end if;    
                when s_STOPPED =>
                     --dead end: the only way to continue is a reset
                     o_input_stopped <= '1';        
                end case;
            end if;         
        end if;
    end process;

    E_HEADER_FIFO : xpm_fifo_async
    generic map (
        DOUT_RESET_VALUE    => "0",
        ECC_MODE            => "no_ecc",
        FIFO_MEMORY_TYPE    => "distributed",
        FIFO_READ_LATENCY   => 0,
        FIFO_WRITE_DEPTH    => 16,
        FULL_RESET_VALUE    => 1,
        PROG_EMPTY_THRESH   => 10,
        PROG_FULL_THRESH    => 7,     
        RD_DATA_COUNT_WIDTH => log2_ceil(16),
        READ_DATA_WIDTH     => pc_CTF_HEADER_WIDTH,
        READ_MODE           => "fwft",
        USE_ADV_FEATURES    => "0000",
        WAKEUP_TIME         => 0,
        WRITE_DATA_WIDTH    => pc_CTF_HEADER_WIDTH,
        WR_DATA_COUNT_WIDTH => log2_ceil(16)
    ) port map (
        --di
        wr_clk        => i_input_clk,
        rst           => i_input_clk_rst,
        din           => header_to_slv(header_in),
        wr_en         => header_in_vld,
        --do
        rd_clk        => i_hbm_clk,
        dout          => header_out,
        rd_en         => header_rd_en,
        empty         => header_empty,
        --unused
        sleep         => '0', 
        injectdbiterr => '0',
        injectsbiterr => '0'
    ); 



    wr_en <= i_data_in_vld when state=s_DATA else '0';

    E_DATA_FIFO : xpm_fifo_async
    generic map (
        DOUT_RESET_VALUE    => "0",
        ECC_MODE            => "no_ecc",
        FIFO_MEMORY_TYPE    => "block",
        FIFO_READ_LATENCY   => 0,
        FIFO_WRITE_DEPTH    => g_FIFO_DEPTH,
        FULL_RESET_VALUE    => 1,
        PROG_EMPTY_THRESH   => 10,
        PROG_FULL_THRESH    => g_FIFO_DEPTH-g_INPUT_PACKET_SIZE-5,     
        RD_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_DEPTH),
        READ_DATA_WIDTH     => 16*pc_CTF_INPUT_NUMBER,
        READ_MODE           => "fwft",
        USE_ADV_FEATURES    => "0002",       --prog_full activated
        WAKEUP_TIME         => 0,
        WRITE_DATA_WIDTH    => 16*pc_CTF_INPUT_NUMBER,
        WR_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_DEPTH)
    ) port map (
        --di
        wr_clk        => i_input_clk,
        rst           => i_input_clk_rst,
        din           => i_data_in_slv,
        wr_en         => wr_en,
        prog_full     => o_data_in_stop,
        full          => full,
        --do
        rd_clk        => i_hbm_clk,
        dout          => data_out,
        rd_en         => rd_en,
        empty         => empty,
        --unused
        sleep         => '0', 
        injectdbiterr => '0',
        injectsbiterr => '0'
    ); 
    assert full/='1' or wr_en/='1' report "Input FIFO overflow!" severity FAILURE;
    rd_en <=      not empty and not i_data_out_stop and not header_empty when output_count=0 
             else not empty and not i_data_out_stop;

    GEN_META_FIFO: if THIS_IS_SIMULATION generate
    begin
        
        process (all)
        begin
            for ip in 0 to pc_CTF_INPUT_NUMBER-1 loop
                meta_in((ip+1)*pc_CTF_META_WIDTH-1 downto ip*pc_CTF_META_WIDTH) <= meta_to_slv(i_data_in_record(ip).meta);
            end loop;    
        end process;
        
        
        E_META_FIFO : xpm_fifo_async
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "block",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => g_FIFO_DEPTH,
            FULL_RESET_VALUE    => 1,
            PROG_EMPTY_THRESH   => 10,
            PROG_FULL_THRESH    => 10,     
            RD_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_DEPTH),
            READ_DATA_WIDTH     => pc_CTF_META_WIDTH*pc_CTF_INPUT_NUMBER,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0000",
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => pc_CTF_META_WIDTH*pc_CTF_INPUT_NUMBER,
            WR_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_DEPTH)
        ) port map (
            --di
            wr_clk        => i_input_clk,
            rst           => i_input_clk_rst,
            din           => meta_in,
            wr_en         => wr_en,
            --do
            rd_clk        => i_hbm_clk,
            dout          => meta_out,
            rd_en         => rd_en,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        ); 
    end generate;


    P_HEADER_OUT: process(i_hbm_clk)
    begin
        if rising_edge(i_hbm_clk) then
 
            --defaults:
            o_header_out_vld <= '0'; 
            header_rd_en     <= '0';
            o_data_out_vld   <= rd_en;
            
            for op in 0 to pc_CTF_INPUT_NUMBER-1 loop
                o_data_out(op).data  <= slv_to_payload(data_out(op*16+15 downto op*16));
                o_data_out(op).meta  <= slv_to_meta(meta_out((op+1)*pc_CTF_META_WIDTH-1 downto op*pc_CTF_META_WIDTH));       
            end loop;
            
            if i_hbm_clk_rst='1' then
                output_count <= (others =>'0');
            else    
                if rd_en='1' then
                    output_count <= output_count + 1;
                    if output_count=0 then
                        o_header_out     <= slv_to_header(header_out);
                        o_header_out_vld <= '1'; 
                        header_rd_en     <= '1';
                    elsif output_count=g_INPUT_PACKET_SIZE-1 then
                        output_count <= (others =>'0');
                    end if;
                end if;        
            end if;
        end if;
    end process; 
    
    
end Behavioral;
