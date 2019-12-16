-- (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;


library unisim;
use unisim.vcomponents.all;
library work;

entity axi_i2c_exdes_3 is
   port (
         clk_in1_p : in std_logic;
         clk_in1_n : in std_logic;
         reset : in std_logic;
         start : in std_logic;
         scl_io : inout std_logic;
         sda_io : inout std_logic;
         to_led : out std_logic_vector (1-1 downto 0); 
         done : out std_logic); 


end entity;

architecture impl of axi_i2c_exdes_3 is
  attribute DowngradeIPIdentifiedWarnings: string;
  attribute DowngradeIPIdentifiedWarnings of impl : architecture is "yes";


--component clock_gen is
--     port (
--           clk_in1_p : in std_logic;
--           clk_in1_n : in std_logic;
--           reset    : in std_logic;
--           locked   : out std_logic;
--           clock_lite : out std_logic;
--           clock : out std_logic
--          );
--
--end component;

--component axi_traffic_gen_0 is 
--  port (
--  s_axi_aclk : in std_logic;
--  s_axi_aresetn : in std_logic;
--  m_axi_lite_ch1_awaddr : out std_logic_vector (31 downto 0);
--  m_axi_lite_ch1_awprot : out std_logic_vector (2 downto 0);
--  m_axi_lite_ch1_awvalid : out std_logic;
--  m_axi_lite_ch1_awready : in std_logic;
--  m_axi_lite_ch1_wdata : out std_logic_vector (31 downto 0);
--  m_axi_lite_ch1_wstrb : out std_logic_vector (3 downto 0);
--  m_axi_lite_ch1_wvalid : out std_logic;
--  m_axi_lite_ch1_wready : in std_logic;
--  m_axi_lite_ch1_bresp : in std_logic_vector (1 downto 0);
--  m_axi_lite_ch1_bvalid : in std_logic;
--  m_axi_lite_ch1_bready : out std_logic;
--  m_axi_lite_ch1_araddr : out std_logic_vector (31 downto 0);
--  m_axi_lite_ch1_arvalid : out std_logic;
--  m_axi_lite_ch1_arready : in std_logic;
--  m_axi_lite_ch1_rdata : in std_logic_vector (31 downto 0);
--  m_axi_lite_ch1_rvalid : in std_logic;
--  m_axi_lite_ch1_rready : out std_logic;
--  m_axi_lite_ch1_rresp : in std_logic_vector (1 downto 0);
--  done : out std_logic;
--  status : out std_logic_vector (31 downto 0)
--);
--end component;
ATTRIBUTE SYN_BLACK_BOX : BOOLEAN;
--ATTRIBUTE SYN_BLACK_BOX OF axi_traffic_gen_0 : COMPONENT IS TRUE;
ATTRIBUTE BLACK_BOX_PAD_PIN : STRING;
--ATTRIBUTE BLACK_BOX_PAD_PIN OF axi_traffic_gen_0 : COMPONENT IS "s_axi_aclk,s_axi_aresetn,irq_out,m_axi_lite_ch1_awaddr[31:0],m_axi_lite_ch1_awprot[2:0],m_axi_lite_ch1_awvalid,m_axi_lite_ch1_awready,m_axi_lite_ch1_wdata[31:0],m_axi_lite_ch1_wstrb[3:0],m_axi_lite_ch1_wvalid,m_axi_lite_ch1_wready,m_axi_lite_ch1_bresp[1:0],m_axi_lite_ch1_bvalid,m_axi_lite_ch1_bready,m_axi_lite_ch1_araddr[31:0],m_axi_lite_ch1_arvalid,m_axi_lite_ch1_arready,m_axi_lite_ch1_rdata[31:0],m_axi_lite_ch1_rvalid,m_axi_lite_ch1_rready,m_axi_lite_ch1_rresp[1:0]";

COMPONENT axi_i2c is
  PORT (
    s_axi_aclk : IN STD_LOGIC;
    s_axi_aresetn : IN STD_LOGIC;
    iic2intc_irpt : OUT STD_LOGIC;
    s_axi_awaddr : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    s_axi_awvalid : IN STD_LOGIC;
    s_axi_awready : OUT STD_LOGIC;
    s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi_wvalid : IN STD_LOGIC;
    s_axi_wready : OUT STD_LOGIC;
    s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_bvalid : OUT STD_LOGIC;
    s_axi_bready : IN STD_LOGIC;
    s_axi_araddr : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    s_axi_arvalid : IN STD_LOGIC;
    s_axi_arready : OUT STD_LOGIC;
    s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_rvalid : OUT STD_LOGIC;
    s_axi_rready : IN STD_LOGIC;
    sda_i : IN STD_LOGIC;
    sda_o : OUT STD_LOGIC;
    sda_t : OUT STD_LOGIC;
    scl_i : IN STD_LOGIC;
    scl_o : OUT STD_LOGIC;
    scl_t : OUT STD_LOGIC;
    gpo : OUT STD_LOGIC_VECTOR(1-1 DOWNTO 0)
  );
END COMPONENT;


signal    m_axi_lite_awready          :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_awvalid          :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_awaddr           :  std_logic_vector (31 downto 0);-- AXI4-Lite
signal    m_axi_lite_wready           :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_wvalid           :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_wdata            :  std_logic_vector (31 downto 0);-- AXI4-Lite
signal    m_axi_lite_bready           :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_bvalid           :  std_logic                         ;-- AXI4-Lite
signal    m_axi_lite_bresp            :  std_logic_vector(1 downto 0)      ;-- AXI4-Lite
signal    s_axi_lite_arready          :  std_logic                         ;-- AXI4-Lite
signal    s_axi_lite_arvalid          :  std_logic                         ;-- AXI4-Lite
signal    s_axi_lite_araddr           :  std_logic_vector (31 downto 0);-- AXI4-Lite
signal    s_axi_lite_rready           :  std_logic                         ;-- AXI4-Lite
signal    s_axi_lite_rvalid           :  std_logic                         ;-- AXI4-Lite
signal    s_axi_lite_rdata            :  std_logic_vector (31 downto 0);-- AXI4-Lite
signal    s_axi_lite_rresp            :  std_logic_vector(1 downto 0)      ;-- AXI4-Lite

  signal clock_lite : std_logic;
  signal clock : std_logic;
  signal locked : std_logic;
  signal reset_lock : std_logic;

---
signal awlen : std_logic_vector (7 downto 0);
signal awvalid : std_logic;
signal init_done : std_logic; 
signal counter : std_logic_vector (7 downto 0);
signal wvalid : std_logic;
---

signal pass : std_logic;
signal fail : std_logic;
signal cdma_intr : std_logic;
signal done_int : std_logic;
signal atg_done : std_logic;
signal atg_status : std_logic_vector (31 downto 0);

signal sda_i : std_logic;
signal sda_o : std_logic;
signal sda_tri : std_logic;
signal scl_i : std_logic;
signal scl_o : std_logic;
signal scl_tri : std_logic;
signal to_led_int : std_logic_vector (1-1 downto 0);
signal all_zero : std_logic_vector (1-1 downto 0);
signal four_vcc : std_logic_vector (3 downto 0);

begin

four_vcc <= "1111";
all_zero <= (others => '0');

--CLOCK_GEN_INST : clock_gen 
--         port map (
--           clk_in1_p => clk_in1_p,
--           clk_in1_n => clk_in1_n,
--           reset    => reset,
--           locked   => locked,  
--           clock_lite => clock_lite,
--           clock => clock);      

reset_lock <= locked;


--ATG1: axi_traffic_gen_0 
--   port map (
--    s_axi_aclk         => clock_lite,
--    s_axi_aresetn      => reset_lock,
--    m_axi_lite_ch1_awaddr   => m_axi_lite_awaddr,
--    m_axi_lite_ch1_awprot   => open,
--    m_axi_lite_ch1_awvalid  => m_axi_lite_awvalid,
--    m_axi_lite_ch1_awready  => m_axi_lite_awready,
--    m_axi_lite_ch1_wdata    => m_axi_lite_wdata,
--    m_axi_lite_ch1_wstrb    => open,
--    m_axi_lite_ch1_wvalid   => m_axi_lite_wvalid,
--    m_axi_lite_ch1_wready   => m_axi_lite_wready,
--    m_axi_lite_ch1_bresp    => m_axi_lite_bresp,
--    m_axi_lite_ch1_bvalid   => m_axi_lite_bvalid,
--    m_axi_lite_ch1_bready   => m_axi_lite_bready,
--    m_axi_lite_ch1_araddr   => s_axi_lite_araddr,
--    m_axi_lite_ch1_arvalid  => s_axi_lite_arvalid,
--    m_axi_lite_ch1_arready  => s_axi_lite_arready,
--    m_axi_lite_ch1_rdata    => s_axi_lite_rdata,
--    m_axi_lite_ch1_rvalid   => s_axi_lite_rvalid,
--    m_axi_lite_ch1_rready   => s_axi_lite_rready,
--    m_axi_lite_ch1_rresp    => s_axi_lite_rresp,
--    done                    => atg_done,
--    status                  => atg_status 
--  );


-- LeonH: commented out the axi_traffic_gen block; fixing the inputs to '0'
DUT : axi_i2c
    PORT MAP (
    iic2intc_irpt     => open,       
    s_axi_aclk       => clock_lite,
    s_axi_aresetn    => reset_lock,
    s_axi_awaddr     => (others => '0'), --m_axi_lite_awaddr (8 downto 0),
    s_axi_awvalid    => '0',--m_axi_lite_awvalid,
    s_axi_awready    => m_axi_lite_awready,
    s_axi_wdata      => (others => '0'), --m_axi_lite_wdata,
    s_axi_wstrb      => four_vcc,
    s_axi_wvalid     => '0',--m_axi_lite_wvalid,
    s_axi_wready     => m_axi_lite_wready,
    s_axi_bresp      => m_axi_lite_bresp,
    s_axi_bvalid     => m_axi_lite_bvalid,
    s_axi_bready     => '0',--m_axi_lite_bready,
    s_axi_araddr     => (others => '0'),--s_axi_lite_araddr (8 downto 0),
    s_axi_arvalid    => '0',--s_axi_lite_arvalid,
    s_axi_arready    => s_axi_lite_arready,
    s_axi_rdata      => s_axi_lite_rdata,
    s_axi_rresp      => s_axi_lite_rresp,
    s_axi_rvalid     => s_axi_lite_rvalid,
    s_axi_rready     => '0',--s_axi_lite_rready,
    sda_i            => sda_i,
    sda_o            => sda_o,
    sda_t            => sda_tri,
    scl_i            => scl_i,
    scl_o            => scl_o,
    scl_t            => scl_tri,
    gpo              => to_led_int
    );

    to_led <= to_led_int;

     scl_inst : IOBUF
       port map (
         IO         => scl_io,
         I          => scl_o,
         O          => scl_i,
         T          => scl_tri);

     sda_inst : IOBUF
       port map (
         IO         => sda_io,
         I          => sda_o,
         O          => sda_i,
         T          => sda_tri);


process (clock_lite)
begin
    if (clock_lite'event and clock_lite = '1') then
        if (reset_lock = '0') then
            done <= '0';
        else
            done <= atg_done;
        end if;
    end if;
end process;


end impl;

