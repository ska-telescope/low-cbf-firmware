-------------------------------------------------------------------------------
--
-- Copyright (C) 2016
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
-- JIVE (Joint Institute for VLBI in Europe) <http://www.jive.nl/>
-- P.O.Box 2, 7990 AA Dwingeloo, The Netherlands
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
-------------------------------------------------------------------------------

LIBRARY IEEE, UNISIM, common_lib, gmi_board_lib, technology_lib, spi_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE gmi_board_lib.gmi_board_pkg.ALL;
USE UNISIM.vcomponents.all; -- IBUFDS, OBUFDS, ...

ENTITY gmi_qsfp_40G_cd IS
  GENERIC (
    g_design_name   : STRING  := "gmi_qsfp_40G_cd";
    g_design_note   : STRING  := "UNUSED";
    g_technology    : NATURAL := c_tech_xcvu9p;
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0;
    g_stamp_date    : NATURAL := 0;  -- Date (YYYYMMDD)
    g_stamp_time    : NATURAL := 0;  -- Time (HHMMSS)
    g_stamp_svn     : NATURAL := 0;  -- SVN revision
    g_factory_image : BOOLEAN := TRUE
  );
  PORT (
    clk_e_p     : in std_logic; -- 125MHz PTP clk
    clk_e_n     : in std_logic;
    debug_mmbx  : out std_logic;
    led_din     : out std_logic;
    led_dout    : in  std_logic;
    led_cs      : out std_logic;
    led_sclk    : out std_logic;

    optics_l_scl : inout std_logic;
    optics_l_sda : inout std_logic;
    optics_l_reset_n : out std_logic;

    qsfp_clock_sel    : out std_logic;
    
    --qsfp_a_mod_prs_n  : in std_logic;
    qsfp_a_reset      : out std_logic;
    --qsfp_a_clk_p      : in std_logic;                              -- 161.13MHz reference
    --qsfp_a_clk_n      : in std_logic;
    --qsfp_a_tx_p       : out std_logic_vector(3 downto 0);
    --qsfp_a_tx_n       : out std_logic_vector(3 downto 0);
    --qsfp_a_rx_p       : in std_logic_vector(3 downto 0);
    --qsfp_a_rx_n       : in std_logic_vector(3 downto 0);

    --qsfp_b_mod_prs_n  : in std_logic;
    qsfp_b_reset      : out std_logic;
    --qsfp_b_clk_p      : in std_logic;                              -- 161.13MHz reference
    --qsfp_b_clk_n      : in std_logic;
    --qsfp_b_tx_p       : out std_logic_vector(3 downto 0);
    --qsfp_b_tx_n       : out std_logic_vector(3 downto 0);
    --qsfp_b_rx_p       : in std_logic_vector(3 downto 0);
    --qsfp_b_rx_n       : in std_logic_vector(3 downto 0);

    qsfp_c_mod_prs_n  : in std_logic;
    qsfp_c_reset      : out std_logic;
    qsfp_c_clk_p      : in std_logic;                              -- 161.13MHz reference
    qsfp_c_clk_n      : in std_logic;
    qsfp_c_tx_p       : out std_logic_vector(3 downto 0);
    qsfp_c_tx_n       : out std_logic_vector(3 downto 0);
    qsfp_c_rx_p       : in std_logic_vector(3 downto 0);
    qsfp_c_rx_n       : in std_logic_vector(3 downto 0);

    qsfp_d_mod_prs_n  : in std_logic;
    qsfp_d_reset      : out std_logic;
    qsfp_d_clk_p      : in std_logic;                              -- 161.13MHz reference
    qsfp_d_clk_n      : in std_logic;
    qsfp_d_tx_p       : out std_logic_vector(3 downto 0);
    qsfp_d_tx_n       : out std_logic_vector(3 downto 0);
    qsfp_d_rx_p       : in std_logic_vector(3 downto 0);
    qsfp_d_rx_n       : in std_logic_vector(3 downto 0)
  );
END gmi_qsfp_40G_cd;

