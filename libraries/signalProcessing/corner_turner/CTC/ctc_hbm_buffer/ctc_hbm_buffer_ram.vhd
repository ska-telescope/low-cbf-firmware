---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Coarse (CTC) - HBM Main Buffer RAM 
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This is a wrapper for the actual HBM entity.
-- Its main function is to provide an HBM Emulator.
-- 
-- The Emulator is similar to the real HBM in all aspects that matter for the CTC.
-- It is however, not a full HBM model.
-- It cannnot be used under all circumstances or to measure throughput.  
--
-- It does not require System-Verilog and can therefore be simulated in Vivado Sim.
-- It simulates much faster than the real HBM simulation model.
--
-- Synthesis cannot use the emulator.
-- Simulation always uses the emulator. It is used to store the meta data.
-- Simulation can choose via g_USE_HBM to utilise Xilinx' HBM simulation model
-- or not. If TRUE, the Emulator runs in tandem mode and data coming out of
-- the HBM and the Emulator are compared and checked to be equal.
--
-- Please note: there have been multiple instances where the Xilinx HBM simulation model failed:
-- 1. using o_hbm_mosi.rready is prone to delta cycle errors - fixed here via a 10ps transport delay
-- 2. using massive amounts of data makes the Xilinx HBM model crash (only "0000...000" on output)
-- 3. performing a second run-time reset makes the Xilinx HBM model crash (only "0000...000" on output)
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

Library xpm;
use xpm.vcomponents.all;

use work.ctc_pkg.all;

library axi4_lib;
use axi4_lib.axi4_full_pkg.all;

entity ctc_hbm_buffer_ram is
    Generic (
        g_DEPTH            : natural := 1024; -- used HBM memory depth
        g_DEPTH_IN_BLOCKS  : natural := 1024; -- used HBM memory depth
        g_INPUT_BLOCK_SIZE : natural := 2048;  
        g_BURST_LEN        : natural := 4;    -- AXI burst len
        g_USE_HBM          : boolean;         -- TRUE: use Xilinx' HBM model, FALSE: use HBM emulator (simpler, faster, no SystemVerilog needed)
        g_HBM_EMU_STUTTER  : boolean          -- if HBM emulator used: set w_ready and wa_ready to '0' in a pseudo random pattern      
    );
    Port ( 
           i_hbm_clk        : in  std_logic;
           i_hbm_rst        : in  std_logic;
           --block tracker:
           i_wa_block_offset     : in std_logic_vector(log2_ceil(g_DEPTH_IN_BLOCKS)-1 downto 0);
           i_wa_block_offset_vld : in std_logic;
           i_wa_block_good       : in std_logic; 
           i_ra_block_offset     : in std_logic_vector(log2_ceil(g_DEPTH_IN_BLOCKS)-1 downto 0);
           i_ra_block_offset_vld : in std_logic;
           i_ra_block_clear      : in std_logic;
           o_error_overwrite     : out std_logic;
           o_error_wa_fifo_full  : out std_logic;
           o_error_ra_fifo_full  : out std_logic;
           o_error_bv_fifo_full  : out std_logic;
           o_error_bv_fifo_underflow : out std_logic;
           o_new_block           : out std_logic;
           o_block_vld           : out std_logic; 
           --wa:
           i_wa             : in  std_logic_vector(log2_ceil(g_DEPTH)-1 downto 0);
           i_wae            : in  std_logic;
           i_wid            : in  std_logic_vector(5 downto 0);
           o_w_ack          : out std_logic;
           o_w_ack_id       : out std_logic_vector(5 downto 0);
           --data_in:
           i_data_in        : in  t_ctc_hbm_data;
           i_we             : in  std_logic;
           i_last           : in  std_logic;
           --ra:
           i_ra             : in  std_logic_vector(log2_ceil(g_DEPTH)-1 downto 0);
           i_re             : in  std_logic;
           i_rid            : in  std_logic_vector(5 downto 0) := (others => '0');
           --data out:
           o_data_out_vld   : out std_logic;       
           o_data_out_id    : out std_logic_vector(5 downto 0);
           o_data_out       : out t_ctc_hbm_data;
           i_data_out_stop  : in  std_logic;
           --ready:
           o_read_ready     : out std_logic;
           o_write_ready    : out std_logic;
           o_wa_ready       : out std_logic;
           --HBM INTERFACE
            o_hbm_mosi  : out t_axi4_full_mosi;
            i_hbm_miso  : in  t_axi4_full_miso;
            i_hbm_ready : in  std_logic
    );
