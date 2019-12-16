----------------------------------------------------------------------------------
-- Company: Massey university
-- Engineer: vignesh raja balu
-- 
-- Create Date: 01.04.2019 22:22:50
-- Design Name: 
-- Module Name: hbm_input_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

Library xpm;
use xpm.vcomponents.all;

library work;
use work.hbm_pkg.all;

entity hbm_input_gen is
    generic(
        g_FRAME_SIZE_BITS    : natural := 15; 
        g_FRAME_COUNT_BITS   : natural :=  4;
        g_BURST_BITS         : natural :=  4;
        g_BURST_LEN          : natural range 1 to 16 := 12;
        g_WRITE_SKIP         : natural := 1021;
        g_READ_SKIP          : natural := 1021
        );
    Port (
        clk_in_100_p    : in std_logic;
        clk_in_100_n    : in std_logic
        );
end hbm_input_gen;

architecture Behavioral of hbm_input_gen is

    component clk_wiz_0
    port (
        clk_100           : out    std_logic;
        clk_450           : out    std_logic;
        ref_clk_100       : out    std_logic;
    -- Status and control signals
        locked            : out    std_logic;
        clk_in1_p         : in     std_logic;
        clk_in1_n         : in     std_logic
    );
    end component;

    COMPONENT vio_0
    PORT (
        clk        : IN STD_LOGIC;
        probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
    END COMPONENT;

    constant g_FRAME_SIZE   : integer := 2**g_FRAME_SIZE_BITS;
    constant g_FRAME_COUNT  : integer := 2**g_FRAME_COUNT_BITS;
    
    attribute mark_debug : string;
     
    signal axi_00_in_i      : i_SAXI_t;
    signal axi_00_out_i     : o_SAXI_t;
    attribute mark_debug of axi_00_in_i  : signal is "true";
    attribute mark_debug of axi_00_out_i : signal is "true";

    signal clk_in_100       : std_logic;
    signal locked           : std_logic;

    signal axi_clk     : std_logic;
    signal axi_clk_rst : std_logic;
    signal apb_clk     : std_logic;
    signal apb_clk_rst : std_logic;
    signal hbm_ref_clk : std_logic;

    signal axi_init_param   : AXI_ADDR_RW_t;
    signal apb_in_i         : i_SAPB_t := i_SAPB_t_ZERO;
    signal apb_complete_i   : std_logic;  
    signal apb_complete_cdc : std_logic;  
    signal rd_en            : std_logic; -- read enable 
    signal wr_en            : std_logic; -- write enable

    signal r_frm_cnt        : unsigned (31 downto 0);   -- read frame count
    signal w_frm_cnt        : unsigned (31 downto 0);   -- write frame count
    attribute mark_debug of r_frm_cnt  : signal is "true";
    attribute mark_debug of w_frm_cnt  : signal is "true";

    signal rw_start         : std_logic := '0'; 
    attribute mark_debug of rw_start  : signal is "true";

    signal r_cnt            : unsigned (47 downto 0);
    signal w_cnt            : unsigned (47 downto 0);
    signal w_clk_cnt        : unsigned (47 downto 0);
    signal r_clk_cnt        : unsigned (47 downto 0);
    signal w_clk_cnt_en     : std_logic;
    signal r_clk_cnt_en     : std_logic;
    attribute mark_debug of r_cnt  : signal is "true";
    attribute mark_debug of w_cnt  : signal is "true";
    attribute mark_debug of r_clk_cnt  : signal is "true";
    attribute mark_debug of w_clk_cnt  : signal is "true";
    attribute mark_debug of r_clk_cnt_en  : signal is "true";
    attribute mark_debug of w_clk_cnt_en  : signal is "true";
    
    signal read_error : std_logic;
    attribute mark_debug of read_error : signal is "true";
        
    signal throughput_w     : real := 0.0;
    signal throughput_r     : real := 0.0;
begin
   
    E_VIO : vio_0
    PORT MAP (
        clk           => axi_clk,
        probe_out0(0) => rw_start
    );
   
    E_CLK_WIZ : clk_wiz_0
    port map ( 
        -- Clock out ports  
        clk_100     => apb_clk,
        clk_450     => axi_clk,
        ref_clk_100 => hbm_ref_clk,
        -- Status and control signals                
        locked      => locked,
        -- Clock in ports
        clk_in1_p   => clk_in_100_p, --pci_clk_100_p,
        clk_in1_n   => clk_in_100_n  --pci_clk_100_n
    );
        
    E_CDC_AXI_RST : xpm_cdc_single
    generic map (
        DEST_SYNC_FF => 2,   
        INIT_SYNC_FF => 0, 
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG => 0 
    )
    port map (
        src_clk  => apb_clk,
        src_in   => not locked,     
        dest_clk => axi_clk,
        dest_out => axi_clk_rst
    );

    E_CDC_APB_RST : xpm_cdc_single
    generic map (
        DEST_SYNC_FF => 2,   
        INIT_SYNC_FF => 0, 
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG => 0  
    )
    port map (
        src_clk  => apb_clk,
        src_in   => not locked,     
        dest_clk => apb_clk,
        dest_out => apb_clk_rst
    );

    E_CDC_APB_COMPLETE : xpm_cdc_single
    generic map (
        DEST_SYNC_FF => 2,   
        INIT_SYNC_FF => 0, 
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG => 1  
    )
    port map (
        src_clk  => apb_clk,
        src_in   => apb_complete_i,     
        dest_clk => axi_clk,
        dest_out => apb_complete_cdc
    );

    
    axi_00_in_i.rready      <= '1';
    axi_00_in_i.bready      <= '1';
          
    E_HBM_MC0_SP0: entity work.hbm_wrapper
        Port Map (
            i_saxi_00           => axi_00_in_i,
            o_saxi_00           => axi_00_out_i,
            i_sapb_0            => apb_in_i,
            o_sapb_0            => open,
            hbm_ref_clk_0       => hbm_ref_clk, 
            axi_00_aclk         => axi_clk, 
            apb_0_pclk          => apb_clk,   
            axi_00_areset_n     => not axi_clk_rst,
            apb_0_preset_n      => not apb_clk_rst,
            axi_00_wdata_parity => (others => '0'),
            axi_00_rdata_parity => open,
            apb_complete_0      => apb_complete_i,
            DRAM_0_STAT_CATTRIP => open,
            DRAM_0_STAT_TEMP    => open);
    
    
    
    ---------------------------------------
    -- Main Control                      --
    ---------------------------------------
    P_RW_EN: process(axi_clk)
    begin
        if rising_edge(axi_clk) then
            if axi_clk_rst = '1' then
                rd_en <= '0';
                wr_en <= '0';
                w_clk_cnt_en <= '0';
                r_clk_cnt_en <= '0';
            elsif rw_start='1' then
                if r_frm_cnt=g_FRAME_COUNT then
                    rd_en <= '0';
                    wr_en <= '0';
                    w_clk_cnt_en <= '0';
                    r_clk_cnt_en <= '0';
                elsif r_frm_cnt+2 = w_frm_cnt then
                    rd_en <= '1';
                    wr_en <= '1';
                    r_clk_cnt_en <= '1';
                    w_clk_cnt_en <= '1';
                elsif r_frm_cnt+3 = w_frm_cnt then
                    rd_en <= '1';
                    wr_en <= '0';
                elsif r_frm_cnt = w_frm_cnt then
                    rd_en <= '0';
                    wr_en <= '1';
                end if; 
            end if;
        end if;
    end process;
    
    
    -----------------------------    
        -- Write address --
    -----------------------------    
    P_WR_ADDR_GEN: process(axi_clk) 
        variable w_count: integer;
        variable f_addr : unsigned(g_FRAME_COUNT_BITS-1 downto 0);
        variable i_addr : unsigned(g_FRAME_SIZE_BITS-1 downto 0);
        variable w_addr : unsigned(g_FRAME_SIZE_BITS+g_FRAME_COUNT_BITS-1 downto 0);
        variable post_reset : std_logic;
    begin
        if rising_edge (axi_clk) then
            if axi_clk_rst = '1' then
                w_count := 0;
                f_addr  := (others => '0');
                i_addr  := (others => '0');
                w_addr  := (others => '0');
                axi_00_in_i.aw.addr <= (others => '0');
                axi_00_in_i.aw.id   <= (others => '0');
                axi_00_in_i.aw.valid <= '0';
                post_reset := '1';
            else
                axi_00_in_i.aw.burst    <= (0 => '1' , others => '0');
                axi_00_in_i.aw.len      <= std_logic_vector(to_unsigned(g_BURST_LEN -1, axi_00_in_i.aw.len'length));
                axi_00_in_i.aw.size     <= B"101";                       
                if axi_00_out_i.awready = '1' then
                    axi_00_in_i.aw.valid <= wr_en;
                    if wr_en = '1' then
                        if post_reset='0' then
                            i_addr := i_addr + g_WRITE_SKIP;
                            w_addr := f_addr & i_addr;
                        end if;    
                        axi_00_in_i.aw.addr(w_addr'length-1+5+g_BURST_BITS downto 5+g_BURST_BITS) <= std_logic_vector(w_addr);
                        if w_count = g_FRAME_SIZE-1 then
                            w_count := 0;
                            f_addr  := f_addr + 1;
                        else
                            w_count := w_count + 1;
                        end if;
                        post_reset:='0';
                    end if;    
                end if;
            end if;
        end if;
    end process;
    
    -----------------------------    
        -- Write Ack --
    -----------------------------    
    P_WR_ACK: process(axi_clk) 
        variable w_count: integer;
    begin
        if rising_edge (axi_clk) then
            if axi_clk_rst = '1' then
                w_count := 0;
                w_frm_cnt           <= (others => '0');
            else
                if (axi_00_out_i.b.valid = '1') then
                    if w_count = g_FRAME_SIZE-1 then
                        w_count := 0;
                        w_frm_cnt <= w_frm_cnt + 1;
                    else
                        w_count := w_count + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -----------------------------    
        -- Write Data --
    -----------------------------    
    P_WR_DATA_GEN: process(axi_clk)
        variable l_count    : integer;
        variable post_reset : std_logic;
    begin
        if rising_edge (axi_clk) then
            if axi_clk_rst = '1' then
                l_count         := 0;
                axi_00_in_i.w.data  <= (others => '0');
                axi_00_in_i.w.last  <= '0';
                post_reset := '1';
                axi_00_in_i.w.valid <= '0';
            else 
                axi_00_in_i.w.strb <= (others => '1');
                if axi_00_out_i.wready = '1' then
                    axi_00_in_i.w.valid <= wr_en;
                    if wr_en='1' then
                        if post_reset='0' then
                            axi_00_in_i.w.data(255 downto 0)  <= std_logic_vector(to_unsigned((to_integer(unsigned(axi_00_in_i.w.data(255 downto 0)))+1), axi_00_in_i.w.data(255 downto 0)'length));
                        end if;
                        axi_00_in_i.w.last  <= '0';
                        if l_count = g_BURST_LEN-1 then
                            axi_00_in_i.w.last <= '1';
                            l_count := 0;
                        else
                            l_count := l_count + 1;
                        end if;
                        post_reset := '0';
                    end if;        
                end if;
            end if;
        end if;
    end process;
    
    
    -----------------------------    
        -- read address --
    -----------------------------    
    P_RD_ADDR_GEN: process(axi_clk)
        variable r_count : integer;
        variable f_addr : unsigned(g_FRAME_COUNT_BITS-1 downto 0);
        variable i_addr : unsigned(g_FRAME_SIZE_BITS-1 downto 0);
        variable w_addr : unsigned(g_FRAME_SIZE_BITS+g_FRAME_COUNT_BITS-1 downto 0);
        variable post_reset : std_logic;
    begin
        if rising_edge (axi_clk) then
            if axi_clk_rst = '1' then
                r_count := 0;
                f_addr  := (others => '0');
                i_addr  := (others => '0');
                w_addr  := (others => '0');
                axi_00_in_i.ar.addr <= (others => '0');
                axi_00_in_i.ar.id   <= (others => '0');
                axi_00_in_i.ar.valid<= '0';        
                r_frm_cnt           <= (others => '0');
                post_reset := '1';
            else
                axi_00_in_i.ar.burst    <= (0 => '1' , others => '0');
                axi_00_in_i.ar.len      <= std_logic_vector(to_unsigned(g_BURST_LEN - 1, axi_00_in_i.ar.len'length));
                axi_00_in_i.ar.size     <= B"101";                       
                if axi_00_out_i.arready = '1' then
                    axi_00_in_i.ar.valid <= rd_en;        
                    if rd_en = '1' then
                        if post_reset='0' then
                            i_addr := i_addr + g_READ_SKIP;
                            w_addr := f_addr & i_addr;
                        end if;
                        axi_00_in_i.ar.addr(w_addr'length-1+5+g_BURST_BITS downto 5+g_BURST_BITS) <= std_logic_vector(w_addr);
                        if r_count = g_FRAME_SIZE-1 then
                            r_count   := 0;
                            f_addr  := f_addr + 1;
                            r_frm_cnt <= r_frm_cnt + 1;
                        else
                            r_count := r_count + 1;
                        end if;
                        post_reset := '0';
                    end if;                        
                end if;
            end if;        
        end if;
    end process;   

    -----------------------------    
        -- read data --
    -----------------------------    
    P_RD_DATA: process(axi_clk)
        variable r_count : integer;
    begin
        if rising_edge (axi_clk) then
            
            read_error <= '0';
            
            if axi_clk_rst = '1' then
                r_count := 0;
            else
                if axi_00_out_i.r.valid='1' then
                    if axi_00_out_i.r.data /= std_logic_vector(to_unsigned(r_count, 256)) then
                        read_error <= '1';
                    end if;    
                    r_count := r_count + 1;
                end if;
            end if;        
        end if;
    end process;   

    
    rw_count: process (axi_clk)
    begin
        if rising_edge (axi_clk) then
            if axi_clk_rst = '1' then
                r_cnt <= (others => '0');
                w_cnt <= (others => '0');
            else
                if axi_00_out_i.b.valid = '1' and w_clk_cnt_en='1' then
                    w_cnt <= w_cnt+1;
                end if;
                if axi_00_out_i.r.valid = '1' and axi_00_out_i.r.last = '1' and r_clk_cnt_en='1' then
                    r_cnt <= r_cnt+1;
                end if;
                
            end if;
        end if;
    end process;
    
    rw_clk_count: process (axi_clk)
    begin
        if rising_edge (axi_clk) then
            if axi_clk_rst = '1' then
                w_clk_cnt <= (others => '0');
                r_clk_cnt <= (others => '0');
            else
                if w_clk_cnt_en = '1' then
                    w_clk_cnt <= w_clk_cnt + 1 ;
                end if;
                if r_clk_cnt_en = '1' then
                    r_clk_cnt <= r_clk_cnt + 1 ;
                end if;
            end if;
        end if;   
    end process;
  
    --synthesis translate_off
        ---------------------------------
                -- Throughput --
        ---------------------------------
        p_read_throughput : process 
        begin
            wait until rising_edge (axi_clk); 
            throughput_r <= real(to_integer(r_cnt)) / (real(to_integer(r_clk_cnt))+0.00000001) * 100.0 * real(g_BURST_LEN);
            throughput_w <= real(to_integer(w_cnt)) / (real(to_integer(w_clk_cnt))+0.00000001) * 100.0 * real(g_BURST_LEN);
        end process;
    --synthesis translate_on
end Behavioral;

