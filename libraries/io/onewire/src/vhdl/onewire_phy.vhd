-------------------------------------------------------------------------------
--
-- File Name:    onewire_phy.vhd
-- Type:         RTL
-- Designer:
-- Created:      10:29:30 14/06/2006
-- Template Rev: 0.1
--
-- Title:        Onewire Physical interface
--
-- Description:  Main state machine for driving a one wire bus, can issue rst
--               pulse and read and write data. The design will work for any
--               1-wire device
--
-------------------------------------------------------------------------------

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.ONEWIRE_PKG.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;

ENTITY onewire_phy IS
   GENERIC (
      g_clk_freq     : INTEGER := 125000000;                         -- Input clk frequency in Hz
      g_tslot        : INTEGER := 90;                                -- Time slot duration, for reads and writes, TW0L+TREC (us)
      g_tmsr         : INTEGER := 10;                                -- Read window sample time from read edge, includes trl (us)
      g_trl          : INTEGER := 6;                                 -- Read low time from read edge (us)
      g_tw0l         : INTEGER := 80;                                -- Write 0 low time (us)
      g_tw1l         : INTEGER := 10;                                -- Write 1 low time (us)
      g_trsth        : INTEGER := 500;                               -- rst recovery time (us)
      g_trstl        : INTEGER := 500;                               -- rst low time (us)
      g_tmsp         : INTEGER := 65);                               -- Presence detect sample time (us)
   PORT(
      clk            : IN STD_LOGIC;                                 -- Main clk signal
      rst            : IN STD_LOGIC;                                 -- Main rst

      go             : IN STD_LOGIC;                                 -- Start signal, rising edge to go
      finished       : OUT STD_LOGIC;                                -- Finished signal

      op_code        : IN T_PHY_OPCODE;                              -- Type of operation
      strong_pullup  : IN STD_LOGIC;                                 -- Enable the strong pullup when asserted

      data_i         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);              -- Write data
      data_o         : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);             -- Read data
      presence       : OUT STD_LOGIC;                                -- Output of rst pulse

      -- CRC SIGNALS
      crc8           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      crc16          : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      crc_rst        : IN STD_LOGIC;                                 -- rst the CRC to 0's

      onewire_strong : OUT STD_LOGIC;                                -- Active low strong pullup
      onewire        : INOUT STD_LOGIC);                             -- Onewire bus
END onewire_phy;

ARCHITECTURE BRAINS OF onewire_phy IS

-------------------------------------------------------------------------------
--                                  Types                                    --
-------------------------------------------------------------------------------

   TYPE t_state IS (s_idle,
                       s_rst_pulse,
                       s_rst_pulse_wait,
                       s_rst_pulse_sample,
                       s_rst_pulse_recovery,
                       s_write_data,
                       s_write_data_wait,
                       s_write_data_shift,
                       s_write_data_recovery,
                       s_read_data,
                       s_read_data_wait,
                       s_read_data_sample,
                       s_read_data_recovery,
                       s_finished);

-------------------------------------------------------------------------------
--                                Constants                                  --
-------------------------------------------------------------------------------

   -- The width of the counter, in bits, used to divide down the clk
   CONSTANT c_width              : INTEGER := ceil_log2((g_trsth*(g_clk_freq/1E3))/1E3);             -- Pick the largest time constant to determine the width of the counter

   -- clk generator constants
   CONSTANT c_tslot_cnt          : UNSIGNED(c_width-1 DOWNTO 0) := TO_UNSIGNED((g_tslot*(g_clk_freq/1E3))/1E3, c_width);
   CONSTANT c_tmsr_cnt           : UNSIGNED(c_width-1 DOWNTO 0) := TO_UNSIGNED((g_tmsr*(g_clk_freq/1E3))/1E3, c_width);
   CONSTANT c_trl_cnt            : UNSIGNED(c_width-1 DOWNTO 0) := TO_UNSIGNED((g_trl*(g_clk_freq/1E3))/1E3, c_width);
   CONSTANT c_tw0l_cnt           : UNSIGNED(c_width-1 DOWNTO 0) := TO_UNSIGNED((g_tw0l*(g_clk_freq/1E3))/1E3, c_width);
   CONSTANT c_tw1l_cnt           : UNSIGNED(c_width-1 DOWNTO 0) := TO_UNSIGNED((g_tw1l*(g_clk_freq/1E3))/1E3, c_width);
   CONSTANT c_trsth_cnt          : UNSIGNED(c_width-1 DOWNTO 0) := TO_UNSIGNED((g_trsth*(g_clk_freq/1E3))/1E3, c_width);
   CONSTANT c_trstl_cnt          : UNSIGNED(c_width-1 DOWNTO 0) := TO_UNSIGNED((g_trstl*(g_clk_freq/1E3))/1E3, c_width);
   CONSTANT c_tmsp_cnt           : UNSIGNED(c_width-1 DOWNTO 0) := TO_UNSIGNED((g_tmsp*(g_clk_freq/1E3))/1E3, c_width);

