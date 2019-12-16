-------------------------------------------------------------------------------
--
-- Copyright (C) 2009
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

ENTITY tb_i2c_master IS
END tb_i2c_master;

LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;
USE common_lib.common_mem_pkg.ALL;
USE common_lib.tb_common_pkg.ALL;
USE common_lib.tb_common_mem_pkg.ALL;
USE work.i2c_smbus_pkg.ALL;
USE work.i2c_dev_max1617_pkg.ALL;
USE work.i2c_dev_max6652_pkg.ALL;
USE work.i2c_pkg.ALL;


ARCHITECTURE tb OF tb_i2c_master IS

  CONSTANT c_sim                 : BOOLEAN := TRUE;  --FALSE
  CONSTANT c_clk_freq_in_MHz     : NATURAL := 100;  -- 100 MHz
  CONSTANT c_clk_period          : TIME    := (10**3/c_clk_freq_in_MHz) * 1 ns;
  CONSTANT c_rst_period          : TIME    := 4 * c_clk_period;
  
  CONSTANT c_phy_i2c              : t_c_i2c_phy := func_i2c_sel_a_b(c_sim, c_i2c_phy_sim, func_i2c_calculate_phy(c_clk_freq_in_MHz));
  
  CONSTANT c_bus_dat_w           : NATURAL := 8;
  CONSTANT c_sens_temp_volt_sz   : NATURAL := 9;  -- Should match nof read bytes via I2C in the sens_ctrl SEQUENCE list
  
  -- Model I2C sensor slaves as on the LOFAR RSP board
  CONSTANT ADR_MAX6652           : NATURAL := MAX6652_ADR_GND;
  CONSTANT ADR_MAX1617_BP        : NATURAL := MAX1617_ADR_MID_MID;
  CONSTANT ADR_MAX1617_AP0       : NATURAL := MAX1617_ADR_LOW_LOW;
  CONSTANT ADR_MAX1617_AP1       : NATURAL := MAX1617_ADR_LOW_HIGH;
  CONSTANT ADR_MAX1617_AP2       : NATURAL := MAX1617_ADR_HIGH_LOW;
  CONSTANT ADR_MAX1617_AP3       : NATURAL := MAX1617_ADR_HIGH_HIGH;
    
  CONSTANT c_bp_volt_address     : STD_LOGIC_VECTOR := TO_UVEC(ADR_MAX6652,     7);  -- MAX6652 address GND
  CONSTANT c_bp_temp_address     : STD_LOGIC_VECTOR := TO_UVEC(ADR_MAX1617_BP,  7);  -- MAX1618 address MID  MID
  CONSTANT c_ap0_temp_address    : STD_LOGIC_VECTOR := TO_UVEC(ADR_MAX1617_AP0, 7);  -- MAX1618 address LOW  LOW
  CONSTANT c_ap1_temp_address    : STD_LOGIC_VECTOR := TO_UVEC(ADR_MAX1617_AP1, 7);  -- MAX1618 address LOW  HIGH
  CONSTANT c_ap2_temp_address    : STD_LOGIC_VECTOR := TO_UVEC(ADR_MAX1617_AP2, 7);  -- MAX1618 address HIGH LOW
  CONSTANT c_ap3_temp_address    : STD_LOGIC_VECTOR := TO_UVEC(ADR_MAX1617_AP3, 7);  -- MAX1618 address HIGH HIGH
  CONSTANT c_bp_temp             : INTEGER := 60;
  CONSTANT c_ap0_temp            : INTEGER := 70;
  CONSTANT c_ap1_temp            : INTEGER := 71;
  CONSTANT c_ap2_temp            : INTEGER := 72;
  CONSTANT c_ap3_temp            : INTEGER := 73;
  CONSTANT c_volt_1v2            : NATURAL := 92;     --  92 *  2.5/192 = 1.2
  CONSTANT c_volt_2v5            : NATURAL := 147;    -- 147 *  3.3/192 = 2.5
  CONSTANT c_volt_nc             : NATURAL := 13;     --  13 * 12  /192 = 0.1
  CONSTANT c_volt_3v3            : NATURAL := 127;    -- 127 *  5.0/192 = 3.3
  CONSTANT c_temp_pcb            : NATURAL := 40;
  CONSTANT c_temp_high           : NATURAL := 127;
  
  CONSTANT c_protocol_list : t_nat_natural_arr := (
    SMBUS_READ_BYTE , ADR_MAX6652    , MAX6652_REG_READ_VIN_2_5,
    SMBUS_READ_BYTE , ADR_MAX6652    , MAX6652_REG_READ_VIN_3_3, 
    SMBUS_READ_BYTE , ADR_MAX6652    , MAX6652_REG_READ_VCC, 
    SMBUS_READ_BYTE , ADR_MAX6652    , MAX6652_REG_READ_TEMP, 
    SMBUS_READ_BYTE , ADR_MAX1617_BP , MAX1617_CMD_READ_REMOTE_TEMP,
--  For debugging, use AP temp fields in RSR to read other info from the sensor, e.g.:
--     SMBUS_READ_BYTE , ADR_MAX1617_BP , MAX1617_CMD_READ_STATUS,
--     SMBUS_READ_BYTE , ADR_MAX1617_BP , MAX1617_CMD_READ_CONFIG,
--     SMBUS_READ_BYTE , ADR_MAX1617_BP , MAX1617_CMD_READ_REMOTE_HIGH,
--     SMBUS_READ_BYTE , ADR_MAX1617_BP , MAX1617_CMD_READ_REMOTE_LOW,
    SMBUS_READ_BYTE , ADR_MAX1617_AP0, MAX1617_CMD_READ_REMOTE_TEMP,
    SMBUS_READ_BYTE , ADR_MAX1617_AP1, MAX1617_CMD_READ_REMOTE_TEMP,
    SMBUS_READ_BYTE , ADR_MAX1617_AP2, MAX1617_CMD_READ_REMOTE_TEMP,
    SMBUS_READ_BYTE , ADR_MAX1617_AP3, MAX1617_CMD_READ_REMOTE_TEMP,
    SMBUS_WRITE_BYTE, ADR_MAX6652    , MAX6652_REG_CONFIG,           MAX6652_CONFIG_LINE_FREQ_SEL+MAX6652_CONFIG_START,
    SMBUS_WRITE_BYTE, ADR_MAX1617_BP , MAX1617_CMD_WRITE_CONFIG,     MAX1617_CONFIG_ID+MAX1617_CONFIG_THERM,
    SMBUS_WRITE_BYTE, ADR_MAX1617_AP0, MAX1617_CMD_WRITE_CONFIG,     MAX1617_CONFIG_ID+MAX1617_CONFIG_THERM,
    SMBUS_WRITE_BYTE, ADR_MAX1617_AP1, MAX1617_CMD_WRITE_CONFIG,     MAX1617_CONFIG_ID+MAX1617_CONFIG_THERM,
    SMBUS_WRITE_BYTE, ADR_MAX1617_AP2, MAX1617_CMD_WRITE_CONFIG,     MAX1617_CONFIG_ID+MAX1617_CONFIG_THERM,
    SMBUS_WRITE_BYTE, ADR_MAX1617_AP3, MAX1617_CMD_WRITE_CONFIG,     MAX1617_CONFIG_ID+MAX1617_CONFIG_THERM,
    SMBUS_WRITE_BYTE, ADR_MAX1617_BP , MAX1617_CMD_WRITE_REMOTE_HIGH, c_temp_high,
    SMBUS_WRITE_BYTE, ADR_MAX1617_AP0, MAX1617_CMD_WRITE_REMOTE_HIGH, c_temp_high,
    SMBUS_WRITE_BYTE, ADR_MAX1617_AP1, MAX1617_CMD_WRITE_REMOTE_HIGH, c_temp_high,
    SMBUS_WRITE_BYTE, ADR_MAX1617_AP2, MAX1617_CMD_WRITE_REMOTE_HIGH, c_temp_high,
    SMBUS_WRITE_BYTE, ADR_MAX1617_AP3, MAX1617_CMD_WRITE_REMOTE_HIGH, c_temp_high,
    SMBUS_C_END
  );
  
  -- Expected result list for the c_protocol_list
  -- . entries 0 should also be 0 in the result buffer
  -- . entries 1 indicate a read octet that needs to be stored for the user
  CONSTANT c_expected_mask : t_nat_natural_arr := (1, 0,
                                                   1, 0,
                                                   1, 0,
                                                   1, 0,
                                                   1, 0,
--                                                    1, 0,
--                                                    1, 0,
--                                                    1, 0,
--                                                    1, 0,
                                                   1, 0,
                                                   1, 0,
                                                   1, 0,
                                                   1, 0,
                                                   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
                                                 
  -- Expected bytes as read by c_protocol_list : 92, 147, 127, 40, 60, 70, 71, 72, 73
  -- . Keep the zeros in like with c_expected_mask to be able to use a single result_cnt for addressing
  CONSTANT c_expected_data : t_nat_natural_arr := (c_volt_1v2, 0,
                                                   c_volt_2v5, 0,
                                                   c_volt_3v3, 0,
                                                   c_temp_pcb, 0,
                                                   c_bp_temp,  0,
--                                                    1, 0,
--                                                    1, 0,
--                                                    1, 0,
--                                                    1, 0,
                                                   c_ap0_temp, 0,
                                                   c_ap1_temp, 0,
                                                   c_ap2_temp, 0,
                                                   c_ap3_temp, 0,
                                                   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
                                                 
  -- Control register
  CONSTANT c_control_activate     : NATURAL := 1;
  CONSTANT c_control_ready_bi     : NATURAL := 1;
  
  signal tb_end            : STD_LOGIC := '0';
  SIGNAL clk               : STD_LOGIC := '0';
  SIGNAL rst               : STD_LOGIC := '1';
 
  SIGNAL scl_stretch       : STD_LOGIC := 'Z';
  SIGNAL scl               : STD_LOGIC;
  SIGNAL sda               : STD_LOGIC;  
  
  -- MM registers interface
  SIGNAL control_miso      : t_mem_miso;
  SIGNAL control_mosi      : t_mem_mosi;
  SIGNAL protocol_miso     : t_mem_miso;
  SIGNAL protocol_mosi     : t_mem_mosi;
  SIGNAL result_miso       : t_mem_miso;
  SIGNAL result_mosi       : t_mem_mosi;
  
  SIGNAL control_status    : STD_LOGIC;
  SIGNAL control_interrupt : STD_LOGIC;
  
  SIGNAL result_rd_dly1    : STD_LOGIC;
  SIGNAL result_rd_dly2    : STD_LOGIC;
  SIGNAL result_val        : STD_LOGIC;
  SIGNAL result_data       : STD_LOGIC_VECTOR(c_byte_w-1 DOWNTO 0);
  SIGNAL result_cnt        : NATURAL := 0;
  
  SIGNAL expected_ctrl     : NATURAL;
  SIGNAL expected_data     : NATURAL;
  SIGNAL expected_cnt      : NATURAL := c_expected_data'LENGTH;
  
BEGIN

  -- run -all

  rst <= '0' AFTER 4*c_clk_period;
  clk <= (NOT clk) OR tb_end AFTER c_clk_period/2;
  
  -- I2C bus
  scl <= 'H';          -- model I2C pull up
  sda <= 'H';          -- model I2C pull up

  scl <= scl_stretch;

  sens_clk_stretch : PROCESS (scl)
  BEGIN
    IF falling_edge(scl) THEN
      scl_stretch <= '0', 'Z' AFTER 50 ns;   -- < 10 ns to effectively disable stretching, >= 50 ns to enable it
    END IF;
  END PROCESS;
  
  
  p_mm_stimuli : PROCESS
  BEGIN
    -- Wait for reset release
    control_mosi   <= c_mem_mosi_rst;
    protocol_mosi  <= c_mem_mosi_rst;
    result_mosi    <= c_mem_mosi_rst;
    control_status <= '0';
    proc_common_wait_until_low(clk, rst);
    proc_common_wait_some_cycles(clk, 10);
    
    -- Write protocol list
    FOR I IN 0 TO c_protocol_list'LENGTH-1 LOOP
      proc_mem_mm_bus_wr(I, c_protocol_list(I), clk, protocol_miso, protocol_mosi);
    END LOOP;

    -- Activate protocol list    
    proc_mem_mm_bus_wr(0, c_control_activate, clk, control_miso, control_mosi);
    
    -- Wait for protocol ready
    WHILE control_status='0' LOOP
      proc_mem_mm_bus_rd(0, clk, control_miso, control_mosi);  -- read result available in control_status
      proc_mem_mm_bus_rd_latency(c_mem_reg_rd_latency, clk);
      control_status <= control_miso.rddata(c_control_ready_bi);
      proc_common_wait_some_cycles(clk, 1);
    END LOOP;
    
    -- Read result list
    FOR I IN 0 TO c_expected_mask'LENGTH-1 LOOP
      proc_mem_mm_bus_rd(I, clk, result_miso, result_mosi);  -- read result available in result_data
    END LOOP;
    
    proc_common_wait_some_cycles(clk, 100);
    
    -- verify that there happened valid I2C communication
    ASSERT result_cnt=expected_cnt REPORT "I2C error in nof result count" SEVERITY ERROR;
    
    proc_common_wait_some_cycles(clk, 100);
    tb_end <= '1';
    WAIT;
  END PROCESS;
  
  -- Derive rdval from rd (read latency = 2) to mark when result_data read in p_mm_stimuli is valid
  result_rd_dly1 <= result_mosi.rd WHEN rising_edge(clk);
  result_rd_dly2 <= result_rd_dly1 WHEN rising_edge(clk);
  result_val  <= result_rd_dly2;
  result_data <= result_miso.rddata(c_byte_w-1 DOWNTO 0) WHEN result_val='1' ELSE (OTHERS=>'X');
  
  -- Show the expected result ctrl and expected result data
  expected_ctrl <= c_expected_mask(result_cnt MOD c_expected_mask'LENGTH);
  expected_data <= c_expected_data(result_cnt MOD c_expected_mask'LENGTH);
  
  result_cnt <= result_cnt + 1 WHEN rising_edge(clk) AND result_val='1';
  
  p_i2c_verify : PROCESS
  BEGIN
    -- verify result_data at clk and when result_val='1'
    WAIT UNTIL rising_edge(clk);
    IF result_val='1' THEN
      IF c_expected_mask(result_cnt)=0 THEN
        IF TO_UINT(result_data)/=0 THEN
          REPORT "I2C error in control result byte" SEVERITY ERROR;
        END IF;
      ELSE
        IF TO_UINT(result_data)/=expected_data THEN
          REPORT "I2C error in control result byte" SEVERITY ERROR;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  
  
  -- I2C master
  u_i2c_master : ENTITY work.i2c_master
  GENERIC MAP (
    g_i2c_mm  => c_i2c_mm,
    g_i2c_phy => c_phy_i2c
  )
  PORT MAP (
    -- GENERIC Signal
    gs_sim                   => c_sim,
    
    rst                      => rst,
    clk                      => clk,
    sync                     => '1',
    
    ---------------------------------------------------------------------------
    -- Memory Mapped Slave interface with Interrupt
    ---------------------------------------------------------------------------
    -- MM slave I2C control register
    mms_control_address      => control_mosi.address(c_i2c_mm.control_adr_w-1 DOWNTO 0),
    mms_control_write        => control_mosi.wr,
    mms_control_read         => control_mosi.rd,
    mms_control_writedata    => control_mosi.wrdata(c_word_w-1 DOWNTO 0),  -- use default MM bus width for control
    mms_control_readdata     => control_miso.rddata(c_word_w-1 DOWNTO 0),
    -- MM slave I2C protocol register
    mms_protocol_address     => protocol_mosi.address(c_i2c_mm.protocol_adr_w-1 DOWNTO 0),
    mms_protocol_write       => protocol_mosi.wr,
    mms_protocol_read        => protocol_mosi.rd,
    mms_protocol_writedata   => protocol_mosi.wrdata(c_byte_w-1 DOWNTO 0),  -- define MM bus data has same width as SMBus data
    mms_protocol_readdata    => protocol_miso.rddata(c_byte_w-1 DOWNTO 0),
    -- MM slave I2C result register
    mms_result_address       => result_mosi.address(c_i2c_mm.result_adr_w-1 DOWNTO 0),
    mms_result_write         => result_mosi.wr,
    mms_result_read          => result_mosi.rd,
    mms_result_writedata     => result_mosi.wrdata(c_byte_w-1 DOWNTO 0),  -- define MM bus data has same width as SMBus data
    mms_result_readdata      => result_miso.rddata(c_byte_w-1 DOWNTO 0),
    -- Interrupt
    ins_result_rdy           => control_interrupt,
    
    ---------------------------------------------------------------------------
    -- I2C interface
    ---------------------------------------------------------------------------
    scl                      => scl,
    sda                      => sda
  );
    
  -- I2C slaves
  sens_temp_bp : ENTITY work.dev_max1618
  GENERIC MAP (
    g_address => c_bp_temp_address
  )
  PORT MAP (
    scl  => scl,
    sda  => sda,
    temp => c_bp_temp
  );

  sens_temp_ap0 : ENTITY work.dev_max1618
  GENERIC MAP (
    g_address => c_ap0_temp_address
  )
  PORT MAP (
    scl  => scl,
    sda  => sda,
    temp => c_ap0_temp
  );

  sens_temp_ap1 : ENTITY work.dev_max1618
  GENERIC MAP (
    g_address => c_ap1_temp_address
  )
  PORT MAP (
    scl  => scl,
    sda  => sda,
    temp => c_ap1_temp
  );

  sens_temp_ap2 : ENTITY work.dev_max1618
  GENERIC MAP (
    g_address => c_ap2_temp_address
  )
  PORT MAP (
    scl  => scl,
    sda  => sda,
    temp => c_ap2_temp
  );

  sens_temp_ap3 : ENTITY work.dev_max1618
  GENERIC MAP (
    g_address => c_ap3_temp_address
  )
  PORT MAP (
    scl  => scl,
    sda  => sda,
    temp => c_ap3_temp
  );

  sens_volt_bp : ENTITY work.dev_max6652
  GENERIC MAP (
    g_address => c_bp_volt_address
  )
  PORT MAP (
    scl       => scl,
    sda       => sda,
    volt_2v5  => c_volt_1v2,
    volt_3v3  => c_volt_2v5,
    volt_12v  => c_volt_nc,
    volt_vcc  => c_volt_3v3,
    temp      => c_temp_pcb
  );
    
END tb;

