-------------------------------------------------------------------------------
-- Title      : WRPC reference design for LRU 
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : lru_wr_exdes_top.vhd (based on spec_wr_ref_top.vhd)
-- Author(s)  : Grzegorz Daniluk <grzegorz.daniluk@cern.ch>
-- Company    : CERN (BE-CO-HT)
-- Created    : 2017-02-20
-- Last update: 2017-03-10
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Top-level file for the WRPC reference design on the SPEC.
--
-- This is a reference top HDL that instanciates the WR PTP Core together with
-- its peripherals to be run on a SPEC card.
--
-- There are two main usecases for this HDL file:
-- * let new users easily synthesize a WR PTP Core bitstream that can be run on
--   reference hardware
-- * provide a reference top HDL file showing how the WRPC can be instantiated
--   in HDL projects.
--
-- SPEC:  http://www.ohwr.org/projects/spec/
--
-------------------------------------------------------------------------------
-- Copyright (c) 2017 CERN
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- either version 2.1 of the License, or (at your option) any
-- later version.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE.  See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work, general_cores_lib, etherbone_lib, wrpc_lib;
use general_cores_lib.gencores_pkg.all;
use general_cores_lib.wishbone_pkg.all;
use wrpc_lib.wr_board_pkg.all;
use wrpc_lib.streamers_pkg.all;
--use wrpc_lib.wr_spec_pkg.all;
--use work.gn4124_core_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity lru_wr_exdes_top is
  generic (
    g_dpram_initf : string := "C:/SKA/Firmware/libraries/external/white_rabbit/wrpc/src/vhdl/bin/wrpc/wrc_phy16.bram";
    -- Simulation-mode enable parameter. Set by default (synthesis) to 0, and
    -- changed to non-zero in the instantiation of the top level DUT in the testbench.
    -- Its purpose is to reduce some internal counters/timeouts to speed up simulations.
    g_simulation : integer := 0
  );
  port (
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------

    -- Local oscillators
    -- clk_20m_vcxo_i : in std_logic;                -- 20MHz VCXO clock
    clk_f : in std_logic;                -- 20MHz VCXO clock

    -- clk_125m_pllref_p_i : in std_logic;           -- 125 MHz PLL reference
    clk_e_p : in std_logic;           -- 125 MHz PLL reference
    clk_e_n : in std_logic;
    
    sfp_clk_e_n : in std_logic;
    -- clk_125m_pllref_n_i : in std_logic;
    sfp_clk_e_p : in std_logic;
    -- clk_125m_gtp_n_i : in std_logic;              -- 125 MHz GTY reference
    -- clk_125m_gtp_p_i : in std_logic;

    ---------------------------------------------------------------------------
    -- GN4124 PCIe bridge signals
    ---------------------------------------------------------------------------
    -- From GN4124 Local bus
--    gn_rst_n : in std_logic; -- Reset from GN4124 (RSTOUT18_N)
--    -- PCIe to Local [Inbound Data] - RX
--    gn_p2l_clk_n  : in  std_logic;       -- Receiver Source Synchronous Clock-
--    gn_p2l_clk_p  : in  std_logic;       -- Receiver Source Synchronous Clock+
--    gn_p2l_rdy    : out std_logic;       -- Rx Buffer Full Flag
--    gn_p2l_dframe : in  std_logic;       -- Receive Frame
--    gn_p2l_valid  : in  std_logic;       -- Receive Data Valid
--    gn_p2l_data   : in  std_logic_vector(15 downto 0);  -- Parallel receive data
--    -- Inbound Buffer Request/Status
--    gn_p_wr_req   : in  std_logic_vector(1 downto 0);  -- PCIe Write Request
--    gn_p_wr_rdy   : out std_logic_vector(1 downto 0);  -- PCIe Write Ready
--    gn_rx_error   : out std_logic;                     -- Receive Error
--    -- Local to Parallel [Outbound Data] - TX
--    gn_l2p_clkn   : out std_logic;       -- Transmitter Source Synchronous Clock-
--    gn_l2p_clkp   : out std_logic;       -- Transmitter Source Synchronous Clock+
--    gn_l2p_dframe : out std_logic;       -- Transmit Data Frame
--    gn_l2p_valid  : out std_logic;       -- Transmit Data Valid
--    gn_l2p_edb    : out std_logic;       -- Packet termination and discard
--    gn_l2p_data   : out std_logic_vector(15 downto 0);  -- Parallel transmit data
--    -- Outbound Buffer Status
--    gn_l2p_rdy    : in std_logic;                     -- Tx Buffer Full Flag
--    gn_l_wr_rdy   : in std_logic_vector(1 downto 0);  -- Local-to-PCIe Write
--    gn_p_rd_d_rdy : in std_logic_vector(1 downto 0);  -- PCIe-to-Local Read Response Data Ready
--    gn_tx_error   : in std_logic;                     -- Transmit Error
--    gn_vc_rdy     : in std_logic_vector(1 downto 0);  -- Channel ready
--    -- General Purpose Interface
--    gn_gpio : inout std_logic_vector(1 downto 0);  -- gn_gpio[0] -> GN4124 GPIO8
--                                                   -- gn_gpio[1] -> GN4124 GPIO9
    ---------------------------------------------------------------------------
    -- SPI interface to DACs
    -- A typical SPI bus shared betwen two AD5662 DACs. The first one (CS1) tunes
    -- the clk_ref oscillator, the second (CS2) - the clk_dmtd VCXO.
    ---------------------------------------------------------------------------
    ptp_clk_sel : out std_logic;
    -- plldac_sclk_o     : out std_logic;
    ptp_sclk            : out std_logic;
    -- plldac_din_o      : out std_logic;
    ptp_din             : out std_logic;
    
    -- pll25dac_cs_n_o : out std_logic; --cs1
    -- pll20dac_cs_n_o : out std_logic; --cs2
    ptp_sync_n          : out std_logic_vector(1 downto 0);
    ---------------------------------------------------------------------------
    -- SFP I/O for transceiver
    ---------------------------------------------------------------------------

    -- sfp_txp_o         : out   std_logic;
    sfp_tx_p         : out   std_logic;
    -- sfp_txn_o         : out   std_logic;
    sfp_tx_n         : out   std_logic;
    -- sfp_rxp_i         : in    std_logic;
    sfp_rx_p         : in    std_logic;
    -- sfp_rxn_i         : in    std_logic;
    sfp_rx_n         : in    std_logic;
    -- sfp_mod_def0_i    : in    std_logic;          -- sfp detect
    sfp_mod_abs : in    std_logic;          -- sfp detect
    -- sfp_mod_def1_b    : inout std_logic;          -- scl
    sfp_scl           : inout std_logic; -- driven through i2c mux chip from FPGA
    -- sfp_mod_def2_b    : inout std_logic;          -- sda
    sfp_sda           : inout std_logic; -- driven through i2c mux chip from FPGA
--    sfp_rate_select_o : out   std_logic; -- MIA: add back in
    -- sfp_tx_fault_i    : in    std_logic;
    sfp_fault         : in std_logic;
    -- sfp_tx_disable_o  : out   std_logic;
    sfp_tx_enable  : out   std_logic; -- misnomer, according to lru_test.vhd, actually active high disable? 
    -- sfp_los_i         : in    std_logic; -- not used in this design

    
    ---------------------------------------------------------------------------
    -- Onewire interface
    ---------------------------------------------------------------------------

    -- onewire_b : inout std_logic;

    ---------------------------------------------------------------------------
    -- UART
    ---------------------------------------------------------------------------

    -- uart_rxd_i : in  std_logic;
    debug_pair0 : in std_logic_vector(1 downto 0);
    -- uart_txd_o : out std_logic;
    debug_pair1 : out std_logic_vector(1 downto 0);
    ---------------------------------------------------------------------------
    -- Flash memory SPI interface - for storing device's config data like MAC address and calibration aprameters 
    ---------------------------------------------------------------------------

    -- flash_sclk_o : out std_logic;
    -- flash_ncs_o  : out std_logic;
    -- flash_mosi_o : out std_logic;
    -- flash_miso_i : in  std_logic;

    ---------------------------------------------------------------------------
    -- Miscellanous SPEC pins
    ---------------------------------------------------------------------------
    -- Red LED next to the SFP: blinking indicates that packets are being
    -- transferred.
    -- led_act_o   : out std_logic;
    qsfp_a_led   : out std_logic; -- hijacked for lack of another LED 
    -- Green LED next to the SFP: indicates if the link is up.
    -- led_link_o : out std_logic;
    sfp_led : out std_logic;

    button1_i   : in  std_logic;

    ---------------------------------------------------------------------------
    -- Digital I/O FMC Pins
    -- used in this design to output WR-aligned 1-PPS (in Slave mode) and input
    -- 10MHz & 1-PPS from external reference (in GrandMaster mode).
    ---------------------------------------------------------------------------

    -- Clock input from LEMO 5 on the mezzanine front panel. Used as 10MHz
    -- -- external reference input.
    -- dio_clk_p_i : in std_logic;
    -- dio_clk_n_i : in std_logic;

    -- Differential inputs, dio_p_i(N) inputs the current state of I/O (N+1) on
    -- the mezzanine front panel.
    -- dio_n_i : in std_logic_vector(4 downto 0);
    -- dio_p_i : in std_logic_vector(4 downto 0);

    -- Differential outputs. When the I/O (N+1) is configured as output (i.e. when
    -- dio_oe_n_o(N) = 0), the value of dio_p_o(N) determines the logic state
    -- of I/O (N+1) on the front panel of the mezzanine
    -- dio_n_o : out std_logic_vector(4 downto 0);
    -- dio_p_o : out std_logic_vector(4 downto 0);

    -- Output enable. When dio_oe_n_o(N) is 0, connector (N+1) on the front
    -- panel is configured as an output.
    -- dio_oe_n_o    : out std_logic_vector(4 downto 0);

    -- Termination enable. When dio_term_en_o(N) is 1, connector (N+1) on the front
    -- panel is 50-ohm terminated
    -- dio_term_en_o : out std_logic_vector(4 downto 0);

    -- Two LEDs on the mezzanine panel. Only Top one is currently used - to
    -- blink 1-PPS.
    -- dio_led_top_o : out std_logic;
    qsfp_b_led: out std_logic
    -- dio_led_bot_o : out std_logic;

    -- I2C interface for accessing FMC EEPROM. Deprecated, was used in
    -- pre-v3.0 releases to store WRPC configuration. Now we use Flash for this.
    -- dio_scl_b : inout std_logic;
    -- dio_sda_b : inout std_logic

  );
