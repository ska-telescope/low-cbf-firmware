-------------------------------------------------------------------------------
--
-- File Name:    onewire_memory.vhd
-- Type:         RTL
-- Designer:
-- Created:      10:55:56 07/15/2009
-- Template Rev: 0.1
--
-- Title:        Onewire Memory Interface
--
-- Description:  Generates complete onewire transactions for standard 1-wire memory
--               chips. ROM code is loaded at startup.
--
-------------------------------------------------------------------------------

LIBRARY ieee, common_lib;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.onewire_pkg.ALL;
USE common_lib.common_pkg.ALL;

ENTITY onewire_memory is
   GENERIC (
      g_clk_freq        : INTEGER := 125000000;                      -- Input clk rate in Hz
      g_prog_delay      : INTEGER := 10);                            -- Programming delay wait time in ms

   PORT (
      clk               : IN STD_LOGIC;                              -- Main clk signal (125MHz)
      rst               : IN STD_LOGIC;                              -- Main reset

      -- Control Interface
      strobe            : IN std_logic;                              -- Asserted to indicate control inputs are valid
      mode              : IN t_onewire_cmd;                          -- Operation Mode
      mem_address       : IN STD_LOGIC_VECTOR(15 downto 0);          -- Address of read/write command

      read_data         : OUT STD_LOGIC_VECTOR(63 downto 0);         -- Read data from ROM
      write_data        : IN STD_LOGIC_VECTOR(63 downto 0);          -- Write data to ROM

      error             : out std_logic;                             -- Indicate the previous transaction ended in error
      running           : out std_logic;                             -- Inidicates if the state machine is busy

      -- ROM Interface (Loaded on startup)
      rom               : out std_logic_vector(47 downto 0);         -- 48 Bit serial number output
      rom_valid         : out std_logic;                             -- Checksum of 48 bit ID ok

      -- 1 Wire Interface
      onewire_strong    : OUT STD_LOGIC;                             -- Active low strong pullup
      onewire           : INOUT STD_LOGIC);                          -- Onewire bus
END onewire_memory;

ARCHITECTURE structure OF onewire_memory IS

-------------------------------------------------------------------------------
--                                  Types                                    --
-------------------------------------------------------------------------------

   TYPE t_fsm_states IS (s_idle, s_no_device,
                         --------------------
                         s_read_rom_present, s_read_rom_cmd, s_read_rom_data,
                         --------------------
                         s_read_mem_present, s_read_mem_skip_rom,
                         s_read_mem_cmd, s_read_mem_address1, s_read_mem_address2,
                         s_read_mem_data,
                         --------------------
                         s_write_scratchpad_present, s_write_scratchpad_skip_rom,
                         s_write_scratchpad_cmd, s_write_scratchpad_address1, s_write_scratchpad_address2,
                         s_write_scratchpad_data,
                         s_write_scratchpad_read_crc,
                         --------------------
                         s_read_scratchpad_present, s_read_scratchpad_skip_rom,
                         s_read_scratchpad_cmd, s_read_scratchpad_registers,
                         --------------------
                         s_write_mem_present, s_write_mem_skip_rom,
                         s_write_mem_cmd, s_write_mem_address1, s_write_mem_address2, s_write_mem_es,
                         s_write_mem_wait,
                         s_write_mem_read_success);

   CONSTANT c_wait_width         : INTEGER := ceil_log2(g_prog_delay*g_clk_freq/1000);
   CONSTANT c_wait_timer         : UNSIGNED(c_wait_width-1 DOWNTO 0) := TO_UNSIGNED(g_prog_delay*g_clk_freq/1000, c_wait_width);

-------------------------------------------------------------------------------
--                                Signals                                    --
-------------------------------------------------------------------------------

   -- Core FSM Signals
   SIGNAL trans_state            : t_fsm_states;
   SIGNAL latch_data             : STD_LOGIC;
   SIGNAL latch_rom_data         : STD_LOGIC;
   SIGNAL started                : STD_LOGIC;
   SIGNAL byte_counter           : UNSIGNED(2 DOWNTO 0);

   -- Register Signals
   SIGNAL mem_data               : STD_LOGIC_VECTOR(63 DOWNTO 0);
   SIGNAL i_rom                  : STD_LOGIC_VECTOR(63 DOWNTO 0);

   -- Programming Wait Counter
   SIGNAL prog_wait_counter      : UNSIGNED(c_wait_width-1 DOWNTO 0);
   SIGNAL prog_wait_finished     : STD_LOGIC;

   -- Onewire Signals
   SIGNAL onewire_command        : T_PHY_OPCODE;
   SIGNAL onewire_start          : STD_LOGIC;
   SIGNAL onewire_finished       : STD_LOGIC;
   SIGNAL onewire_present        : STD_LOGIC;
   SIGNAL onewire_data_i         : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL onewire_data_o         : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL onewire_crc8           : STD_LOGIC_VECTOR(7 DOWNTO 0);
   SIGNAL onewire_crc16          : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL onewire_crc_rst        : STD_LOGIC;
   SIGNAL onewire_strong_pullup  : STD_LOGIC;

