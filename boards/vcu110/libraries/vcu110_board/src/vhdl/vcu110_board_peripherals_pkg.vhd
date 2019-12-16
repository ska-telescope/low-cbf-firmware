-------------------------------------------------------------------------------
--
-- Copyright (C) 2009-2016
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

-- Purpose: Central location for collecting the peripheral MM register widths
-- Description:
--   The MM register width can be fixed or application dependent. When the MM
--   register width is fixed it can be defined as a local constant in the
--   module *_reg.vhd file or it may be defined in a module package.
--   When modules are used in a design the MM register widths are needed to
--   connect the 'node' part of the design to the 'sopc' part. Most designs do
--   use the same widths also for the variable width MM registers. Therefore
--   rather then obtaining the variable MM register widths from local design
--   constants and the fixed widths from module packages, it seems easier to
--   collect them here in t_c_vcu110_board_peripherals_mm_reg.
-- Remarks:
-- . The c_vcu110_board_peripherals_mm_reg_default suits most designs, if
--   necessary design specific t_c_vcu110_board_peripherals_mm_reg constants
--   can be defined here as well.
-- . If some design would need different widths for multiple instances, then
--   these widths need to be defined locally in that design.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE vcu110_board_peripherals_pkg IS

  
  -- *_adr_w : Actual MM address widths
  -- *_dat_w : The default MM data width is c_word_w=32, otherwise it is specified in the record
  TYPE t_c_vcu110_board_peripherals_mm_reg IS RECORD
    cross_clock_domain         : BOOLEAN;  -- = TRUE  -- use FALSE when mm_clk and dp_clk are the same, else use TRUE to cross the clock domain
    
    -- 1GbE
    reg_tse_adr_w              : NATURAL;  -- = 10  -- = c_tse_byte_addr_w from tse_pkg.vhd
    reg_eth_adr_w              : NATURAL;  -- = 4   -- = c_eth_reg_addr_w from eth_pkg.vhd
    ram_eth_adr_w              : NATURAL;  -- = 10  -- = c_eth_ram_addr_w from eth_pkg.vhd
    
    -- pi_system_info (first word of reg_unb_system_info_adr_w is backwards compatible with the original single word PIO system info)
    reg_unb_system_info_adr_w  : NATURAL;  -- = 5   -- fixed, from c_mm_reg in unb_system_info_reg
    rom_unb_system_info_adr_w  : NATURAL;  -- = 10  -- fixed, from c_mm_rom in mms_unb_system_info
    -- pi_reg_common
    reg_common_adr_w           : NATURAL;  -- = 1   -- fixed, from c_mem_reg in mms_common_reg
    
    -- pi_ppsh
    reg_ppsh_adr_w             : NATURAL;  -- = 1   -- fixed, from c_mm_reg in ppsh_reg
    
    -- pi_unb_sens
    reg_unb_sens_adr_w         : NATURAL;  -- = 6   -- fixed, from c_mm_reg in unb_sens_reg
    
    -- pi_dpmm
    reg_dpmm_data_adr_w        : NATURAL;  -- = 1   -- fixed, see dp_fifo_to_mm.vhd
    reg_dpmm_ctrl_adr_w        : NATURAL;  -- = 1   -- fixed, from c_mm_reg in dp_fifo_to_mm_reg.vhd
    
    -- pi_mmdp
    reg_mmdp_data_adr_w        : NATURAL;  -- = 1   -- fixed, see dp_fifo_from_mm.vhd
    reg_mmdp_ctrl_adr_w        : NATURAL;  -- = 1   -- fixed, from c_mm_reg in dp_fifo_from_mm_reg.vhd

    -- pi_dp_ram_from_mm
    reg_dp_ram_from_mm_adr_w   : NATURAL;  -- = 1   -- fixed, see dp_ram_from_mm.vhd
 -- ram_dp_ram_from_mm_adr_w   : NATURAL;  -- = VAR -- Variable, from c_mm_reg in dp_ram_from_mm_reg.vhd

    -- pi_dp_ram_to_mm
