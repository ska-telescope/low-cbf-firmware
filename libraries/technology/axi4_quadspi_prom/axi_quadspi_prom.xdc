# Ultrascale Timing (Different spec for Ultrascale+ , see PG153 pp89)
# You must provide all the delay numbers
# CCLK delay is 0.1, 6.7 ns min/max for ultra-scale devices; refer Data sheet
# Consider the max delay for worst case analysis
set cclk_delay 6.7
create_generated_clock -name qspi_clk_sck -source [get_pins -hierarchical *qspi_prom_core/ext_spi_clk] -edges {3 5 7} -edge_shift [list $cclk_delay $cclk_delay $cclk_delay] [get_pins -hierarchical *USRCCLKO]
set_multicycle_path -setup -from [get_clocks qspi_clk_sck] -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] 2
set_multicycle_path -hold -end -from [get_clocks qspi_clk_sck] -to [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] 1
set_multicycle_path -setup -start -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to [get_clocks qspi_clk_sck] 2
set_multicycle_path -hold -from [get_clocks -of_objects [get_pins -hierarchical */ext_spi_clk]] -to [get_clocks qspi_clk_sck] 1



