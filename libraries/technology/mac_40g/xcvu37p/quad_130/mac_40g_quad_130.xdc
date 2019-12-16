#------------------------------------------------------------------------------
# XXV_ETHERNET exceptions XDC file
# -----------------------------------------------------------------------------

set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad130_gen*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad130_gen*/dclk}]] -datapath_only 3.20
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad130_gen*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad130_gen*/dclk}]] -datapath_only 3.20
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad130_gen*/dclk}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad130_gen*/channel_inst/*_CHANNEL_PRIM_INST/TXOUTCLK}]] -datapath_only 10.000
set_max_delay -from [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad130_gen*/dclk}]] -to [get_clocks -of_objects [get_pins -hierarchical -filter {NAME =~ *quad130_gen*/channel_inst/*_CHANNEL_PRIM_INST/RXOUTCLK}]] -datapath_only 10.000