ARCHITECTURE str OF gmi_qsfp_40G_cd IS

  -- Firmware version x.y
  CONSTANT c_fw_version         : t_gmi_board_fw_version := (1, 1);
  CONSTANT c_reset_len          : NATURAL := 4;  -- >= c_meta_delay_len from common_pkg
  CONSTANT c_mm_clk_freq        : NATURAL := c_gmi_board_mm_clk_freq_125M;

  -- System
  SIGNAL pll_locked             : STD_LOGIC;
  SIGNAL xo_clk                 : STD_LOGIC;
  SIGNAL xo_rst                 : STD_LOGIC;
  SIGNAL clk125                 : STD_LOGIC := '1';
  SIGNAL clk100                 : STD_LOGIC := '1';
  SIGNAL clk50                  : STD_LOGIC := '1';
  
  SIGNAL cs_sim                 : STD_LOGIC;
  SIGNAL mm_clk                 : STD_LOGIC;
  SIGNAL mm_rst                 : STD_LOGIC;

  SIGNAL pulse_10Hz             : STD_LOGIC;
  SIGNAL pulse_10Hz_extended    : STD_LOGIC;
  SIGNAL mm_pulse_ms            : STD_LOGIC;
  SIGNAL mm_pulse_s             : STD_LOGIC;
  SIGNAL mm_board_sens_start    : STD_LOGIC;


  SIGNAL led_toggle             : STD_LOGIC;
  SIGNAL led_flash              : STD_LOGIC;
  SIGNAL led_flash_green0       : STD_LOGIC;
  SIGNAL led_flash_green1       : STD_LOGIC;

  SIGNAL test_reg               : STD_LOGIC_VECTOR(31 downto 0);

  -- color leds:
  SIGNAL led1_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led2_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL led3_colour_arr        : STD_LOGIC_VECTOR(23 DOWNTO 0);
  
  SIGNAL reg_axi_out            : STD_LOGIC_VECTOR(127 downto 0);
  SIGNAL reg_axi_in             : STD_LOGIC_VECTOR(127 downto 0);
  
  SIGNAL reg_axi_mosi           : t_mem_mosi;
  SIGNAL reg_axi_miso           : t_mem_miso;
  SIGNAL reg_mosi_arr           : t_mem_mosi_arr(1 DOWNTO 0);
  SIGNAL reg_miso_arr           : t_mem_miso_arr(1 DOWNTO 0);


component gmi_qsfp_axi_wrapper is
  port (
    M03_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M03_AXI_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_arready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_arvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_awready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_awvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_bvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_rready : out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_rvalid : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_wready : in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    M04_AXI_wvalid : out STD_LOGIC_VECTOR ( 0 to 0 );
    avm_address : out STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_read : out STD_LOGIC;
    avm_readdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    avm_write : out STD_LOGIC;
    avm_writedata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    clock_rtl : in STD_LOGIC;
    led_axi_out : out STD_LOGIC_VECTOR ( 23 downto 0 );
    pll_locked : in STD_LOGIC;
    reg_axi_in : in STD_LOGIC_VECTOR ( 127 downto 0 );
    reg_axi_out : out STD_LOGIC_VECTOR ( 127 downto 0 );
    reset_rtl : in STD_LOGIC
  );
end component gmi_qsfp_axi_wrapper;

