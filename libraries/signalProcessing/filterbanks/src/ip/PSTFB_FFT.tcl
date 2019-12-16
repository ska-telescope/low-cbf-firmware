create_ip -name xfft -vendor xilinx.com -library ip -version 9.1 -module_name fft256_16bit
set_property -dict [list CONFIG.Component_Name {fft256_16bit} CONFIG.transform_length {256} CONFIG.implementation_options {pipelined_streaming_io} CONFIG.xk_index {true} CONFIG.throttle_scheme {realtime} CONFIG.complex_mult_type {use_mults_performance} CONFIG.number_of_stages_using_block_ram_for_data_and_phase_factors {1}] [get_ips fft256_16bit]
create_ip_run [get_ips fft256_16bit]