--  ram_dp_ram_to_mm_adr_w     : NATURAL;  -- = VAR -- Variable, from c_mm_reg in dp_ram_to_mm_reg.vhd
    
    -- pi_epcs (uses DP-MM read and write FIFOs for data access)
    reg_epcs_adr_w             : NATURAL;  -- = 3   -- fixed, from c_mm_reg in epcs_reg
    
    -- pi_remu
    reg_remu_adr_w             : NATURAL;  -- = 3   -- fixed, from c_mm_reg in remu_reg
    
    -- pi_ddr
    -- pi_ddr_capture (uses DP-MM read FIFO for data access)
    reg_ddr_adr_w              : NATURAL;  -- = 3   -- fixed, from c_mm_reg in ddr_reg
    
    -- pi_io_ddr
    reg_io_ddr_adr_w           : NATURAL;  -- = 16  -- fixed, from c_mm_reg in io_ddr (3) and in io_ddr_reg (8) that get multiplexed in on addresses 0..2, 8..15
    
    -- pi_tr_nonbonded
    reg_tr_nonbonded_adr_w     : NATURAL;  -- = 4   -- fixed, from c_mm_reg in tr_nonbonded_reg

    -- pi_diagnostics
    reg_diagnostics_adr_w      : NATURAL;  -- = 6   -- fixed, from c_mm_reg in diagnostics_reg

    -- pi_dp_throttle
    reg_dp_throttle_adr_w      : NATURAL;  -- = 2   -- fixed, from c_mm_reg in dp_throttle_reg
    
    -- pi_bsn_source
    reg_bsn_source_adr_w       : NATURAL;  -- = 2   -- fixed, from c_mm_reg in dp_bsn_source_reg.vhd
    
    -- pi_bsn_schedurer
    reg_bsn_scheduler_adr_w    : NATURAL;  -- = 1   -- fixed, from c_mm_reg in dp_bsn_scheduler_reg.vhd
    
    -- pi_bsn_monitor
    reg_bsn_monitor_adr_w      : NATURAL;  -- = 4   -- fixed, from c_mm_reg in dp_bsn_monitor_reg.vhd
    
    -- pi_aduh_quad (defaults for ADU)
    reg_adc_quad_adr_w         : NATURAL;  -- = 3   -- fixed, from c_mm_reg in aduh_quad_reg.vhd
    
    -- pi_aduh_i2c_commander (defaults for ADU)
    reg_i2c_commander_adr_w    : NATURAL;  -- = 6   -- = c_i2c_cmdr_aduh_i2c_mm.control_adr_w,  from i2c_commander_aduh_pkg, used to pass on commander_adr_w
    ram_i2c_protocol_adr_w     : NATURAL;  -- = 13  -- = c_i2c_cmdr_aduh_i2c_mm.protocol_adr_w, from i2c_commander_aduh_pkg
    ram_i2c_result_adr_w       : NATURAL;  -- = 12  -- = c_i2c_cmdr_aduh_i2c_mm.result_adr_w,   from i2c_commander_aduh_pkg
    
    -- pi_aduh_monitor (defaults for ADU or WG used in bn_capture)
    reg_aduh_mon_adr_w         : NATURAL;  -- = 2   -- fixed, from c_mm_reg in aduh_monitor_reg.vhd
    ram_aduh_mon_dat_w         : NATURAL;  -- = 32  -- = c_sp_data_w, see node_bn_capture.vhd
    ram_aduh_mon_adr_w         : NATURAL;  -- = 8   -- = ceil_log2(c_bn_capture.sp.monitor_buffer_nof_samples/c_wideband_factor), see node_bn_capture.vhd
    
    -- pi_diag_wg_wideband.py (defaults for WG used in bn_capture)
    reg_diag_wg_adr_w          : NATURAL;  -- = 2   -- fixed, from c_mm_reg in diag_wg_wideband_reg
    ram_diag_wg_dat_w          : NATURAL;  -- = 8   -- defined here, see bn_capture_input.vhd
    ram_diag_wg_adr_w          : NATURAL;  -- = 10  -- defined here, see bn_capture_input.vhd
    
    -- pi_diag_data_buffer.py
    ram_diag_db_nof_buf        : NATURAL;  -- = 16
    ram_diag_db_buf_size       : NATURAL;  -- = 1024
    ram_diag_db_adr_w          : NATURAL;  -- = 14  -- = ram_diag_db_nof_buf*ceil_log2(ram_diag_db_buf_size)
    reg_diag_db_adr_w          : NATURAL;  -- = 5   -- 32 words for 16 streams max

    -- pi_diag_block_gen (defaults when used with the BF for Apertif)
    reg_diag_bg_adr_w          : NATURAL;  -- = 3
    ram_diag_bg_adr_w          : NATURAL;  -- = 11  -- = ceil_log2(c_bf.nof_subbands*c_bf.nof_signal_paths/c_bf.nof_input_streams = 24*64/16 = 96) + ceil_log2(c_bf.nof_input_streams = 16)
  
    -- pi_diag_tx_seq.py
    reg_diag_tx_seq_w          : NATURAL;  -- = 2
    
    -- pi_diag_tx_seq.py
    reg_diag_rx_seq_w          : NATURAL;  -- = 3
    
    -- pi_bf_bf (defaults for the BF for Apertif)
    reg_bf_offsets_adr_w       : NATURAL;  -- = 5   -- = ceil_log2(c_bf.nof_offsets = 6) + ceil_log2(c_bf.nof_bf_units = 4)
    ram_bf_weights_adr_w       : NATURAL;  -- = 16  -- = ceil_log2(c_bf.nof_bf_units*c_bf.nof_signal_paths*c_bf.nof_weights = 4 * 64 * 256 = 65536)
    ram_st_sst_bf_adr_w        : NATURAL;  -- = 11  -- = ceil_log2(c_bf.nof_bf_units*c_bf.stat_data_sz*c_bf.nof_weights = 4 * 2 * 256 = 2048)

    -- pi_mdio
    reg_mdio_adr_w             : NATURAL;  -- = 3

    -- dp_offload
    reg_dp_offload_tx_adr_w    : NATURAL;  -- = 1

    -- pi_unb_fpga_sensors
    reg_fpga_temp_sens_adr_w    : NATURAL;  -- = 3
    reg_fpga_voltage_sens_adr_w : NATURAL;  -- = 4

    -- pi_unb_pmbus
    reg_unb_pmbus_adr_w        : NATURAL;  -- = 6
  END RECORD;
  
  CONSTANT c_vcu110_board_peripherals_mm_reg_default    : t_c_vcu110_board_peripherals_mm_reg := (TRUE, 10, 4, 10, 5, 10, 1, 1, 6, 1, 1, 1, 1, 1, 3, 3, 3, 16, 4, 6, 2, 2, 1, 4, 3, 6, 13, 12, 2, 32, 8, 2, 8, 10, 16, 1024, 14, 5, 3, 11, 2, 3, 5, 16, 11, 3, 1, 3, 4, 6);
  
END vcu110_board_peripherals_pkg;

PACKAGE BODY vcu110_board_peripherals_pkg IS
END vcu110_board_peripherals_pkg;