end ctc_hbm_buffer_ram;

architecture Behavioral of ctc_hbm_buffer_ram is

    constant c_HBM_WIDTH         : natural := 256;

    constant g_LOG2_DEPTH        : natural := log2_ceil(g_DEPTH);
    
    -- The bigger value is so that the emulator FIFO
    -- never runs out of space whilst data flow is controlled by the HBM.
    constant g_FIFO_SIZE : integer := sel(g_USE_HBM, 1024, 64);  

    signal f_wa_ready    : std_logic;
    signal f_read_ready  : std_logic;
    signal f_write_ready : std_logic;
    signal f_w_ack       : std_logic;
    signal f_w_ack_id    : std_logic_vector(5 downto 0);
    
    signal f_data_out     : t_ctc_hbm_data;
    signal f_data_out_vld : std_logic;
    signal f_data_out_id  : std_logic_vector(5 downto 0);

    signal block_tracker_reset_busy : std_logic;

begin

    -----------------------------------------------------------------------------------------
    -- HBM BLOCK TRACKER
    --
    -- Which block is valid?
    -----------------------------------------------------------------------------------------
    E_BLOCK_TRACKER: entity work.ctc_hbm_block_tracker
    Generic Map(
        g_DEPTH_IN_BLOCKS     => g_DEPTH_IN_BLOCKS,
        g_INPUT_BLOCK_SIZE    => g_INPUT_BLOCK_SIZE,
        g_HBM_BURST_LEN       => g_BURST_LEN
    ) Port Map (
        i_hbm_clk             => i_hbm_clk,            
        i_hbm_rst             => i_hbm_rst,            
        i_wa_block_offset     => i_wa_block_offset,    
        i_wa_block_offset_vld => i_wa_block_offset_vld,
        i_wa_block_good       => i_wa_block_good,
        i_wa_ack              => o_w_ack,      
        i_ra_block_offset     => i_ra_block_offset,    
        i_ra_block_offset_vld => i_ra_block_offset_vld,
        i_ra_block_clear      => i_ra_block_clear,
        i_ra_ack              => o_data_out_vld,     
        o_error_overwrite     => o_error_overwrite,
        o_error_wa_fifo_full  => o_error_wa_fifo_full, 
        o_error_ra_fifo_full  => o_error_ra_fifo_full, 
        o_error_bv_fifo_full  => o_error_bv_fifo_full,
        o_error_bv_fifo_underflow => o_error_bv_fifo_underflow,
        o_new_block           => o_new_block,
        o_block_vld           => o_block_vld,
        o_reset_busy          => block_tracker_reset_busy        
    );
    


    -----------------------------------------------------------------------------------------
    -- XILINX HBM INSTANCE (DATA ONLY, NO META DATA)
    -----------------------------------------------------------------------------------------
    G_HBM: if g_USE_HBM generate
        signal data_out_p1      : std_logic_vector(255 downto 0);
        signal data_out_vld_p1  : std_logic;
        signal data_out_id_p1   : std_logic_vector(5 downto 0);
        signal data_out_stop_p1 : std_logic;
        
        signal r_data_cycle       : integer := 1;
        signal r_data_valid_cycle : integer := 1;
        signal r_throughput       : real;
        signal w_data_cycle       : integer := 1;
        signal w_data_valid_cycle : integer := 1;
        signal w_throughput       : real;
                
    begin

        -----------------------------------------------------------------------------------------
        -- HBM (DATA + STUTTER)
        -----------------------------------------------------------------------------------------
   
        o_write_ready <= i_hbm_ready and i_hbm_miso.wready and not block_tracker_reset_busy;
        o_wa_ready    <= i_hbm_ready and i_hbm_miso.awready and not block_tracker_reset_busy;
        o_read_ready  <= i_hbm_ready and i_hbm_miso.arready and not block_tracker_reset_busy;

        P_READY: process (i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                o_hbm_mosi.bready <= '1';
                data_out_stop_p1 <= i_data_out_stop;
            end if;
        end process;
        o_hbm_mosi.rready <= transport not data_out_stop_p1 after 10 ps;    

        P_AR: process (i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                if i_hbm_miso.arready='1' then
                    o_hbm_mosi.araddr <= (others => '0');
                    o_hbm_mosi.araddr(i_ra'LEFT+5 downto i_ra'RIGHT+5) <= i_ra;
                    
                    o_hbm_mosi.arburst             <= (0=>(i_re and i_hbm_ready), others => '0');
                    o_hbm_mosi.arid(5 downto 0)    <= i_rid;
                    o_hbm_mosi.arlen(3 downto 0)   <= std_logic_vector(to_unsigned(g_BURST_LEN-1, 4));
                    o_hbm_mosi.arsize              <= B"101"; --256bit
                    o_hbm_mosi.arvalid             <= i_re and i_hbm_ready;
                end if;    
            end if;
        end process;    
            
        P_AW:
        process (i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                if i_hbm_miso.awready='1' then
                    o_hbm_mosi.awaddr <= (others => '0');
                    o_hbm_mosi.awaddr(i_wa'LEFT+5 downto i_wa'RIGHT+5) <= i_wa;
            
                    o_hbm_mosi.awburst           <= (0=>'1', others => '0');
                    o_hbm_mosi.awid(5 downto 0)  <= i_wid;
                    o_hbm_mosi.awlen(3 downto 0) <= std_logic_vector(to_unsigned(g_BURST_LEN-1, 4));
                    o_hbm_mosi.awsize            <= B"101"; --256bit
                    o_hbm_mosi.awvalid           <= i_wae and i_hbm_ready;
                end if;
            end if;
        end process;    
                
        P_W:
        process (i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                if i_hbm_miso.wready='1' then
                    o_hbm_mosi.wdata(255 downto 0)  <= i_data_in.data;
                    o_hbm_mosi.wlast  <= i_last;
                    o_hbm_mosi.wstrb  <= (others=>'1');
                    o_hbm_mosi.wvalid <= i_we and i_hbm_ready;
                end if;
            end if;    
        end process;    
        
        o_w_ack    <= i_hbm_miso.bvalid and i_hbm_ready;
        o_w_ack_id <= i_hbm_miso.bid(5 downto 0);

        o_data_out.data  <= data_out_p1;
        o_data_out_vld   <= data_out_vld_p1 and i_hbm_ready;
        o_data_out_id    <= data_out_id_p1;

        P_DATA_OUT: process(i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                data_out_p1     <= i_hbm_miso.rdata(255 downto 0);
                data_out_vld_p1 <= i_hbm_miso.rvalid and not data_out_stop_p1;
                data_out_id_p1  <= i_hbm_miso.rid(5 downto 0);
               
                if data_out_vld_p1='1' then
                   assert f_data_out_vld='1'          report "HBM SIM vs. EMU mismatch: data_valid" severity FAILURE; 
                   assert f_data_out.data=data_out_p1 report "HBM SIM vs. EMU mismatch: data"       severity FAILURE; 
                end if;
            end if;
        end process;
        
        --synthesis translate_off
            P_R_THROUGHPUT: process
            begin
                wait until data_out_vld_p1='1';
                while true loop
                    wait until rising_edge(i_hbm_clk);
                    r_data_cycle <= r_data_cycle + 1;
                    if data_out_vld_p1='1' then
                        r_data_valid_cycle <= r_data_valid_cycle + 1;
                    end if;
                    -- ratio * 256bits / 2.222ns (450Mhz) = __ Gb/s
                    r_throughput <= real(r_data_valid_cycle) / real(r_data_cycle) * 256.0 / 2.222;
                end loop;
            end process;
            
            P_W_THROUGHPUT: process
                variable pre_read : boolean := true;
            begin
                wait until o_w_ack='1';
                while true loop
                    wait until rising_edge(i_hbm_clk);
                    if pre_read=true and data_out_vld_p1='1' then
                        pre_read:=false;
                        w_data_cycle       <= 1;
                        w_data_valid_cycle <= 1;
                    else   
                        w_data_cycle <= w_data_cycle + 1;
                        if i_we='1' and o_write_ready='1' then
                            w_data_valid_cycle <= w_data_valid_cycle + 1;
                        end if;
                        -- ratio * 256bits / 2.222ns (450Mhz) = __ Gb/s
                    end if;
                    w_throughput <= real(w_data_valid_cycle) / real(w_data_cycle) * 256.0 / 2.222;
                end loop;
            end process;
        --synthesis translate_on
    
    else generate --no XILINX HBM

        GEN_WA_READY_STUTTER: if true generate
            signal dice1, dice2, dice3: integer := 0;
        begin
            P_WA_READY_STUTTER: process
                variable seed1: positive := 101;
                variable seed2: positive := 2;
                variable rand: real;
            begin
                uniform(seed1, seed2, rand);
                dice1 <= integer(rand*6.0);
                uniform(seed1, seed2, rand);
                dice2 <= integer(rand*6.0);
                uniform(seed1, seed2, rand);
                dice3 <= integer(rand*6.0);
                wait until rising_edge(i_hbm_clk);    
            end process;
            o_wa_ready    <= f_wa_ready and not block_tracker_reset_busy when not g_HBM_EMU_STUTTER or dice1/=1 else '0';
            o_write_ready <= f_write_ready and not block_tracker_reset_busy when not g_HBM_EMU_STUTTER or dice2/=1 else '0';
            o_read_ready  <= f_read_ready and not block_tracker_reset_busy when not g_HBM_EMU_STUTTER or dice3=1 else '0';
        end generate;    

        o_w_ack       <= f_w_ack;
        o_w_ack_id    <= f_w_ack_id;
    
        o_data_out.data  <= f_data_out.data;
        o_data_out_vld   <= f_data_out_vld;
        o_data_out_id    <= f_data_out_id;
            
    end generate;
    


    
    
    
    
    -----------------------------------------------------------------------------------------
    -- HBM EMULATOR (DATA + META DATA)
    -----------------------------------------------------------------------------------------
    GEN_EMULATOR: if THIS_IS_SIMULATION generate
        constant c_DATA_WIDTH  : natural := 16*pc_CTC_META_WIDTH+c_HBM_WIDTH+1;
        constant c_ADDR_WIDTH  : natural := g_LOG2_DEPTH+6;
        
        constant c_READOUT_DELAY : integer := sel(g_USE_HBM, 1, 16); --additional cycles that it takes to get a readout answer (allow block tracker to finish) 
        
        signal read_out_delay : std_logic_vector(c_READOUT_DELAY-1 downto 0);
        
        signal w_din, w_dout   : std_logic_vector(c_DATA_WIDTH-1 downto 0);
        signal w_re, w_empty   : std_logic := '0';
        signal w_we            : std_logic;
        signal w_full          : std_logic := '0';
        signal w_burst_count   : natural := 0;
        signal wa_din, wa_dout : std_logic_vector(c_ADDR_WIDTH-1 downto 0);
        signal wa_re, wa_empty : std_logic := '0';
        signal wa_full         : std_logic := '0';
        signal ra_din, ra_dout : std_logic_vector(c_ADDR_WIDTH-1 downto 0);
        signal ra_re, ra_empty : std_logic := '0';
        signal ra_full         : std_logic := '0';
        signal r_burst_count   : natural := 0;

        signal w, r : std_logic_vector(c_DATA_WIDTH-1 downto 0);
        signal wa   : unsigned(g_LOG2_DEPTH-1 downto 0);
        signal ra   : unsigned(g_LOG2_DEPTH-1 downto 0);
        
        signal r_vld    : std_logic := '0';
        signal r_id     : std_logic_vector(5 downto 0);
        signal r_vld_p1 : std_logic := '0';
        signal r_id_p1  : std_logic_vector(5 downto 0);

        signal r_din, r_dout   : std_logic_vector(c_DATA_WIDTH+6-1 downto 0);
        signal r_re, r_empty   : std_logic := '0';
        signal r_full          : std_logic := '0';
        signal r_we            : std_logic;
        
        signal ra_wr_rst_busy : std_logic;
        signal wa_wr_rst_busy : std_logic;
        signal w_wr_rst_busy : std_logic;
        
    begin
        
        w_din <= i_last & meta_to_slv(i_data_in.meta) & i_data_in.data;
        
        E_W_FIFO : xpm_fifo_sync
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "block",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => g_FIFO_SIZE,
            FULL_RESET_VALUE    => 0,
            PROG_EMPTY_THRESH   => g_BURST_LEN-1,
            PROG_FULL_THRESH    => 10,     
            RD_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_SIZE),
            READ_DATA_WIDTH     => c_DATA_WIDTH,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0200",   --prog_empty    
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => c_DATA_WIDTH,
            WR_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_SIZE)
        ) port map (
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_rst,
            wr_rst_busy   => w_wr_rst_busy,
            --di
            din           => w_din,
            wr_en         => i_we and o_write_ready,
            full          => w_full,
            --do
            dout          => w_dout,
            rd_en         => w_re,
            prog_empty    => w_empty,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );    
        f_write_ready <= not w_full and not w_wr_rst_busy;
        
        wa_din <= i_wid & i_wa;  
        
        E_WA_FIFO : xpm_fifo_sync
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "block",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => g_FIFO_SIZE,
            FULL_RESET_VALUE    => 0,
            PROG_EMPTY_THRESH   => 10,
            PROG_FULL_THRESH    => 10,     
            RD_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_SIZE),
            READ_DATA_WIDTH     => c_ADDR_WIDTH,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0000",       
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => c_ADDR_WIDTH,
            WR_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_SIZE)
        ) port map (
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_rst,
            wr_rst_busy   => wa_wr_rst_busy,
            --di
            din           => wa_din,
            wr_en         => i_wae and o_wa_ready,
            full          => wa_full,
            --do
            dout          => wa_dout,
            rd_en         => wa_re,
            empty         => wa_empty,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );    
        f_wa_ready <= not wa_full and not wa_wr_rst_busy;
       
        w_re  <= '1' when w_burst_count/=0 or (w_empty='0' and wa_empty='0') else '0';
        wa_re <= '1' when w_burst_count=g_BURST_LEN-1 else '0';
       
        P_WRITE_MEM_LOGIC: process(i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                
                w_we    <= w_re;
                f_w_ack <= '0';
                
                if i_hbm_rst='1' then
                    wa <= (others => '0');
                    w_burst_count <= 0;
                else
                    if w_burst_count=0 and w_empty='0' and wa_empty='0' then
                        assert w_dout(w_dout'HIGH)='0' report "Last bit set!" severity FAILURE;
                        w  <= w_dout;
                        wa <= unsigned(wa_dout(c_ADDR_WIDTH-7 downto 0));
                        w_burst_count <= 1;
                    elsif w_burst_count/=0 then
                        w     <= w_dout;
                        wa    <= wa + 1;
                        if w_burst_count = g_BURST_LEN-1 then
                            assert w_dout(w_dout'HIGH)='1' report "Last bit not set!" severity FAILURE;
                            w_burst_count<= 0;
                            f_w_ack      <= '1';
                            f_w_ack_id   <= wa_dout(c_ADDR_WIDTH-1 downto c_ADDR_WIDTH-6);
                        else    
                            assert w_dout(w_dout'HIGH)='0' report "Last bit set!" severity FAILURE;
                            w_burst_count <= w_burst_count + 1;
                        end if;
                    end if;                    
                end if;
            end if;
        end process;
                
        BRAM : entity work.emulator_ram
        generic map (
            g_FULL_DEPTH      => g_DEPTH,
            g_PRIMITIVE_DEPTH => 2**17,
            g_DATA_WIDTH      => c_DATA_WIDTH
        )
        port map (
          clka  => i_hbm_clk,
          clkb  => i_hbm_clk,
          rstb  => i_hbm_rst,
          --di:
          wea   => w_we,
          addra => std_logic_vector(wa),      
          dina  => w,       
          --do:
          addrb => std_logic_vector(ra),     
          doutb => r 
        );

        P_READ_MEM_LOGIC: process(i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
            
                --defaults:
                r_vld    <= '0';
                r_vld_p1 <= r_vld;
                r_id_p1  <= r_id;
                ra_re    <= '0';
            
                if i_hbm_rst='1' then
                    ra <= (others => '0');
                    r_burst_count <= 0;
                else

                    if r_burst_count=0 and ra_empty='0' and r_full='0' then
                        ra    <= unsigned(ra_dout(c_ADDR_WIDTH-7 downto 0));
                        r_id  <= ra_dout(c_ADDR_WIDTH-1 downto c_ADDR_WIDTH-6); 
                        r_vld <= '1';
                        r_burst_count   <= 1;
                        ra_re  <= '1';
                    elsif r_burst_count/=0 then
                        ra    <= ra + 1;
                        r_vld <= '1';
                        if r_burst_count = g_BURST_LEN-1 then
                            r_burst_count <= 0;
                        else    
                            r_burst_count <= r_burst_count + 1;
                        end if;
                    end if;                    

                end if;    
            end if;
        end process;
    
        ra_din <= i_rid & i_ra;  
        
        E_RA_FIFO : xpm_fifo_sync
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "block",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => g_FIFO_SIZE,
            FULL_RESET_VALUE    => 0,
            PROG_EMPTY_THRESH   => 10,
            PROG_FULL_THRESH    => 10,     
            RD_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_SIZE),
            READ_DATA_WIDTH     => c_ADDR_WIDTH,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0000",       
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => c_ADDR_WIDTH,
            WR_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_SIZE)
        ) port map (
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_rst,
            wr_rst_busy   => ra_wr_rst_busy,
            --di
            din           => ra_din,
            wr_en         => i_re and o_read_ready,
            full          => ra_full,
            --do
            dout          => ra_dout,
            rd_en         => ra_re,
            empty         => ra_empty,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );    

        r_din <= r_id_p1 & r;
        
        E_R_FIFO : xpm_fifo_sync
        generic map (
            DOUT_RESET_VALUE    => "0",
            ECC_MODE            => "no_ecc",
            FIFO_MEMORY_TYPE    => "block",
            FIFO_READ_LATENCY   => 0,
            FIFO_WRITE_DEPTH    => g_FIFO_SIZE,
            FULL_RESET_VALUE    => 0,
            PROG_EMPTY_THRESH   => 10,
            PROG_FULL_THRESH    => g_FIFO_SIZE-g_BURST_LEN-8,     
            RD_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_SIZE),
            READ_DATA_WIDTH     => c_DATA_WIDTH+6,
            READ_MODE           => "fwft",
            USE_ADV_FEATURES    => "0002",  --prog_full       
            WAKEUP_TIME         => 0,
            WRITE_DATA_WIDTH    => c_DATA_WIDTH+6,
            WR_DATA_COUNT_WIDTH => log2_ceil(g_FIFO_SIZE)
        ) port map (
            wr_clk        => i_hbm_clk,
            rst           => i_hbm_rst,
            --di
            din           => r_din,
            wr_en         => r_vld_p1,
            prog_full     => r_full,
            --do
            dout          => r_dout,
            rd_en         => r_re,
            empty         => r_empty,
            --unused
            sleep         => '0', 
            injectdbiterr => '0',
            injectsbiterr => '0'
        );    

        P_READOUT_DELAY: process (i_hbm_clk)
        begin
            if rising_edge(i_hbm_clk) then
                if i_hbm_rst='1' then
                    read_out_delay <= (others => '1');
                else
                    read_out_delay <= read_out_delay(read_out_delay'HIGH-1 downto 0) & r_empty;
                end if;    
            end if;    
        end process;

        r_re <= not i_hbm_rst and not (OR(read_out_delay)) and not r_empty and not i_data_out_stop when not g_USE_HBM else o_data_out_vld;

        f_data_out_vld  <= r_re;
        f_data_out_id   <= r_dout(r_dout'HIGH downto r_dout'HIGH-5);
        f_data_out.data <= r_dout(c_HBM_WIDTH-1 downto 0);
        f_data_out.meta <= slv_to_meta(r_dout(c_DATA_WIDTH-2 downto c_HBM_WIDTH));

        f_read_ready <= not ra_full and not ra_wr_rst_busy;
        
        --Meta Data always comes from the HBM Emulator
        o_data_out.meta <= f_data_out.meta;
        
    else generate --not SIMULATION:
    
        assert g_USE_HBM=true report "XILINX HBM needs to be turned on for synthesis!" severity FAILURE;
        
    end generate;
    
    
end Behavioral;
