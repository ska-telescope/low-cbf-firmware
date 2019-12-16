LIBRARY IEEE, UNISIM, common_lib, axi4_lib, technology_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use UNISIM.VCOMPONENTS.ALL;
USE common_lib.common_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE technology_lib.technology_pkg.ALL;



ENTITY mmm_lru_mbo_25G_ibert IS
  GENERIC (
    g_sim           : BOOLEAN := FALSE; --Overridden by TB
    g_technology    : t_technology := c_tech_xcvu9p;
    g_sim_unb_nr    : NATURAL := 0;
    g_sim_node_nr   : NATURAL := 0
  );
  PORT (
    mm_clk        : IN  STD_LOGIC;
    mm_rst        : IN  STD_LOGIC;
    ph_rst        : IN  STD_LOGIC;

    -- system_info
    reg_lru_system_info_mosi : OUT t_axi4_lite_mosi;
    reg_lru_system_info_miso : IN  t_axi4_lite_miso;
    rom_lru_system_info_mosi : OUT t_axi4_lite_mosi;
    rom_lru_system_info_miso : IN  t_axi4_lite_miso;

    -- lru led
    reg_led_mosi  : OUT t_axi4_lite_mosi;
    reg_led_miso  : IN  t_axi4_lite_miso

    --master_mosi   : OUT t_axi4_lite_mosi;
    --master_miso   : IN  t_axi4_lite_miso
  );
END mmm_lru_mbo_25G_ibert;

ARCHITECTURE str OF mmm_lru_mbo_25G_ibert IS
   SIGNAL ph_rst_n, mm_rst_n : STD_LOGIC;