-------------------------------------------------------------------------------
--                                Signals                                    --
-------------------------------------------------------------------------------

   -- Onewire Signals
   SIGNAL i_onewire_i            : STD_LOGIC;
   SIGNAL onewire_oe             : STD_LOGIC;
   SIGNAL i_onewire_oe           : STD_LOGIC;

   -- Core FSM Signals
   SIGNAL op_state               : t_state;
   SIGNAL period_counter           : UNSIGNED(c_width-1 DOWNTO 0);
   SIGNAL rst_counter            : STD_LOGIC;
   SIGNAL bit_count              : UNSIGNED(2 downto 0);
   SIGNAL shifter                : STD_LOGIC_VECTOR(7 DOWNTO 0);

   -- CRC Signals
   SIGNAL sig_crc_data           : STD_LOGIC;
   SIGNAL sig_crc16              : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL sig_crc8               : STD_LOGIC_VECTOR(7 DOWNTO 0);

BEGIN

-------------------------------------------------------------------------------
--                             IO REGISTERING                                --
-------------------------------------------------------------------------------

   -- Strong pullup not used
   onewire_strong <= NOT(strong_pullup);

   onewire <= '0' WHEN onewire_oe = '0' ELSE 'Z';

io_register: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(CLK) THEN
         i_onewire_i <= to_x01(onewire);
         onewire_oe <= i_onewire_oe;
      END IF;
   END PROCESS;


-------------------------------------------------------------------------------
--                              CRC GENERATOR                                --
-------------------------------------------------------------------------------

crc_gen: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         if crc_rst = '1' then
            sig_crc8 <= (others => '0');
            sig_crc16 <= (others => '0');
         else
            if op_state = s_write_data_shift or op_state = s_read_data_sample then
               -- X8+X5+X4+1 (0x00 on success)
               sig_crc8 <= (sig_crc8(0) xor sig_crc_data) &
                            sig_crc8(7 downto 5) &
                           (sig_crc8(4) xor (sig_crc8(0) xor sig_crc_data)) &
                           (sig_crc8(3) xor (sig_crc8(0) xor sig_crc_data)) &
                            sig_crc8(2 downto 1);

               -- X16+X15+X2+1 (0xB001 on success)
               sig_crc16 <= (sig_crc16(0) xor sig_crc_data) &
                             sig_crc16(15) &
                            (sig_crc16(14) xor (sig_crc16(0) xor sig_crc_data)) &
                             sig_crc16(13 downto 2) &
                            (sig_crc16(1) xor (sig_crc16(0) xor sig_crc_data));
            END IF;
         END IF;
      END IF;
   END PROCESS;

   sig_crc_data <= shifter(0) WHEN op_code = OP_WRITE8 ELSE i_onewire_i;

   crc16 <= sig_crc16;
   crc8 <= sig_crc8;

-------------------------------------------------------------------------------
--                               DATA SHIFTER                                --
-------------------------------------------------------------------------------

