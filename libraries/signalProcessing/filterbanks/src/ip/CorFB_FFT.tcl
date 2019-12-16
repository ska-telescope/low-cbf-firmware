create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name fft4096_25bit
set_property -dict [list CONFIG.Component_Name {fft4096_25bit} CONFIG.transform_length {4096} CONFIG.implementation_options {pipelined_streaming_io} CONFIG.input_width {25} CONFIG.phase_factor_width {17} CONFIG.rounding_modes {convergent_rounding} CONFIG.xk_index {true} CONFIG.throttle_scheme {realtime} CONFIG.complex_mult_type {use_mults_performance} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {5}] [get_ips fft4096_25bit]
create_ip_run [get_ips fft4096_25bit]