end entity lru_wr_exdes_top;

architecture top of lru_wr_exdes_top is

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------

  -- Ethertype we are going to use for the streamer protocol. Value 0xdbff
  -- is default for standard WR Core CPU firmware. Other values need re-configuring
  -- the WR Core packet filter.
  constant c_STREAMER_ETHERTYPE : std_logic_vector(15 downto 0) := x"dbff";
  constant c_tx_streamer_cfg : t_tx_streamer_params := (data_width => 80, buffer_size => 256, threshold => 128, max_words_per_frame => 256, timeout => 1024, escape_code_disable => FALSE);
  constant c_rx_streamer_cfg : t_rx_streamer_params := (data_width => 80, buffer_size => 256, escape_code_disable => FALSE, expected_words_number => 0);
    -- Trigger-to-output value, in 8 ns ticks. Set by default to 20us to work
    -- for 10km+ fibers.
  constant c_PULSE_DELAY : integer := 30000/8;
  -- Number of masters on the wishbone crossbar
  constant c_NUM_WB_MASTERS : integer := 2;

  -- Number of slaves on the primary wishbone crossbar
  constant c_NUM_WB_SLAVES : integer := 1;

  -- Primary Wishbone master(s) offsets
  constant c_WB_MASTER_PCIE    : integer := 0;
  constant c_WB_MASTER_ETHBONE : integer := 0;

  -- Primary Wishbone slave(s) offsets
  constant c_WB_SLAVE_WRC : integer := 0;

  -- sdb header address on primary crossbar
  constant c_SDB_ADDRESS : t_wishbone_address := x"00040000";

  -- f_xwb_bridge_manual_sdb(size, sdb_addr)
  -- Note: sdb_addr is the sdb records address relative to the bridge base address
  constant c_wrc_bridge_sdb : t_sdb_bridge :=
    f_xwb_bridge_manual_sdb(x"0003ffff", x"00030000");

  -- Primary wishbone crossbar layout
