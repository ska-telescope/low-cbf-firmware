library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.ctf_pkg.all;

entity synth_wrapper is
Port ( i_clk           : in  STD_LOGIC;
       i_rst           : in  STD_LOGIC;
       i_data_in       : in  t_ctf_input_data_a(g_CTF_INPUT_NUMBER-1 downto 0);
       i_data_in_vld   : in  std_logic_vector(g_CTF_INPUT_NUMBER-1 downto 0);
       o_data_in_stop  : out std_logic_vector(g_CTF_INPUT_NUMBER-1 downto 0);  
       o_data_out      : out t_ctf_input_data_a(g_CTF_INPUT_NUMBER-1 downto 0);
       o_data_out_vld  : out std_logic;
       i_data_out_stop : in  std_logic
     );  
end synth_wrapper;

architecture Behavioral of synth_wrapper is
    signal i_rst_p           : STD_LOGIC;
    signal i_data_in_p       : t_ctf_input_data_a(g_CTF_INPUT_NUMBER-1 downto 0);
    signal i_data_in_vld_p   : std_logic_vector(g_CTF_INPUT_NUMBER-1 downto 0);
    signal o_data_in_stop_p  : std_logic_vector(g_CTF_INPUT_NUMBER-1 downto 0);  
    signal o_data_out_p      : t_ctf_input_data_a(g_CTF_INPUT_NUMBER-1 downto 0);
    signal o_data_out_vld_p  : std_logic;
    signal i_data_out_stop_p : std_logic;
    
begin

    E_DUT: entity work.ctf_input_buffer
    generic map (
        g_BLOCK_SIZE        => 3456,
        g_BLOCK_COUNT       => 4,
        g_ATOM_SIZE         => 4,
        g_INPUT_STOP_WORDS  => 1,
        g_OUTPUT_STOP_WORDS => 1
    ) port map (
           i_clk           => i_clk,
           i_rst           => i_rst_p,
           i_data_in       => i_data_in_p,
           i_data_in_vld   => i_data_in_vld_p,
           o_data_in_stop  => o_data_in_stop_p,  
           o_data_out      => o_data_out_p,
           o_data_out_vld  => o_data_out_vld_p,
           i_data_out_stop => i_data_out_stop_p
    );  

    P_FLOP: process(i_clk)
    begin
        if rising_edge(i_clk) then
            i_rst_p           <= i_rst;
            i_data_in_p       <= i_data_in;
            i_data_in_vld_p   <= i_data_in_vld;
            o_data_in_stop    <= o_data_in_stop_p;
            o_data_out        <= o_data_out_p;
            o_data_out_vld    <= o_data_out_vld_p;
            i_data_out_stop_p <= i_data_out_stop;
        end if;
    end process;
    

end Behavioral;
