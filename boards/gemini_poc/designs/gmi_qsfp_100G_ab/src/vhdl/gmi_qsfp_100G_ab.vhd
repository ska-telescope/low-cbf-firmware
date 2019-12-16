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

ENTITY gmi_qsfp_100G_ab IS
  GENERIC (
    g_design_name   : STRING  := "gmi_qsfp_100G_ab";
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
    
    qsfp_a_mod_prs_n  : in std_logic;
    qsfp_a_reset      : out std_logic;
    qsfp_a_clk_p      : in std_logic;                              -- 161.13MHz reference
    qsfp_a_clk_n      : in std_logic;
    qsfp_a_tx_p       : out std_logic_vector(3 downto 0);
    qsfp_a_tx_n       : out std_logic_vector(3 downto 0);
    qsfp_a_rx_p       : in std_logic_vector(3 downto 0);
    qsfp_a_rx_n       : in std_logic_vector(3 downto 0);

    qsfp_b_mod_prs_n  : in std_logic;
    qsfp_b_reset      : out std_logic;
    qsfp_b_clk_p      : in std_logic;                              -- 161.13MHz reference
    qsfp_b_clk_n      : in std_logic;
    qsfp_b_tx_p       : out std_logic_vector(3 downto 0);
    qsfp_b_tx_n       : out std_logic_vector(3 downto 0);
    qsfp_b_rx_p       : in std_logic_vector(3 downto 0);
    qsfp_b_rx_n       : in std_logic_vector(3 downto 0);

    --qsfp_c_mod_prs_n  : in std_logic;
    qsfp_c_reset      : out std_logic;
    --qsfp_c_clk_p      : in std_logic;                              -- 161.13MHz reference
    --qsfp_c_clk_n      : in std_logic;
    --qsfp_c_tx_p       : out std_logic_vector(3 downto 0);
    --qsfp_c_tx_n       : out std_logic_vector(3 downto 0);
    --qsfp_c_rx_p       : in std_logic_vector(3 downto 0);
    --qsfp_c_rx_n       : in std_logic_vector(3 downto 0);

    --qsfp_d_mod_prs_n  : in std_logic;
    qsfp_d_reset      : out std_logic
    --qsfp_d_clk_p      : in std_logic;                              -- 161.13MHz reference
    --qsfp_d_clk_n      : in std_logic;
    --qsfp_d_tx_p       : out std_logic_vector(3 downto 0);
    --qsfp_d_tx_n       : out std_logic_vector(3 downto 0);
    --qsfp_d_rx_p       : in std_logic_vector(3 downto 0);
    --qsfp_d_rx_n       : in std_logic_vector(3 downto 0)
    
  );
END gmi_qsfp_100G_ab;

ARCHITECTURE str OF gmi_qsfp_100G_ab IS

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
  SIGNAL nof_packets            : STD_LOGIC_VECTOR(31 downto 0);
  
  SIGNAL reg_axi_mosi           : t_mem_mosi;
  SIGNAL reg_axi_miso           : t_mem_miso;
  SIGNAL reg_mosi_arr           : t_mem_mosi_arr(1 DOWNTO 0);
  SIGNAL reg_miso_arr           : t_mem_miso_arr(1 DOWNTO 0);

  SIGNAL qsfp_a_axi_araddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
  SIGNAL qsfp_a_axi_arready : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_arvalid : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_awaddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
  SIGNAL qsfp_a_axi_awready : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_awvalid : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_bready  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_bresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL qsfp_a_axi_bvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_rdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
  SIGNAL qsfp_a_axi_rready  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_rresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL qsfp_a_axi_rvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_wdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
  SIGNAL qsfp_a_axi_wready  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_a_axi_wstrb   : STD_LOGIC_VECTOR ( 3 downto 0 );
  SIGNAL qsfp_a_axi_wvalid  : STD_LOGIC_VECTOR ( 0 to 0 );

  SIGNAL qsfp_b_axi_araddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
  SIGNAL qsfp_b_axi_arready : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_arvalid : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_awaddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
  SIGNAL qsfp_b_axi_awready : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_awvalid : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_bready  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_bresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL qsfp_b_axi_bvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_rdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
  SIGNAL qsfp_b_axi_rready  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_rresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
  SIGNAL qsfp_b_axi_rvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_wdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
  SIGNAL qsfp_b_axi_wready  : STD_LOGIC_VECTOR ( 0 to 0 );
  SIGNAL qsfp_b_axi_wstrb   : STD_LOGIC_VECTOR ( 3 downto 0 );
  SIGNAL qsfp_b_axi_wvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
    

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

