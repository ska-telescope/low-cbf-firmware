---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - CONFIGURATION MODULE
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert_abel@gmx.net)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- This module is the interface between MACE and the CTF.
--
-- It manages clock domain crossings of config, debug and error signals.
-- It also has a reset FSM that releases the internal resets in a well-defined order.
-- Plus: it allows MACE to reset the design at any point in time. 
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library xpm;
use xpm.vcomponents.all;

Library axi4_lib;
USE axi4_lib.axi4_lite_pkg.ALL;

use work.ctf_pkg.all;
use work.ctf_config_reg_pkg.all;

entity ctf_config is
    Port ( 
        i_mace_clk                  : in  std_logic;
        i_mace_clk_rst              : in  std_logic;
        i_input_clk                 : in  std_logic;            
        o_input_clk_rst             : out std_logic;            
        i_hbm_clk                   : in  std_logic;
        o_hbm_clk_rst               : out std_logic;
        --MACE:
        i_saxi_mosi                 : IN  t_axi4_lite_mosi;
        o_saxi_miso                 : OUT t_axi4_lite_miso;
        
        -- input buffer config (input_clk):
        o_input_halt_ts             : out std_logic_vector(43 downto 0); --maximum timestamp - filter packets higher than this            
        i_input_stopped             : in std_logic;
        
        -- CTF status (hbm_clk)
        i_hbm_ready                 : in std_logic;
        i_debug_ctf_empty           : in std_logic;
        i_debug_wa                  : in std_logic_vector(31 downto 0);
        i_debug_ra                  : in std_logic_vector(31 downto 0);
        
        --station-table (hbm_clk):
        i_station_addr  : in  std_logic_vector(09 downto 0); 
        o_station_value : out std_logic_vector(31 downto 0)
    );        
end ctf_config;

architecture Behavioral of ctf_config is

    signal mace_reset   : std_logic;
    signal mace_hbm_rst : std_logic;
    signal mace_in_rst  : std_logic;

    signal hbm_ready    : std_logic;

    signal SETUP_FIELDS_RW : t_setup_rw;
    signal SETUP_FIELDS_RO : t_setup_ro;

    signal STATIONS_TABLE_IN  : t_stations_table_ram_in;
    signal STATIONS_TABLE_OUT : t_stations_table_ram_out;

    signal REPORT_FIELDS_RO : t_report_ro;

