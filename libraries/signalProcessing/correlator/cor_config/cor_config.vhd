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

use work.cor_config_reg_pkg.all;

entity cor_config is
    Generic (
        g_COL_DIMENSION : integer
    );
    Port ( 
        i_mace_clk                  : in  std_logic;
        i_mace_clk_rst              : in  std_logic;
        i_cturn_clks                : in  std_logic_vector(g_COL_DIMENSION-1 downto 0);            
        o_cturn_clk_resets          : out std_logic_vector(g_COL_DIMENSION-1 downto 0);            
        i_ctx_clk                   : in  std_logic;
        o_ctx_clk_reset             : out std_logic;
        i_cmac_clk                  : in  std_logic;
        o_cmac_clk_reset            : out std_logic;
        
        --MACE:
        i_saxi_mosi                 : IN  t_axi4_lite_mosi;
        o_saxi_miso                 : OUT t_axi4_lite_miso
    );        
end cor_config;

architecture Behavioral of cor_config is

    signal mace_reset        : std_logic;
    signal mace_ctx_reset    : std_logic;
    signal mace_cmac_reset   : std_logic;
    signal mace_cturn_reset  : std_logic;

    signal SETUP_FIELDS_RW : t_setup_rw;
    signal SETUP_FIELDS_RO : t_setup_ro;

begin
    
    ------------------------------------------------------------------------------------
    -- MACE
    ------------------------------------------------------------------------------------
    E_MACE_CONFIG: entity work.cor_config_reg
    PORT MAP(
        MM_CLK  => i_mace_clk,
        MM_RST  => i_mace_clk_rst,
        SLA_IN  => i_saxi_mosi,
        SLA_OUT => o_saxi_miso,
        --setup
        SETUP_FIELDS_RW => SETUP_FIELDS_RW,
        SETUP_FIELDS_RO => SETUP_FIELDS_RO
    );
    
    mace_reset <= SETUP_FIELDS_RW.full_reset;
    
    ------------------------------------------------------------------------------------
    -- Reset FSM
    ------------------------------------------------------------------------------------
    -- Release reset in a defined order from output to input.
    -- We actively wait for the HBM to report having finished its setup routine.
    ------------------------------------------------------------------------------------
    GEN_RESET: if true generate
        type t_state is (s_POR, s_RESET, s_RUNNING); 
        signal state   : t_state := s_POR;
    begin
        P_FSM: process(i_mace_clk)
        begin
            if rising_edge(i_mace_clk) then
                if i_mace_clk_rst='1' then
                    state <= s_POR;
                    mace_ctx_reset   <= '1';
                    mace_cmac_reset  <= '1';
                    mace_cturn_reset <= '1';
                else
                    case state is
                    when s_POR =>
                        mace_ctx_reset   <= '1';
                        mace_cmac_reset  <= '1';
                        mace_cturn_reset <= '1';
                        if mace_reset='1' then
                            state <= s_RESET;
                        end if;
                    
                    when s_RESET =>
                        mace_ctx_reset   <= '1';
                        mace_cmac_reset  <= '1';
                        mace_cturn_reset <= '1';
                        if mace_reset='0' then
                            state <= s_RUNNING;
                        end if;
                   
                    when s_RUNNING =>
                        mace_ctx_reset   <= '0';
                        mace_cmac_reset  <= '0';
                        mace_cturn_reset <= '0';
                        if mace_reset='1' then
                            state <= s_RESET;
                        end if;
                    end case;
                end if; 
            end if;
        end process;

        G_CTURN_RST: for idx in 0 to g_COL_DIMENSION-1 generate
        begin
            E_CDC_CTURN_RST : xpm_cdc_single
            generic map (
                DEST_SYNC_FF => 2,   
                INIT_SYNC_FF => 0, 
                SIM_ASSERT_CHK => 0,
                SRC_INPUT_REG => 1  
            )
            port map (
                src_clk  => i_mace_clk,  
                src_in   => mace_cturn_reset,     
                dest_clk => i_cturn_clks(idx),
                dest_out => o_cturn_clk_resets(idx)
            );
        end generate;
        
        E_CDC_CTX_RST : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_ctx_reset,     
            dest_clk => i_ctx_clk,
            dest_out => o_ctx_clk_reset
        );

        E_CDC_CMAC_RST : xpm_cdc_single
        generic map (
            DEST_SYNC_FF => 2,   
            INIT_SYNC_FF => 0, 
            SIM_ASSERT_CHK => 0,
            SRC_INPUT_REG => 1  
        )
        port map (
            src_clk  => i_mace_clk,  
            src_in   => mace_cmac_reset,     
            dest_clk => i_cmac_clk,
            dest_out => o_cmac_clk_reset
        );
        
    end generate;

end Behavioral;