component cmac_usplus_100G_qsfp_a_0_exdes is
port (
    gt0_rxp_in  : in std_logic;
    gt0_rxn_in  : in std_logic;
    gt1_rxp_in  : in std_logic;
    gt1_rxn_in  : in std_logic;
    gt2_rxp_in  : in std_logic;
    gt2_rxn_in  : in std_logic;
    gt3_rxp_in  : in std_logic;
    gt3_rxn_in  : in std_logic;
    gt0_txn_out : out std_logic;
    gt0_txp_out : out std_logic;
    gt1_txn_out : out std_logic;
    gt1_txp_out : out std_logic;
    gt2_txn_out : out std_logic;
    gt2_txp_out : out std_logic;
    gt3_txn_out : out std_logic;
    gt3_txp_out : out std_logic;
    lbus_tx_rx_restart_in : in std_logic;

    tx_done_led : out std_logic;
    tx_busy_led : out std_logic;
    
    rx_gt_locked_led : out std_logic;
    rx_aligned_led   : out std_logic;
    rx_done_led      : out std_logic;
    rx_data_fail_led : out std_logic;
    rx_busy_led      : out std_logic;

    sys_reset     : in std_logic;
    s_axi_pm_tick : in std_logic;

    gt_ref_clk_p : in std_logic;
    gt_ref_clk_n : in std_logic;
    init_clk     : in std_logic;

    gt_rxpolarity : in STD_LOGIC_VECTOR (3 downto 0);
    gt_txpolarity : in STD_LOGIC_VECTOR (3 downto 0);

    s_axi_araddr  : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_arready : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_arvalid : in  STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_awaddr  : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_awready : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_awvalid : in  STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_bready  : in  STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_bresp   : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_bvalid  : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_rdata   : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_rready  : in  STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_rresp   : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_rvalid  : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_wdata   : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_wready  : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_wstrb   : in  STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_wvalid  : in  STD_LOGIC_VECTOR ( 0 to 0 );
    
    sanity_init_done : in std_logic;
    pause_init_done  : in std_logic;
    nof_packets      : in std_logic_vector(31 downto 0)
);
end component cmac_usplus_100G_qsfp_a_0_exdes;

