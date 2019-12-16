#------------------------------------------------------------------------------
# XXV_ETHERNET exceptions XDC file
# -----------------------------------------------------------------------------

set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] 6.400
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ */channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] 6.400
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/dclk}]] 6.400
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/dclk}]] 6.400
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/dclk}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] 18.000
set_max_delay -datapath_only -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/dclk}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad135_0*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] 18.000