BEGIN

   mm_rst_n <= NOT mm_rst;
   ph_rst_n <= NOT ph_rst;
   

  u_lru_led_axi_wrapper : ENTITY work.lru_led_axi_wrapper
  PORT MAP (
    mm_clk   => mm_clk,
    mm_rst_n => mm_rst_n,
    ph_rst_n => ph_rst_n,

    AXI4_LITE_SLAVE_REG_INFO_araddr     => reg_lru_system_info_mosi.araddr(31 downto 0), --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_arprot     => reg_lru_system_info_mosi.arprot(2 downto 0),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_arready(0) => reg_lru_system_info_miso.arready,             --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_arvalid(0) => reg_lru_system_info_mosi.arvalid,             --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_awaddr     => reg_lru_system_info_mosi.awaddr(31 downto 0), --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_awprot     => reg_lru_system_info_mosi.awprot(2 downto 0),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_awready(0) => reg_lru_system_info_miso.awready,             --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_awvalid(0) => reg_lru_system_info_mosi.awvalid,             --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_bready(0)  => reg_lru_system_info_mosi.bready,              --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_bresp      => reg_lru_system_info_miso.bresp(1 downto 0),   --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_bvalid(0)  => reg_lru_system_info_miso.bvalid,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_rdata      => reg_lru_system_info_miso.rdata(31 downto 0),  --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_rready(0)  => reg_lru_system_info_mosi.rready,              --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_rresp      => reg_lru_system_info_miso.rresp(1 downto 0),   --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_rvalid(0)  => reg_lru_system_info_miso.rvalid,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_wdata      => reg_lru_system_info_mosi.wdata(31 downto 0),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_wready(0)  => reg_lru_system_info_miso.wready,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_INFO_wstrb      => reg_lru_system_info_mosi.wstrb(3 downto 0),   --: out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_REG_INFO_wvalid(0)  => reg_lru_system_info_mosi.wvalid,              --: out STD_LOGIC_VECTOR ( 0 to 0 );

    AXI4_LITE_SLAVE_ROM_INFO_araddr     => rom_lru_system_info_mosi.araddr(31 downto 0), --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arprot     => rom_lru_system_info_mosi.arprot(2 downto 0),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arready(0) => rom_lru_system_info_miso.arready,             --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_arvalid(0) => rom_lru_system_info_mosi.arvalid,             --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awaddr     => rom_lru_system_info_mosi.awaddr(31 downto 0), --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awprot     => rom_lru_system_info_mosi.awprot(2 downto 0),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awready(0) => rom_lru_system_info_miso.awready,             --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_awvalid(0) => rom_lru_system_info_mosi.awvalid,             --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bready(0)  => rom_lru_system_info_mosi.bready,              --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bresp      => rom_lru_system_info_miso.bresp(1 downto 0),   --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_bvalid(0)  => rom_lru_system_info_miso.bvalid,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rdata      => rom_lru_system_info_miso.rdata(31 downto 0),  --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rready(0)  => rom_lru_system_info_mosi.rready,              --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rresp      => rom_lru_system_info_miso.rresp(1 downto 0),   --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_rvalid(0)  => rom_lru_system_info_miso.rvalid,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wdata      => rom_lru_system_info_mosi.wdata(31 downto 0),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wready(0)  => rom_lru_system_info_miso.wready,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wstrb      => rom_lru_system_info_mosi.wstrb(3 downto 0),   --: out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_ROM_INFO_wvalid(0)  => rom_lru_system_info_mosi.wvalid,              --: out STD_LOGIC_VECTOR ( 0 to 0 );

    AXI4_LITE_SLAVE_REG_LED_araddr     => reg_led_mosi.araddr(31 downto 0), --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_arprot     => reg_led_mosi.arprot(2 downto 0),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_arready(0) => reg_led_miso.arready,             --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_arvalid(0) => reg_led_mosi.arvalid,             --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_awaddr     => reg_led_mosi.awaddr(31 downto 0), --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_awprot     => reg_led_mosi.awprot(2 downto 0),  --: out STD_LOGIC_VECTOR ( 2 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_awready(0) => reg_led_miso.awready,             --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_awvalid(0) => reg_led_mosi.awvalid,             --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_bready(0)  => reg_led_mosi.bready,              --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_bresp      => reg_led_miso.bresp(1 downto 0),   --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_bvalid(0)  => reg_led_miso.bvalid,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_rdata      => reg_led_miso.rdata(31 downto 0),  --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_rready(0)  => reg_led_mosi.rready,              --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_rresp      => reg_led_miso.rresp(1 downto 0),   --: in STD_LOGIC_VECTOR ( 1 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_rvalid(0)  => reg_led_miso.rvalid,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_wdata      => reg_led_mosi.wdata(31 downto 0),  --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_wready(0)  => reg_led_miso.wready,              --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_SLAVE_REG_LED_wstrb      => reg_led_mosi.wstrb(3 downto 0),   --: out STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_SLAVE_REG_LED_wvalid(0)  => reg_led_mosi.wvalid,              --: out STD_LOGIC_VECTOR ( 0 to 0 );

    AXI4_LITE_MASTER_araddr  => (others => '0'), --master_miso.araddr(31 downto 0),  --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_arprot  => (others => '0'), --master_miso.arprot(2 downto 0),   --: in STD_LOGIC_VECTOR ( 2 downto 0 );
    --AXI4_LITE_MASTER_arready => master_mosi.arready(0 to 0),      --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_arvalid => (others => '0'), --master_miso.arvalid(0 to 0),      --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_awaddr  => (others => '0'), --master_miso.awaddr(31 downto 0),  --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_awprot  => (others => '0'), --master_miso.awprot(2 downto 0),   --: in STD_LOGIC_VECTOR ( 2 downto 0 );
    --AXI4_LITE_MASTER_awready => master_mosi.awready(0 to 0),      --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_awvalid => (others => '0'), --master_miso.awvalid(0 to 0),      --: in STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_bready  => (others => '1'), --master_miso.bready(0 to 0),       --: in STD_LOGIC_VECTOR ( 0 to 0 );
    --AXI4_LITE_MASTER_bresp   => master_mosi.bresp(1 downto 0),    --: out STD_LOGIC_VECTOR ( 1 downto 0 );
    --AXI4_LITE_MASTER_bvalid  => master_mosi.bvalid(0 to 0),       --: out STD_LOGIC_VECTOR ( 0 to 0 );
    --AXI4_LITE_MASTER_rdata   => master_mosi.rdata(31 downto 0),   --: out STD_LOGIC_VECTOR ( 31 downto 0 );
    AXI4_LITE_MASTER_rready  => (others => '1'), --master_miso.rready(0 to 0),       --: in STD_LOGIC_VECTOR ( 0 to 0 );
    --AXI4_LITE_MASTER_rresp   => master_mosi.rresp(1 downto 0),    --: out STD_LOGIC_VECTOR ( 1 downto 0 );
    --AXI4_LITE_MASTER_rvalid  => master_mosi.rvalid(0 to 0),       --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_wdata   => (others => '0'), --master_miso.wdata(31 downto 0),   --: in STD_LOGIC_VECTOR ( 31 downto 0 );
    --AXI4_LITE_MASTER_wready  => master_mosi.wready(0 to 0),       --: out STD_LOGIC_VECTOR ( 0 to 0 );
    AXI4_LITE_MASTER_wstrb   => (others => '0'), --master_miso.wstrb(3 downto 0),    --: in STD_LOGIC_VECTOR ( 3 downto 0 );
    AXI4_LITE_MASTER_wvalid  => (others => '0')  --master_miso.wvalid(0 to 0)        --: in STD_LOGIC_VECTOR ( 0 to 0 );
  );
END str;

