    CONSTANT c_mm_<reg_name>_<reg_ram>	: t_c_mem :=   (latency     => 1, 
                                            adr_w	    => <adr_w>,
                                            dat_w	    => <dat_w>,
                                            nof_dat	    => <nof_dat>,
                                            nof_slaves  => <nof_slaves>,                                                    
                                            addr_base   => <addr_base>,
                                            init_sl     => '0');
    
    CONSTANT c_<reg_name>_spare_init : STD_LOGIC_VECTOR(c_mem_reg_init_w-c_dat_w*c_mm_<reg_name>_reg.nof_dat-1 downto 0) := (OTHERS => '0');
    CONSTANT c_<reg_name>_part_init  : STD_LOGIC_VECTOR(c_dat_w*c_mm_<reg_name>_reg.nof_dat-1 downto 0) := <c_init_reg>;                                                
    CONSTANT c_<reg_name>_init_reg   : STD_LOGIC_VECTOR(c_mem_reg_init_w-1 downto 0) := c_<reg_name>_spare_init & c_<reg_name>_part_init;
    CONSTANT c_<reg_name>_spare_clr  : STD_LOGIC_VECTOR(c_mem_reg_init_w-c_dat_w*c_mm_<reg_name>_reg.nof_dat-1 downto 0) := (OTHERS => '0');
    CONSTANT c_<reg_name>_part_clr   : STD_LOGIC_VECTOR(c_dat_w*c_mm_<reg_name>_reg.nof_dat-1 downto 0) := <c_clr_mask>;                                                
    CONSTANT c_<reg_name>_clr_reg    : STD_LOGIC_VECTOR(c_mem_reg_init_w-1 downto 0) := c_<reg_name>_spare_clr & c_<reg_name>_part_clr;    