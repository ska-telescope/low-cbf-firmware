LIBRARY IEEE, technology_lib, common_lib, axi4_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE work.tech_system_monitor_component_pkg.ALL;

ENTITY tech_system_monitor IS
   GENERIC (
      g_technology         : t_technology);

   PORT (
      axi_clk              : IN STD_LOGIC;
      axi_reset            : IN STD_LOGIC;

      axi_lite_mosi        : IN t_axi4_lite_mosi;
      axi_lite_miso        : OUT t_axi4_lite_miso;

      interrupt            : OUT STD_LOGIC;

      -- Alarms
      over_temperature     : OUT STD_LOGIC;
      voltage_alarm        : OUT STD_LOGIC;

      -- Temperature Output (for DDR4 core)
      temp_out             : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);

      -- System Monitor IO
      v_p                  : IN STD_LOGIC;
      v_n                  : IN STD_LOGIC;

      vaux_p               : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      vaux_n               : IN STD_LOGIC_VECTOR(15 DOWNTO 0));
END tech_system_monitor;

ARCHITECTURE str OF tech_system_monitor IS

   SIGNAL vbram_alarm         : STD_LOGIC;
   SIGNAL vccaux_alarm        : STD_LOGIC;
   SIGNAL vccint_alarm        : STD_LOGIC;
   SIGNAL not_axi_reset       : STD_LOGIC;

BEGIN

   voltage_alarm <= vbram_alarm OR vccaux_alarm OR vccint_alarm;

   not_axi_reset <= NOT(axi_reset);

   gen_ip_lru: IF tech_is_board(g_technology, c_tech_board_gemini_lru) GENERATE
      u_sys_monitor: system_monitor_gemini_lru
      PORT MAP (
         s_axi_aclk => axi_clk, s_axi_aresetn => not_axi_reset,
         s_axi_awaddr => axi_lite_mosi.awaddr(12 DOWNTO 0), s_axi_awvalid => axi_lite_mosi.awvalid,
         s_axi_awready => axi_lite_miso.awready, s_axi_wdata => axi_lite_mosi.wdata(31 DOWNTO 0),
         s_axi_wstrb => axi_lite_mosi.wstrb(3 DOWNTO 0), s_axi_wvalid => axi_lite_mosi.wvalid,
         s_axi_wready => axi_lite_miso.wready, s_axi_bresp => axi_lite_miso.bresp,
         s_axi_bvalid => axi_lite_miso.bvalid, s_axi_bready => axi_lite_mosi.bready,
         s_axi_araddr => axi_lite_mosi.araddr(12 DOWNTO 0), s_axi_arvalid => axi_lite_mosi.arvalid,
         s_axi_arready => axi_lite_miso.arready, s_axi_rdata => axi_lite_miso.rdata(31 DOWNTO 0),
         s_axi_rresp => axi_lite_miso.rresp, s_axi_rvalid => axi_lite_miso.rvalid,
         s_axi_rready => axi_lite_mosi.rready, ip2intc_irpt => interrupt,
         vp => v_p, vn => v_n, eoc_out => OPEN, alarm_out => OPEN, eos_out => OPEN, busy_out => OPEN,
         user_temp_alarm_out => over_temperature, vccint_alarm_out => vccint_alarm, vbram_alarm_out => vbram_alarm,
         vccaux_alarm_out => vccaux_alarm, ot_out => OPEN, channel_out => OPEN, temp_out => temp_out);
   END GENERATE;

   gen_ip_xh_lru: IF tech_is_board(g_technology, c_tech_board_gemini_xh_lru) GENERATE
      u_sys_monitor: system_monitor_gemini_xh_lru
      PORT MAP (
         s_axi_aclk => axi_clk, s_axi_aresetn => not_axi_reset,
         s_axi_awaddr => axi_lite_mosi.awaddr(12 DOWNTO 0), s_axi_awvalid => axi_lite_mosi.awvalid,
         s_axi_awready => axi_lite_miso.awready, s_axi_wdata => axi_lite_mosi.wdata(31 DOWNTO 0),
         s_axi_wstrb => axi_lite_mosi.wstrb(3 DOWNTO 0), s_axi_wvalid => axi_lite_mosi.wvalid,
         s_axi_wready => axi_lite_miso.wready, s_axi_bresp => axi_lite_miso.bresp,
         s_axi_bvalid => axi_lite_miso.bvalid, s_axi_bready => axi_lite_mosi.bready,
         s_axi_araddr => axi_lite_mosi.araddr(12 DOWNTO 0), s_axi_arvalid => axi_lite_mosi.arvalid,
         s_axi_arready => axi_lite_miso.arready, s_axi_rdata => axi_lite_miso.rdata(31 DOWNTO 0),
         s_axi_rresp => axi_lite_miso.rresp, s_axi_rvalid => axi_lite_miso.rvalid,
         s_axi_rready => axi_lite_mosi.rready, ip2intc_irpt => interrupt,
         vp => v_p, vn => v_n, eoc_out => OPEN, alarm_out => OPEN, eos_out => OPEN, busy_out => OPEN,
         user_temp_alarm_out => over_temperature, vccint_alarm_out => vccint_alarm, vbram_alarm_out => vbram_alarm,
         vccaux_alarm_out => vccaux_alarm, ot_out => OPEN, channel_out => OPEN, temp_out => temp_out);
   END GENERATE;

   gen_ip_kcu105: IF tech_is_board(g_technology, c_tech_board_kcu105) GENERATE
      u_sys_monitor: system_monitor_kcu105
      PORT MAP (
         s_axi_aclk => axi_clk, s_axi_aresetn => not_axi_reset,
         s_axi_awaddr => axi_lite_mosi.awaddr(12 DOWNTO 0), s_axi_awvalid => axi_lite_mosi.awvalid,
         s_axi_awready => axi_lite_miso.awready, s_axi_wdata => axi_lite_mosi.wdata(31 DOWNTO 0),
         s_axi_wstrb => axi_lite_mosi.wstrb(3 DOWNTO 0), s_axi_wvalid => axi_lite_mosi.wvalid,
         s_axi_wready => axi_lite_miso.wready, s_axi_bresp => axi_lite_miso.bresp,
         s_axi_bvalid => axi_lite_miso.bvalid, s_axi_bready => axi_lite_mosi.bready,
         s_axi_araddr => axi_lite_mosi.araddr(12 DOWNTO 0), s_axi_arvalid => axi_lite_mosi.arvalid,
         s_axi_arready => axi_lite_miso.arready, s_axi_rdata => axi_lite_miso.rdata(31 DOWNTO 0),
         s_axi_rresp => axi_lite_miso.rresp, s_axi_rvalid => axi_lite_miso.rvalid,
         s_axi_rready => axi_lite_mosi.rready, ip2intc_irpt => interrupt,
         vauxp0 => vaux_p(0), vauxn0 => vaux_n(0), vauxp2 => vaux_p(2), vauxn2 => vaux_n(2),
         vauxp8 => vaux_p(8), vauxn8 => vaux_n(8), eoc_out => OPEN, alarm_out => OPEN, eos_out => OPEN, busy_out => OPEN,
         user_temp_alarm_out => over_temperature, vccint_alarm_out => vccint_alarm, vbram_alarm_out => vbram_alarm,
         vccaux_alarm_out => vccaux_alarm, ot_out => OPEN, channel_out => OPEN, temp_out => temp_out);
   END GENERATE;






END str;





