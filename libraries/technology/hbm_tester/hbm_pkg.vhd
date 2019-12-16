----------------------------------------------------------------------------------
-- Company:  Massey university
-- Engineer: Vignesh raja balu
-- 
-- Create Date: 28.03.2019 22:54:37
-- Design Name: hbm_pkg
-- Module Name: hbm_pkg - Behavioral
-- Project Name: hbm_synth
-- Target Devices: xcvu37p-fsvh2892-3-e (active)
-- Tool Versions: vivado 2018.3, Modelsim SE-64 10.6b
-- Description: Package for HBM_TESTER
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--library UNISIM;
--use UNISIM.VComponents.all;

package hbm_pkg is
    subtype burst_t is std_logic_vector(1 downto 0);
    constant BURST_FIXED : burst_t := "00";
    constant BURST_INCR  : burst_t := "01";
    constant BURST_WRAP  : burst_t := "10";
    constant BURST_RESVD : burst_t := "11";
    
    constant KB : natural := 1000;
    constant MB : natural := KB * 1000;
    constant GB : natural := MB * 1000;
     
    type INT_VECTOR_t is array (natural range <>) of integer;
    type REAL_VECTOR_t is array (natural range <>) of real;
    type POSITIVE_VECTOR_t is array (natural range <>) of positive;
    
             
    type AXI_ADDR_RW_t is record
        addr    : std_logic_vector(32 downto 0);
        burst   : std_logic_vector(1 downto 0);
        id      : std_logic_vector(5 downto 0);
        len     : std_logic_vector(3 downto 0);
        size    : std_logic_vector(2 downto 0);
        valid   : std_logic;
    end record AXI_ADDR_RW_t;
    
    constant AXI_ADDR_RW_t_ZERO : AXI_ADDR_RW_t := (
        addr  => (others => '0'),
        burst => (others => '0'),
        id    => (others => '0'),
        len   => (others => '0'),
        size  => (others => '0'),
        valid => '0');
    
    subtype AXI_AWREADY_t is std_logic;
    subtype AXI_ARREADY_t is std_logic;
    
    type AXI_W_t is record
        data    : std_logic_vector(255 downto 0);
        last    : std_logic;
        strb    : std_logic_vector (31 downto 0);
        valid   : std_logic;
     end record AXI_W_t;
     
     constant AXI_W_t_ZERO : AXI_W_t := (
        data  => (others => '0'),
        last  => '0',
        strb  => (others => '0'),
        valid =>'0');
     
     subtype AXI_WREADY_t is std_logic;
     
     type AXI_R_t is record
        data    : std_logic_vector(255 downto 0);
        id      : std_logic_vector (5 downto 0);
        last    : std_logic;
        resp    : std_logic_vector (1 downto 0);
        valid   : std_logic;
    end record AXI_R_t;
    
    constant AXI_R_t_ZERO : AXI_R_t := (
        data  => (others => '0'),
        id    => (others => '0'),
        last  => '0',
        resp  => (others => '0'),
        valid =>'0');
    
    subtype AXI_RREADY_t is std_logic;
    
    type AXI_B_t is record
        id      : std_logic_vector(5 downto 0);
        resp    : std_logic_vector(1 downto 0);
        valid   : std_logic;
    end record AXI_B_t;
    
    constant AXI_B_t_ZERO : AXI_B_t := (
        id    => (others => '0'),
        resp  => (others => '0'),
        valid =>'0');
    
    subtype AXI_BREADY_t is std_logic;
    
    type i_SAXI_t is record
        ar      : AXI_ADDR_RW_t;
        aw      : AXI_ADDR_RW_t;
        w       : AXI_W_t;
        rready  : AXI_RREADY_t;
        bready  : AXI_BREADY_t;
    end record i_SAXI_t;
    
    constant i_SAXI_t_ZERO : i_SAXI_t :=(
        ar      => AXI_ADDR_RW_t_ZERO,
        aw      => AXI_ADDR_RW_t_ZERO,
        w       => AXI_W_t_ZERO,
        rready  => '0',
        bready  => '0');
    
    type i_SAXI_VECTOR_t is array (natural range<>) of i_SAXI_t;
    
    type o_SAXI_t is record
        arready : AXI_ARREADY_t;
        awready : AXI_AWREADY_t;
        wready  : AXI_WREADY_t;
        r       : AXI_R_t;
        b       : AXI_B_t;
    end record o_SAXI_t;
    
    constant o_SAXI_t_ZERO : o_SAXI_t :=(
        arready => '0',
        awready => '0',
        wready  => '0',
        r       => AXI_R_t_ZERO,
        b       => AXI_B_t_ZERO);
    
    type o_SAXI_VECTOR_t is array (natural range<>) of o_SAXI_t;
    
    type i_SAPB_t is record
        paddr    : std_logic_vector (21 downto 0);
        penable  : std_logic;
        psel     : std_logic;
        pwdata   : std_logic_vector (31 downto 0);
        pwrite   : std_logic;
    end record i_SAPB_t;    
    
    constant i_SAPB_t_ZERO : i_SAPB_t := (
        paddr   => (others => '0'),
        penable => '0',
        psel    => '0',
        pwdata  => (others => '0'),
        pwrite  => '0');
    
    type o_SAPB_t is record
        prdata   : std_logic_vector (31 downto 0);
        pready   : std_logic;
        pslverr  : std_logic;
    end record o_SAPB_t;
    
    type AXI_ADDR_t is array (natural range <>) of std_logic_vector(32 downto 0);
    type AXI_DATA_t is array (natural range <>) of std_logic_vector(255 downto 0);
    type AXI_ADDR_USED_t is array (natural range <>) of std_logic_vector(22 downto 0);
    
    type AXI_PARITY_t is array(natural range <>)of std_logic_vector(31 downto 0);
    
     
end package hbm_pkg;