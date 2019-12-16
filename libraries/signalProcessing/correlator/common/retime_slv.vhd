-------------------------------------------------------------------------------
-- Title      : Retime a std_logic_vector between clock domains
-- Project    :
-------------------------------------------------------------------------------
-- File       : retime_slv.vhd
-- Author     : William Kamp  <william.kamp@aut.ac.nz>
-- Company    : High Performance Computing Research Lab, Auckland University of Technology
-- Created    : 2018-01-22
-- Last update: 2018-09-11
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2018 High Performance Computing Research Lab, Auckland University of Technology
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2018-01-22  1.0      will    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity retime_slv is

    generic (
        g_SYNCHRONISER_FLOPS : natural range 2 to 4 := 3
        );
    port (
        i_tx_clk       : in  std_logic;
        i_tx_clk_reset : in  std_logic;
        i_tx_data      : in  std_logic_vector;
        i_tx_vld       : in  std_logic;
        o_tx_ready     : out std_logic;
        --------------------------------------
        i_rx_clk       : in  std_logic;
        i_rx_clk_reset : in  std_logic;
        o_rx_data      : out std_logic_vector;
        o_rx_vld       : out std_logic;
        i_rx_ack       : in  std_logic := '1'
        );

end entity retime_slv;

architecture rtl of retime_slv is

    -- i_tx_clk domain
    type t_tx_states is (s_TX_CAPTURE, s_TX_SEND, s_TX_WAIT);
    signal tx_state : t_tx_states;

    signal tx_vld : std_logic;
    signal tx_data_false_path_from_anchor : std_logic_vector(i_tx_data'range);
    signal rx_ack_rt : std_logic;

    signal retime_slv_rx_data_false_path_to_anchor : std_logic_vector(i_tx_data'range);
    attribute ASYNC_REG : string; -- Xilinx Attribute
    attribute KEEP : string;
    attribute ASYNC_REG of retime_slv_rx_data_false_path_to_anchor : signal is "True"; -- Xilinx Attribute
    attribute KEEP of retime_slv_rx_data_false_path_to_anchor : signal is "True"; -- Xilinx Attribute

    -- i_rx_clk domain.
    type t_rx_states is (s_CAPTURE, s_RECEIVED, s_END);
    signal rx_state : t_rx_states;
    signal rx_ack : std_logic;
    signal tx_vld_rt : std_logic;

    attribute altera_attribute : string;
    attribute altera_attribute of rtl : architecture is "-name SDC_STATEMENT ""set_false_path -to *retime_slv_rx_data_false_path_to_anchor[*]""";

begin  -- architecture rtl

    P_TX_FSM : process (i_tx_clk) is
    begin
        if rising_edge(i_tx_clk) then
            tx_state <= tx_state;
            case tx_state is
                when s_TX_CAPTURE =>
                    if i_tx_vld='1' then
                        tx_state <= s_TX_SEND;
                    end if;
                when s_TX_SEND =>
                    -- wait for rx to assert ack.
                    if rx_ack_rt='1' then
                        tx_state <= s_TX_WAIT;
                    end if;
                when s_TX_WAIT =>
                    -- wait for rx to deassert ack.
                    if rx_ack_rt = '0' then
                        tx_state <= s_TX_CAPTURE;
                    end if;
                when others => null;
            end case;
            if i_tx_clk_reset='1' then
                -- start in the wait state, waiting for the receive side to exit reset, where rx_ack is held high.
                tx_state <= s_TX_WAIT;
            end if;
        end if;
    end process;

    o_tx_ready <= '1' when tx_state = s_TX_CAPTURE else '0';
    tx_vld <= '1' when tx_state = s_TX_SEND else '0';

    P_CAPTURE_TX : process (i_tx_clk) is
    begin
        if rising_edge(i_tx_clk) then
            if tx_state = s_TX_CAPTURE and i_tx_vld = '1' then
                tx_data_false_path_from_anchor <= i_tx_data;
            end if;
        end if;
    end process;

    E_SYNC_RX_TO_TX: entity work.synchroniser
        generic map (
            g_SYNCHRONISER_FLOPS => g_SYNCHRONISER_FLOPS)  -- [natural range 2 to 4]
        port map (
            i_bit    => rx_ack,            -- [std_logic] bit in another clock domain.
            i_clk    => i_tx_clk,            -- [std_logic]
            o_bit_rt => rx_ack_rt);        -- [std_logic] synchronised to i_clk domain.

    ------------------------------------------------------------
    -- Clock Domain Crossing
    ------------------------------------------------------------

    E_SYNC_TX_TO_RX: entity work.synchroniser
        generic map (
            g_SYNCHRONISER_FLOPS => g_SYNCHRONISER_FLOPS)  -- [natural range 2 to 4]
        port map (
            i_bit    => tx_vld,            -- [std_logic] bit in another clock domain.
            i_clk    => i_rx_clk,            -- [std_logic]
            o_bit_rt => tx_vld_rt);        -- [std_logic] synchronised to i_clk domain.

    P_RX_FSM : process (i_rx_clk) is
    begin
        if rising_edge(i_rx_clk) then
            rx_state <= rx_state;
            case rx_state is
                when s_CAPTURE =>
                    if tx_vld_rt='1' then
                        rx_state <= s_RECEIVED;
                    end if;
                when s_RECEIVED =>
                    if i_rx_ack='1' then
                        rx_state <= s_END;
                    end if;
                when s_END =>
                    if not tx_vld_rt='1' then
                        rx_state <= s_CAPTURE;
                    end if;
                when others =>
                    rx_state <= s_CAPTURE;
            end case;
            if i_rx_clk_reset='1' then
                rx_state <= s_CAPTURE;
            end if;
        end if;
    end process;

    rx_ack <= '1' when rx_state = s_END else '0';
    o_rx_vld <= '1' when rx_state = s_RECEIVED else '0';

    P_CAPTURE_RX : process (i_rx_clk) is
    begin
        if rising_edge(i_rx_clk) then
            if rx_state = s_CAPTURE and tx_vld_rt = '1' then
                retime_slv_rx_data_false_path_to_anchor <=  tx_data_false_path_from_anchor;
            end if;
        end if;
    end process;
    o_rx_data <= retime_slv_rx_data_false_path_to_anchor;

end architecture rtl;