component l_ethernet_40G_qsfp_c_0_exdes is
port (
    gt_rxp_in_0  : in  std_logic;
    gt_rxn_in_0  : in  std_logic;
    gt_txp_out_0 : out std_logic;
    gt_txn_out_0 : out std_logic;
    gt_rxp_in_1  : in  std_logic;
    gt_rxn_in_1  : in  std_logic;
    gt_txp_out_1 : out std_logic;
    gt_txn_out_1 : out std_logic;
    gt_rxp_in_2  : in  std_logic;
    gt_rxn_in_2  : in  std_logic;
    gt_txp_out_2 : out std_logic;
    gt_txn_out_2 : out std_logic;
    gt_rxp_in_3  : in  std_logic;
    gt_rxn_in_3  : in  std_logic;
    gt_txp_out_3 : out std_logic;
    gt_txn_out_3 : out std_logic;
                      
    rx_gt_locked_led  : out std_logic;
    rx_aligned_led    : out std_logic;
    completion_status : out std_logic_vector(4 downto 0);

    sys_reset     : in std_logic;
    restart_tx_rx : in std_logic;

    gt_refclk_p   : in std_logic;
    gt_refclk_n   : in std_logic;
    dclk          : in std_logic;
    gt_rxpolarity_0 : in std_logic_vector(3 downto 0);
    gt_txpolarity_0 : in std_logic_vector(3 downto 0)
);
end component l_ethernet_40G_qsfp_c_0_exdes;

component l_ethernet_40G_qsfp_d_0_exdes is
port (
    gt_rxp_in_0  : in  std_logic;
    gt_rxn_in_0  : in  std_logic;
    gt_txp_out_0 : out std_logic;
    gt_txn_out_0 : out std_logic;
    gt_rxp_in_1  : in  std_logic;
    gt_rxn_in_1  : in  std_logic;
    gt_txp_out_1 : out std_logic;
    gt_txn_out_1 : out std_logic;
    gt_rxp_in_2  : in  std_logic;
    gt_rxn_in_2  : in  std_logic;
    gt_txp_out_2 : out std_logic;
    gt_txn_out_2 : out std_logic;
    gt_rxp_in_3  : in  std_logic;
    gt_rxn_in_3  : in  std_logic;
    gt_txp_out_3 : out std_logic;
    gt_txn_out_3 : out std_logic;
                      
    rx_gt_locked_led  : out std_logic;
    rx_aligned_led    : out std_logic;
    completion_status : out std_logic_vector(4 downto 0);

    sys_reset     : in std_logic;
    restart_tx_rx : in std_logic;

    gt_refclk_p   : in std_logic;
    gt_refclk_n   : in std_logic;
    dclk          : in std_logic;
    gt_rxpolarity_0 : in std_logic_vector(3 downto 0);
    gt_txpolarity_0 : in std_logic_vector(3 downto 0)
);
end component l_ethernet_40G_qsfp_d_0_exdes;



BEGIN
  optics_l_reset_n <= NOT mm_rst;

  -----------------------------------------------------------------------------

  u_IBUFDS_clk_e_inst : IBUFDS -- page 201 of ug974-vivado-ultrascale-libraries.pdf
                               -- http://www.xilinx.com/support/documentation/sw_manuals/xilinx2016_1/ug974-vivado-ultrascale-libraries.pdf
   PORT MAP (
    O => xo_clk,
    I => clk_e_p,
    IB=> clk_e_n
  );

  u_common_areset_xo : ENTITY common_lib.common_areset
  GENERIC MAP (
    g_rst_level => '1',       -- power up default will be inferred in FPGA
    g_delay_len => c_reset_len
  )
  PORT MAP (
    in_rst    => '0',         -- release reset after some clock cycles
    clk       => xo_clk,
    out_rst   => xo_rst
  );

  -----------------------------------------------------------------------------
  -- mm_clk
  -- . use mm_sim_clk in sim
  -- . derived from CLK via PLL on hardware
  -----------------------------------------------------------------------------

  mm_clk <= clk125; --clk50;
  debug_mmbx <= mm_clk;
  
--  gen_mm_clk_sim: IF g_sim = TRUE GENERATE
--      clk50       <= NOT clk50 AFTER 10 ns;      -- 50 MHz, 20ns/2
--      mm_locked   <= '0', '1' AFTER 70 ns;
--  END GENERATE;

--  gen_mm_clk_hardware: IF g_sim = FALSE GENERATE
    u_gmi_board_clk125_pll : ENTITY gmi_board_lib.gmi_board_clk125_pll
    GENERIC MAP (
      g_technology => g_technology
    )
    PORT MAP (
      arst       => xo_rst,
      clk125     => xo_clk,
      c0_clk50   => clk50,
      c1_clk100  => clk100,
      c2_clk125  => clk125,
      pll_locked => pll_locked
    );
