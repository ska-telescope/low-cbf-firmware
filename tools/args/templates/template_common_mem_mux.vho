    sig_wea_sum <= '1' WHEN sig_wea /= (sig_wea'range => '0') ELSE '0';
    sig_rea_sum <= NOT sig_wea_sum;
 
    -- instantiate common_mem_mux 
    slave_port_mux_inst : ENTITY common_lib.common_mem_mux
    GENERIC MAP (
        g_broadcast     => FALSE,
        g_nof_mosi      => c_ram_a.nof_slaves,
        g_mult_addr_w   => c_ram_a.adr_w,
        g_rd_latency    => c_ram_a.latency
    )
    PORT MAP (
        clk                                     => sig_clka,
        mosi.address                            => sig_addra,
        mosi.wrdata(c_ram_a.dat_w-1 downto 0)   => sig_dina,
        mosi.wr                                 => sig_wea_sum,
        mosi.rd                                 => sig_rea_sum,
        miso.rddata(c_ram_a.dat_w-1 downto 0)   => sig_douta,
        mosi_arr                                => mem_mosi_arr_a,
        miso_arr                                => mem_miso_arr_a
    );  