component cmac_usplus_100G_qsfp_b_0_exdes is
port (
    gt0_rxp_in  : in std_logic;
    gt0_rxn_in  : in std_logic;
    gt1_rxp_in  : in std_logic;
    gt1_rxn_in  : in std_logic;
    gt2_rxp_in  : in std_logic;
    gt2_rxn_in  : in std_logic;
    gt3_rxp_in  : in std_logic;
    gt3_rxn_in  : in std_logic;
    gt0_txn_out : out std_logic;
    gt0_txp_out : out std_logic;
    gt1_txn_out : out std_logic;
    gt1_txp_out : out std_logic;
    gt2_txn_out : out std_logic;
    gt2_txp_out : out std_logic;
    gt3_txn_out : out std_logic;
    gt3_txp_out : out std_logic;
    lbus_tx_rx_restart_in : in std_logic;

    tx_done_led : out std_logic;
    tx_busy_led : out std_logic;
    
    rx_gt_locked_led : out std_logic;
    rx_aligned_led   : out std_logic;
    rx_done_led      : out std_logic;
    rx_data_fail_led : out std_logic;
    rx_busy_led      : out std_logic;

    sys_reset     : in std_logic;
    s_axi_pm_tick : in std_logic;

    gt_ref_clk_p : in std_logic;
    gt_ref_clk_n : in std_logic;
    init_clk     : in std_logic;

    gt_rxpolarity : in STD_LOGIC_VECTOR (3 downto 0);
    gt_txpolarity : in STD_LOGIC_VECTOR (3 downto 0);

    s_axi_araddr  : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_arready : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_arvalid : in  STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_awaddr  : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_awready : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_awvalid : in  STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_bready  : in  STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_bresp   : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_bvalid  : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_rdata   : out STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_rready  : in  STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_rresp   : out STD_LOGIC_VECTOR ( 1 downto 0 );
    s_axi_rvalid  : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_wdata   : in  STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axi_wready  : out STD_LOGIC_VECTOR ( 0 to 0 );
    s_axi_wstrb   : in  STD_LOGIC_VECTOR ( 3 downto 0 );
    s_axi_wvalid  : in  STD_LOGIC_VECTOR ( 0 to 0 );
  
    sanity_init_done : in std_logic;
    pause_init_done  : in std_logic;
    nof_packets      : in std_logic_vector(31 downto 0)
);
end component cmac_usplus_100G_qsfp_b_0_exdes;

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
    M03_AXI_araddr  => qsfp_a_axi_araddr,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    --M03_AXI_arprot => (others => '0'),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_arready => qsfp_a_axi_arready,--(others => '1'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_arvalid => qsfp_a_axi_arvalid,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_awaddr  => qsfp_a_axi_awaddr,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    --M03_AXI_awprot => (others => '0'),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    M03_AXI_awready => qsfp_a_axi_awready,--(others => '1'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_awvalid => qsfp_a_axi_awvalid,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bready  => qsfp_a_axi_bready,--(others => '1'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_bresp   => qsfp_a_axi_bresp,--(others => '0'), --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_bvalid  => qsfp_a_axi_bvalid,--(others => '0'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rdata   => qsfp_a_axi_rdata,--(others => '0'), --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_rready  => qsfp_a_axi_rready,--(others => '1'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_rresp   => qsfp_a_axi_rresp,--(others => '0'), --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    M03_AXI_rvalid  => qsfp_a_axi_rvalid,--(others => '0'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_wdata   => qsfp_a_axi_wdata,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    M03_AXI_wready  => qsfp_a_axi_wready,--(others => '1'),--: in STD_LOGIC_VECTOR ( 0 to 0 );
    M03_AXI_wstrb   => qsfp_a_axi_wstrb,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 3 downto 0 );
    M03_AXI_wvalid  => qsfp_a_axi_wvalid,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    
    M04_AXI_araddr  => qsfp_b_axi_araddr,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    --M04_AXI_arprot => (others => '0'),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_arready => qsfp_b_axi_arready,--(others => '1'),--: in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_arvalid => qsfp_b_axi_arvalid,--(others => '0'), --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_awaddr  => qsfp_b_axi_awaddr,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    --M04_AXI_awprot => (others => '0'),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    M04_AXI_awready => qsfp_b_axi_awready,--(others => '1'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_awvalid => qsfp_b_axi_awvalid,--(others => '0'), --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bready  => qsfp_b_axi_bready,--(others => '1'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_bresp   => qsfp_b_axi_bresp,--(others => '0'), --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_bvalid  => qsfp_b_axi_bvalid,--(others => '0'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rdata   => qsfp_b_axi_rdata,--(others => '0'), --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_rready  => qsfp_b_axi_rready,--(others => '1'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_rresp   => qsfp_b_axi_rresp,--(others => '0'), --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    M04_AXI_rvalid  => qsfp_b_axi_rvalid,--(others => '0'), --: in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_wdata   => qsfp_b_axi_wdata,--(others => '0'),   --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    M04_AXI_wready  => qsfp_b_axi_wready,--(others => '1'),--: in STD_LOGIC_VECTOR ( 0 to 0 );
    M04_AXI_wstrb   => qsfp_b_axi_wstrb,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 3 downto 0 );
    M04_AXI_wvalid  => qsfp_b_axi_wvalid,--(others => '0'),  --: out STD_LOGIC_VECTOR ( 0 to 0 );
    
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

    nof_packets <= reg_axi_out(63 downto 32);
    reg_axi_in(63 downto 32) <= nof_packets;

 u_cmac_usplus_100G_qsfp_a_0_exdes : cmac_usplus_100G_qsfp_a_0_exdes
  port map (
    gt0_rxp_in => qsfp_a_rx_p(0),
    gt0_rxn_in => qsfp_a_rx_n(0), 
    gt1_rxp_in => qsfp_a_rx_p(1), 
    gt1_rxn_in => qsfp_a_rx_n(1), 
    gt2_rxp_in => qsfp_a_rx_p(2), 
    gt2_rxn_in => qsfp_a_rx_n(2), 
    gt3_rxp_in => qsfp_a_rx_p(3), 
    gt3_rxn_in => qsfp_a_rx_n(3), 

    gt0_txn_out => qsfp_a_tx_n(0),
    gt0_txp_out => qsfp_a_tx_p(0),
    gt1_txn_out => qsfp_a_tx_n(1),
    gt1_txp_out => qsfp_a_tx_p(1),
    gt2_txn_out => qsfp_a_tx_n(2),
    gt2_txp_out => qsfp_a_tx_p(2),
    gt3_txn_out => qsfp_a_tx_n(3),
    gt3_txp_out => qsfp_a_tx_p(3),

    gt_ref_clk_p => qsfp_a_clk_p,
    gt_ref_clk_n => qsfp_a_clk_n,

    lbus_tx_rx_restart_in => reg_axi_out(5),

    tx_done_led => reg_axi_in(8),
    tx_busy_led => reg_axi_in(9),
    rx_gt_locked_led => reg_axi_in(10),
    rx_aligned_led   => reg_axi_in(11),
    rx_done_led      => reg_axi_in(12),
    rx_data_fail_led => reg_axi_in(13),
    rx_busy_led      => reg_axi_in(14),

    sys_reset     => mm_rst,
    s_axi_pm_tick  => mm_board_sens_start,

    init_clk      => clk125,
    gt_rxpolarity => "0000",
    gt_txpolarity => "1111",

    s_axi_araddr  => qsfp_a_axi_araddr  ,
    s_axi_arready => qsfp_a_axi_arready ,
    s_axi_arvalid => qsfp_a_axi_arvalid ,
    s_axi_awaddr  => qsfp_a_axi_awaddr  ,
    s_axi_awready => qsfp_a_axi_awready ,
    s_axi_awvalid => qsfp_a_axi_awvalid ,
    s_axi_bready  => qsfp_a_axi_bready  ,
    s_axi_bresp   => qsfp_a_axi_bresp   ,
    s_axi_bvalid  => qsfp_a_axi_bvalid  ,
    s_axi_rdata   => qsfp_a_axi_rdata   ,
    s_axi_rready  => qsfp_a_axi_rready  ,
    s_axi_rresp   => qsfp_a_axi_rresp   ,
    s_axi_rvalid  => qsfp_a_axi_rvalid  ,
    s_axi_wdata   => qsfp_a_axi_wdata   ,
    s_axi_wready  => qsfp_a_axi_wready  ,
    s_axi_wstrb   => qsfp_a_axi_wstrb   ,
    s_axi_wvalid  => qsfp_a_axi_wvalid  ,
    
    sanity_init_done => reg_axi_out(8),
    pause_init_done  => reg_axi_out(9),

    nof_packets      => nof_packets
  );
 u_cmac_usplus_100G_qsfp_b_0_exdes : cmac_usplus_100G_qsfp_b_0_exdes
  port map (
    gt0_rxp_in => qsfp_b_rx_p(0),
    gt0_rxn_in => qsfp_b_rx_n(0), 
    gt1_rxp_in => qsfp_b_rx_p(1), 
    gt1_rxn_in => qsfp_b_rx_n(1), 
    gt2_rxp_in => qsfp_b_rx_p(2), 
    gt2_rxn_in => qsfp_b_rx_n(2), 
    gt3_rxp_in => qsfp_b_rx_p(3), 
    gt3_rxn_in => qsfp_b_rx_n(3), 

    gt0_txn_out => qsfp_b_tx_n(0),
    gt0_txp_out => qsfp_b_tx_p(0),
    gt1_txn_out => qsfp_b_tx_n(1),
    gt1_txp_out => qsfp_b_tx_p(1),
    gt2_txn_out => qsfp_b_tx_n(2),
    gt2_txp_out => qsfp_b_tx_p(2),
    gt3_txn_out => qsfp_b_tx_n(3),
    gt3_txp_out => qsfp_b_tx_p(3),

    gt_ref_clk_p => qsfp_b_clk_p,
    gt_ref_clk_n => qsfp_b_clk_n,

    lbus_tx_rx_restart_in => reg_axi_out(6),

    tx_done_led => reg_axi_in(16),
    tx_busy_led => reg_axi_in(17),
    rx_gt_locked_led => reg_axi_in(18),
    rx_aligned_led   => reg_axi_in(19),
    rx_done_led      => reg_axi_in(20),
    rx_data_fail_led => reg_axi_in(21),
    rx_busy_led      => reg_axi_in(22),

    sys_reset     => mm_rst,
    s_axi_pm_tick => mm_board_sens_start,

    init_clk      => clk125,
    gt_rxpolarity => "1111",
    gt_txpolarity => "0100",

    s_axi_araddr  => qsfp_b_axi_araddr  ,
    s_axi_arready => qsfp_b_axi_arready ,
    s_axi_arvalid => qsfp_b_axi_arvalid ,
    s_axi_awaddr  => qsfp_b_axi_awaddr  ,
    s_axi_awready => qsfp_b_axi_awready ,
    s_axi_awvalid => qsfp_b_axi_awvalid ,
    s_axi_bready  => qsfp_b_axi_bready  ,
    s_axi_bresp   => qsfp_b_axi_bresp   ,
    s_axi_bvalid  => qsfp_b_axi_bvalid  ,
    s_axi_rdata   => qsfp_b_axi_rdata   ,
    s_axi_rready  => qsfp_b_axi_rready  ,
    s_axi_rresp   => qsfp_b_axi_rresp   ,
    s_axi_rvalid  => qsfp_b_axi_rvalid  ,
    s_axi_wdata   => qsfp_b_axi_wdata   ,
    s_axi_wready  => qsfp_b_axi_wready  ,
    s_axi_wstrb   => qsfp_b_axi_wstrb   ,
    s_axi_wvalid  => qsfp_b_axi_wvalid,
  
    sanity_init_done => reg_axi_out(12),
    pause_init_done  => reg_axi_out(13),
    nof_packets      => nof_packets
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
