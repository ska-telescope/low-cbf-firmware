-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (lin64) Build 2086221 Fri Dec 15 20:54:30 MST 2017
-- Date        : Tue Jun 12 15:20:39 2018
-- Host        : dop350 running 64-bit Ubuntu 16.04.4 LTS
-- Command     : write_vhdl -force -mode synth_stub
--               /home/hiemstra/svnlowcbf/LOWCBF/Firmware/build/lru/vivado/lru_qsfp_mbobc_25G_ibert_build_180111_153000/ibert_ultrascale_gty_0_ex/ibert_ultrascale_gty_0_ex.srcs/sources_1/ip/ibert_ultrascale_gty_0/ibert_ultrascale_gty_0_stub.vhdl
-- Design      : ibert_ultrascale_gty_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xcvu9p-flga2577-2L-e-es1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ibert_ultrascale_gty_0 is
  Port ( 
    txn_o : out STD_LOGIC_VECTOR ( 51 downto 0 );
    txp_o : out STD_LOGIC_VECTOR ( 51 downto 0 );
    rxn_i : in STD_LOGIC_VECTOR ( 51 downto 0 );
    rxp_i : in STD_LOGIC_VECTOR ( 51 downto 0 );
    gtrefclk0_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtrefclk1_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtnorthrefclk0_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtnorthrefclk1_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtsouthrefclk0_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtsouthrefclk1_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtrefclk00_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtrefclk10_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtrefclk01_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtrefclk11_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtnorthrefclk00_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtnorthrefclk10_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtnorthrefclk01_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtnorthrefclk11_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtsouthrefclk00_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtsouthrefclk10_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtsouthrefclk01_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    gtsouthrefclk11_i : in STD_LOGIC_VECTOR ( 12 downto 0 );
    clk : in STD_LOGIC
  );

end ibert_ultrascale_gty_0;

architecture stub of ibert_ultrascale_gty_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "txn_o[51:0],txp_o[51:0],rxn_i[51:0],rxp_i[51:0],gtrefclk0_i[12:0],gtrefclk1_i[12:0],gtnorthrefclk0_i[12:0],gtnorthrefclk1_i[12:0],gtsouthrefclk0_i[12:0],gtsouthrefclk1_i[12:0],gtrefclk00_i[12:0],gtrefclk10_i[12:0],gtrefclk01_i[12:0],gtrefclk11_i[12:0],gtnorthrefclk00_i[12:0],gtnorthrefclk10_i[12:0],gtnorthrefclk01_i[12:0],gtnorthrefclk11_i[12:0],gtsouthrefclk00_i[12:0],gtsouthrefclk10_i[12:0],gtsouthrefclk01_i[12:0],gtsouthrefclk11_i[12:0],clk";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "ibert_ultrascale_gty,Vivado 2017.4";
begin
end;