begin
    
    ------------------------------------------------------------------------------------
    -- MACE
    ------------------------------------------------------------------------------------
    E_MACE_CONFIG: entity work.ctf_config_reg
    PORT MAP(
        MM_CLK  => i_mace_clk,
        MM_RST  => i_mace_clk_rst,
        SLA_IN  => i_saxi_mosi,
        SLA_OUT => o_saxi_miso,
        --setup
        SETUP_FIELDS_RW => SETUP_FIELDS_RW,
        SETUP_FIELDS_RO => SETUP_FIELDS_RO,
        --stations
        st_clk_stations(0) => i_hbm_clk,
        st_rst_stations(0) => '0',
        STATIONS_TABLE_IN  => STATIONS_TABLE_IN,
		STATIONS_TABLE_OUT => STATIONS_TABLE_OUT,
		--report
		REPORT_FIELDS_RO   => REPORT_FIELDS_RO
    );
    
    mace_reset <= SETUP_FIELDS_RW.full_reset;
    
    -----------------------------------------------------------------
    -- Stop Control:
    --
    -- Halt the Input on a given timestamp
    -----------------------------------------------------------------
    GEN_STOP_CONTROL: if true generate
        signal halt_ts         : std_logic_vector(43 downto 0);
        signal halt_ts_cdc     : std_logic_vector(43 downto 0);
        signal halt_ts_vld     : std_logic := '0';
        signal halt_ts_vld_cdc : std_logic;
        signal empty_cdc       : std_logic;
        signal running         : std_logic;   
    begin
        E_CDC_EMPTY : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_hbm_clk,  
            src_in   => i_debug_ctf_empty,     
            dest_clk => i_input_clk,
            dest_out => empty_cdc
        );

        E_CDC_RUNNING : xpm_cdc_single
        generic map (
            DEST_SYNC_FF   => 2,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1
        ) port map (
            src_clk   => i_input_clk,   
            src_in    => not (i_input_stopped and empty_cdc),
            dest_out  => running, 
            dest_clk  => i_mace_clk 
        );
        SETUP_FIELDS_RO.running <= running and not mace_hbm_rst;
        
        P_HALT_TS: process (i_mace_clk)
        begin
            if rising_edge(i_mace_clk) then
                halt_ts <= SETUP_FIELDS_RW.halt_timestamp_high(11 downto 0) & SETUP_FIELDS_RW.halt_timestamp_low;
                if i_mace_clk_rst='1' then
                    halt_ts_vld <= '1';
                elsif halt_ts /= SETUP_FIELDS_RW.halt_timestamp_high(11 downto 0) & SETUP_FIELDS_RW.halt_timestamp_low then
                    halt_ts_vld <= '1';
                else
                    halt_ts_vld <= '0';
                end if;
            end if;
        end process;

        E_CDC_LAST_VLD : xpm_cdc_pulse
        generic map (
            DEST_SYNC_FF   => 5,
            INIT_SYNC_FF   => 0,
            REG_OUTPUT     => 1,  
            RST_USED       => 0,    
            SIM_ASSERT_CHK => 1 
        )
        port map (
            src_clk    => i_mace_clk,
            src_rst    => '0',     
            src_pulse  => halt_ts_vld,  
            dest_clk   => i_input_clk, 
            dest_rst   => '0', 
            dest_pulse => halt_ts_vld_cdc 
        );

        E_CDC_HALT_TS : xpm_cdc_array_single
        generic map (
            DEST_SYNC_FF   => 2,
            INIT_SYNC_FF   => 0,
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG  => 1,
            WIDTH          => 44
        ) port map (
            src_clk   => i_mace_clk,   
            src_in    => halt_ts,
            dest_out  => halt_ts_cdc, 
            dest_clk  => i_input_clk
        );

        P_HALT_TS_CDC: process (i_input_clk)
        begin
            if rising_edge(i_input_clk) then
                if halt_ts_vld_cdc='1' then
                    o_input_halt_ts <= halt_ts_cdc;
                end if;
            end if;
        end process;
        
    end generate;
    
    
    
    -----------------------------------------------------------------
    -- Station Memory
    -----------------------------------------------------------------
    GEN_STATION: if true generate
    begin
        STATIONS_TABLE_IN.clk    <= i_hbm_clk;
        STATIONS_TABLE_IN.rst    <= '0';
        STATIONS_TABLE_IN.adr    <= i_station_addr;
        STATIONS_TABLE_IN.wr_en  <= '0';
        STATIONS_TABLE_IN.wr_dat <= (others => '0');
        STATIONS_TABLE_IN.rd_en  <= '1';

        o_station_value <= STATIONS_TABLE_OUT.rd_dat;        

    end generate;    
    

    
    ------------------------------------------------------------------------------------
    -- Reset FSM
    ------------------------------------------------------------------------------------
    -- Release reset in a defined order from output to input.
    -- We actively wait for the HBM to report having finished its setup routine.
    ------------------------------------------------------------------------------------
    GEN_RESET: if true generate
        type t_state is (s_POR, s_RESET, s_RELEASE_HBM, s_RUNNING); 
        signal state   : t_state := s_POR;
    begin
        P_FSM: process(i_mace_clk)
        begin
            if rising_edge(i_mace_clk) then
                if i_mace_clk_rst='1' then
                    state <= s_POR;
                    mace_in_rst  <= '1';
                    mace_hbm_rst <= '1';
                else
                    case state is
                    when s_POR =>
                        mace_in_rst  <= '1';
                        mace_hbm_rst <= '1';
                        if mace_reset='1' then
                            state <= s_RESET;
                        end if;
                    
                    when s_RESET =>
                        mace_in_rst  <= '1';
                        mace_hbm_rst <= '1';
                        if mace_reset='0' then
                            state <= s_RELEASE_HBM;
                        end if;
                   
                    when s_RELEASE_HBM =>
                        mace_in_rst  <= '1';
                        mace_hbm_rst <= '0';
                        if hbm_ready='1' then
                            state <= s_RUNNING;                        
                        end if;
                        
                    when s_RUNNING =>
                        mace_in_rst  <= '0';
                        mace_hbm_rst <= '0';
                        if mace_reset='1' then
                            state <= s_RESET;
                        end if;
                    end case;
                end if; 
            end if;
        end process;
        
        E_CDC_HBM_READY : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_hbm_clk,  
            src_in   => i_hbm_ready,     
            dest_clk => i_mace_clk,
            dest_out => hbm_ready
        );

        E_CDC_INPUT_RST : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_in_rst,     
            dest_clk => i_input_clk,
            dest_out => o_input_clk_rst
        );

        E_CDC_HBM_RST : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_hbm_rst,     
            dest_clk => i_hbm_clk,
            dest_out => o_hbm_clk_rst
        );
        
    end generate;

    E_CDC_DEBUG_WA : xpm_cdc_array_single
    generic map (
        DEST_SYNC_FF   => 2,
        INIT_SYNC_FF   => 0,
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG  => 1,
        WIDTH          => 32
    ) port map (
        src_clk   => i_hbm_clk,   
        src_in    => i_debug_wa,
        dest_out  => REPORT_FIELDS_RO.write_address, 
        dest_clk  => i_mace_clk
    );

    E_CDC_DEBUG_RA : xpm_cdc_array_single
    generic map (
        DEST_SYNC_FF   => 2,
        INIT_SYNC_FF   => 0,
        SIM_ASSERT_CHK => 0,
        SRC_INPUT_REG  => 1,
        WIDTH          => 32
    ) port map (
        src_clk   => i_hbm_clk,   
        src_in    => i_debug_ra,
        dest_out  => REPORT_FIELDS_RO.read_address, 
        dest_clk  => i_mace_clk
    );


end Behavioral;
