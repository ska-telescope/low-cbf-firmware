-------------------------------------------------------------------------------
--
-- File Name:    prom_interface.vhd
-- Type:         RTL
-- Designer:
-- Created:      10:29:30 16/11/2017
-- Template Rev: 0.1
--
-- Title:        DS2431 Interface
--
-- Description:  Provdies register access to the onewire part and generates the
--               local MAC address from the 1-wire ROM code
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib, onewire_lib, axi4_lib, technology_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE onewire_lib.onewire_pkg.ALL;
USE axi4_lib.axi4_lite_pkg.ALL;
USE common_lib.common_pkg.ALL;
USE technology_lib.technology_pkg.ALL;
USE technology_lib.technology_select_pkg.ALL;
USE onewire_lib.onewire_pkg.ALL;
USE work.gemini_lru_board_onewire_prom_reg_pkg.ALL;

-------------------------------------------------------------------------------
ENTITY prom_interface IS
   GENERIC (
      g_technology         : t_technology := c_tech_select_default;
      g_clk_rate           : INTEGER := 156250000;                            -- Clk rate in HZ
      g_default_ip_addr    : INTEGER := 1;                                    -- Address of the default ip address
      g_serial_num_addr    : INTEGER := 0;                                    -- Address of the serial number
      g_default_ip         : STD_LOGIC_VECTOR(31 DOWNTO 0) := X"0A200102";    -- 10.32.1.2
      g_default_mac        : STD_LOGIC_VECTOR(47 DOWNTO 0) := X"C02B3C4D5E6F");

   PORT (
      rst                  : IN  STD_LOGIC;
      clk                  : IN  STD_LOGIC;

      -- Derived information
      mac                  : OUT STD_LOGIC_VECTOR(47 DOWNTO 0);
      ip                   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      ip_valid             : OUT STD_LOGIC;
      serial_number        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      aux                  : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);

      startup_complete     : OUT STD_LOGIC;
      prom_present         : OUT STD_LOGIC;

      --AXI Interface
      s_axi_mosi           : IN t_axi4_lite_mosi;
      s_axi_miso           : OUT t_axi4_lite_miso;

      -- Physical Interfaces
      onewire_strong       : OUT STD_LOGIC;                             -- Active low strong pullup
      onewire              : INOUT STD_LOGIC);                          -- Onewire bus
END prom_interface;

ARCHITECTURE rtl OF prom_interface IS

  ---------------------------------------------------------------------------
  -- CONSTANT, TYPE AND GENERIC DEFINITIONS  --
  ---------------------------------------------------------------------------

   TYPE t_fsm_states IS (s_idle, s_startup, s_read_ip, s_read_serial, s_process_op);


   ---------------------------------------------------------------------------
   -- SIGNAL DECLARATIONS  --
   ---------------------------------------------------------------------------

   SIGNAL op_state                  : t_fsm_states := s_startup;
   SIGNAL latch_serial              : STD_LOGIC;
   SIGNAL latch_mac                 : STD_LOGIC;
   SIGNAL latch_ip                  : STD_LOGIC;
   SIGNAL error_latch               : STD_LOGIC;
   SIGNAL onewire_read_data_latch   : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL read_execute_latch        : STD_LOGIC;
   SIGNAL write_execute_latch       : STD_LOGIC;
   SIGNAL reload_parameters_latch   : STD_LOGIC;
   SIGNAL read_cmd                  : STD_LOGIC;
   SIGNAL onewire_mode              : t_onewire_cmd;
   SIGNAL i_rst                     : STD_LOGIC;

   SIGNAL onewire_mem_address       : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL onewire_running           : STD_LOGIC;
   SIGNAL onewire_running_dly       : STD_LOGIC;
   SIGNAL onewire_error             : STD_LOGIC;
   SIGNAL onewire_rom_valid         : STD_LOGIC;
   SIGNAL onewire_rom               : STD_LOGIC_VECTOR(47 DOWNTO 0);
   SIGNAL onewire_read_data         : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL onewire_write_data        : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL onewire_strobe            : STD_LOGIC;

   -- Registers
   SIGNAL onewire_prom_fields_rw    : t_onewire_prom_rw;
   SIGNAL onewire_prom_fields_ro    : t_onewire_prom_ro;

   ---------------------------------------------------------------------------
   -- ATTRIBUTES  --
   ---------------------------------------------------------------------------

   ATTRIBUTE DONT_TOUCH                : STRING;
   ATTRIBUTE DONT_TOUCH OF i_rst       : SIGNAL IS "true";

