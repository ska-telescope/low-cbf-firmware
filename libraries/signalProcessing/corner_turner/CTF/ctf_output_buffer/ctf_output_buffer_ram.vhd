---------------------------------------------------------------------------------------------------
-- 
-- Corner Turner Fine (CTF) - Output Buffer Memory Unit
--
---------------------------------------------------------------------------------------------------
--
-- Author  : Norbert Abel (norbert.abel@autac.nz)
-- Standard: VHDL'08
--
---------------------------------------------------------------------------------------------------
--
-- Based on macros. Vivado editor pretends to not know them, which is nonsense - both, Vivcado
-- simulation and synthesis tools do.
-- They are required here because otherwise Vivado starts implementing distributed memory. 
-- 
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

Library xpm;
use xpm.vcomponents.all;

--library unisim;
--use unisim.vcomponents.all;

library work;
use work.ctf_pkg.all;

entity ctf_output_buffer_ram is
    Generic (
        g_DEPTH       : natural := 1024;
        g_LOG2_DEPTH  : natural := log2_ceil(g_DEPTH)
    );
    Port ( i_clk      : in  std_logic;
           i_rst      : in  std_logic;
           i_we       : in  std_logic;
           i_wa       : in  std_logic_vector(g_LOG2_DEPTH-1 downto 0); 
           i_data_in  : in  t_ctf_output_data;
           i_ra       : in  std_logic_vector(g_LOG2_DEPTH-1 downto 0);
           o_data_out : out t_ctf_output_data
    );
end ctf_output_buffer_ram;

architecture Behavioral of ctf_output_buffer_ram is

    COMPONENT output_port_bram
      PORT (
        clka : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        clkb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
      );
    END COMPONENT;

    constant g_WIDTH : natural := pc_CTF_OUTPUT_FACTOR*pc_CTF_DATA_WIDTH;

    type t_mem is array (g_DEPTH-1 downto 0) of t_ctf_output_data;
    signal mem : t_mem;
    
    signal data_in  : std_logic_vector(g_WIDTH-1 downto 0);
    signal data_out : std_logic_vector(g_WIDTH-1 downto 0);
    signal meta_out : t_ctf_output_data;
    
begin

    --synthesis translate_off
    P_MEM: process(i_clk)
    begin
        if rising_edge(i_clk) then
            if i_we ='1' then
                mem(to_integer(unsigned(i_wa))) <= i_data_in;
            end if;
            meta_out <= mem(to_integer(unsigned(i_ra)));
        end if;
    end process;
    --synthesis translate_on

    GEN_IN: for seg in 0 to pc_CTF_OUTPUT_FACTOR-1 generate
        data_in(seg*pc_CTF_DATA_WIDTH+pc_CTF_DATA_WIDTH-1 downto seg*pc_CTF_DATA_WIDTH+00) <= i_data_in(seg).data.im & i_data_in(seg).data.re;
    end generate;   


   BRAM : xpm_memory_sdpram
   generic map (
      ADDR_WIDTH_A => i_wa'length,     
      ADDR_WIDTH_B => i_ra'length,     
      AUTO_SLEEP_TIME => 0,            
      BYTE_WRITE_WIDTH_A => g_WIDTH,   
      CLOCKING_MODE => "common_clock", 
      ECC_MODE => "no_ecc",            
      MEMORY_INIT_FILE => "none",      
      MEMORY_INIT_PARAM => "0",        
      MEMORY_OPTIMIZATION => "true",   
      MEMORY_PRIMITIVE => "block",      
      MEMORY_SIZE => g_DEPTH*g_WIDTH,   
      MESSAGE_CONTROL => 0,           
      READ_DATA_WIDTH_B => g_WIDTH,   
      READ_LATENCY_B => 1,            
      READ_RESET_VALUE_B => "0",      
      USE_EMBEDDED_CONSTRAINT => 0,   
      USE_MEM_INIT => 0,              
      WAKEUP_TIME => "disable_sleep", 
      WRITE_DATA_WIDTH_A => g_WIDTH,  
      WRITE_MODE_B => "no_change"     
   )
   port map (
      doutb => data_out,                   -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      addra => i_wa,                       -- ADDR_WIDTH_A-bit input: Address for port A write operations.
      addrb => i_ra,                       -- ADDR_WIDTH_B-bit input: Address for port B read operations.
      clka  => i_clk,                      -- 1-bit input: Clock signal for port A. Also clocks port B when
      clkb  => i_clk,                      -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
      dina  => data_in,                    -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      ena   => '1',                        -- 1-bit input: Memory enable signal for port A. Must be high on clock
      enb   => '1',                        -- 1-bit input: Memory enable signal for port B. Must be high on clock
      rstb  => i_rst,                      -- 1-bit input: Reset signal for the final port B output register
      sleep => '0',
      injectsbiterra => '0',
      injectdbiterra => '0',
      regceb         => '1',
      wea   => (others=>i_we)             -- WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
   );

    GEN_OUT: for seg in 0 to pc_CTF_OUTPUT_FACTOR-1 generate
        o_data_out(seg).data.im <= data_out(seg*pc_CTF_DATA_WIDTH+pc_CTF_DATA_WIDTH-1   downto seg*pc_CTF_DATA_WIDTH+pc_CTF_DATA_WIDTH/2);
        o_data_out(seg).data.re <= data_out(seg*pc_CTF_DATA_WIDTH+pc_CTF_DATA_WIDTH/2-1 downto seg*pc_CTF_DATA_WIDTH+00);
        --synthesis translate_off
        o_data_out(seg).meta    <= meta_out(seg).meta;
        --synthesis translate_on
    end generate;   

end Behavioral;
