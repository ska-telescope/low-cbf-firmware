LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE common_lib.common_pkg.ALL;


PACKAGE eth_pkg IS
  CONSTANT c_max_pkt_size_in64bitwords : NATURAL := 9018; -- (frameheader..payload) https://en.wikipedia.org/wiki/Jumbo_frame
  type t_eth_hdr_arr is array (0 to 6) of std_logic_vector(63 downto 0);

  function byte_swap_vector (a: in std_logic_vector) return std_logic_vector;
END eth_pkg;



PACKAGE BODY eth_pkg IS

  function byte_swap_vector (a: in std_logic_vector) return std_logic_vector is
    variable result: std_logic_vector(a'RANGE);
  begin
    result(7 downto 0)   := a(63 downto 56);
    result(15 downto 8)  := a(55 downto 48);
    result(23 downto 16) := a(47 downto 40);
    result(31 downto 24) := a(39 downto 32);
    result(39 downto 32) := a(31 downto 24);
    result(47 downto 40) := a(23 downto 16);
    result(55 downto 48) := a(15 downto 8);
    result(63 downto 56) := a(7 downto 0);
    return result;
  end;

END eth_pkg;
