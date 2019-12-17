
    <reg_name>_reg : ENTITY common_lib.common_reg_r_w_dc
     GENERIC MAP (g_reg         => c_mm_<reg_name>_reg,
                  g_init_reg    => c_<reg_name>_init_reg,
                  g_clr_mask    => c_<reg_name>_clr_reg)
     PORT MAP (mm_rst          => mm_rst,
               mm_clk          => mm_clk,
               st_clk          => st_clk_<reg_name>,
               st_rst          => st_rst_<reg_name>,
               wr_en           => reg_wren,
               wr_adr          => wr_adr,
               wr_dat          => wr_dat,
               wr_val          => <reg_name>_wr_val,
               wr_busy         => <reg_name>_wr_busy,
               rd_en           => reg_rden,
               rd_adr          => rd_adr,
               rd_dat          => <reg_name>_rd_dat,
               rd_val          => <reg_name>_rd_val,
               rd_busy         => <reg_name>_rd_busy,
               reg_wr_arr      => <reg_name>_pulse_write,
               reg_rd_arr      => <reg_name>_pulse_read,
               out_reg         => <reg_name>_out_reg,
               in_reg          => <reg_name>_in_reg);


