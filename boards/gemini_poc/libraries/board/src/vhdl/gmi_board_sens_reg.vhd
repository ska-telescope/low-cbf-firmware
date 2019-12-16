-------------------------------------------------------------------------------
--
-- Copyright (C) 2012-2014
-- ASTRON (Netherlands Institute for Radio Astronomy) <http://www.astron.nl/>
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

-- Purpose: Provide MM slave register for unb2_board_sens
-- Description:
--
--   31             24 23             16 15              8 7               0  wi
--  |-----------------|-----------------|-----------------|-----------------|
--  |                xxx                     fpga_temp   = sens_data[0][7:0]|  0
--  |-----------------------------------------------------------------------|
--  |                xxx                     eth_temp    = sens_data[1][7:0]|  1
--  |-----------------------------------------------------------------------|
--  |                xxx               hot_swap_v_sense  = sens_data[2][7:0]|  2
--  |-----------------------------------------------------------------------|
--  |                xxx               hot_swap_v_source = sens_data[3][7:0]|  3
--  |-----------------------------------------------------------------------|
--  |                xxx                                         sens_err[0]|  4
--  |-----------------------------------------------------------------------|
--  |                xxx                                      temp_high[6:0]|  5
--  |-----------------------------------------------------------------------|
--
-- * The fpga_temp and eth_temp are in degrees (two's complement)
-- * The hot swap voltages depend on:
--   . From i2c_dev_ltc4260_pkg:
--     LTC4260_V_UNIT_SENSE        = 0.0003  --   0.3 mV over Rs for current sense
--     LTC4260_V_UNIT_SOURCE       = 0.4     -- 400   mV supply voltage (e.g +48 V)
--     LTC4260_V_UNIT_ADIN         = 0.01    --  10   mV ADC
--
--   . From UniBoard unb_sensors.h:
--     SENS_HOT_SWAP_R_SENSE       = 0.005   -- R sense on UniBoard is 5 mOhm (~= 10 mOhm // 10 mOhm)
--     SENS_HOT_SWAP_I_UNIT_SENSE  = LTC4260_V_UNIT_SENSE / SENS_HOT_SWAP_R_SENSE
--     SENS_HOT_SWAP_V_UNIT_SOURCE = LTC4260_V_UNIT_SOURCE
--
-- ==> 
--   Via all nodes:
--   0 = FPGA temperature                 = TInt8(fpga_temp)
--   Only via node2:
--   1 = UniBoard ETH PHY temperature     = TInt8(eth_temp)
--   2 = UniBoard hot swap supply current = hot_swap_v_sense * SENS_HOT_SWAP_I_UNIT_SENSE
--   3 = UniBoard hot swap supply voltage = hot_swap_v_source * SENS_HOT_SWAP_V_UNIT_SOURCE
--   4 = I2C error status for node2 sensors access only, 0 = ok
--   

LIBRARY IEEE, common_lib;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;

ENTITY gmi_board_sens_reg IS
  GENERIC (
    g_sens_nof_result : NATURAL := 4;
    g_temp_high       : NATURAL := 85
  );
  PORT (
    -- Clocks and reset
    mm_rst     : IN  STD_LOGIC;   -- reset synchronous with mm_clk
    mm_clk     : IN  STD_LOGIC;   -- memory-mapped bus clock
    
    -- Memory Mapped Slave in mm_clk domain
    sla_in     : IN  t_mem_mosi;  -- actual ranges defined by c_mm_reg
    sla_out    : OUT t_mem_miso;  -- actual ranges defined by c_mm_reg
    
    -- MM registers
    sens_err   : IN  STD_LOGIC := '0';
    sens_data  : IN  t_slv_8_arr(0 TO g_sens_nof_result-1);

    -- Max temp output
    temp_high  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)

  );
END gmi_board_sens_reg;


ARCHITECTURE rtl OF gmi_board_sens_reg IS

  -- Define the actual size of the MM slave register
  CONSTANT c_mm_nof_dat : NATURAL := g_sens_nof_result+1+1;  -- +1 to fit user set temp_high one additional address
                                                             -- +1 to fit sens_err in the last address

  CONSTANT c_mm_reg     : t_c_mem := (latency  => 1,
                                      adr_w    => ceil_log2(c_mm_nof_dat),
                                      dat_w    => c_word_w,  -- Use MM bus data width = c_word_w = 32 for all MM registers
                                      nof_dat  => c_mm_nof_dat,
                                      init_sl  => '0');

  SIGNAL i_temp_high    : STD_LOGIC_VECTOR(6 DOWNTO 0);
                                  
BEGIN

  temp_high <= i_temp_high;

  ------------------------------------------------------------------------------
  -- MM register access in the mm_clk domain
  -- . Hardcode the shared MM slave register directly in RTL instead of using
  --   the common_reg_r_w instance. Directly using RTL is easier when the large
  --   MM register has multiple different fields and with different read and
  --   write options per field in one MM register.
  ------------------------------------------------------------------------------
  
  p_mm_reg : PROCESS (mm_rst, mm_clk)
    VARIABLE vA : NATURAL := 0;
  BEGIN
    IF mm_rst = '1' THEN
      -- Read access
      sla_out <= c_mem_miso_rst;
      -- Write access, register values
      i_temp_high <= TO_UVEC(g_temp_high, 7);

    ELSIF rising_edge(mm_clk) THEN
      vA := TO_UINT(sla_in.address(c_mm_reg.adr_w-1 DOWNTO 0));
      
      -- Read access defaults
      sla_out.rdval <= '0';
      
      -- Write access: set register value
      IF sla_in.wr = '1' THEN
        IF vA = g_sens_nof_result+1 THEN
            -- Only change temp_high if user writes a max. 7-bit value. This prevents accidentally
            -- setting a negative temp as temp_high, e.g. 128 which becomes -128. 
            IF UNSIGNED(sla_in.wrdata(c_word_w-1 DOWNTO 7)) = 0 THEN 
              i_temp_high <= sla_in.wrdata(6 DOWNTO 0);
            END IF;
        END IF;
  
      -- Read access: get register value
      ELSIF sla_in.rd = '1' THEN
        sla_out        <= c_mem_miso_rst;  -- set unused rddata bits to '0' when read
        sla_out.rdval  <= '1';             -- c_mm_reg.latency = 1
        
        -- no need to capture sens_data, it is not critical if the sens_data happens to be read just before and after an I2C access occurred
        IF vA < g_sens_nof_result THEN
          sla_out.rddata <= RESIZE_MEM_DATA(sens_data(vA)(c_byte_w-1 DOWNTO 0));
        ELSIF vA = g_sens_nof_result THEN
          sla_out.rddata(0) <= sens_err;   -- only valid for node2
        ELSE
          sla_out.rddata(6 DOWNTO 0) <= i_temp_high; 
        END IF;
        -- else unused addresses read zero
      END IF;
    END IF;
  END PROCESS;
  
END rtl;