begin

----------------------------------------------------------------------------------
-- ROM Latch: Stores the 64bit ROM code from the 1-wire device, is loaded at startup
--             and can be reloaded by command.


rom_latch: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF latch_rom_data = '1' THEN
            i_rom <= onewire_data_o & i_rom(63 DOWNTO 8);
         END IF;
      END IF;
   END PROCESS;

   rom <= i_rom(55 DOWNTO 8);

----------------------------------------------------------------------------------
-- Data Latch: Stores the data read from the 1-wire device

data_latch: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF strobe = '1' AND trans_state = s_idle THEN
            mem_data <= write_data;
         ELSE
            IF latch_data = '1' THEN
               mem_data <= onewire_data_o & mem_data(63 DOWNTO 8);
            END IF;
         END IF;
      END IF;
   END PROCESS;

   read_data <= mem_data;

----------------------------------------------------------------------------------
-- Programming Counter: Counts down the 10ms for the programming of the chip to be
--                      complete

prog_count: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF trans_state /= s_write_mem_wait THEN
            prog_wait_counter <= c_wait_timer;
            prog_wait_finished <= '0';
         ELSE
            IF prog_wait_counter = 0 THEN
               prog_wait_finished <= '1';
            END IF;

            prog_wait_counter <= prog_wait_counter - 1;
         END IF;
      END IF;
   END PROCESS;

----------------------------------------------------------------------------------
-- Main FSM: Top level control state machine responsible for sequencing the ROM
--           retrieval and the EEPROM read and write

