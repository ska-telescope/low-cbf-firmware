library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library std;
use std.env.all;

library common_tb_lib;
use common_tb_lib.common_tb_pkg.all;

use work.ctc_pkg.all;

entity tb_hbm_buffer_ram is
    generic (
        g_USE_HBM         : boolean := true;
        g_HBM_EMU_STUTTER : boolean := true;
        g_DEPTH           : integer := 2**16;
        g_BURST_LEN       : integer := 16
    );
end tb_hbm_buffer_ram;

architecture Behavioral of tb_hbm_buffer_ram is

    signal rst     : std_logic := '0';
    signal hbm_clk : std_logic := '0';
    signal apb_clk : std_logic := '0';
    
    signal ra_ready : std_logic;
    signal wa_ready : std_logic;
    signal w_ready  : std_logic;
    
    signal write_enable  : std_logic;
    signal data_in       : t_ctc_hbm_data;
    signal w_last        : std_logic;     

    signal write_address : std_logic_vector(log2_ceil(g_DEPTH)-1 downto 0);
    signal wa_valid : std_logic;
    signal w_ack    : std_logic;

    signal read_address  : std_logic_vector(log2_ceil(g_DEPTH)-1 downto 0);
    signal ra_valid      : std_logic;
    
    signal data_out      : t_ctc_hbm_data;
    signal data_out_vld  : std_logic;
    signal data_out_stop : std_logic := '0';
    
    signal wa_id, ra_id : std_logic_vector(5 downto 0);

begin

    rst <= '0', '1' after 10 ns, '0' after 20 ns;  

    --450MHz
    hbm_clk <= not hbm_clk after 1.111 ns;

    --100MHz
    apb_clk <= not apb_clk after 5 ns;


    E_BUFFER: entity work.ctc_hbm_buffer_ram
    generic map(
       g_USE_HBM         => g_USE_HBM,
       g_HBM_EMU_STUTTER => g_HBM_EMU_STUTTER,
       g_DEPTH           => g_DEPTH,
       g_BURST_LEN       => g_BURST_LEN
    ) port map (
       i_hbm_ref_clk  => apb_clk,
       i_hbm_clk      => hbm_clk,
       i_hbm_rst      => rst,
       i_apb_clk      => apb_clk,
       o_read_ready   => ra_ready,
       o_write_ready  => w_ready,
       o_wa_ready     => wa_ready,
       --write
       i_we           => write_enable,
       i_wa           => write_address,
       i_wae          => wa_valid,
       i_wid          => wa_id,
       o_w_ack        => w_ack,
       o_w_ack_id     => open,
       i_data_in      => data_in,
       i_last         => w_last,
       --read
       i_re             => ra_valid,
       i_ra             => read_address,
       i_rid            => ra_id,
       o_data_out_vld   => data_out_vld,
       o_data_out       => data_out,
       i_data_out_stop  => data_out_stop
    );
    
    P_ADDR: process
    begin

        wa_valid <= '0';
        ra_valid <= '0';
        wait for 20 us;
        wait until rising_edge(hbm_clk);
        
        for addr in 0 to g_DEPTH/g_BURST_LEN-1 loop
            while wa_ready='0' loop
                wait until rising_edge(hbm_clk);
            end loop; 
            write_address <= std_logic_vector(to_unsigned(addr*g_BURST_LEN, write_address'length));
            wa_id         <= std_logic_vector(to_unsigned(addr, wa_id'length));
            wa_valid      <= '1';
            wait until rising_edge(hbm_clk);
        end loop;

        while wa_ready='0' loop
            wait until rising_edge(hbm_clk);
        end loop; 
        wa_valid <= '0';
        ra_valid <= '0';
        wait for 20 us;
        wait until rising_edge(hbm_clk);

        for addr in 0 to g_DEPTH/g_BURST_LEN-1 loop
            while ra_ready='0' loop
                wait until rising_edge(hbm_clk);
            end loop; 
            ra_valid      <= '1';
            read_address <= std_logic_vector(to_unsigned(addr*g_BURST_LEN,  read_address'length));
            ra_id         <= std_logic_vector(to_unsigned(addr, ra_id'length));
            wait until rising_edge(hbm_clk);
        end loop;

        while ra_ready='0' loop
            wait until rising_edge(hbm_clk);
        end loop; 
        wa_valid <= '0';
        ra_valid <= '0';
        wait;
        
    end process;
      
      
      
    P_W_DATA: process
    begin

        write_enable <= '0';
        w_last       <= '0';
        wait for 20 us;
        wait until rising_edge(hbm_clk);
        
        for addr in 0 to g_DEPTH/g_BURST_LEN-1 loop
            for data in 0 to g_BURST_LEN-1 loop
                while w_ready='0' loop
                    wait until rising_edge(hbm_clk);
                end loop; 
                data_in.data <= std_logic_vector(to_unsigned(data+addr*g_BURST_LEN, data_in.data'length));
                write_enable <= '1';
                if data=g_BURST_LEN-1 then
                    w_last <= '1';
                else
                    w_last <= '0';
                end if;
                wait until rising_edge(hbm_clk);
            end loop;    
        end loop;

        while w_ready='0' loop
            wait until rising_edge(hbm_clk);
        end loop; 
        write_enable <= '0';
        w_last       <= '0';
        wait;
        
    end process;
      
    P_R_DATA: process
    begin

        wait for 20 us;
        wait until rising_edge(hbm_clk);
        
        for addr in 0 to g_DEPTH/g_BURST_LEN-1 loop
            for data in 0 to g_BURST_LEN-1 loop
                while data_out_vld='0' loop
                    wait until rising_edge(hbm_clk);
                end loop; 
                check_equal(unsigned(data_out.data), to_unsigned(data+addr*g_BURST_LEN, data_out.data'length), "DATA OUT");
                wait until rising_edge(hbm_clk);
            end loop;    
        end loop;
        
        assert data_out_vld='0' report "TOO MUCH DATA!" severity FAILURE;
         
        echoln;
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln("!                             !");
        echoln("!     SIMULATION FINISHED     !");
        echoln("!                             !");
        echoln("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        echoln;
         
        stop(2); --end simulation
                
    end process;

    P_STOP: process
    begin

        wait for 20 us;
        wait until rising_edge(hbm_clk);
        
        loop
            data_out_stop <= not data_out_stop;
            wait for 30 ns;
            wait until rising_edge(hbm_clk);
        end loop;    

    end process;
        
end Behavioral;