--  END GENERATE;

  u_gmi_board_node_ctrl : ENTITY gmi_board_lib.gmi_board_node_ctrl
  GENERIC MAP (
    g_pulse_us => c_mm_clk_freq / (10**6)     -- nof system clock cycles to get us period, equal to system clock frequency / 10**6
  )
  PORT MAP (
    -- MM clock domain reset
    mm_clk      => mm_clk,
    mm_locked   => pll_locked,
    mm_rst      => mm_rst,
    -- WDI extend
    mm_wdi_in   => mm_pulse_s,
    -- Pulses
    mm_pulse_us => OPEN,
    mm_pulse_ms => mm_pulse_ms,
    mm_pulse_s  => mm_pulse_s  -- could be used to toggle a LED
  );

  mm_board_sens_start <= mm_pulse_s WHEN g_sim=FALSE ELSE mm_pulse_ms;  -- speed up in simulation

  ------------------------------------------------------------------------------
  -- Toggle red LED when gmi_minimal is running, green LED for other designs.
  ------------------------------------------------------------------------------
  led_flash_green0 <= sel_a_b(g_factory_image=TRUE,  led_flash, '0');
  led_flash_green1 <= sel_a_b(g_factory_image=FALSE, led_flash, '0');


  u_extend : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 22 -- (2^22) / 50e6 = 0.083886 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => mm_pulse_s,
    ep_out  => led_flash
  );


  u_common_pulser_10Hz : ENTITY common_lib.common_pulser
  GENERIC MAP (
    g_pulse_period => 100,
    g_pulse_phase  => 100-1
  )
  PORT MAP (
    rst            => mm_rst,
    clk            => mm_clk,
    clken          => '1',
    pulse_en       => mm_pulse_ms,
    pulse_out      => pulse_10Hz
  );

  u_extend_10Hz : ENTITY common_lib.common_pulse_extend
  GENERIC MAP (
    g_extend_w => 21 -- (2^21) / 50e6 = 0.041943 th of 1 sec
  )
  PORT MAP (
    rst     => mm_rst,
    clk     => mm_clk,
    p_in    => pulse_10Hz,
    ep_out  => pulse_10Hz_extended
  );

  u_toggle : ENTITY common_lib.common_toggle
  PORT MAP (
    rst         => mm_rst,
    clk         => mm_clk,
    in_dat      => mm_pulse_s,
    out_dat     => led_toggle
  );


  u_spi_max6966 : ENTITY spi_lib.spi_max6966
  GENERIC MAP (
    con_simulation => g_sim
  )
  PORT MAP (
    clock       => mm_clk,
    reset       => mm_rst,
    enable      => '1',
    led1_colour => led1_colour_arr,
    led2_colour => led2_colour_arr,
    led3_colour => led3_colour_arr,
    din         => led_din,
    sclk        => led_sclk,
    cs          => led_cs,
    dout        => led_dout
  );

  -- Copied the color codes from the spi_lib.spi_max6966 testbench
  led1_colour_arr <= X"4578ef" WHEN (led_flash_green0 = '1') ELSE (OTHERS => '0');
  led3_colour_arr <= X"47a6c8" WHEN (led_flash_green1 = '1') ELSE (OTHERS => '0');

  u_gmi_qsfp_axi_wrapper : gmi_qsfp_axi_wrapper 
  port map (
    --M03_AXI_araddr => (others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    --M03_AXI_arprot => (others => '0'),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_arready => (others => '1'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    --M03_AXI_arvalid => (others => '0'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    --M03_AXI_awaddr => (others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    --M03_AXI_awprot => (others => '0'),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_awready => (others => '1'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    --M03_AXI_awvalid => (others => '0'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    --M03_AXI_bready => (others => '1'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bresp => (others => '0'), --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_bvalid => (others => '0'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rdata => (others => '0'), --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    --M03_AXI_rready => (others => '1'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rresp => (others => '0'), --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_rvalid => (others => '0'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    --M03_AXI_wdata => (others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_wready => (others => '1'),--: in STD_LOGIC_VECTOR ( 0 to 0 );
    --M03_AXI_wstrb => (others => '0'),  --: out STD_LOGIC_VECTOR ( 3 downto 0 );
    --M03_AXI_wvalid => (others => '0'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    
    --M04_AXI_araddr => (others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    --M04_AXI_arprot => (others => '0'),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_arready => (others => '1'),--: in STD_LOGIC_VECTOR ( 0 to 0 );
    --M04_AXI_arvalid => (others => '0'), --: out STD_LOGIC_VECTOR ( 0 to 0 );
    --M04_AXI_awaddr => (others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    --M04_AXI_awprot => (others => '0'),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_awready => (others => '1'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    --M04_AXI_awvalid => (others => '0'), --: out STD_LOGIC_VECTOR ( 0 to 0 );
    --M04_AXI_bready => (others => '1'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bresp => (others => '0'), --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_bvalid => (others => '0'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rdata => (others => '0'), --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    --M04_AXI_rready => (others => '1'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rresp => (others => '0'), --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_rvalid => (others => '0'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    --M04_AXI_wdata => (others => '0'),   --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_wready => (others => '1'),--: in STD_LOGIC_VECTOR ( 0 to 0 );
    --M04_AXI_wstrb  => (others => '0'),  --: out STD_LOGIC_VECTOR ( 3 downto 0 );
    --M04_AXI_wvalid => (others => '0'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    
    -- t_mem_miso:
    avm_readdata     => reg_axi_miso.rddata(c_word_w-1 downto 0),
    
    -- t_mem_mosi:
    avm_address      => reg_axi_mosi.address,
    avm_writedata    => reg_axi_mosi.wrdata(c_word_w-1 downto 0),
    avm_write        => reg_axi_mosi.wr,
    avm_read         => reg_axi_mosi.rd,
    
    clock_rtl   => mm_clk,
    led_axi_out => led2_colour_arr,
    pll_locked  => pll_locked,
    reg_axi_in  => reg_axi_in,
    reg_axi_out => reg_axi_out,
    reset_rtl   => mm_rst
  );
  

    qsfp_a_reset <= reg_axi_out(0);
    qsfp_b_reset <= reg_axi_out(1);
    qsfp_c_reset <= reg_axi_out(2);
    qsfp_d_reset <= reg_axi_out(3);
    qsfp_clock_sel <= reg_axi_out(4);

 u_l_ethernet_40G_qsfp_c_0_exdes : l_ethernet_40G_qsfp_c_0_exdes
 port map (
    gt_rxp_in_0  => qsfp_c_rx_p(0),
    gt_rxn_in_0  => qsfp_c_rx_n(0),
    gt_txp_out_0 => qsfp_c_tx_p(0),
    gt_txn_out_0 => qsfp_c_tx_n(0),
    gt_rxp_in_1  => qsfp_c_rx_p(1),
    gt_rxn_in_1  => qsfp_c_rx_n(1),
    gt_txp_out_1 => qsfp_c_tx_p(1),
    gt_txn_out_1 => qsfp_c_tx_n(1),
    gt_rxp_in_2  => qsfp_c_rx_p(2),
    gt_rxn_in_2  => qsfp_c_rx_n(2),
    gt_txp_out_2 => qsfp_c_tx_p(2),
    gt_txn_out_2 => qsfp_c_tx_n(2),
    gt_rxp_in_3  => qsfp_c_rx_p(3),
    gt_rxn_in_3  => qsfp_c_rx_n(3),
    gt_txp_out_3 => qsfp_c_tx_p(3),
    gt_txn_out_3 => qsfp_c_tx_n(3),
                      
    rx_gt_locked_led     => reg_axi_in(8),
    rx_aligned_led       => reg_axi_in(9),
    completion_status(0) => reg_axi_in(10),
    completion_status(1) => reg_axi_in(11),
    completion_status(2) => reg_axi_in(12),
    completion_status(3) => reg_axi_in(13),
    completion_status(4) => reg_axi_in(14),

    sys_reset     => mm_rst,
    restart_tx_rx => reg_axi_out(5),

    gt_refclk_p   => qsfp_c_clk_p,
    gt_refclk_n   => qsfp_c_clk_n,
    dclk          => xo_clk,
    gt_rxpolarity_0 => "1111",
    gt_txpolarity_0 => reg_axi_out(11 downto 8) --"0010"
);

 u_l_ethernet_40G_qsfp_d_0_exdes : l_ethernet_40G_qsfp_d_0_exdes
 port map (
    gt_rxp_in_0  => qsfp_d_rx_p(0),
    gt_rxn_in_0  => qsfp_d_rx_n(0),
    gt_txp_out_0 => qsfp_d_tx_p(0),
    gt_txn_out_0 => qsfp_d_tx_n(0),
    gt_rxp_in_1  => qsfp_d_rx_p(1),
    gt_rxn_in_1  => qsfp_d_rx_n(1),
    gt_txp_out_1 => qsfp_d_tx_p(1),
    gt_txn_out_1 => qsfp_d_tx_n(1),
    gt_rxp_in_2  => qsfp_d_rx_p(2),
    gt_rxn_in_2  => qsfp_d_rx_n(2),
    gt_txp_out_2 => qsfp_d_tx_p(2),
    gt_txn_out_2 => qsfp_d_tx_n(2),
    gt_rxp_in_3  => qsfp_d_rx_p(3),
    gt_rxn_in_3  => qsfp_d_rx_n(3),
    gt_txp_out_3 => qsfp_d_tx_p(3),
    gt_txn_out_3 => qsfp_d_tx_n(3),
                      
    rx_gt_locked_led     => reg_axi_in(16),
    rx_aligned_led       => reg_axi_in(17),
    completion_status(0) => reg_axi_in(18),
    completion_status(1) => reg_axi_in(19),
    completion_status(2) => reg_axi_in(20),
    completion_status(3) => reg_axi_in(21),
    completion_status(4) => reg_axi_in(22),

    sys_reset     => mm_rst,
    restart_tx_rx => reg_axi_out(5),

    gt_refclk_p   => qsfp_d_clk_p,
    gt_refclk_n   => qsfp_d_clk_n,
    dclk          => xo_clk,
    gt_rxpolarity_0 => "1111",
    gt_txpolarity_0 => reg_axi_out(15 downto 12) --"0001"
);

  u_mms_common_reg : ENTITY common_lib.mms_common_reg
  PORT MAP (
     mm_clk       => mm_clk,
     mm_rst       => mm_rst,
     st_clk       => mm_clk,
     st_rst       => mm_rst,

     reg_mosi     => reg_mosi_arr(0),
     reg_miso     => reg_miso_arr(0),

     in_reg       => test_reg,
     out_reg      => test_reg
  );

  u_mms_gmi_board_sens_optics_l : ENTITY gmi_board_lib.mms_gmi_board_sens
  GENERIC MAP (
    g_sim             => g_sim,
    g_i2c_peripheral  => c_i2c_peripheral_optics_l,
    g_sens_nof_result => 40,
    g_clk_freq        => c_mm_clk_freq
  )
  PORT MAP (
    mm_clk       => mm_clk,
    mm_rst       => mm_rst,
    mm_start     => mm_board_sens_start,

    reg_mosi     => reg_mosi_arr(1),
    reg_miso     => reg_miso_arr(1),
    -- i2c bus
    scl          => optics_l_scl,
    sda          => optics_l_sda
  );

  u_reg_mux : ENTITY common_lib.common_mem_mux
  GENERIC MAP (
    g_nof_mosi    => 2,
    g_mult_addr_w => 6
  )
  PORT MAP (
    mosi     => reg_axi_mosi,
    miso     => reg_axi_miso,
    mosi_arr => reg_mosi_arr,
    miso_arr => reg_miso_arr
  );
END str;