BEGIN

   io_reg: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         i_rst <= rst;

         prom_present <= onewire_rom_valid;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- Registers  --
---------------------------------------------------------------------------

regs: ENTITY work.gemini_lru_board_onewire_prom_reg
      GENERIC MAP (g_technology        => g_technology)
      PORT MAP (mm_clk                 => clk,
                mm_rst                 => i_rst,
                sla_in                 => s_axi_mosi,
                sla_out                => s_axi_miso,
                onewire_prom_fields_rw => onewire_prom_fields_rw,
                onewire_prom_fields_ro => onewire_prom_fields_ro);

   -- Readback fields
   onewire_prom_fields_ro.status_rom_invalid <= not(onewire_rom_valid);
   onewire_prom_fields_ro.rom_low <= onewire_rom(31 DOWNTO 0);
   onewire_prom_fields_ro.rom_high <= onewire_rom(47 DOWNTO 32);

   onewire_prom_fields_ro.status_error <= error_latch;
   onewire_prom_fields_ro.status_running <= onewire_running;

   onewire_prom_fields_ro.data_read_low   <= onewire_read_data_latch(31 DOWNTO 0);
   onewire_prom_fields_ro.data_read_high  <= onewire_read_data_latch(63 DOWNTO 32);

---------------------------------------------------------------------------
-- Address Formation  --
---------------------------------------------------------------------------
-- Use the generic defaults until the PROM is proven to be valid. Keep using the
-- generic IP unless the IP has has the corerct checkcode.


serial_latch: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF i_rst = '1' THEN
            serial_number <= X"00000001";
         ELSE
            -- Make sure the checkcode is correct (prevents unprogrammed EEPROM from being loaded)
            IF latch_serial = '1' AND onewire_read_data(63 DOWNTO 56) = X"ca" THEN
               serial_number <= onewire_read_data(31 DOWNTO 0);
            END IF;
         END IF;
      END IF;
   END PROCESS;

ip_latch: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF i_rst = '1' THEN
            ip <= g_default_ip;
            ip_valid <= '0';
         ELSE
            -- Make sure the checkcode is correct (prevents unprogrammed EEPROM from being loaded)
            IF latch_ip = '1' AND onewire_read_data(63 DOWNTO 56) = X"ab" THEN
               aux <= onewire_read_data(55 DOWNTO 32);
               ip <= onewire_read_data(31 DOWNTO 0);
               ip_valid <= '1';
            END IF;
         END IF;
      END IF;
   END PROCESS;

mac_latch: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF i_rst = '1' THEN
            mac <= g_default_mac;
         ELSE
            -- Make sure the checkcode is correct (prevents unprogrammed EEPROM from being loaded)
            IF latch_mac = '1' AND onewire_rom_valid = '1' THEN
               mac(39 DOWNTO 0) <= onewire_rom(39 DOWNTO 0);
               mac(47 DOWNTO 40) <= X"C0";         -- Identify as Gemini Hardware, unique and unicast
            END IF;
         END IF;
      END IF;
   END PROCESS;

---------------------------------------------------------------------------
-- High Level Controller  --
---------------------------------------------------------------------------
-- At Startup or reset the onewire controller will automatically read the ROM.
-- IF the ROM read was sucessful the serila number and default IP address
-- is also read


