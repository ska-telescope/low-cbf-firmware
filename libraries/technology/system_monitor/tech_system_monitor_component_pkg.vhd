LIBRARY IEEE, technology_lib, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;


PACKAGE tech_system_monitor_component_pkg IS

   COMPONENT system_monitor_gemini_lru
     PORT (
       s_axi_aclk : IN STD_LOGIC;
       s_axi_aresetn : IN STD_LOGIC;
       s_axi_awaddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
       s_axi_awvalid : IN STD_LOGIC;
       s_axi_awready : OUT STD_LOGIC;
       s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
       s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       s_axi_wvalid : IN STD_LOGIC;
       s_axi_wready : OUT STD_LOGIC;
       s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       s_axi_bvalid : OUT STD_LOGIC;
       s_axi_bready : IN STD_LOGIC;
       s_axi_araddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
       s_axi_arvalid : IN STD_LOGIC;
       s_axi_arready : OUT STD_LOGIC;
       s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
       s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       s_axi_rvalid : OUT STD_LOGIC;
       s_axi_rready : IN STD_LOGIC;
       ip2intc_irpt : OUT STD_LOGIC;
       vp : IN STD_LOGIC;
       vn : IN STD_LOGIC;
       user_temp_alarm_out : OUT STD_LOGIC;
       vccint_alarm_out : OUT STD_LOGIC;
       vccaux_alarm_out : OUT STD_LOGIC;
       ot_out : OUT STD_LOGIC;
       channel_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
       eoc_out : OUT STD_LOGIC;
       vbram_alarm_out : OUT STD_LOGIC;
       alarm_out : OUT STD_LOGIC;
       eos_out : OUT STD_LOGIC;
       busy_out : OUT STD_LOGIC;
       temp_out : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
     );
   END COMPONENT;

   COMPONENT system_monitor_gemini_xh_lru
     PORT (
       s_axi_aclk : IN STD_LOGIC;
       s_axi_aresetn : IN STD_LOGIC;
       s_axi_awaddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
       s_axi_awvalid : IN STD_LOGIC;
       s_axi_awready : OUT STD_LOGIC;
       s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
       s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       s_axi_wvalid : IN STD_LOGIC;
       s_axi_wready : OUT STD_LOGIC;
       s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       s_axi_bvalid : OUT STD_LOGIC;
       s_axi_bready : IN STD_LOGIC;
       s_axi_araddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
       s_axi_arvalid : IN STD_LOGIC;
       s_axi_arready : OUT STD_LOGIC;
       s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
       s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       s_axi_rvalid : OUT STD_LOGIC;
       s_axi_rready : IN STD_LOGIC;
       ip2intc_irpt : OUT STD_LOGIC;
       vp : IN STD_LOGIC;
       vn : IN STD_LOGIC;
       user_temp_alarm_out : OUT STD_LOGIC;
       vccint_alarm_out : OUT STD_LOGIC;
       vccaux_alarm_out : OUT STD_LOGIC;
       ot_out : OUT STD_LOGIC;
       channel_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
       eoc_out : OUT STD_LOGIC;
       vbram_alarm_out : OUT STD_LOGIC;
       alarm_out : OUT STD_LOGIC;
       eos_out : OUT STD_LOGIC;
       busy_out : OUT STD_LOGIC;
       temp_out : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
     );
   END COMPONENT;

   COMPONENT system_monitor_kcu105
     PORT (
       s_axi_aclk : IN STD_LOGIC;
       s_axi_aresetn : IN STD_LOGIC;
       s_axi_awaddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
       s_axi_awvalid : IN STD_LOGIC;
       s_axi_awready : OUT STD_LOGIC;
       s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
       s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
       s_axi_wvalid : IN STD_LOGIC;
       s_axi_wready : OUT STD_LOGIC;
       s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       s_axi_bvalid : OUT STD_LOGIC;
       s_axi_bready : IN STD_LOGIC;
       s_axi_araddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
       s_axi_arvalid : IN STD_LOGIC;
       s_axi_arready : OUT STD_LOGIC;
       s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
       s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
       s_axi_rvalid : OUT STD_LOGIC;
       s_axi_rready : IN STD_LOGIC;
       ip2intc_irpt : OUT STD_LOGIC;
       vauxp0 : IN STD_LOGIC;
       vauxn0 : IN STD_LOGIC;
       vauxp2 : IN STD_LOGIC;
       vauxn2 : IN STD_LOGIC;
       vauxp8 : IN STD_LOGIC;
       vauxn8 : IN STD_LOGIC;
       user_temp_alarm_out : OUT STD_LOGIC;
       vccint_alarm_out : OUT STD_LOGIC;
       vccaux_alarm_out : OUT STD_LOGIC;
       ot_out : OUT STD_LOGIC;
       channel_out : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
       eoc_out : OUT STD_LOGIC;
       vbram_alarm_out : OUT STD_LOGIC;
       alarm_out : OUT STD_LOGIC;
       eos_out : OUT STD_LOGIC;
       busy_out : OUT STD_LOGIC;
       temp_out : OUT STD_LOGIC_VECTOR(9 DOWNTO 0)
     );
   END COMPONENT;

END tech_system_monitor_component_pkg;