main_fsm: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF rst = '1' THEN
            trans_state <= s_read_rom_present;
            rom_valid <= '0';
            started <= '0';
            error <= '0';
            running <= '0';
            onewire_start <= '0';
            latch_data <= '0';
            latch_rom_data <= '0';
         ELSE
            latch_data <= '0';
            latch_rom_data <= '0';
            onewire_start <= '1';
            running <= '1';
            CASE trans_state IS
               WHEN s_idle =>
                  started <= '1';
                  onewire_start <= '0';
                  running <= '0';
                  IF strobe = '1' THEN
                     error <= '0';
                     IF mode = CMD_READ_ROM THEN
                        trans_state <= s_read_rom_present;
                        running <= '1';
                     ELSIF mode = CMD_READ_MEMORY THEN
                        trans_state <= s_read_mem_present;
                        running <= '1';
                     ELSIF mode = CMD_WRITE_MEMORY THEN
                        trans_state <= s_write_scratchpad_present;
                        running <= '1';
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_read_rom_present =>                            -- Issue reset Pulse
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     IF onewire_present = '1' THEN
                        trans_state <= s_read_rom_cmd;
                        error <= '0';                                -- Clear any previosu error flag if present, only a problem if doing initial loop
                     ELSE
                        trans_state <= s_no_device;
                     END IF;
                   END IF;

               -------------------------------
               WHEN s_read_rom_cmd =>                                -- Issue the Read ROM command
                  byte_counter <= (OTHERS => '0');
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_read_rom_data;
                  END IF;

               -------------------------------
               WHEN s_read_rom_data =>                               -- Read 8 bytes & check the CRC on the last byte
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     latch_rom_data <= '1';
                     IF byte_counter = 7 THEN
                        -- CRC should be 0
                        IF onewire_crc8 = X"00" THEN
                           rom_valid <= '1';
                           trans_state <= s_idle;
                        ELSE                                         -- Keep Reading if the CRC is faulty or device not present
                           rom_valid <= '0';
                           trans_state <= s_read_rom_present;
                        END IF;
                     ELSE
                        byte_counter <= byte_counter + 1;
                     END IF;
                  END IF;

               -------------------------------
               -------------------------------
               WHEN s_read_mem_present =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     IF onewire_present = '1' THEN
                        trans_state <= s_read_mem_skip_rom;
                     ELSE
                        trans_state <= s_no_device;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_read_mem_skip_rom =>                           -- Issue the skip ROM command
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     trans_state <= s_read_mem_cmd;
                  END IF;

               -------------------------------
               WHEN s_read_mem_cmd =>                                -- Issue the read memory command
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     trans_state <= s_read_mem_address1;
                  END IF;

               -------------------------------
               WHEN s_read_mem_address1 =>                           -- Send start memory address
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     trans_state <= s_read_mem_address2;
                  END IF;

               -------------------------------
               WHEN s_read_mem_address2 =>
                  byte_counter <= (OTHERS => '0');

                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     trans_state <= s_read_mem_data;
                  END IF;

               -------------------------------
               WHEN s_read_mem_data =>                            -- Read 8 bytes of data
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     latch_data <= '1';
                     IF byte_counter = 7 THEN
                        trans_state <= s_idle;
                     ELSE
                        byte_counter <= byte_counter + 1;
                     END IF;
                  END IF;

               -------------------------------
               -------------------------------

               WHEN s_write_scratchpad_present =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     IF onewire_present = '1' THEN
                        trans_state <= s_write_scratchpad_skip_rom;
                     ELSE
                        trans_state <= s_no_device;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_write_scratchpad_skip_rom =>                   -- Issue the skip ROM command
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_scratchpad_cmd;
                  END IF;

               -------------------------------
               WHEN s_write_scratchpad_cmd =>                        -- Issue the write scratchpad memory command
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_scratchpad_address1;
                  END IF;

               -------------------------------
               WHEN s_write_scratchpad_address1 =>                   -- Send start memory address
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_scratchpad_address2;
                  END IF;

               -------------------------------
               WHEN s_write_scratchpad_address2 =>
                  byte_counter <= (OTHERS => '0');

                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_scratchpad_data;
                  END IF;

               -------------------------------
               when s_write_scratchpad_data =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     latch_data <= '1';

                     IF byte_counter = 7 THEN
                        trans_state <= s_write_scratchpad_read_crc;
                        byte_counter <= (OTHERS => '0');
                     else
                        byte_counter <= byte_counter + 1;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_write_scratchpad_read_crc =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';

                     IF byte_counter = 1 THEN
                        IF onewire_crc16 = X"b001" THEN
                           trans_state <= s_read_scratchpad_present;
                        ELSE
                           trans_state <= s_no_device;
                        END IF;
                     ELSE
                        byte_counter <= byte_counter + 1;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_read_scratchpad_present =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     IF onewire_present = '1' THEN
                        trans_state <= s_read_scratchpad_skip_rom;
                     ELSE
                        trans_state <= s_no_device;
                     END IF;
                  END IF;

               -------------------------------
               when s_read_scratchpad_skip_rom =>                    -- Issue the skip ROM command
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_read_scratchpad_cmd;
                  END IF;

               -------------------------------
               when s_read_scratchpad_cmd =>                         -- Issue the write scratchpad memory command
                  byte_counter <= (others => '0');
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_read_scratchpad_registers;
                  END IF;

               -------------------------------
               WHEN s_read_scratchpad_registers =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     latch_data <= '1';
                     IF byte_counter = 2 THEN                    -- 3 address bytes back first
                        trans_state <= s_write_mem_present;
                     ELSE
                        byte_counter <= byte_counter + 1;
                     END IF;
                  END IF;

               -------------------------------
               WHEN s_write_mem_present =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     if onewire_present = '1' then
                        trans_state <= s_write_mem_skip_rom;
                     else
                        trans_state <= s_no_device;
                     end if;
                  END IF;

               -------------------------------
               WHEN s_write_mem_skip_rom =>                          -- Issue the skip ROM command
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_mem_cmd;
                  END IF;

               -------------------------------
               WHEN s_write_mem_cmd =>                               -- Issue the write scratchpad memory command
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_mem_address1;
                  END IF;

               -------------------------------
               WHEN s_write_mem_address1 =>                          -- Send start memory address
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_mem_address2;

                  END IF;

               -------------------------------
               WHEN s_write_mem_address2 =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_mem_es;

                  END IF;

               -------------------------------
               WHEN s_write_mem_es =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     trans_state <= s_write_mem_wait;
                  END IF;

               -------------------------------
               WHEN s_write_mem_wait =>                              -- Wait for  tPROGRMAX for EEPROM to write
                  onewire_start <= '0';
                  IF prog_wait_finished = '1' THEN                   -- About 10 ms
                     trans_state <= s_write_mem_read_success;
                  END IF;

               -------------------------------
               WHEN s_write_mem_read_success =>
                  IF onewire_finished = '1' AND onewire_start = '1' THEN
                     onewire_start <= '0';
                     IF onewire_data_o = X"AA" THEN              -- Completion code
                        trans_state <= s_idle;
                     ELSE
                        trans_state <= s_no_device;
                     END IF;
                  END IF;

               -------------------------------
               -------------------------------
               WHEN s_no_device =>
                  onewire_start <= '0';
                  error <= '1';
                  IF started = '1' THEN                              -- If the 1-wire device hasn't been detected
                     trans_state <= s_idle;                          -- then loop until it is
                  ELSE
                     trans_state <= s_read_rom_present;
                  END IF;
            END CASE;
         END IF;
      END IF;
   END PROCESS;

   --------------
   -- Assign the control signals based the the state machine

   onewire_command <= OP_READ8     WHEN trans_state = s_read_rom_data OR
                                        trans_state = s_read_mem_data OR
                                        trans_state = s_write_scratchpad_read_crc OR
                                        trans_state = s_read_scratchpad_registers OR
                                        trans_state = s_write_mem_read_success ELSE
                      OP_PRESENCE  WHEN trans_state = s_read_rom_present OR
                                        trans_state = s_read_mem_present OR
                                        trans_state = s_write_scratchpad_present OR
                                        trans_state = s_read_scratchpad_present OR
                                        trans_state = s_write_mem_present ELSE
                      OP_WRITE8;

   onewire_data_i <= ONEWIRE_READ_ROM           WHEN trans_state = s_read_rom_cmd ELSE
                     ONEWIRE_SKIP_ROM           WHEN trans_state = s_read_mem_skip_rom OR
                                                     trans_state = s_write_scratchpad_skip_rom OR
                                                     trans_state = s_read_scratchpad_skip_rom OR
                                                     trans_state = s_write_mem_skip_rom ELSE
                     ONEWIRE_READ_MEMORY        WHEN trans_state = s_read_mem_cmd ELSE
                     ONEWIRE_WRITE_SCRATCHPAD   WHEN trans_state = s_write_scratchpad_cmd ELSE
                     ONEWIRE_COPY_SCRATCHPAD    WHEN trans_state = s_write_mem_cmd ELSE
                     ONEWIRE_READ_SCRATCHPAD    WHEN trans_state = s_read_scratchpad_cmd ELSE
                     mem_address(7 DOWNTO 0)    WHEN trans_state = s_read_mem_address1 OR
                                                     trans_state = s_write_scratchpad_address1 ELSE
                     mem_address(15 DOWNTO 8)   WHEN trans_state = s_read_mem_address2 OR
                                                     trans_state = s_write_scratchpad_address2 ELSE
                     mem_data(7 DOWNTO 0)       WHEN trans_state = s_write_scratchpad_data ELSE
                     mem_data(47 DOWNTO 40)     WHEN trans_state = s_write_mem_address1 ELSE
                     mem_data(55 DOWNTO 48)     WHEN trans_state = s_write_mem_address2 ELSE
                     mem_data(63 DOWNTO 56)     WHEN trans_state = s_write_mem_es ELSE
                     X"00";

   onewire_crc_rst <= '0' WHEN trans_state = s_read_rom_data OR
                               trans_state = s_write_scratchpad_cmd OR
                               trans_state = s_write_scratchpad_address1 OR
                               trans_state = s_write_scratchpad_address2 OR
                               trans_state = s_write_scratchpad_data OR
                               trans_state = s_write_scratchpad_read_crc ELSE '1';

onewire_strong_pullup <= '1' WHEN trans_state = s_write_mem_wait ELSE '0';

----------------------------------------------------------------------------------
-- The Physical layer of the 1-wire interface

onewire_phy_1: ENTITY work.onewire_phy
               GENERIC MAP (g_clk_freq       => g_clk_freq)
               PORT MAP (clk                 => clk,
                         rst                 => rst,
                         go                  => onewire_start,
                         finished            => onewire_finished,
                         op_code             => onewire_command,
                         strong_pullup       => onewire_strong_pullup,
                         data_i              => onewire_data_i,
                         data_o              => onewire_data_o,
                         presence            => onewire_present,
                         crc8                => onewire_crc8,
                         crc16               => onewire_crc16,
                         crc_rst             => onewire_crc_rst,
                         onewire_strong      => onewire_strong,
                         onewire             => onewire);

END Structure;

