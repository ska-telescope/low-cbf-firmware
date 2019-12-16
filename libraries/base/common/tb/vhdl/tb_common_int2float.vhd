LIBRARY IEEE, common_lib;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE common_lib.common_pkg.ALL;

ENTITY tb_common_int2float IS
END tb_common_int2float;

ARCHITECTURE tb OF tb_common_int2float IS
  
  CONSTANT clk_period   : TIME := 10 ns;

  -- use smaller values to ease use of 32 bit integers
  CONSTANT c_in_dat_w   : NATURAL := 8;
  CONSTANT c_out_dat_w  : NATURAL := 6;
  CONSTANT c_exp        : INTEGER := 2**(c_in_dat_w-c_out_dat_w+1);
  CONSTANT c_pipeline   : NATURAL := 2;
  
  SIGNAL clk               : STD_LOGIC := '0';

  SIGNAL exp               : INTEGER := c_exp;
  SIGNAL in_dat            : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL in_dat1           : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL in_dat2           : STD_LOGIC_VECTOR(c_in_dat_w-1 DOWNTO 0) := (OTHERS=>'0');  -- delay by c_pipeline to compare with out_dat
  SIGNAL out_dat           : STD_LOGIC_VECTOR(c_out_dat_w-1 DOWNTO 0) := (OTHERS=>'0');
  SIGNAL out_dat_exp       : STD_LOGIC;
  SIGNAL out_dat_man       : STD_LOGIC_VECTOR(c_out_dat_w-2 DOWNTO 0);
  
  SIGNAL in_val            : STD_LOGIC := '0';
  SIGNAL in_val1           : STD_LOGIC := '0';
  SIGNAL in_val2           : STD_LOGIC := '0';
  SIGNAL out_val           : STD_LOGIC := '0';
  
  SIGNAL in_dat_value      : INTEGER := 0;
  SIGNAL nxt_in_dat_value  : INTEGER;
  SIGNAL out_dat_value     : INTEGER := 0;
  SIGNAL nxt_out_dat_value : INTEGER;
  SIGNAL out_exp_value     : STD_LOGIC := '0';
  SIGNAL out_diff_value    : INTEGER := 0;

BEGIN

  clk <= NOT clk AFTER clk_period/2;
  
  p_dly : PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      in_dat1 <= in_dat;
      in_dat2 <= in_dat1;
      in_val1 <= in_val;
      in_val2 <= in_val1;
      out_val <= in_val2;
    END IF;
  END PROCESS;
  
  out_dat_exp <= out_dat(out_dat'HIGH);
  out_dat_man <= out_dat(out_dat'HIGH-1 DOWNTO 0);
  
  p_reg : PROCESS(clk)
  BEGIN
    IF rising_edge(clk) THEN
      in_dat_value  <= nxt_in_dat_value;
      out_dat_value <= nxt_out_dat_value;
      out_exp_value <= out_dat_exp;
    END IF;
  END PROCESS;
  
  nxt_in_dat_value  <= TO_SINT(in_dat2);
  nxt_out_dat_value <= TO_SINT(out_dat_man) WHEN out_dat_exp='0' ELSE TO_SINT(out_dat_man) * c_exp;
  
  out_diff_value <= in_dat_value - out_dat_value;
  
  p_stimuli : PROCESS
  BEGIN
    in_val <= '0';
    in_dat <= TO_SVEC(0, in_dat'LENGTH);
    WAIT UNTIL rising_edge(clk);
    WAIT UNTIL rising_edge(clk);
    FOR I IN -2**(c_in_dat_w-1) TO 2**(c_in_dat_w-1)-1 LOOP
      in_val <= '1';
      in_dat <= TO_SVEC( I, in_dat'LENGTH);
      WAIT UNTIL rising_edge(clk);
    END LOOP;
    in_val <= '0';
    WAIT;
  END PROCESS;

  u_float : ENTITY work.common_int2float
  GENERIC MAP (
    g_pipeline  => c_pipeline
  )
  PORT MAP (
    clk        => clk,
    in_dat     => in_dat,
    out_dat    => out_dat
  );
    
END tb;