data_shifter: process(clk)
   begin
      if rising_edge(clk) then
         if go = '1' and op_state = s_idle then
            shifter <= data_i;
            presence <= '0';
         else
            if op_state = s_write_data_shift or op_state = s_read_data_sample then
               shifter <= i_onewire_i & shifter(7 downto 1);
            end if;
         end if;

         if op_state = s_rst_pulse_sample then
            presence <= not(i_onewire_i);
         end if;
      end if;
   end process;

   data_o <= shifter;

   i_onewire_oe <= '0' when op_state = s_rst_pulse or op_state = s_write_data or op_state = s_read_data else
                   shifter(0) when op_state = s_write_data_wait else
                   '1';

-------------------------------------------------------------------------------
--                                    FSM                                    --
-------------------------------------------------------------------------------
-- OPERATION: Simple state machine based on a counter and the timing constants as
--            defined by the device datasheet.

main_fsm: process(clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
            op_state <= s_idle;
            rst_counter <= '1';
         else
            rst_counter <= '0';
            case op_state is
               when s_idle =>                                        -- FSM is off
                  if go = '1' then
                     if i_onewire_i /= '1' then                      -- 1 wire bus must be high to start with
                        op_state <= s_finished;
                     else
                        if op_code = OP_PRESENCE then
                           op_state <= s_rst_pulse;
                        elsif op_code = OP_WRITE8 then
                           op_state <= s_write_data;
                        else
                           op_state <= s_read_data;
                        end if;
                        rst_counter <= '1';
                        bit_count <= (others => '0');
                     end if;
                  end if;

               --------------
               when s_rst_pulse =>                                 -- Hold the IO line low until tRSTL has expired then release
                  if period_counter = c_trstl_cnt then
                     rst_counter <= '1';
                     op_state <= s_rst_pulse_wait;
                  end if;
               when s_rst_pulse_wait =>
                  if period_counter = c_tmsp_cnt then
                     op_state <= s_rst_pulse_sample;
                  end if;
               when s_rst_pulse_sample =>
                  op_state <= s_rst_pulse_recovery;
               when s_rst_pulse_recovery =>
                  if period_counter = c_trsth_cnt then
                     op_state <= s_finished;
                  end if;

               --------------
               when s_write_data =>                                  -- Create the time slot first then transmit the data
                  if period_counter = c_tw1l_cnt then
                     op_state <= s_write_data_wait;
                  end if;
               when s_write_data_wait =>
                  if period_counter = c_tw0l_cnt then
                     op_state <= s_write_data_shift;
                  end if;
               when s_write_data_shift =>
                  op_state <= s_write_data_recovery;
               when s_write_data_recovery =>
                  if period_counter = c_tslot_cnt then
                     if bit_count = 7 then
                        op_state <= s_finished;
                     else
                        bit_count <= bit_count+1;
                        op_state <= s_write_data;
                        rst_counter <= '1';
                     end if;
                  end if;

               --------------
               when s_read_data =>
                  if period_counter = c_trl_cnt then
                     op_state <= s_read_data_wait;
                  end if;
               when s_read_data_wait =>
                  if period_counter = c_tmsr_cnt then
                     op_state <= s_read_data_sample;
                  end if;
               when s_read_data_sample =>
                  op_state <= s_read_data_recovery;
               when s_read_data_recovery =>
                  if period_counter = c_tslot_cnt then
                     if bit_count = 7 then
                        op_state <= s_finished;
                     else
                        bit_count <= bit_count + 1;
                        op_state <= s_read_data;
                        rst_counter <= '1';
                     end if;
                  end if;

               --------------
               WHEN s_finished =>
                  IF go = '0' THEN
                     op_state <= s_idle;
                  END IF;
            end case;
         end if;
      end if;
   end process;

   finished <= '1' WHEN op_state = s_finished ELSE '0';


counter: PROCESS(clk)
   BEGIN
      IF RISING_EDGE(clk) THEN
         IF rst_counter = '1' THEN
            period_counter <= (OTHERS => '0');
         ELSE
            period_counter <= period_counter + 1;
         END IF;
      END IF;
   END PROCESS;


end brains;




