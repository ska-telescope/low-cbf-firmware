<nof_slaves>    <field_name>_wr_en_vec(0) <= <field_name>_wr_en;
<nof_slaves>    <field_name>_wr_val <= <field_name>_wr_val_vec(0);

    u_<field_name>_wr_val : ENTITY common_lib.common_pipeline
    GENERIC MAP (
        g_pipeline   => c_mm_<field_name>_ram.latency,
        g_in_dat_w   => c_mm_<field_name>_ram.nof_slaves,
        g_out_dat_w  => c_mm_<field_name>_ram.nof_slaves)
    PORT MAP (
        clk     => mm_clk,
        clken   => '1',
        in_dat  => <field_name>_wr_en<_vec>,
        out_dat => <field_name>_wr_val<_vec>);