top_fsm: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         onewire_running_dly <= onewire_running;

         IF i_rst = '1' THEN
            op_state <= s_startup;
            latch_serial <= '0';
            latch_mac <= '0';
            latch_ip <= '0';
            error_latch <= '0';
            startup_complete <= '0';
         ELSE
            error_latch <= error_latch OR (onewire_error AND NOT(onewire_strobe));
            read_execute_latch <= read_execute_latch OR onewire_prom_fields_rw.control_read_execute;
            write_execute_latch <= write_execute_latch OR onewire_prom_fields_rw.control_write_execute;
            reload_parameters_latch <= reload_parameters_latch OR onewire_prom_fields_rw.control_reload_parameters;

            latch_serial <= '0';
            latch_mac <= '0';
            latch_ip <= '0';
            onewire_strobe <= '0';

            CASE op_state IS

               -------------------------------
               WHEN s_startup =>
                  IF onewire_running_dly = '1' AND onewire_running = '0' THEN
                     latch_mac <= NOT(onewire_error);
                     IF onewire_rom_valid = '1' THEN
                        op_state <= s_read_ip;
                        onewire_strobe <= '1';
                     ELSE
                        op_state <= s_idle;
                        startup_complete <= '1';
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_read_ip =>
                  IF onewire_running_dly = '1' AND onewire_running = '0' THEN
                     latch_ip <= NOT(onewire_error);
                     op_state <= s_read_serial;
                     onewire_strobe <= '1';
                  END IF;

               -------------------------------
               WHEN s_read_serial =>
                  IF onewire_running_dly = '1' AND onewire_running = '0' THEN
                     op_state <= s_idle;
                     latch_serial <= NOT(onewire_error);
                     startup_complete <= '1';
                  END IF;

               -------------------------------
               WHEN s_idle =>
                  IF read_execute_latch = '1' THEN
                     read_cmd <= '1';
                     error_latch <= '0';
                     op_state <= s_process_op;
                     onewire_strobe <= '1';
                  ELSIF write_execute_latch = '1' THEN
                     read_cmd <= '0';
                     error_latch <= '0';
                     op_state <= s_process_op;
                     onewire_strobe <= '1';
                     onewire_write_data(31 DOWNTO 0) <= onewire_prom_fields_rw.data_write_low;
                     onewire_write_data(63 DOWNTO 32) <= onewire_prom_fields_rw.data_write_high;
                  ELSIF reload_parameters_latch = '1' THEN
                     IF onewire_rom_valid = '1' THEN
                        op_state <= s_read_ip;
                        onewire_strobe <= '1';
                     END IF;
                     reload_parameters_latch <= '0';
                  END IF;

               -------------------------------
               WHEN s_process_op =>
                  -- Can't start pending until transaction is finished
                  read_execute_latch <= '0';
                  write_execute_latch <= '0';

                  IF onewire_running_dly = '1' AND onewire_running = '0' THEN
                     op_state <= s_idle;
                     onewire_read_data_latch <= onewire_read_data;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   onewire_mem_address(2 DOWNTO 0) <= (OTHERS => '0');        -- Always 64bit aligned addresses
   onewire_mem_address(7 DOWNTO 3) <= STD_LOGIC_VECTOR(TO_UNSIGNED(g_default_ip_addr, 5)) WHEN op_state = s_read_ip ELSE
                                      STD_LOGIC_VECTOR(TO_UNSIGNED(g_serial_num_addr, 5)) WHEN op_state = s_read_serial ELSE
                                      onewire_prom_fields_rw.control_address;

   onewire_mem_address(15 DOWNTO 8) <= (OTHERS => '0');        -- Not used

   onewire_mode <= CMD_READ_MEMORY WHEN op_state = s_read_ip OR
                                        op_state = s_read_serial OR
                                        (op_state = s_process_op AND read_cmd = '1') ELSE
                   CMD_WRITE_MEMORY;


---------------------------------------------------------------------------
-- SMBUS Controller  --
---------------------------------------------------------------------------

u_onewire_memory: ENTITY onewire_lib.onewire_memory
                  GENERIC MAP (g_clk_freq    => g_clk_rate)
                  PORT MAP (clk              => clk,
                            rst              => i_rst,
                            strobe           => onewire_strobe,
                            mode             => onewire_mode,
                            mem_address      => onewire_mem_address,
                            read_data        => onewire_read_data,
                            write_data       => onewire_write_data,
                            error            => onewire_error,
                            running          => onewire_running,
                            rom              => onewire_rom,
                            rom_valid        => onewire_rom_valid,
                            onewire_strong   => onewire_strong,
                            onewire          => onewire);

END rtl;