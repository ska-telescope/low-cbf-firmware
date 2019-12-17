    <field_name>_ram_block : block
        CONSTANT addr_base : NATURAL := to_integer(shift_right(to_unsigned(c_mm_<field_name>_ram.addr_base, 32), ceil_log2(c_mm_<field_name>_ram.nof_dat))) + i;
    begin
        <field_name>_wr_en(i) <= reg_wren AND is_true(addr_base = unsigned(wr_adr(wr_adr'length-1 downto c_mm_<field_name>_ram.adr_w)));
        <field_name>_rd_en(i) <= reg_rden AND is_true(addr_base = unsigned(rd_adr(rd_adr'length-1 downto c_mm_<field_name>_ram.adr_w)));

        u_ram_<field_name> : ENTITY common_lib.common_ram_crw_crw
        GENERIC MAP (
            g_technology        => g_technology,
            g_ram               => c_mm_<field_name>_ram,
            g_true_dual_port    => TRUE)
        PORT MAP (
            rst_a       => mm_rst,
            rst_b       => <FIELD_NAME>_IN.rst(i),
            clk_a       => mm_clk,
            clk_b       => <FIELD_NAME>_IN.clk(i),
            clken_a     => '1',
            clken_b     => '1',
            wr_en_a     => <field_name>_wr_en(i),
            wr_dat_a    => wr_dat(c_mm_<field_name>_ram.dat_w-1 downto 0),
            adr_a       => <field_name>_adr,
            rd_en_a     => <field_name>_rd_en(i),
            rd_dat_a    => <field_name>_rd_dat(i),
            rd_val_a    => <field_name>_rd_val(i),
            wr_en_b     => <FIELD_NAME>_IN.wr_en(i),
            wr_dat_b    => <FIELD_NAME>_IN.wr_dat(i)(c_mm_<field_name>_ram.dat_w-1 downto 0),
            adr_b       => <FIELD_NAME>_IN.adr(i)(c_mm_<field_name>_ram.adr_w-1 downto 0),
            rd_en_b     => <FIELD_NAME>_IN.rd_en(i),
            rd_dat_b    => <FIELD_NAME>_OUT.rd_dat(i)(c_mm_<field_name>_ram.dat_w-1 downto 0),
            rd_val_b    => <FIELD_NAME>_OUT.rd_val(i)
        );

    end block <field_name>_ram_block;