--  constant c_WB_LAYOUT : t_sdb_record_array(c_NUM_WB_SLAVES - 1 downto 0) := (
--    c_WB_SLAVE_WRC => f_sdb_embed_bridge(c_wrc_bridge_sdb, x"00000000"));

COMPONENT vio_0
  PORT (
    clk : IN STD_LOGIC;
    probe_in0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe_in1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe_out1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;
    COMPONENT whiterabbit_gty_vio_0
      PORT (
        clk : IN STD_LOGIC;
        probe_in0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in3 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        probe_in4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in8 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_in10 : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
        probe_out0 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out4 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out5 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out6 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out7 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
      );
    END COMPONENT;


    
  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

--    signal pulse_delay : std_logic_vector()

    attribute mark_debug : string;

    -- clock and reset
    signal clk_sys_62m5   : std_logic;
    signal rst_sys_62m5_n : std_logic;
    signal rst_ref_125m_n : std_logic;
    signal clk_ref_125m   : std_logic;
    signal clk_ref_div2   : std_logic;
    -- signal clk_ext_10m    : std_logic;

    -- I2C EEPROM
    -- signal eeprom_sda_in  : std_logic;
    -- signal eeprom_sda_out : std_logic;
    -- signal eeprom_scl_in  : std_logic;
    -- signal eeprom_scl_out : std_logic;

    -- SFP
    signal sfp_sda_in  : std_logic;
    signal sfp_sda_out : std_logic;
    signal sfp_scl_in  : std_logic;
    signal sfp_scl_out : std_logic;

  -- OneWire
  -- signal onewire_data : std_logic;
  -- signal onewire_oe   : std_logic;

    -- LEDs and GPIO
    signal wrc_abscal_txts_out : std_logic;
    signal wrc_abscal_rxts_out : std_logic;
    signal wrc_pps_out : std_logic;
    signal wrc_pps_led : std_logic;

    signal wrc_pps_in  : std_logic;
    signal svec_led    : std_logic_vector(15 downto 0);

    -- DIO Mezzanine
    signal dio_in  : std_logic_vector(4 downto 0);
    signal dio_out : std_logic_vector(4 downto 0);

    
    -- WR Streamers
  
    -- TX streamer signals
    signal tx_tag_tai                    : std_logic_vector(39 downto 0);
    signal tx_tag_cycles                 : std_logic_vector(27 downto 0);
    signal tx_tag_valid                  : std_logic;
    signal tx_data                       : std_logic_vector(79 downto 0);
    signal tx_valid, tx_dreq, tx_dreq_d0 : std_logic;
  
    -- RX streamer signals
    signal rx_data  : std_logic_vector(79 downto 0);
    signal rx_valid : std_logic;  
    signal rx_latency       : std_logic_vector(27 downto 0);
    signal rx_latency_valid : std_logic;
    
    -- Timing interface  
    signal tm_link_up           : std_logic;
    signal tm_time_valid        : std_logic;
    signal tm_tai               : std_logic_vector(39 downto 0);
    signal tm_cycles            : std_logic_vector(27 downto 0);
 
    -- Trigger timestamp adjusted with delay
    signal adjusted_ts_valid  : std_logic;
    signal adjusted_ts_tai    : std_logic_vector(39 downto 0);
    signal adjusted_ts_cycles : std_logic_vector(27 downto 0); 
    
    -- pulse generation
    signal pulse_out, pulse_in_synced            : std_logic;
    signal pulse_vio_in                         : std_logic;
    -- signal
    
    signal rst_n                : std_logic;
    signal clk_20m_vcxo_buf     : std_logic;
    
    attribute mark_debug of wrc_pps_led : signal is "true";
begin  -- architecture top

inst_vio : vio_0
  PORT MAP (
    clk => clk_sys_62m5,
    probe_in0(0) => '1',
    probe_in1(0) => '1',
    probe_out0(0) => rst_n,
    probe_out1(0) => pulse_vio_in
  );
  -----------------------------------------------------------------------------
  -- Trigger distribution stuff - timestamping & packet transmission part
  -----------------------------------------------------------------------------
  ptp_clk_sel <= '0'; -- low for 125 MHz
  U_Pulse_Stamper : ENTITY wrpc_lib.pulse_stamper
    generic map (
        g_ref_clk_rate => 125000000)
    port map (
        clk_ref_i => clk_ref_125m,
        clk_sys_i => clk_sys_62m5,
        rst_n_i   => rst_n,
        pulse_a_i => pulse_vio_in,           -- I/O 2 = our pulse input

        tm_time_valid_i => tm_time_valid,  -- timing ports of the WR Core
        tm_tai_i        => tm_tai,
        tm_cycles_i     => tm_cycles,

        tag_tai_o    => tx_tag_tai,       -- time tag of the latest pulse
        tag_cycles_o => tx_tag_cycles,
        tag_valid_o  => tx_tag_valid);



    -- Pack the time stamp into a 80-bit data word for the streamer
    tx_data(27 downto 0)       <= tx_tag_cycles;
    tx_data(32 + 39 downto 32) <= tx_tag_tai;
    -- avoid Xes (this may break simulations)
    tx_data(31 downto 28)      <= (others => '0');
    tx_data(79 downto 32+40)   <= (others => '0');

    -- Data valid signal: simply drop the timestamp if the streamer can't accept
    -- data for the moment.
    tx_valid <= tx_dreq_d0 and tx_tag_valid;

    -- tx_dreq_o output of the streamer is asserted one clock cycle in advance,
    -- while the line above drives the valid signal combinatorially. We need a delay.
    process(clk_sys_62m5)
    begin
    if rising_edge(clk_sys_62m5) then
      tx_dreq_d0 <= tx_dreq;
    end if;
    end process;

  
  -----------------------------------------------------------------------------
  -- Trigger distribution stuff - packet reception and pulse generation
  -----------------------------------------------------------------------------  
    -- Add a fixed delay to the reveived trigger timestamp
    U_Add_Delay1 : ENTITY wrpc_lib.timestamp_adder
    generic map (
        g_ref_clk_rate => 125000000,
        g_tai_bits => 40)
    port map (
        clk_i   => clk_sys_62m5,
        rst_n_i => rst_n,
        valid_i => rx_valid,

        a_tai_i    => rx_data(32 + 39 downto 32),
        a_cycles_i => rx_data(27 downto 0),

        b_tai_i    => (others => '0'),
        b_cycles_i => std_logic_vector(to_unsigned(c_PULSE_DELAY, 28)),

        valid_o    => adjusted_ts_valid,
        q_tai_o    => adjusted_ts_tai,
        q_cycles_o => adjusted_ts_cycles);
        
    -- And a pulse generator that produces a pulse at a time received by the
    -- streamer above adjusted with the delay
    U_Pulse_Generator : ENTITY wrpc_lib.pulse_gen
    generic map (
        g_ref_clk_rate => 125000000)
    port map (
        clk_ref_i       => clk_ref_125m,
        clk_sys_i       => clk_sys_62m5,
        rst_n_i         => rst_n,
        pulse_o         => pulse_out,
        tm_time_valid_i => tm_time_valid,
        tm_tai_i        => tm_tai,
        tm_cycles_i     => tm_cycles,
        trig_tai_i      => adjusted_ts_tai,
        trig_cycles_i   => adjusted_ts_cycles,
        trig_valid_i    => adjusted_ts_valid);

    -- pulse_gen above generates pulses that are single-cycle long. This is too
    -- short to observe on a scope, particularly with slower time base (to see 2
    -- pulses simulatenously). Let's extend it a bit:
    U_Extend_Output_Pulse : ENTITY general_cores_lib.gc_extend_pulse
    generic map (
      -- 1000 * 8ns = 8 us
        g_width => 1000)
    port map (
        clk_i      => clk_ref_125m,
        rst_n_i    => rst_n,
        pulse_i    => pulse_out,
        extended_o => open ); --debug_pair(1));        
        
    -----------------------------------------------------------------------------
  -- The WR PTP core board package (WB Slave + WB Master #2 (Etherbone))
  -----------------------------------------------------------------------------

  -- A global clock buffer to drive the PLL input pin from the 20 MHz VCXO clock
  -- input pin on the FPGA
  U_DMTD_VCXO_Clock_Buffer : BUFG
    port map (
      O => clk_20m_vcxo_buf,
      I => clk_f);

  
  cmp_xwrc_board_lru : ENTITY wrpc_lib.xwrc_board_lru
    generic map (
      g_simulation                => g_simulation,
      g_with_external_clock_input => TRUE,
      g_dpram_initf               => g_dpram_initf,
      g_fabric_iface              => STREAMERS, 
      g_rx_streamer_params        => c_rx_streamer_cfg,
      g_tx_streamer_params        => c_tx_streamer_cfg)
    port map (
      areset_n_i          => '1', --button1_i,
      areset_edge_n_i     => rst_n, -- MIA: change to JTAG  VIO 
      clk_20m_vcxo_i      => clk_20m_vcxo_buf,
       clk_125m_pllref_p_i => clk_e_p,
       clk_125m_pllref_n_i => clk_e_n,
      clk_125m_gtp_n_i    => sfp_clk_e_n, --clk_125m_gtp_n_i,
      clk_125m_gtp_p_i    => sfp_clk_e_p, --clk_125m_gtp_p_i,
      clk_10m_ext_i       => '0', --clk_ext_10m,
      clk_sys_62m5_o      => clk_sys_62m5,
      clk_ref_125m_o      => clk_ref_125m,
      rst_sys_62m5_n_o    => rst_sys_62m5_n,
      rst_ref_125m_n_o    => rst_ref_125m_n,

      plldac_sclk_o       => ptp_sclk,
      plldac_din_o        => ptp_din,
      pll25dac_cs_n_o     => ptp_sync_n(0), --pll25dac_cs_n_o,
      pll20dac_cs_n_o     => ptp_sync_n(1), --pll20dac_cs_n_o,

      sfp_txp_o           => sfp_tx_p,
      sfp_txn_o           => sfp_tx_n,
      sfp_rxp_i           => sfp_rx_p,
      sfp_rxn_i           => sfp_rx_n,
      sfp_det_i           => sfp_mod_abs,
      sfp_sda_i           => sfp_sda_in,
      sfp_sda_o           => sfp_sda_out,
      sfp_scl_i           => sfp_scl_in,
      sfp_scl_o           => sfp_scl_out,
      sfp_rate_select_o   => open, --sfp_rate_select_o,
      sfp_tx_fault_i      => sfp_fault,
      sfp_tx_disable_o    => open, --sfp_tx_enable,
      sfp_los_i           => '0',--sfp_los_i, serdes held in reset if this is high 

      eeprom_sda_i        => '0',
      eeprom_sda_o        => open,
      eeprom_scl_i        => '0',
      eeprom_scl_o        => open,

      onewire_i           => '0',
      onewire_oen_o       => open,
      -- Uart
      uart_rxd_i          => debug_pair0(0), --uart_rxd_i,
      uart_txd_o          => debug_pair1(0), --uart_txd_o,
      -- SPI Flash
      flash_sclk_o        => open, --flash_sclk_o,
      flash_ncs_o         => open, --flash_ncs_o,
      flash_mosi_o        => open, --flash_mosi_o,
      flash_miso_i        => '0', --flash_miso_i,

--      wb_slave_o          => cnx_slave_out(c_WB_SLAVE_WRC),
--      wb_slave_i          => cnx_slave_in(c_WB_SLAVE_WRC),

      -- wb_eth_master_o     => cnx_master_out(c_WB_MASTER_ETHBONE),
      -- wb_eth_master_i     => cnx_master_in(c_WB_MASTER_ETHBONE),
      
    ---------------------------------------------------------------------------
    -- WR streamers (when g_fabric_iface = "streamers")
    ---------------------------------------------------------------------------
    wrs_tx_data_i        => tx_data,
    wrs_tx_valid_i       => tx_valid,
    wrs_tx_dreq_o        => tx_dreq,
    -- wrs_tx_last_i        => , -- internally set to 1 
    -- wrs_tx_flush_i       => , -- internally set to 0
    -- wrs_tx_cfg_i         => , internally set to c_tx_streamer_cfg_default
    wrs_rx_first_o       => open,
    wrs_rx_last_o        => open,
    wrs_rx_data_o        => rx_data,
    wrs_rx_valid_o       => rx_valid,
    wrs_rx_dreq_i        => '1',
    -- wrs_rx_cfg_i         => , internally set to c_rx_streamer_cfg_default
      
          
    -----------------------------------------
    -- Timestamp helper signals, used for Absolute Calibration
    -----------------------------------------      
      abscal_txts_o       => wrc_abscal_txts_out,
      abscal_rxts_o       => wrc_abscal_rxts_out,

    ---------------------------------------------------------------------------
    -- Timecode I/F
    ---------------------------------------------------------------------------
    tm_link_up_o            => tm_link_up, --: out std_logic;
    tm_time_valid_o         => tm_time_valid, --: out std_logic;
    tm_tai_o                => tm_tai, --: out std_logic_vector(39 downto 0);
    tm_cycles_o             => tm_cycles, --: out std_logic_vector(27 downto 0);
      
      
    pps_ext_i           => '0',--wrc_pps_in,
    pps_p_o             => wrc_pps_out,
    pps_led_o           => wrc_pps_led,
    led_link_o          => sfp_led,
    led_act_o           => qsfp_a_led);

    -- Tristates for SFP EEPROM
    sfp_scl <= '0' when sfp_scl_out = '0' else 'Z';
    sfp_sda <= '0' when sfp_sda_out = '0' else 'Z';
    sfp_scl_in     <= sfp_scl;
    sfp_sda_in     <= sfp_sda;

  -- tri-state onewire access
  -- onewire_b    <= '0' when (onewire_oe = '1') else 'Z';
  -- onewire_data <= onewire_b;

  ------------------------------------------------------------------------------
  -- Debug cores for signals in/out of xwrc_board_lru
  -----------------------------------------------------------------------------
    -- gty_vio_inst : whiterabbit_gty_vio_0
      -- PORT MAP (
        -- clk => clk,
        -- probe_in0       => ,
        -- probe_in1       => ,
        -- probe_in2       => ,
        -- probe_in3       => ,
        -- probe_in4       => ,
        -- probe_in5       => ,
        -- probe_in6       => ,
        -- probe_in7       => ,
        -- probe_in8       => ,
        -- probe_in9       => ,
        -- probe_in10      => ,
        -- probe_out0      => ,
        -- probe_out1      => ,
        -- probe_out2      => ,
        -- probe_out3      => ,
        -- probe_out4      => ,
        -- probe_out5      => ,
        -- probe_out6      => ,
        -- probe_out7      => 
      -- );

      
      
      
  ------------------------------------------------------------------------------
  -- Digital I/O FMC Mezzanine connections
  ------------------------------------------------------------------------------

  -- LEDs
  U_Extend_PPS : ENTITY general_cores_lib.gc_extend_pulse
  generic map (
    g_width => 10000000)
  port map (
    clk_i      => clk_ref_125m,
    rst_n_i    => rst_ref_125m_n,
    pulse_i    => wrc_pps_led,
    extended_o => qsfp_b_led); --dio_led_top_o);

--  dio_led_bot_o <= '0';

end architecture top;
