create_clock -name FPGA_EMCCLK -period 11.111 [get_ports FPGA_EMCCLK]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets CLK_IBUF_inst/O]


